"""
Energy-based silence trimmer for the Awing family-recording pipeline.

Mirrors the algorithm in lib/utils/silence_trim.dart EXACTLY so the on-
device pronunciation grader and the server-side recording ingestion
behave identically. When the Dart side decides "this kid recording has
1.4 sec of silence", this Python side makes the same decision for the
matching MP3 that ships in the PAD pack.

USAGE (as a library):
    from scripts.trim_silence import trim_audio_file, trim_audio_array

    # File-in-place rewrite (handles .wav/.mp3/.m4a via pydub):
    result = trim_audio_file("input.wav", "trimmed.wav")
    print(f"Removed {result.removed_sec:.2f}s of silence")

    # Pure numpy:
    import soundfile as sf
    audio, sr = sf.read("input.wav")
    trimmed, info = trim_audio_array(audio, sr)
    sf.write("trimmed.wav", trimmed, sr)

USAGE (CLI batch):
    python scripts/trim_silence.py path/to/dir              # trim every .wav/.mp3 in place
    python scripts/trim_silence.py file.wav file_out.wav    # single file, explicit output
    python scripts/trim_silence.py --dry-run path/to/dir    # report what WOULD be trimmed
    python scripts/trim_silence.py --pattern "*.m4a" path/  # filter by glob

The dry-run mode is the recommended first pass — review the per-file
"removed Xs" report before committing to in-place rewrites of the
PAD pack assets.

Why this exists:
- Family / kids tap Record, pause, speak, pause, tap Stop. Real
  recordings routinely have 0.5-2.5 seconds of silence padding.
- That silence inflates the PAD pack download size for every user
  (compressed silence still costs bytes).
- It also poisons the on-device pronunciation grader (DTW assigns
  high cost when aligning kid silence to native-speaker speech).
- Trimming server-side once means every device benefits.
"""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Tuple

import numpy as np

# ---------------------------------------------------------------------------
# Algorithm parameters — must match lib/utils/silence_trim.dart defaults
# ---------------------------------------------------------------------------
DEFAULT_SAMPLE_RATE = 16000
DEFAULT_WINDOW_MS = 10
DEFAULT_RELATIVE_THRESHOLD = 0.05
DEFAULT_HARD_FLOOR = 0.005
DEFAULT_PAD_MS = 20


@dataclass
class TrimInfo:
    """Diagnostic info from a single trim. Mirrors Dart TrimResult."""

    original_samples: int
    trimmed_samples: int
    sample_rate: int
    threshold_used: float
    all_silent: bool = False

    @property
    def original_sec(self) -> float:
        return self.original_samples / self.sample_rate

    @property
    def trimmed_sec(self) -> float:
        return self.trimmed_samples / self.sample_rate

    @property
    def removed_sec(self) -> float:
        return self.original_sec - self.trimmed_sec

    @property
    def keep_ratio(self) -> float:
        return 1.0 if self.original_samples == 0 else self.trimmed_samples / self.original_samples


def trim_audio_array(
    audio: np.ndarray,
    sample_rate: int = DEFAULT_SAMPLE_RATE,
    window_ms: int = DEFAULT_WINDOW_MS,
    relative_threshold: float = DEFAULT_RELATIVE_THRESHOLD,
    hard_floor: float = DEFAULT_HARD_FLOOR,
    pad_ms: int = DEFAULT_PAD_MS,
) -> Tuple[np.ndarray, TrimInfo]:
    """Trim leading/trailing silence from a 1-D float audio array.

    Algorithm (must match lib/utils/silence_trim.dart):
      1. Split into 10ms windows
      2. RMS energy per window
      3. threshold = max(peak * relative, hard_floor)
      4. Trim leading + trailing windows below threshold
      5. Pad 20ms on each side so plosives aren't clipped

    Returns (trimmed_audio, info). If audio was already <3 windows, or
    entirely silent, returns the original array unchanged with
    `info.all_silent=True` (for the silent case).
    """
    if audio.ndim > 1:
        # Average channels to mono if needed
        audio = audio.mean(axis=1).astype(np.float32, copy=False)
    else:
        audio = audio.astype(np.float32, copy=False)

    n = audio.shape[0]
    if n == 0:
        return audio, TrimInfo(
            original_samples=0,
            trimmed_samples=0,
            sample_rate=sample_rate,
            threshold_used=0.0,
        )

    window_size = round(sample_rate * window_ms / 1000)
    num_windows = n // window_size
    if num_windows < 3:
        return audio, TrimInfo(
            original_samples=n,
            trimmed_samples=n,
            sample_rate=sample_rate,
            threshold_used=0.0,
        )

    # Vectorized RMS per window — much faster than Python loop
    usable = num_windows * window_size
    windowed = audio[:usable].reshape(num_windows, window_size)
    energies = np.sqrt(np.mean(windowed * windowed, axis=1))
    peak = float(energies.max())
    threshold = max(peak * relative_threshold, hard_floor)

    active = energies >= threshold
    if not active.any():
        return audio, TrimInfo(
            original_samples=n,
            trimmed_samples=n,
            sample_rate=sample_rate,
            threshold_used=threshold,
            all_silent=True,
        )

    first_active = int(active.argmax())
    # argmax on reversed gives offset from the END
    last_active = num_windows - 1 - int(active[::-1].argmax())

    if first_active >= last_active:
        return audio, TrimInfo(
            original_samples=n,
            trimmed_samples=n,
            sample_rate=sample_rate,
            threshold_used=threshold,
            all_silent=True,
        )

    pad_windows = round(pad_ms / window_ms)
    first_active = max(0, first_active - pad_windows)
    last_active = min(num_windows - 1, last_active + pad_windows)

    start = first_active * window_size
    end = min(n, (last_active + 1) * window_size)
    trimmed = audio[start:end]
    return trimmed, TrimInfo(
        original_samples=n,
        trimmed_samples=trimmed.shape[0],
        sample_rate=sample_rate,
        threshold_used=threshold,
    )


