# The duplicates — what they are and which ones I can safely merge

Dr. Sama, on the regenerated sample: *"while this pictures are not the best,
it do reveal still lots of duplicates"*. Correct. 41 files in that folder are
about twelve actual words.

The cause is not the generator. **One image key is one GLOSS, not one word**
(`audioKey + '__' + englishSlug`), and the dictionary import created a row
per gloss. So `tsentə` — one Awing word, one dictionary entry — became eight
cards:

```
tsentə  assemble, meet, heap up, join, put together, gather
tsentə  assemble
tsentə  gather
tsentə  heap up
tsentə  join
tsentə  meet
tsentə  put together
tsentə  assemble, meet, heap up
```

The comma-separated gloss list was exploded into separate rows, and then the
whole list was kept as a row too.

## Tier A — safe to merge. 571 groups, 1,315 cards → 571

**Identical Awing spelling**, character for character, tone marks included.
Only the English differs, and the differences are pieces of one gloss list.
No orthography judgement is involved — these are the same dictionary entry
entered several times.

`contributions/merge_tier_a_same_spelling.json`. **Removes 744 cards.**

Examples: `akwa'lə` (6 cards: question / temptation / criticism / interview /
the full list / a partial list), `aŋwa'lə` (5: book / school / knowledge),
`tsənkeelə` (5: round / globe shaped / spherical), `akoŋə` (5: stem / stalk
of maize).

## Tier B — NOT mine to decide. 425 groups, 1,055 cards

**Spelling differs only in tone marks**, and tone is phonemic in Awing:

```
ghó'kə   respect, honour, praise; worship
ghô'kə   honour, praise          <- high vs falling. Same word or not?
ghó'kə̌  respect, honour, praise
```

If these are one word, merging removes **630 more cards**. If the tone marks
are real distinctions, merging destroys them. The standing rule in CLAUDE.md
is that picking canonical spellings is an orthography decision and I do not
guess, so this list stays untouched until Dr. Sama rules on it.

`contributions/merge_tier_b_tone_differs.json`.

There is precedent for the fix either way — `awing_vocabulary.dart` line 7104
already carries `// REMOVED Session 61 Phase1: OCR clone, kept L3998`, so the
mechanism and the comment format exist.

## Total

| | groups | cards now | after | removed |
|---|---|---|---|---|
| Tier A, same spelling | 571 | 1,315 | 571 | **744** |
| Tier B, tone differs | 425 | 1,055 | 425 | 630 |
| both | 996 | 2,370 | 996 | 1,374 |

Tier A alone takes the pack from 8,227 cards to 7,483 and removes 744
pictures that were never telling a child anything new.

## Separately: a prompt lesson from the same sample

The celibate cards came back as couples holding hands. My prompt said
*"standing alone and smiling, **no wedding ring, a married couple holding
hands in the distance**"*. A positive prompt cannot say "not" — SDXL renders
every noun it is given, so naming a couple put a couple on the card, which is
the one thing the word means the absence of. Same reason `emptiness` said
"nothing inside it" and drew a full pot.

Fixed: describe only what should be **on** the card. "one young person
standing by themselves in an empty village courtyard, alone."
