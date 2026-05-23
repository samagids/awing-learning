# Family Recordings

This folder is where downloaded `.webm` voice recordings live before they are
processed into the app's audio pipeline.

## Workflow

1. Run `scripts\serve_family_recorder.bat` from the project root. It serves
   the recorder at <http://localhost:8765/family_recorder.html> and opens
   your browser.
2. Each family member records by clicking their mic button on each Awing
   item. Recordings auto-download with names like:

   ```
   man_guidion__apo.webm
   woman_berlin__apo.webm
   boy_joel__apo.webm
   boy_janelle__apo.webm
   girl_joyce__apo.webm
   girl_jadyne__apo.webm
   ```

3. Move every downloaded file from your Downloads folder INTO this
   `family_recordings/` folder. Browser checkmarks (saved in localStorage)
   tell you which words each person has done.
4. After a recording session, run the upcoming
   `scripts\process_family_recordings.py` to convert the `.webm` files into
   `.mp3` and copy them into the proper Play Asset Delivery directory.

## Filename convention

```
{voice}_{name}__{audio_key}.webm
└─ voice ── man / woman / boy / girl  (matches the 4 native-voice tiers)
└─ name ─── lowercase given name      (guidion / berlin / joel / janelle / joyce / jadyne)
└─ audio_key ── same key used by generate_audio_edge.py
```

Disambiguated tonal collisions use `__2`, `__3` suffixes on the key.

## Notes

* Recordings stay private to this folder until you explicitly run the
  processing script.
* If you re-record an item, the browser auto-downloads a new file with
  the same name. Replace the old one in this folder.
* `.gitignore` keeps `*.webm` and `*.mp3` out of version control by default.