def trim_audio_file(
    input_path: Path,
    output_path: Path,
    target_sample_rate: int = DEFAULT_SAMPLE_RATE,
    **trim_kwargs,
) -> TrimInfo:
    """Trim an audio file (any format pydub can read) and write the result.

    The output is always a 16 kHz mono PCM-16 WAV (or matching format if
    output_path has a non-.wav extension). Uses pydub for codec support.
    """
    try:
        from pydub import AudioSegment
    except ImportError as exc:  # pragma: no cover
        raise RuntimeError(
            "pydub is required for trim_audio_file. Install via: "
            "pip install pydub"
        ) from exc

    seg = AudioSegment.from_file(str(input_path))
    seg = seg.set_channels(1).set_frame_rate(target_sample_rate).set_sample_width(2)

    # to_numpy via samples array — int16 → float32 normalized
    samples = np.array(seg.get_array_of_samples(), dtype=np.float32) / 32768.0

    trimmed, info = trim_audio_array(
        samples,
        sample_rate=target_sample_rate,
        **trim_kwargs,
    )

    if info.all_silent or info.trimmed_samples == info.original_samples:
        # Nothing to do — copy through unchanged so caller doesn't have to
        # special-case "no-op trim"
        out_seg = seg
    else:
        # Convert back to int16 PCM AudioSegment
        out_int16 = np.clip(trimmed * 32768.0, -32768, 32767).astype(np.int16)
        out_seg = AudioSegment(
            out_int16.tobytes(),
            frame_rate=target_sample_rate,
            sample_width=2,
            channels=1,
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    fmt = output_path.suffix.lstrip(".").lower() or "wav"
    out_seg.export(str(output_path), format=fmt)
    return info


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def _format_info(path: Path, info: TrimInfo) -> str:
    if info.all_silent:
        flag = "  ⚠ ENTIRELY SILENT — left unchanged"
    elif info.removed_sec < 0.05:
        flag = "  (≤50ms removed — clean recording)"
    else:
        flag = f"  ✂ removed {info.removed_sec:.2f}s ({(1 - info.keep_ratio) * 100:.0f}%)"
    return (
        f"{path.name:<40}  "
        f"{info.original_sec:.2f}s → {info.trimmed_sec:.2f}s{flag}"
    )


def _cli_directory(
    src_dir: Path,
    pattern: str,
    dry_run: bool,
) -> None:
    matches = sorted(p for p in src_dir.rglob(pattern) if p.is_file())
    if not matches:
        print(f"No files matching '{pattern}' under {src_dir}")
        return

    total_removed_sec = 0.0
    total_trimmed = 0
    total_silent = 0
    print(f"Found {len(matches)} file(s). Trimming silence ...\n")
    for p in matches:
        try:
            if dry_run:
                # Read without writing, just compute info
                from pydub import AudioSegment

                seg = AudioSegment.from_file(str(p))
                seg = (
                    seg.set_channels(1)
                    .set_frame_rate(DEFAULT_SAMPLE_RATE)
                    .set_sample_width(2)
                )
                samples = (
                    np.array(seg.get_array_of_samples(), dtype=np.float32) / 32768.0
                )
                _, info = trim_audio_array(samples)
            else:
                # In-place rewrite via temp file
                tmp = p.with_suffix(p.suffix + ".trim.tmp")
                info = trim_audio_file(p, tmp)
                if not info.all_silent and info.removed_sec >= 0.05:
                    tmp.replace(p)
                else:
                    tmp.unlink(missing_ok=True)

            print(_format_info(p, info))
            if info.all_silent:
                total_silent += 1
            elif info.removed_sec >= 0.05:
                total_trimmed += 1
                total_removed_sec += info.removed_sec
        except Exception as exc:  # noqa: BLE001
            print(f"{p.name:<40}  ✗ ERROR: {exc}")

    print("")
    print(
        f"{'(DRY-RUN) Would trim' if dry_run else 'Trimmed'} "
        f"{total_trimmed} of {len(matches)} files — "
        f"saved {total_removed_sec:.1f} sec of silence."
    )
    if total_silent:
        print(f"⚠ {total_silent} file(s) were entirely silent (left unchanged).")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("source", help="File or directory to process")
    parser.add_argument(
        "output",
        nargs="?",
        help="Output file (only valid when source is a single file)",
    )
    parser.add_argument(
        "--pattern",
        default="*.wav",
        help="Glob pattern when source is a directory (default: *.wav). "
        "Try '*.mp3' for the PAD pack assets.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Report what would be trimmed without writing any files.",
    )
    args = parser.parse_args()

    src = Path(args.source)
    if not src.exists():
        print(f"✗ Source does not exist: {src}", file=sys.stderr)
        return 1

    if src.is_dir():
        _cli_directory(src, args.pattern, args.dry_run)
        return 0

    # Single-file mode
    if args.output:
        out = Path(args.output)
    else:
        out = src.with_stem(src.stem + ".trimmed")

    if args.dry_run:
        from pydub import AudioSegment

        seg = AudioSegment.from_file(str(src))
        seg = (
            seg.set_channels(1)
            .set_frame_rate(DEFAULT_SAMPLE_RATE)
            .set_sample_width(2)
        )
        samples = np.array(seg.get_array_of_samples(), dtype=np.float32) / 32768.0
        _, info = trim_audio_array(samples)
        print(_format_info(src, info))
        return 0

    info = trim_audio_file(src, out)
    print(_format_info(src, info))
    print(f"\nWrote: {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
