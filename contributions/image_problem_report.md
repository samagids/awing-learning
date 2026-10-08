# Why the image folder looks full of duplicates — 2026-10-08

Dr. Sama, looking at the generated folder: *"why are there so much
duplicates. not sure which is which"* and *"celibate for instance does not
make sense. many picture like that"*.

Both are real. They are **three different problems** and only one of them is
the generator's fault.

**Important: every image in that folder was drawn with the OLD prompts.**
Nothing has been regenerated since the v1.24.5 prompt fix. Some of what is on
screen will change when the run happens; the rest will not, and those are
what this report is about.

---

## 1. Duplicates — the data, not the generator

There are **8,227 cards for 5,007 distinct Awing spellings**. 1,457 spellings
carry more than one card; the worst carries eleven.

One image key is `audioKey + '__' + englishSlug`, so **one card per gloss**,
not one per word. The dictionary gives a word several glosses, and each gloss
became its own card with its own picture.

Three different things are mixed together in that number:

| | cards | what it is |
|---|---|---|
| same spelling, same meaning | **735** | pure duplication — `achú'ə` has four cards for "pounded cocoyam", "pounded cocoyams", "cocoyams pounded and eaten with red soup…" |
| same spelling, different sense | ~2,400 | correct — `aghə'ə` is both "cave" and "frugality" |
| different spelling, same meaning | ~790 | the orthography question, already logged in `near_duplicate_review.md` |

**The 735 are the ones to act on.** They are listed as 565 merge groups in
`contributions/duplicate_glosses.json`, each with the gloss I would keep and
the ones that fold into it. **Not merged automatically** — which gloss is the
headword is a dictionary decision, not a script's.

## 2. "Not sure which is which" — the file names

`ENGLISH_SLUG_MAX = 32` cuts the gloss mid-phrase, so two different cards end
up as near-identical names:

```
achibemateene_cheap_and_undesirable_pr
achibemateene_cheap_and_undesirable_products_o
```

The app never shows these — it looks a card up by key — so this is a problem
for reviewing the folder by eye, not for the product. Fixing it means
changing the key format, which renames all 9,025 files and invalidates every
contributed-image record. Worth doing once, with the merge above, not
separately.

## 3. "Celibate does not make sense" — words with no visual referent

This one the prompt fix does **not** solve, and it would be dishonest to
imply otherwise.

`celibate` has six cards across four Awing spellings. The new prompt for one
of them is `a celibate, simple flat cartoon clipart…`, which is correct
English and carries the whole meaning. It will still produce a picture of a
person, because **a celibate person looks exactly like anyone else**. There
is no drawing that means celibacy. Same for `frugality`, `selfishness`,
`literacy`, `intelligence`, `corruption`, `carelessness`, `bad reputation`.

That is also why so many thumbnails look like the same crowd: every abstract
quality converges on the same generic scene of people.

**244 entries** are in this class — `contributions/no_visual_referent.json`.
Dr. Sama's own instruction already covers them: *"should be replaced by
images natives submit and is approved"*. These are that list. Until a photo
arrives they are better with **no image** than a wrong one — `hasImageSync()`
already filters an image-less word out of games and quizzes, so a gap is safe
and a wrong picture is not.

---

## What the prompt fix does and does not reach

| | count | fixed by the v1.24.5 prompts? |
|---|---|---|
| picture ignored the word (the hump case) | ~6,900 prompts changed | **yes** — needs the `--force` run |
| abstract quality, no visual referent | 244 | **no** — wants a native's photo or no image |
| one content word, no override (`a hump`) | 2,485 | **partly** — correct prompt, still a coin toss |
| duplicate cards for one word+meaning | 735 | **no** — data merge, Dr. Sama's call |
