#!/usr/bin/env python3
"""Check the RENDERED IMAGES: if a person is in it, are they Black African?

Dr. Sama: "even so if there is human in the image it should follow the
rule."

That cannot be guaranteed from the prompt. A diffusion model will put a
person into an image that never asked for one, so any rule enforced at
prompt-build time is a hope. This checks the output instead.

WHY CLIP AND NOT PIXELS
-----------------------
The first attempt (check_skin_tones.py) used the standard RGB skin rule.
It does not work on cartoons: sand, clay, wood and palm fruit all satisfy
"red dominant, bright", so a camel on sand scored 70% skin while a
genuinely white image scored 2% light. That script is kept with a warning
on it; this one replaces it for this purpose.

CLIP is already a dependency (audit_images.py uses it). It is asked to
choose between three captions per image:

    a cartoon of a Black African person with dark brown skin
    a cartoon of a white European person with pale skin
    a cartoon with no people in it, only objects or animals

An image is FLAGGED when the white caption wins. That is a comparison
between captions on the same image, not an absolute score, so it does not
depend on a threshold anyone has to tune.

It is a review list, not a verdict. CLIP is wrong sometimes, especially on
a small cartoon face. Every flagged file should be opened before anything
is deleted or regenerated.

    python scripts/check_people_skin.py                  # whole pack
    python scripts/check_people_skin.py --since 2        # last 2 hours
    python scripts/check_people_skin.py --regen-list     # write keys file
"""
import argparse, json, os, time
from pathlib import Path

IMAGES = Path("android/install_time_assets/src/main/assets/images/vocabulary")
OUT = "contributions/wrong_skin_images.json"
KEYS = "contributions/wrong_skin_keys.txt"

CAPTIONS = [
    ("black",   "a cartoon of a Black African person with dark brown skin"),
    ("white",   "a cartoon of a white European person with pale skin"),
    ("nobody",  "a cartoon with no people in it, only objects or animals"),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--since", type=float, default=None,
                    help="only files modified in the last N hours")
    ap.add_argument("--dir", default=str(IMAGES))
    ap.add_argument("--batch", type=int, default=64)
    ap.add_argument("--regen-list", action="store_true",
                    help="also write a --keys-file of the flagged images")
    args = ap.parse_args()

    import torch
    from PIL import Image
    from transformers import CLIPModel, CLIPProcessor

    root = Path(args.dir)
    files = sorted(list(root.glob("*.webp")) + list(root.glob("*.png")))
    if args.since:
        cut = time.time() - args.since * 3600
        files = [f for f in files if f.stat().st_mtime >= cut]
    if not files:
        print("no images to check")
        return

    device = "cuda" if torch.cuda.is_available() else "cpu"
    name = "openai/clip-vit-base-patch32"
    print(f"loading {name} on {device}")
    model = CLIPModel.from_pretrained(name).to(device).eval()
    proc = CLIPProcessor.from_pretrained(name)

    labels = [c for _, c in CAPTIONS]
    with torch.no_grad():
        tok = proc(text=labels, return_tensors="pt", padding=True).to(device)
        tvec = torch.nn.functional.normalize(model.get_text_features(**tok), dim=-1)

    print(f"checking {len(files)} images")
    flagged = []
    for i in range(0, len(files), args.batch):
        part = files[i:i + args.batch]
        imgs, keep = [], []
        for f in part:
            try:
                imgs.append(Image.open(f).convert("RGB"))
                keep.append(f)
            except Exception:
                pass
        if not imgs:
            continue
        with torch.no_grad():
            px = proc(images=imgs, return_tensors="pt").to(device)
            ivec = torch.nn.functional.normalize(model.get_image_features(**px), dim=-1)
            sims = (ivec @ tvec.T).cpu()
        for f, row in zip(keep, sims):
            best = int(row.argmax())
            if CAPTIONS[best][0] == "white":
                flagged.append({
                    "file": f.name,
                    "white": round(float(row[1]), 4),
                    "black": round(float(row[0]), 4),
                    "nobody": round(float(row[2]), 4),
                    "margin": round(float(row[1] - row[0]), 4),
                })
        print(f"  {min(i + args.batch, len(files))}/{len(files)}"
              f"  flagged {len(flagged)}", end="\r")

    flagged.sort(key=lambda h: -h["margin"])
    print(f"\n\nFLAGGED {len(flagged)} of {len(files)}: "
          f"CLIP reads a white person as the best description.")
    os.makedirs("contributions", exist_ok=True)
    json.dump(flagged, open(OUT, "w"), indent=1)
    print(f"-> {OUT}")
    if args.regen_list and flagged:
        with open(KEYS, "w", encoding="utf-8") as fh:
            for h in flagged:
                fh.write(Path(h["file"]).stem + "\n")
        print(f"-> {KEYS}")
        print("   redraw them with:")
        print(f"     python scripts/generate_images.py generate --force "
              f"--format webp --keys-file {KEYS}")
    for h in flagged[:40]:
        print(f"  margin {h['margin']:+.3f}  white {h['white']:.3f} "
              f"black {h['black']:.3f}  {h['file']}")
    print("\nOPEN THESE BEFORE ACTING ON THEM. CLIP is wrong sometimes, "
          "especially on a small cartoon face.")


if __name__ == "__main__":
    main()
