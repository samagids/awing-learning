#!/usr/bin/env python3
"""
Generate vocabulary illustration images for Awing AI Learning app.

Uses SDXL Turbo (Stable Diffusion XL Turbo) running locally on your NVIDIA GPU
to generate kid-friendly cartoon illustrations. No internet needed after first
model download (~5GB). Falls back to Twemoji emoji when GPU is unavailable.

Usage:
  python generate_images.py generate                    # Generate all (GPU + emoji fallback)
  python generate_images.py generate --category body    # Generate for one category
  python generate_images.py generate --force            # Regenerate existing images
  python generate_images.py generate --emoji-only       # Use only emoji (no GPU)
  python generate_images.py list                        # Show status
  python generate_images.py clean                       # Remove generated images
  python generate_images.py test                        # Generate 5 test images

Requirements:
  pip install diffusers transformers accelerate Pillow
  NVIDIA GPU with >= 4GB VRAM (CUDA)
  First run downloads SDXL Turbo model (~5GB, cached in ~/.cache/huggingface/)
"""

import os

# Must be set BEFORE torch initialises CUDA, so it lives at the top of the
# module rather than next to the pipeline. expandable_segments lets the
# allocator grow a block instead of hunting for a contiguous one, which is
# what fails after thousands of generations in one process.
os.environ.setdefault("PYTORCH_CUDA_ALLOC_CONF", "expandable_segments:True")
import sys
import re
import json
import time
import argparse
import hashlib
import itertools
import math
import unicodedata
from pathlib import Path
from io import BytesIO

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
except ImportError:
    print("ERROR: Pillow not installed. Run: pip install Pillow")
    sys.exit(1)

# ============================================================
# CONFIGURATION
# ============================================================

SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
VOCAB_FILE = PROJECT_ROOT / "lib" / "data" / "awing_vocabulary.dart"
# AwingPhrase literals live in awing_vocabulary.dart alongside AwingWord.
# AwingSentence literals live in sentences_screen.dart.
# StorySentence literals live in stories_screen.dart.
PHRASES_FILE = VOCAB_FILE
SENTENCES_FILE = PROJECT_ROOT / "lib" / "screens" / "medium" / "sentences_screen.dart"
STORIES_FILE = PROJECT_ROOT / "lib" / "screens" / "stories_screen.dart"
# Default output: PAD install-time asset pack (for Play Store size limits)
# Override with --output-dir flag
OUTPUT_DIR = PROJECT_ROOT / "android" / "install_time_assets" / "src" / "main" / "assets" / "images" / "vocabulary"
EMOJI_CACHE_DIR = SCRIPT_DIR / "_emoji_cache"

# Filename length cap for sentence/story keys. Very long Awing sentences would
# produce illegal filenames on some filesystems; cap at 60 chars of the
# audio_key portion (excluding the "sentence_"/"story_" prefix).
MULTI_WORD_KEY_MAX = 60

# Image settings
IMAGE_SIZE = 256
CORNER_RADIUS = 24
BORDER_WIDTH = 6

# SDXL Turbo generates at 512x512, we downscale to 256x256
GENERATION_SIZE = 512

# Model: SDXL Turbo — 1-step generation, fast, ~4GB VRAM
SDXL_TURBO_MODEL = "stabilityai/sdxl-turbo"

# Twemoji CDN (fallback when GPU unavailable)
TWEMOJI_BASE = "https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72"

# Category colors for border/accent
CATEGORY_COLORS = {
    "body":        (219, 112, 147),
    "animals":     (60, 179, 113),
    "nature":      (70, 130, 180),
    "food":        (255, 140, 50),
    "actions":     (138, 90, 220),
    "things":      (160, 120, 80),
    "family":      (32, 178, 170),
    "descriptive": (255, 165, 0),
    "numbers":     (220, 60, 60),
    "default":     (130, 130, 150),
}

# ============================================================
# AI PROMPT STYLE
# Every prompt gets this suffix for consistent kid-friendly style
# ============================================================

# v1.24.0 (NACDA DMV feedback): "change the images and items to mimic the
# people. dark skin images for people or child in the images and other
# objects should be things from Awing."
#
# The old suffix said nothing about who the children were, and SDXL's
# unprompted default for "a cartoon child" is a light-skinned Western one.
# Awing children opened this app and did not see themselves.
#
# Two separate levers, because they fail differently:
#   PEOPLE_STYLE  - stated FIRST so it carries weight in CLIP's 77-token
#                   budget. Skin tone described plainly and more than once;
#                   a single adjective gets diluted by the rest of the
#                   prompt and comes out inconsistent.
#   STYLE_SUFFIX  - the shared look, now anchored in the Cameroonian
#                   Grassfields rather than nowhere in particular.
#
# There is NO negative prompt: SDXL Turbo runs at guidance_scale=0, where
# negative prompts are ignored. "no text, no words" in the positive prompt is
# the only lever available. (An earlier comment here claimed negatives were
# handled in generate_ai_image() - they never were.)
# v1.24.0b: a FIXED PEOPLE_STYLE produced 9,000 pictures of the same boy -
# same short afro, same yellow shirt, same green field. Dr. Sama, on seeing
# the first sample: "wonderful if we can make it have variety or hair
# styles". So the look is drawn per-word from these pools instead, keyed on
# a hash of the image key: deterministic (the same word regenerates
# identically) but spread across 9 x 8 x 4 x 5 = 1,440 combinations.
# (subject, gender, is_child). Weighted toward children - this is a
# children's app - but not exclusively, because "grandmother", "father" and
# "farmer" are real vocabulary and a village has adults in it.
PERSONA_PEOPLE = [
    ("young boy", "m", True),
    ("little boy", "m", True),
    ("teenage boy", "m", True),
    ("young girl", "f", True),
    ("little girl", "f", True),
    ("teenage girl", "f", True),
    ("man", "m", False),
    ("woman", "f", False),
    ("grandfather", "m", False),
    ("grandmother", "f", False),
]

# Gendered, because the first pass put two puff buns on a grandfather.
PERSONA_HAIR = {
    "m": [
        "short natural afro hair", "a neatly shaved head", "short twists",
        "long locs", "a high-top afro",
    ],
    "f": [
        "cornrow braids", "two puff buns", "braided hair with colorful beads",
        "short natural afro hair", "a bright patterned head wrap",
        "long twists",
    ],
}

PERSONA_SKIN = [
    "dark brown skin", "deep brown skin", "rich dark skin",
    "warm brown skin",
]

# Elders get their own pool rather than a "greying " prefix on the general
# one - that produced "greying a neatly shaved head" and would have put grey
# on a head WRAP rather than on hair.
PERSONA_HAIR_ELDER = {
    "m": [
        "short grey hair", "a bald head with grey stubble",
        "grey-flecked short afro hair",
    ],
    "f": [
        "grey cornrow braids", "short grey afro hair",
        "a bright patterned head wrap over grey hair",
    ],
}

# Keyed on (gender, is_child), because the first pass also dressed a man in
# a wrapper dress and a grandfather in a school uniform.
# NACDA DMV asked for the people and the objects to look like Awing. One of
# the adult-male options was "bright kente-pattern cloth", which is Ashanti
# and Ewe - Ghana, 1,000 km west. Awing is in the Bamenda Grassfields of
# Cameroon's North West Region, whose own regalia is TOGHU (atoghu): heavy
# black velvet embroidered in red and white with sun, moon, star and animal
# motifs, worn with a matching wrapper.
#   https://mimimefoinfos.com/toghu-a-unique-cameroonian-identity/
# Ankara print stays - it is everyday wear across the region - but the one
# borrowed-from-elsewhere entry is replaced by the local one, and toghu is
# offered to adult women too, where it is worn just as much.
_TOGHU = "a black toghu robe with red and white embroidery"

PERSONA_CLOTHES = {
    ("m", True): [
        "a colorful Ankara print shirt", "a simple bright t-shirt",
        "a plain school uniform",
    ],
    ("f", True): [
        "a colorful Ankara print dress", "a simple bright t-shirt",
        "a plain school uniform",
    ],
    ("m", False): [
        "a colorful Ankara print shirt", _TOGHU,
        "a plain work shirt",
    ],
    ("f", False): [
        "a colorful Ankara print dress", "a patterned wrapper dress",
        _TOGHU,
    ],
}


def _persona_bits(seed_key: str):
    """Deterministic (hair, skin, clothes, subject) for one image key."""
    h = hashlib.md5(("persona:" + (seed_key or "")).encode("utf-8")).digest()
    subject, gender, is_child = PERSONA_PEOPLE[h[3] % len(PERSONA_PEOPLE)]
    elder = subject.startswith("grand")
    hair_pool = PERSONA_HAIR_ELDER[gender] if elder else PERSONA_HAIR[gender]
    hair = hair_pool[h[0] % len(hair_pool)]
    skin = PERSONA_SKIN[h[1] % len(PERSONA_SKIN)]
    clothes_pool = PERSONA_CLOTHES[(gender, is_child)]
    clothes = clothes_pool[h[2] % len(clothes_pool)]
    return hair, skin, clothes, subject


def people_style(seed_key: str) -> str:
    """Opening clause for a prompt that must depict a person.

    Replaces the old fixed PEOPLE_STYLE constant. Skin tone still leads -
    CLIP weights early tokens most and a single adjective late in the prompt
    gets diluted - but everything after it varies per word.
    """
    hair, skin, clothes, subject = _persona_bits(seed_key)
    return (f"a Cameroonian {subject} with {skin}, {hair}, "
            f"wearing {clothes}, ")


# Back-compat for any caller that still wants a single fixed string (none in
# this file; kept so an external script importing it does not break).
PEOPLE_STYLE = people_style("")

# NACDA DMV, Sept 2026: "change the images and items to mimic the people.
# dark skin images for people or child in the images".
#
# PEOPLE_STYLE covers the prompts BUILT from a category, but ~387 of the 1,108
# hand-written PROMPT_OVERRIDES name a human ("a child's hand waving hello",
# "a cartoon family dinner table") and carry no skin descriptor at all, so
# SDXL renders its default — white. Those overrides are the curated ones,
# i.e. the common words children actually meet. Rather than hand-editing 387
# strings, qualify the human noun at prompt-build time.
#
# Deliberately inserts BEFORE the noun rather than appending a clause: CLIP
# weights early tokens more heavily, and a trailing ", dark skin" reads as a
# separate subject often enough to be ignored.
_HUMAN_NOUN_RE = re.compile(
    r"\b(children|child|kids|kid|people|person|men|man|women|woman|"
    r"boys|boy|girls|girl|babies|baby|toddler|"
    r"mother|father|parents|parent|family|families|grandmother|grandfather|"
    r"brother|sister|brothers|sisters|twins|friend|friends|"
    r"teacher|student|pupil|farmer|hunter|fisherman|chief|elder|elders|"
    r"adult|adults|villager|villagers|crowd|mourners|dancer|drummer|"
    r"king|queen|nurse|doctor|trader|traders|kings|queens|nurses|doctors|"
    # Added after round 2: these appeared in glosses, were not matched, and
    # so were rendered with SDXL's default (white) complexion.
    r"enemy|enemies|warrior|warriors|soldier|soldiers|swimmer|swimmers|"
    r"thief|thieves|fon|wizard|witch|worker|workers|guest|guests|"
    r"stranger|strangers|neighbour|neighbor|bride|groom|widow|widower|"
    r"singer|singers|rider|cook|seller|buyer|herder|weaver|potter|"
    r"blacksmith|carpenter|messenger|servant|slave|orphan|patient|"
    r"human|humans|person\'s|figure|figures|"
    # Round 3, 2026-10-08. Dr. Sama on the newest batch: "with white people
    # in them." These role nouns were in 124 prompts - most of them ones I
    # had just written - and none of them matched here, so africanize_people()
    # inserted nothing AND _is_person_prompt() said False, which meant the
    # object suffix, which carries no skin clause. Nothing in the prompt said
    # the person was African, so SDXL drew its default.
    r"runner|runners|traveller|traveler|travellers|travelers|tailor|"
    r"crier|passer-by|passerby|listener|listeners|lender|borrower|"
    r"official|officials|diviner|diviners|shepherd|shepherds|prisoner|"
    # Round 4, Session 66v. Found by listing every gloss whose head is a
    # person role and checking whether africanize_people() fired: 15 did
    # not, so "a priest" and "a slaughterer" went to SDXL with no tone
    # named at all. These are the role nouns the dictionary actually uses.
    # Deliberately NOT here: male, female (adjectives - "a male goat"),
    # host, guide (not always a person), god, angel, demon, nobody.
    r"accuser|ancestor|ancestors|apostle|bachelor|baptist|barber|beggar|"
    r"bishop|boss|boyfriend|butcher|butler|catcher|clerk|co-wife|"
    r"companion|councillor|cripple|daughter|daughter-in-law|delegate|"
    r"descendant|disciple|divorcee|drunkard|dwarf|escort|fool|gentile|"
    r"giant|girlfriend|giver|glutton|godfather|godmother|guard|heir|"
    r"heiress|hunchback|husband|hypocrite|imbecile|judge|junior|liar|"
    r"midwife|mourner|murderer|namesake|nephew|niece|photographer|priest|"
    r"priests|prophet|prostitute|roofer|ruler|saviour|senior|simpleton|"
    r"sinner|slaughterer|son|son-in-law|sorcerer|spinster|stepdaughter|"
    r"stepfather|stepmother|stepson|traitor|unbeliever|wife|youth|"
    r"prisoners|secretary|treasurer|announcer|tailors|"
    r"youngster|youngsters|tapper|carver|builder|carrier|sweeper|"
    r"visitor|visitors|owner|master|helper|leader|speaker|writer|reader|"
    r"driver|player|players|clan|follower|followers|inhabitant|"
    r"someone|somebody)\b",
    re.I,
)

# BROADER than _HUMAN_NOUN_RE: anything that puts human SKIN on the card,
# including a part of a person standing in for the whole.
#
# "a cartoon hand with one finger pointing up" has no person noun in it, so
# it took the object path with no skin instruction - and a hand is skin. The
# backdrop decision stays with _HUMAN_NOUN_RE, because "a hand pressing a
# button" does not want a Grassfields landscape behind it; only the SKIN
# decision uses this.
_BODY_PART_RE = re.compile(
    r"\b(hands|hand|palms|palm|fingers|finger|thumb|arms|arm|"
    r"feet|foot|legs|leg|knees|knee|face|cheeks|cheek)\b", re.I)

_HUMAN_REF_RE = re.compile(
    _HUMAN_NOUN_RE.pattern[:-3]  # drop the trailing )\b
    # Only parts that are unmistakably a PERSON'S. "back", "hair", "mouth",
    # "head", "eye" and "face" all belong to animals too: the camel prompt
    # ("two large rounded humps rising from its back") matched on "back" and
    # was handed a clause about people.
    + r"|hand|hands|palm|palms|finger|fingers|thumb|thumbs|"
      r"arm|arms|elbow|elbows|wrist|wrists|knee|knees|cheek|cheeks)\b",
    re.I,
)

# Already carries a skin descriptor (PEOPLE_STYLE itself, or an override we
# hand-wrote). Keeps the function idempotent, which matters because the
# category prompts already start with PEOPLE_STYLE.
# "Cameroonian" is NOT a skin tone and must not count as one. It used to be
# in this list, so any override that said "a Cameroonian boy" satisfied the
# test, africanize_people() skipped the insertion, and the prompt went to
# SDXL naming a nationality and no colour at all. That is how a tan hand got
# onto the `finger` card after three rounds of strengthening the wording.
_SKIN_DESCRIBED_RE = re.compile(
    r"(?:dark|deep|rich|warm)\s+(?:brown\s+)?skin"
    # "a dark brown hand" states the tone without the word "skin", and was
    # being qualified a second time: "a dark brown very dark brown Black
    # African hand".
    r"|(?:dark|deep|rich|warm)\s+brown\b"
    r"|dark[- ]skinned|Black African",
    re.I,
)


# Nouns that fix the gender of the figure, so hair can be chosen without
# contradicting the gloss. Anything not listed here gets no hair clause.
_NOUN_GENDER = {
    "man": "m", "men": "m", "boy": "m", "boys": "m", "father": "m",
    "grandfather": "m", "brother": "m", "brothers": "m", "king": "m",
    "chief": "m", "fon": "m", "groom": "m", "widower": "m",
    "fisherman": "m", "blacksmith": "m",
    "woman": "f", "women": "f", "girl": "f", "girls": "f", "mother": "f",
    "grandmother": "f", "sister": "f", "sisters": "f", "queen": "f",
    "bride": "f", "widow": "f",
}

_ELDER_NOUNS = {"grandfather", "grandmother", "elder", "elders"}


def africanize_people(prompt: str, seed_key: str = "") -> str:
    """Qualify the first human noun in `prompt` as dark-skinned and African.

    The override text keeps its own subject ("a cartoon mother holding a
    baby" stays a mother), so only the LOOK varies per word - skin tone and
    hair - never the subject. Age and gender come from the override itself.

    No-op when the prompt names no person (a yam, a drum, the number 4) or
    already says so. Returns the prompt unchanged in both cases, so it is
    safe to run over every prompt rather than only the ones we think need it.
    """
    if _SKIN_DESCRIBED_RE.search(prompt):
        return prompt
    m = _HUMAN_NOUN_RE.search(prompt)
    if not m:
        # A body part with no person attached - "a hand squeezing a lemon".
        # The trailing clause alone loses to the early tokens, so qualify the
        # part itself.
        mp = _BODY_PART_RE.search(prompt)
        if mp:
            # "a cartoon dark brown skinned hand with one finger pointing
            # up" still came back a tan hand. At 4 steps a single adjective
            # in front of the noun is not enough; naming the people as well
            # as the tone is. Verified on ntsenge__finger.
            return (prompt[:mp.start()] + "very dark brown Black African "
                    + prompt[mp.start():] + ", deep dark brown skin tone")
        return prompt
    _hair, skin, _clothes, _subject = _persona_bits(seed_key)
    noun = prompt[m.start() : m.end()].lower()

    # Skin qualifier goes immediately before the noun - short, and it cannot
    # break the phrase.
    out = prompt[: m.start()] + f"Cameroonian {skin} " + prompt[m.start() :]

    # Hair is APPENDED, never spliced mid-phrase, and only when the noun
    # itself tells us the gender - otherwise we would put beads on a chief.
    #
    # v1.24.5: and only when the person is the SUBJECT. On a prompt whose
    # point is an object or a body feature the person is context, and a
    # hair clause tacked on the end lands where the prompt is weakest:
    #
    #   "the curved rounded hump on the upper back of a standing man seen
    #    from the side, his back bent forward, long locs"
    #
    # The last thing the model reads is hair, on a card that exists to show
    # a hump. If the human noun does not appear near the front, the persona
    # is not what is being depicted and the tokens belong to the subject.
    gender = _NOUN_GENDER.get(noun) if m.start() <= 25 else None
    if gender:
        pool = (PERSONA_HAIR_ELDER[gender]
                if noun in _ELDER_NOUNS else PERSONA_HAIR[gender])
        h = hashlib.md5(("hair:" + (seed_key or "")).encode("utf-8")).digest()
        out = f"{out}, {pool[h[0] % len(pool)]}"

    # "an dark brown skin ..." -> "a ..." (wrong article before a consonant).
    out = re.sub(r"\ban (Cameroonian)", r"a \1", out)
    return out


# The first sample asked for "Grassfields setting" AND "white background" in
# the same prompt. They fight, the setting won, and every object ended up
# buried in a busy green field - an open gourd read as a doorway, a yam as
# scenery. On a vocabulary card the ITEM has to be identifiable, which is
# half of "ensure the pictures match the words".
#
# So: two suffixes. A person gets a simple Grassfields backdrop (that is the
# whole point of the NACDA request). An object gets a plain background and
# nothing competing with it.
_STYLE_COMMON = (
    "cute cartoon illustration for children, "
    "simple flat design, bright colorful, "
    "friendly and cheerful, "
    "no text, no words, no letters, "
    "digital art, clipart style"
)

# The trailing skin clause is on BOTH suffixes on purpose. africanize_people()
# and people_style() only fire when the prompt is RECOGNISED as depicting a
# person. Plenty do not get recognised: "be carried away by water current" is
# categorised `things`, so it took the object path with no persona and no
# skin guidance - and SDXL drew a (white) person anyway, because the gloss
# means a person. A negative prompt cannot win against a gloss whose meaning
# requires a human. So the instruction goes everywhere: if a person appears
# at all, by any route, they are Black African.
# RETIRED as a suffix, 2026-10-08. Kept only so _is_person_prompt() can
# strip it from a legacy string.
#
# This one clause caused the whole day's back-and-forth. It is a sentence
# whose subject is "people", so:
#   * on every prompt  -> it is the only noun phrase in "a what" or "a turf
#                         of grass", and SDXL draws the people.
#   * conditionally    -> every word I forgot to list (runner, tailor,
#                         crier, hands) got no skin instruction at all and
#                         came back white.
# Both failures are the same bug: a SENTENCE ABOUT PEOPLE cannot double as
# an ADJECTIVE ON THE SUBJECT.
#
# Replaced by two mechanisms that cannot fail open, neither of which needs
# to guess whether a person is present:
#   1. africanize_people() inserts "Cameroonian <skin>" immediately BEFORE
#      a human noun. It only fires when there IS one, so it can never add a
#      person to an object card - and when it fires, the skin is attached
#      to the subject where CLIP weights it, not trailing at the end.
#   2. _NEGATIVE_COMMON bans caucasian / white / pale / tan / peach / olive
#      skin on EVERY prompt, with no detection involved. If a person
#      appears by a route nobody predicted, that is what catches them.
_SKIN_CLAUSE = "any people shown are Black African with dark brown skin"

# ORDER MATTERS. CLIP truncates at 77 tokens and silently drops the tail.
# The scene suffix used to end with the skin clause, so on the 1,548 prompts
# that run long it was simply cut off - the log filled with
#   "truncated ... ['black african with dark brown skin, digital art,
#    clipart style']"
# For a person-path prompt that was harmless (people_style() states skin at
# character ~30), but a SENTENCE prompt gets no persona - skin is injected
# only if africanize_people() finds a human noun, and "He went to the
# market" has none. 94 sentence/story scenes lost their only skin
# instruction that way. The clause now comes FIRST in the suffix, where it
# cannot be truncated, and the suffix is shorter so less is lost generally.
# NO SKIN CLAUSE IN THE SUFFIX, on purpose. See the note on _SKIN_CLAUSE.
STYLE_SUFFIX_SCENE = (
    "cute cartoon illustration for children, "
    "simple Cameroonian Grassfields background, "
    "flat design, bright colorful, no text, no words, "
    "digital art, clipart style"
)

# Deliberately SHORT. Every style token competes with the subject for the
# model's attention, and the object suffix used to open with "cute cartoon
# illustration FOR CHILDREN ... FRIENDLY AND CHEERFUL", which is a direct
# instruction to draw a happy child. For an object prompt that phrasing was
# actively causing the bug.
_PLAIN_BODY = (
    "simple flat cartoon clipart, bright colors, "
    "single object centered, plain white background"
)

# WITH the skin clause - kept for any caller that wants the old string.
STYLE_SUFFIX_PLAIN = _PLAIN_BODY

# WITHOUT it, and this is what an object prompt gets now.
#
# "any people shown are Black African with dark brown skin" was on the object
# suffix too, on the reasoning above. The cost was not visible until the
# contact sheets: for a gloss with no concrete noun of its own the clause is
# the ONLY noun phrase in the prompt, so it stops being a qualifier and
# becomes the subject.
#
#   "a cartoon emptiness, any people shown are Black African with dark
#    brown skin, simple flat cartoon clipart, ..."
#
# SDXL drew a Black African. 665 of the 1,485 worst-ranked images were
# category `things` for exactly this reason - the template contains no person,
# so the suffix supplied one.
#
# Dropping it is safe because the protection does not depend on it:
# _NEGATIVE_COMMON opens with "caucasian, pale skin, light skin, european
# features" and is on EVERY prompt, and at GUIDANCE_SCALE 1.5 negatives are
# active. So a gloss that pulls in a person despite the object negative still
# does not get a white one.
STYLE_SUFFIX_OBJECT = _PLAIN_BODY

# Back-compat alias for anything importing the old name.
STYLE_SUFFIX = STYLE_SUFFIX_SCENE


def _is_person_prompt(prompt: str, category: str) -> bool:
    """Does this prompt depict a person or a scene with people in it?

    _SKIN_CLAUSE is stripped first: it contains the word "people", so once it
    was appended to every suffix this matched EVERYTHING, and the object
    negative prompt ("person, people, child...") silently stopped being used.
    """
    # "nature" was in this list, so every landscape got the Grassfields
    # scene suffix AND the skin clause, and a turf of grass came back with
    # people standing on it. A nature scene does not need a person in it.
    if category in ("phrase", "sentence", "story"):
        return True
    return bool(_HUMAN_NOUN_RE.search(prompt.replace(_SKIN_CLAUSE, "")))


def _style_suffix_for(prompt: str, category: str) -> str:
    """Scene backdrop for people and landscapes, plain for objects.

    An object prompt gets STYLE_SUFFIX_OBJECT, which carries no skin clause -
    see the comment on it.
    """
    if _is_person_prompt(prompt, category):
        return STYLE_SUFFIX_SCENE
    # A prompt with a hand or a face in it is skin, and skin with no
    # instruction comes out white. A prompt with NEITHER must not carry the
    # clause at all: it says "any people shown are Black African with dark
    # brown skin", and on "a what" or "a turf of grass" that phrase is the
    # only concrete noun in the prompt, so SDXL draws the people.
    #
    # I made this unconditional this morning to stop white hands, having
    # failed three times to list every word that counts as a person. That
    # traded one fault for a worse one - Dr. Sama: "why do all the images
    # have people in them. ake for instance meaning what has people in it."
    #
    # Conditional again, but it is no longer the same gamble: _HUMAN_REF_RE
    # now covers role nouns AND body parts, and _NEGATIVE_OBJECT names
    # person/people/child/face/crowd plus caucasian, white person, pale,
    # tan, peach and olive skin. An object prompt is defended by the
    # negative; a person prompt is defended by the clause.
    if _HUMAN_REF_RE.search(prompt.replace(_SKIN_CLAUSE, "")):
        return STYLE_SUFFIX_PLAIN
    return STYLE_SUFFIX_OBJECT
# ============================================================
# PROMPT OVERRIDES
# Custom AI prompts for words where the English definition alone
# doesn't produce good results. All prompts are kid-friendly.
# ============================================================

# Shared so the several glosses that all mean "achu" cannot drift apart.
_ACHU_PLATE = (
    "a cartoon plate of achu, a smooth white mound of pounded cocoyam with "
    "a well of yellow palm oil soup in the middle, Cameroonian food"
)
_ACHU_BOWL = (
    "a cartoon small round carved wooden bowl of yellow achu palm oil soup"
)
_COCOYAM_LEAF = (
    "a large green heart-shaped cartoon cocoyam taro leaf"
)
_PLANT_COCOYAM = (
    "a cartoon farmer planting taro cocoyam corms in a field"
)

PROMPT_OVERRIDES = {
    # Body parts — clear simple illustrations
    "hand": "a child's hand waving hello",
    "head": "a happy child's face and head",
    "nose": "a cartoon face showing a cute nose",
    "neck": "a cartoon giraffe with a long neck",
    "back": "a child stretching showing their back",
    "shoulder": "a cartoon child pointing to shoulder",
    "blood": "a cartoon red blood drop with a happy face",
    "leg": "a cartoon child's leg running",
    "tongue": "a funny cartoon face sticking tongue out",
    "body": "a happy cartoon child standing with arms out",
    "eye": "a big sparkling cartoon eye",
    "ear": "a cartoon bunny with big ears",
    "liver": "a friendly cartoon liver organ with a smile",
    "intestine": "a cartoon digestive system simple illustration",
    "chest": "a cartoon superhero child showing chest",
    "breastbone": "a cartoon skeleton chest bone",
    "mouth": "a big cartoon smiling mouth",
    "tooth": "a happy cartoon white tooth with a smile",
    "hair": "a cartoon child with colorful wild hair",
    "bone": "a cartoon dog bone",
    "stomach": "a cartoon child holding tummy after eating",
    "hip": "a cartoon child dancing showing hips",
    "foot": "a cartoon bare foot",
    "crown": "a golden cartoon crown on a head",
    "beard": "a friendly cartoon man with a fluffy beard",
    "breast": "a cartoon mother holding a baby lovingly",
    "knee": "a cartoon child with a bandage on knee",
    "wing": "a cartoon bird with colorful spread wings",
    "navel": "a simple labelled outline diagram of a torso wearing a t-shirt, an arrow pointing to the middle",
    "thigh": "a cartoon chicken drumstick",
    "soul": "a glowing cartoon heart with sparkles",
    "spirit": "a cartoon white dove flying in sunshine",
    "heart": "a big red cartoon heart with sparkles",
    # NOT "rosy pink cheeks" — that phrase drags SDXL toward light skin no
    # matter what africanize_people() prepends.
    "cheek": "a cartoon child with round full cheeks",
    "chin": "a cartoon face pointing at chin",
    "elbow": "a boy holding up his bent arm, pointing at his elbow",
    "finger": "a boy holding up one hand with the index finger raised",
    "jaw": "a cartoon dinosaur with a big jaw",
    "forehead": "a cartoon child thinking with hand on forehead",
    "rib": "a cartoon rib bones",
    "palm": "a girl holding up one open hand, palm facing the viewer",
    "throat": "a cartoon child singing loudly",
    "skin": "a cartoon child with smooth dark brown skin smiling",
    "waist": "a Cameroonian woman in a full-length wrapper dress, a wide cloth belt tied at the waist",
    # Animals — cute cartoon versions
    "ram": "a cute cartoon ram with curly horns",
    "louse": "a tiny cartoon louse bug with big eyes",
    "locust": "a cute cartoon grasshopper on a leaf",
    "antelope": "a cute cartoon antelope running in savanna",
    "fish": "a colorful cartoon tropical fish",
    "snake": "a cute friendly cartoon green snake smiling",
    "dog": "a happy cartoon puppy wagging its tail",
    "cat": "a cute cartoon kitten playing with yarn",
    "chicken": "a cartoon hen with her little chicks",
    "bird": "a colorful cartoon bird singing on a branch",
    "elephant": "a cute small cartoon elephant with big ears",
    "lion": "a friendly cartoon lion cub with a fluffy mane",
    "hippo": "a happy cartoon hippo in water",
    "mosquito": "a funny cartoon mosquito with big eyes",
    "tortoise": "a cute cartoon tortoise with a patterned shell",
    "pig": "a cute pink cartoon piglet in mud",
    "frog": "a happy green cartoon frog on a lily pad",
    "toad": "a cartoon bumpy toad sitting on a rock",
    "giraffe": "a cute tall cartoon giraffe eating leaves",
    "donkey": "a friendly cartoon donkey with big ears",
    "leopard": "a cute cartoon leopard cub with spots",
    "butterfly": "a beautiful colorful cartoon butterfly",
    "rat": "a cute cartoon mouse with big round ears",
    "shrimp": "a cute cartoon pink shrimp",
    "squirrel": "a cute cartoon squirrel holding an acorn",
    "rooster": "a colorful cartoon rooster crowing at sunrise",
    "spider": "a cute friendly cartoon spider with big eyes",
    "cow": "a friendly cartoon cow in a green field",
    "monkey": "a playful cartoon monkey swinging from a vine",
    "snail": "a cute cartoon snail with a colorful shell",
    "owl": "a cute cartoon owl on a branch at night",
    "duck": "a cute cartoon yellow duck in water",
    "goat": "a cute cartoon goat on a hill",
    "bee": "a cute cartoon bumblebee on a flower",
    "ant": "a cartoon ant carrying a leaf",

    # Nature — bright colorful scenes
    "river": "a cartoon river flowing through green hills",
    "water": "a cartoon splash of blue water drops",
    "sky": "a cartoon blue sky with fluffy white clouds",
    "sun": "a happy cartoon sun with a smiling face",
    "rain": "cartoon rain drops falling from clouds with rainbow",
    "wind": "cartoon leaves blowing in the wind",
    "grass": "cartoon bright green grass with flowers",
    "thunder": "cartoon lightning bolt in dark clouds",
    "night": "cartoon night sky with moon and stars",
    "morning": "cartoon sunrise over green hills",
    "evening": "cartoon orange sunset sky",
    "road": "cartoon winding road through countryside",
    "waterfall": "cartoon beautiful waterfall in jungle",
    "ground": "cartoon earth soil cross-section with worm",
    "shadow": "cartoon child making shadow puppet",
    "valley": "cartoon green valley between mountains",
    "mountain": "cartoon snowy mountain peak",
    "moonlight": "cartoon full moon shining over landscape",
    "forest": "cartoon colorful forest with friendly animals",
    "tree": "a big cartoon tree with green leaves",
    "flower": "a colorful cartoon flower in bloom",
    "rock": "a cartoon grey rock",
    "cloud": "a fluffy white cartoon cloud",
    "star": "a bright sparkling cartoon star",
    "dust": "cartoon dust cloud in the air",
    "stream": "a cartoon babbling brook with pebbles",

    # Food — appetizing cartoon illustrations
    "food": "a cartoon plate with colorful food",
    "meal": "a cartoon family dinner table with food",
    "banana": "a bright yellow cartoon banana",
    "yam": "a cartoon yam tuber vegetable",
    "cocoyam": ("a cartoon taro cocoyam root, rough brown hairy skin, "
                "cut open showing white flesh"),
    "corn": "a cartoon yellow corn on the cob",
    "honey": "a cartoon honey jar with bees",
    "vegetable": "cartoon colorful vegetables in a basket",
    "potato": "a cartoon potato with a smile",
    "pawpaw": "a cartoon papaya fruit cut in half",
    "egg": "a cartoon cracked egg with yolk",
    "meat": "a cartoon meat drumstick",
    "rice": "a cartoon bowl of steaming white rice",
    "milk": "a cartoon glass of white milk",
    "orange": "a cartoon orange fruit",
    "tomato": "a cartoon red shiny tomato",
    "soup": "a cartoon bowl of colorful soup steaming",
    "guava": "a cartoon green guava fruit",
    "pineapple": "a cartoon pineapple with sunglasses",
    "coffee": "a cartoon steaming cup of coffee",
    "avocado": "a cartoon avocado cut in half",
    "onion": "a cartoon purple onion",
    "cassava": "a cartoon cassava root vegetable",
    "grape": "cartoon bunch of purple grapes",
    "pepper": "a cartoon red chili pepper",
    "mango": "a cartoon ripe mango fruit",
    "coconut": "a cartoon coconut cut open",
    "bread": "a cartoon loaf of bread",

    # Actions — show kids doing activities
    "eat": "a happy cartoon child eating food",
    "sleep": "a cartoon child sleeping peacefully in bed",
    "rest": "a cartoon child relaxing on a couch",
    "buy": "a cartoon child shopping at a store",
    "catch": "a cartoon child catching a ball",
    "walk": "a cartoon child walking happily",
    "kick": "a cartoon child kicking a soccer ball",
    "say": "a cartoon child talking with speech bubble",
    "laugh": "a cartoon child laughing out loud",
    "smile": "a cartoon child with a big smile",
    "cry": "a cartoon child with tears",
    "sing": "a cartoon child singing with music notes",
    "write": "a cartoon child writing with a pencil",
    "teach": "a cartoon teacher at a blackboard",
    "learn": "a cartoon child reading a book",
    "wash": "a cartoon child washing hands with soap",
    "prepare": "a cartoon child helping cook in kitchen",
    "run": "a cartoon child running fast",
    "jump": "a cartoon child jumping with joy",
    "dance": "a cartoon child dancing to music",
    "swim": "a boy in a full swimming costume swimming in a river, water up to his shoulders",
    "climb": "a cartoon child climbing a tree",
    "fall": "a cartoon leaf falling from a tree",
    "fight": "two cartoon kids play-wrestling and laughing",
    "carry": "a cartoon child carrying a basket on head",
    "throw": "a cartoon child throwing a ball",
    "dig": "a cartoon child digging in a garden",
    "plant": "a cartoon child planting a seed in soil",
    "build": "a cartoon child building with blocks",
    "cook": "a cartoon child helping cook food",
    "drink": "a cartoon child drinking juice",
    "open": "a cartoon child opening a door",
    "close": "a cartoon child closing a box",
    "give": "a cartoon child giving a gift to friend",
    "take": "a cartoon child receiving a present",
    "sit": "a cartoon child sitting on a chair",
    "stand": "a cartoon child standing tall",
    "play": "cartoon children playing together happily",
    "work": "a cartoon person working at a desk",
    "call": "a cartoon child talking on a phone",
    "help": "a cartoon child helping another child up",
    "cut": "a cartoon child cutting paper with scissors",
    "pull": "a cartoon child pulling a wagon",
    "push": "a cartoon child pushing a toy car",
    "pour": "a cartoon child pouring water from a jug",
    "sew": "cartoon sewing needle and colorful thread",
    "grind": "cartoon mortar and pestle grinding grain",
    "harvest": "cartoon child picking vegetables in garden",
    "hunt": "cartoon bow and arrow target",
    "sell": "cartoon child at a lemonade stand",
    "count": "cartoon child counting on fingers",
    "measure": "cartoon ruler measuring something",
    "believe": "a cartoon child with hands together",
    "forget": "a cartoon confused child with question marks",
    "remember": "a cartoon child with lightbulb above head",
    "goodbye": "a cartoon child waving goodbye",

    # Things — colorful object illustrations
    "house": "a colorful cartoon house with a garden",
    "hut": "a cartoon African thatched roof hut",
    "room": "a cartoon bedroom with bed and toys",
    "soap": "a cartoon bar of soap with bubbles",
    "clothes": "cartoon colorful shirts and pants on a line",
    "car": "a cartoon red toy car",
    "book": "a cartoon open colorful book",
    "school": "a cartoon school building with children",
    "fire": "a cartoon campfire with orange flames",
    "chain": "cartoon colorful chain links",
    "rope": "a cartoon coiled rope",
    "box": "a cartoon open cardboard box",
    "ball": "a cartoon colorful bouncing ball",
    "door": "a cartoon colorful wooden door",
    "basket": "a cartoon woven basket with fruit",
    "plate": "a cartoon dinner plate",
    "trousers": "cartoon blue jeans trousers",
    "money": "cartoon gold coins and dollar bills",
    "instrument": "cartoon colorful musical instruments",
    "horn": "a cartoon musical horn trumpet",
    "mat": "a cartoon colorful woven mat",
    "machete": "a cartoon garden tool",
    "bamboo": "cartoon tall green bamboo stalks",
    "drum": "a cartoon colorful African drum",
    "key": "a cartoon golden key",
    "lamp": "a cartoon bright lamp glowing",
    "mirror": "a cartoon mirror with reflection",
    "broom": "a cartoon colorful broom",
    "bag": "a cartoon colorful school bag",
    "hat": "a cartoon colorful hat",
    "shoe": "a cartoon pair of colorful sneakers",
    "bell": "a cartoon golden bell ringing",
    "table": "a cartoon wooden table",
    "chair": "a cartoon colorful chair",
    "bed": "a cartoon cozy bed with pillow",
    "pot": "a cartoon cooking pot",
    "cup": "a cartoon colorful cup",
    "spoon": "a cartoon shiny spoon",
    "knife": "a cartoon butter knife",
    "candle": "a cartoon lit candle with warm glow",
    "bucket": "a cartoon colorful bucket",
    "pen": "a cartoon colorful pen",

    # Family — friendly diverse cartoon people
    "father": "a cartoon happy father with children",
    "mother": "a cartoon happy mother hugging child",
    "friend": "two cartoon children holding hands as friends",
    "husband": "a cartoon happy man",
    "wife": "a cartoon happy woman",
    "elder": "a cartoon friendly smiling grandfather with white hair",
    "chief": "a cartoon friendly African chief with colorful hat",
    "person": "a cartoon happy person waving",
    "boy": "a cartoon happy boy playing",
    "girl": "a cartoon happy girl playing",
    "baby": "a cute cartoon baby laughing",
    "child": "a cartoon happy child playing in garden",
    "servant": "a cartoon helpful person carrying items",
    "stranger": "a cartoon person waving hello",
    "orphan": "a cartoon gentle child alone",
    "widow": "a cartoon gentle woman",
    "twin": "cartoon twin children smiling identically",
    "warrior": "a cartoon brave kid superhero",
    "grandmother": "a cartoon friendly smiling grandmother",
    "grandfather": "a cartoon friendly smiling grandfather",
    "teacher": "a cartoon friendly teacher with books",
    "doctor": "a cartoon friendly doctor with stethoscope",
    "family": "a cartoon happy family together",

    # Descriptive — visual concept illustrations
    "big": "a cartoon big elephant next to a tiny mouse",
    "small": "a cartoon tiny ant next to a big shoe",
    "long": "a cartoon very long snake",
    "short": "a cartoon short penguin next to tall giraffe",
    "fat": "a cartoon round chubby cat",
    "thin": "a cartoon thin stick figure",
    "hard": "a cartoon solid grey rock",
    "soft": "a cartoon fluffy white pillow",
    "heavy": "a cartoon elephant standing on a scale",
    "light": "a cartoon floating feather in the air",
    "fast": "a cartoon cheetah running fast with speed lines",
    "slow": "a cute cartoon slow turtle",
    "hot": "a cartoon thermometer showing hot with sun",
    "cold": "a cartoon snowman in winter",
    "clean": "a cartoon sparkling clean room",
    "dirty": "a cartoon muddy dog",
    "bright": "a cartoon bright sun with rainbow",
    "dark": "a cartoon dark night with stars and moon",
    "beautiful": "a cartoon beautiful flower garden",
    "ugly": "a cartoon funny silly monster making a face",
    "clever": "a cartoon smart child with graduation cap",
    "empty": "a cartoon empty glass jar",
    "full": "a cartoon jar overflowing with candy",
    "round": "a cartoon collection of round balls",
    "straight": "a cartoon straight road to the horizon",
    "sweet": "cartoon colorful candies and lollipops",
    "bitter": "a cartoon lemon with a sour face",
    "dry": "a cartoon desert with cactus",
    "wet": "a cartoon child playing in rain puddle",
    "rich": "a cartoon treasure chest full of gold coins",
    "poor": "a cartoon simple small house",
    "alive": "a cartoon green plant growing from seed",
    "dead": "a cartoon withered brown tree",
    "happy": "a cartoon very happy smiling child",
    "sad": "a cartoon sad child with a tear",
    "angry": "a cartoon child with an angry face",
    "afraid": "a cartoon child scared hiding behind pillow",
    "tired": "a cartoon child yawning and sleepy",
    "hungry": "a cartoon child with empty plate looking sad",
    "sick": "a cartoon child in bed with thermometer",
    "young": "a cartoon cute baby",
    "old": "a cartoon friendly old man with walking stick",
    "new": "a cartoon shiny new toy in a box",
    "many": "cartoon many many colorful marbles",
    "few": "cartoon just three marbles",
    "tall": "a cartoon very tall giraffe",
    "alone": "a cartoon child sitting alone under a tree",
    "good": "a cartoon child giving thumbs up",
    "bad": "a cartoon broken toy",
    "strong": "a cartoon strong child flexing muscles",

    # Numbers
    "one": "cartoon number 1 with one apple",
    "two": "cartoon number 2 with two bananas",
    "three": "cartoon number 3 with three stars",
    "four": "cartoon number 4 with four flowers",
    "five": "a child holding up one hand with all five fingers spread",
    "six": "cartoon number 6 with six butterflies",
    "seven": "cartoon number 7 with seven birds",
    "eight": "cartoon number 8 with eight balls",
    "nine": "cartoon number 9 with nine hearts",
    "ten": "cartoon number 10 with ten balloons",

    # Numbers (extended)
    "eleven": "cartoon number 11 with eleven stars",
    "twelve": "cartoon number 12 with twelve circles",
    "twenty": "cartoon number 20 with twenty dots",
    "thirty": "cartoon number 30",
    "forty": "cartoon number 40",
    "fifty": "cartoon number 50",
    "sixty": "cartoon number 60",
    "seventy": "cartoon number 70",
    "eighty": "cartoon number 80",
    "ninety": "cartoon number 90",
    "thirteen": "cartoon number 13",
    "fourteen": "cartoon number 14",
    "fifteen": "cartoon number 15",
    "sixteen": "cartoon number 16",
    "seventeen": "cartoon number 17",
    "eighteen": "cartoon number 18",
    "nineteen": "cartoon number 19",
    "twenty-one": "cartoon number 21",
    "twenty-two": "cartoon number 22",
    "twenty-three": "cartoon number 23",
    "twenty-four": "cartoon number 24",
    "twenty-five": "cartoon number 25",
    "two hundred": "cartoon number 200",
    "three hundred": "cartoon number 300",
    "four hundred": "cartoon number 400",
    "five hundred": "cartoon number 500",
    "hundred": "cartoon number 100 with confetti",
    "thousand": "cartoon number 1000 with fireworks",

    # Time & abstract concepts
    "month": "a cartoon calendar page showing one month",
    "moon": "a cartoon crescent moon in a night sky",
    "week": "a cartoon calendar showing seven days in a row",
    "day": "a cartoon bright sunny day with blue sky",
    "year": "a cartoon calendar with all twelve months",
    "time": "a cartoon colorful clock with happy face",
    "today": "a cartoon sun with the word TODAY on a calendar",
    "tomorrow": "a cartoon sunrise over hills with an arrow pointing forward",
    "yesterday": "a cartoon sunset with an arrow pointing backward",
    "morning": "a cartoon sunrise with a rooster crowing",
    "noon, mid-day": "a cartoon bright sun directly overhead at noon",
    "now": "a cartoon clock with hands pointing to the current moment",
    "early": "a cartoon child waking up at dawn with alarm clock",
    "late": "a cartoon child running to school in a hurry",
    "later": "a cartoon hourglass with sand flowing",
    "dawn": "a cartoon pink and orange dawn sky over hills",
    "season": "cartoon four seasons in quadrants: spring flowers, summer sun, autumn leaves, winter snow",
    "second": "a cartoon stopwatch showing one second tick",
    "never": "a cartoon circle with a line through it",
    "often/usually": "a cartoon repeating pattern of sunny days",
    "period (countable)": "a cartoon hourglass measuring time",
    "darkness": "a cartoon dark room with glowing eyes peeking out",

    # Pronouns & question words
    "he/she": "a cartoon boy and girl standing side by side waving",
    "you (singular)": "a child pointing straight at the viewer, friendly smile",
    "and": "a cartoon plus sign connecting two happy friends",

    # Body parts (additional)
    "armpit": "a cartoon child raising arm showing armpit",
    "anus": "a cartoon medical anatomy diagram simple",
    "bladder": "a cartoon simple kidney and bladder medical diagram",
    "lip": "a cartoon big smiling lips",
    "skull": "a cartoon friendly pirate skull with crossbones",
    "skeleton": "a cartoon friendly dancing skeleton",
    "nape of neck": "a cartoon showing the back of a childs head and neck",
    "palate": "a cartoon open mouth showing the roof of the mouth",
    "fist": "a cartoon raised fist bump",
    "knuckle, joint": "a boy holding up a closed fist, knuckles facing the viewer",
    "joint": "a boy bending his knee, hands resting on it",
    "lung": "a cartoon pair of happy pink lungs breathing",
    "lungs, especially of animals": "a cartoon pair of lungs with air bubbles",
    "kidney": "a cartoon friendly kidney organ with a smile",
    "side (of body)": "a cartoon child pointing to their side",
    "sole of foot": "a cartoon bare foot showing the sole",
    "abdomen (external), stomach": "a cartoon child patting their tummy",
    "molar tooth": "a cartoon big molar tooth with a smile",
    "cartilage": "a cartoon ear showing cartilage",
    "vein. 2) root": "a cartoon tree with visible roots",
    "womb": "a cartoon stork carrying a baby bundle",
    "bile, gall": "a cartoon green gallbladder organ",
    "flesh, of living person": "a man flexing his upper arm muscle",
    # Medical & health
    "hernia": "a cartoon doctor examining a patient",
    "pus": "a child with a small bandage on a scraped knee",
    "mucus": "a cartoon child with a runny nose and tissue",
    "nasal mucus": "a cartoon child blowing nose into tissue",
    "cough": "a cartoon child coughing into elbow",
    "sneeze": "a cartoon child sneezing with tissue",
    "illness": "a cartoon child in bed feeling unwell",
    "illness, of the skin": "a child showing a forearm with red spots",
    "exzema": "a child showing a forearm with red itchy patches",
    "conjunctivitis": "a cartoon eye that looks red and irritated",
    "swelling": "a child holding out one hand with a swollen finger, ice pack on it",
    "rheumatism": "a cartoon elderly person rubbing sore knee",
    "whooping cough": "a cartoon child coughing hard",
    "ringworm": "a cartoon circular red rash on skin",
    "scar": "a boy showing a small healed scar on his forearm",
    "bruise": "a girl pointing at a purple bruise on her knee",
    "hiccough": "a cartoon child hiccupping with surprise",
    "frontal headache": "a cartoon child holding forehead in pain",
    "side pain": "a cartoon child holding their side",
    "blind person": "a cartoon person with sunglasses and white cane",
    "deaf person": "a cartoon person pointing to ear with hand cupped",
    "medicine man, traditional healer": "a cartoon friendly African healer with herbs",
    "traditional doctor": "a cartoon friendly doctor with herbal medicine",
    "spiritual healer": "a cartoon peaceful person meditating with light",
    "nurse": "a cartoon friendly nurse with cap and clipboard",
    "midwife": "a cartoon friendly nurse holding a baby",
    "hospital": "a cartoon hospital building with red cross",
    "disease, sort of": "a cartoon thermometer showing fever",
    "symtom of disease": "a cartoon child looking unwell with question marks",
    "poison": "a cartoon bottle with skull and crossbones warning label",
    "madness": "a cartoon swirly dizzy stars around a head",
    "mad person": "a cartoon dizzy person with stars around head",

    # Cultural terms
    "dowry (v)": "a cartoon bride and groom exchanging gifts at ceremony",
    "charm (fetish)": "a cartoon colorful African beaded necklace charm",
    "mask": "a cartoon colorful African ceremonial mask",
    "ancestors; les ancetre": "a cartoon family tree with old photos",
    "paramount chief": "a cartoon African king on a colorful throne",
    "chief/ruler": "a cartoon friendly chief with crown and staff",
    "compound": "a cartoon African village compound with several huts",
    "compound, residence": "a cartoon traditional African homestead",
    "courtyard": "a cartoon open courtyard with trees and benches",
    "council/meeting": "a cartoon group of people sitting in a circle talking",
    "balafon": "a cartoon colorful African xylophone instrument",
    "talking drum": "a cartoon hourglass-shaped African talking drum",
    "rattle (musical instrument)": "a cartoon colorful maraca shaker",
    "cowrie shell": "a cartoon shiny cowrie shell necklace",
    "cola nut": "a cartoon brown cola nut split open",
    "raffia palm": "a cartoon tall raffia palm tree",
    "palm wine": "a cartoon gourd with palm wine being tapped from tree",
    "palm tree": "a cartoon tropical palm tree",
    "palm fruit": "a cartoon bunch of red palm fruits",
    "palm branch": "a cartoon green palm leaf branch",
    "palm (of hand)": "a girl holding up one open hand, palm facing the viewer",
    "palm oil": "a cartoon bottle of red palm oil",
    "dance group": "cartoon children in colorful costumes dancing together",
    "latrine": "a cartoon small outdoor toilet hut",
    "toilet, of the public": "a cartoon public restroom sign",
    "incense": "a cartoon incense stick with curling smoke",

    # Animals (additional)
    "cockroach": "a cartoon silly cockroach with big eyes",
    "caterpillar": "a cute cartoon green caterpillar on a leaf",
    "chameleon": "a colorful cartoon chameleon changing colors",
    "porcupine": "a cute cartoon porcupine with pointy quills",
    "bat. 2) fruit bat": "a cute cartoon fruit bat hanging upside down",
    "jackal": "a cartoon jackal in the savanna",
    "scorpion": "a cartoon scorpion with big claws",
    "worm": "a cute cartoon pink worm in soil",
    "termite": "a cartoon termite on a piece of wood",
    "hawk": "a cartoon hawk soaring in the sky",
    "dove": "a cartoon white dove with olive branch",
    "parrot": "a colorful cartoon parrot on a branch",
    "weaver-bird": "a cartoon weaver bird building a nest",
    "waxbill": "a cartoon small colorful waxbill bird",
    "cricket": "a cartoon cricket insect chirping",
    "grasshopper": "a cute cartoon grasshopper jumping",
    "mudfish": "a cartoon mudfish in shallow water",
    "crab": "a cute cartoon red crab on a beach",
    "pangolin": "a cute cartoon pangolin curled up",
    "buffalo": "a cartoon African buffalo in grassland",
    "wild cat": "a cartoon wild cat in the jungle",
    "lizard": "a cartoon colorful lizard on a rock",
    "army ant, soldier ant": "cartoon line of marching ants carrying leaves",
    "moth": "a cartoon moth flying near a lamp",
    "domestic animal": "a cartoon farm with chickens, goats and dog",
    "wild animal": "a cartoon lion and elephant in the wild",
    "guard dog": "a cartoon loyal guard dog sitting alert",
    "he-goat": "a cartoon male goat with horns",
    "hen": "a cartoon hen sitting on eggs in a nest",
    "shrew, name of animal": "a cartoon tiny shrew with a pointy nose",
    "puff adder": "a cartoon patterned puff adder snake",
    "insect": "cartoon colorful bugs and insects collection",
    "maggot (found in rotten meat)": "a cartoon wiggly white grub",

    # Nature (additional)
    "rainbow": "a cartoon bright rainbow over green hills",
    "swamp": "a cartoon marshy swamp with frogs and reeds",
    "marsh": "a cartoon wetland with tall grasses and birds",
    "lake": "a cartoon peaceful blue lake surrounded by trees",
    "sea": "a cartoon blue ocean with waves and fish",
    "ocean/sea": "a cartoon blue ocean with a sailing boat",
    "pool": "a cartoon deep blue pool of water",
    "hill": "a cartoon green grassy hill",
    "cave": "a cartoon dark cave entrance in a hillside",
    "ditch": "a cartoon ditch in the ground",
    "path": "a cartoon winding dirt path through trees",
    "sand": "a cartoon sandy beach with shells",
    "rust": "a cartoon rusty old key",
    "flood waters": "a cartoon river overflowing its banks",
    "drizzle": "cartoon light rain drizzle from grey clouds",
    "storm or wind; vent": "a cartoon stormy sky with wind and rain",
    "heaven": "a cartoon beautiful golden clouds with sunbeams",
    "dry season": "a cartoon dry brown savanna landscape with hot sun",
    "thorn": "a cartoon rose stem with sharp thorns",
    "leaf": "a cartoon bright green leaf",
    "flower": "a cartoon colorful flower blooming",
    "stem, of banana": "a cartoon banana plant stem with fruit",
    "seed": "a cartoon seed sprouting in soil",
    "mushroom": "a cartoon cute red and white mushroom",
    "beans": "cartoon colorful beans in a bowl",
    "groundnuts": "cartoon peanuts in their shells",
    "okra": "a cartoon green okra vegetable",
    "plantain": "a cartoon bunch of plantain bananas",
    "date palm": "a cartoon date palm tree with fruit clusters",
    "fig (tree)": "a cartoon fig tree with purple figs",
    "elephant grass": "a cartoon tall grass swaying in the wind",

    # Food (additional)
    "fufu corn": "a cartoon bowl of yellow fufu corn meal",
    "flour": "a cartoon bag of white flour",
    "sugar": "a cartoon pile of white sugar crystals",
    "sugar cane": "a cartoon stick of green sugar cane",
    "salt": "a cartoon salt shaker",
    "oil": "a cartoon bottle of cooking oil",
    "cooked rice": "a cartoon plate of steaming cooked rice",
    "breakfast": "a cartoon breakfast plate with eggs and toast",
    "food/meal": "a cartoon plate full of colorful food",
    "soup/sauce": "a cartoon bowl of soup with steam rising",
    "guinea corn": "a cartoon stalk of guinea corn grain",
    "fresh corn": "a cartoon ear of fresh green corn",
    "green pepper": "a cartoon green bell pepper",
    "red pepper": "a cartoon red hot pepper",
    "pumpkin": "a cartoon orange pumpkin",
    "carrot-like food": "a cartoon orange carrot",
    "pounded cocoyam": ("a cartoon plate of achu, a smooth white mound of "
                        "pounded cocoyam with a well of yellow palm oil soup "
                        "in the middle"),

    # Things/Objects (additional)
    "axe": "a cartoon woodcutting axe in a tree stump",
    "hoe": "a cartoon garden hoe tool",
    "needle": "a cartoon sewing needle with thread",
    "razor": "a cartoon razor blade",
    "chisel": "a cartoon chisel tool and wood",
    "sickle": "a cartoon curved sickle tool",
    "pestle": "a cartoon wooden pestle",
    "mortar": "a cartoon mortar bowl for grinding",
    "grinding stone": "a cartoon traditional grinding stone",
    "ladder": "a cartoon wooden ladder leaning on wall",
    "fence": "a cartoon wooden picket fence",
    "gate": "a cartoon colorful garden gate",
    "bridge": "a cartoon stone bridge over a river",
    "window": "a cartoon open window with curtains blowing",
    "roof of a house": "a cartoon thatched roof on a house",
    "ceiling": "a cartoon room looking up at the ceiling",
    "wall of a house": "a cartoon brick wall of a house",
    "wall, of a house": "a cartoon colorful house wall",
    "pillow": "a cartoon soft fluffy white pillow",
    "matress": "a cartoon bed mattress",
    "calabash": "a cartoon African gourd calabash",
    "goblet": "a cartoon golden goblet cup",
    "bowl": "a cartoon colorful ceramic bowl",
    "cooking pot": "a cartoon clay cooking pot on fire",
    "container": "a cartoon storage container with lid",
    "sieve": "a cartoon kitchen sieve strainer",
    "comb": "a cartoon colorful hair comb",
    "bracelet": "a cartoon colorful beaded bracelet",
    "necklace": "a cartoon colorful bead necklace",
    "helmet": "a cartoon safety helmet",
    "ring of any sort": "a cartoon shiny golden ring",
    "wire": "a cartoon coil of wire",
    "nail": "a cartoon metal nail and hammer",
    "peg": "a cartoon wooden clothes peg",
    "gun": "cartoon water gun toy squirting water",
    "trap": "a cartoon animal trap in the forest",
    "trap of any sort": "a cartoon mouse trap with cheese",
    "candle": "a cartoon glowing lit candle",
    "lamp": "a cartoon bright oil lamp glowing",
    "metal": "a cartoon shiny metal bar",
    "rubber": "a cartoon rubber band stretched",
    "chalk": "a cartoon piece of white chalk on blackboard",
    "thread": "a cartoon spool of colorful thread",
    "string": "a cartoon ball of string",
    "stick/staff": "a cartoon wooden walking stick",
    "firewood": "a cartoon bundle of firewood logs",
    "bulb": "a cartoon bright light bulb glowing",

    # Family & people (additional)
    "mother-in-law": "a cartoon friendly older woman with kind smile",
    "sister-in-law": "a cartoon friendly young woman waving",
    "sister/sibling": "cartoon two children as brother and sister together",
    "brother": "a cartoon boy with his arm around his brother",
    "nephew": "a cartoon young boy being hugged by uncle",
    "descendant": "a cartoon family tree showing generations",
    "acquaintance": "two cartoon people shaking hands meeting",
    "age group": "cartoon group of children same age playing together",
    "beggar": "a cartoon humble person sitting with a bowl",
    "hunter": "a cartoon hunter with bow and arrows in forest",
    "owner": "a cartoon person proudly holding a key to a house",
    "traveller, very mobile person": "a cartoon person walking with a bag on a journey",
    "messenger": "a cartoon person running to deliver a letter",
    "tax collector": "a cartoon person with clipboard collecting",
    "giver": "a cartoon child handing a gift to another",
    "seller or somebody who sells": "a cartoon market vendor at a stall",
    "reader": "a cartoon child reading a book happily",
    "host, \"nga nga ngedtapona owner of the compound": "a cartoon welcoming host at a door",
    "lazy person": "a cartoon person sleeping on a couch",
    "stupid person / fool": "a cartoon silly clown making a funny face",
    "deceitful person": "a cartoon person with crossed fingers behind back",
    "unmarried person": "a cartoon single person standing alone happy",
    "crowd": "a cartoon crowd of diverse happy people",
    "enemy": "two cartoon children with arms crossed facing away",
    "co-wife": "two cartoon women standing together",
    "disciple, follower": "a cartoon child following a teacher",

    # Actions (additional)
    "ask": "a cartoon child raising hand to ask a question",
    "ask, request": "a cartoon child politely asking with hands together",
    "agree": "two cartoon children shaking hands nodding",
    "announce, inform": "a cartoon child with a megaphone",
    "blow": "a cartoon child blowing out birthday candles",
    "bite": "a cartoon apple with a bite taken out",
    "breathe": "a cartoon child taking a deep breath of fresh air",
    "burn": "a cartoon campfire with bright flames",
    "chase": "a cartoon child chasing a butterfly",
    "chew": "a cartoon child chewing bubblegum with a bubble",
    "choose": "a cartoon child pointing at one of three colorful doors",
    "come": "a cartoon child walking toward with arms open",
    "come, approach": "a cartoon child walking toward with welcoming gesture",
    "cover": "a cartoon child covering a pot with a lid",
    "crawl": "a cartoon baby crawling on the floor happily",
    "cry, weep": "a cartoon child crying with big tears",
    "descend": "a cartoon child going down a slide",
    "destroy": "a cartoon child knocking down a block tower",
    "die": "a cartoon withered flower drooping",
    "disappear": "an empty wooden stool with a puff of smoke above it where something has just gone",
    "dream": "a cartoon child sleeping with dream cloud above",
    "drip": "a cartoon water faucet dripping drops",
    "drown (intr)": "a cartoon person in water waving for help with lifering",
    "embrace": "two cartoon children hugging each other",
    "embrace, hug": "a cartoon parent hugging a child warmly",
    "enter": "a cartoon child walking through a doorway",
    "escape capture easily, skilled in evading capture": "a cartoon rabbit quickly escaping from a fox",
    "exchange": "two cartoon children trading toys",
    "fade": "a cartoon flower slowly losing its color",
    "fail, not work as planned": "a cartoon broken machine with smoke",
    "fill": "a cartoon glass being filled with orange juice",
    "find": "a cartoon child finding treasure in a box",
    "finish": "a cartoon child crossing a finish line with ribbon",
    "float": "a cartoon rubber duck floating on water",
    "fly": "a cartoon bird flying in the blue sky",
    "follow": "cartoon ducklings following their mother duck",
    "frighten": "a cartoon ghost saying boo to a surprised child",
    "fry": "a cartoon pan frying an egg with sizzle",
    "go": "a cartoon child walking forward on a path",
    "greet": "two cartoon children waving hello to each other",
    "groan": "a cartoon child moaning holding stomach",
    "growl": "a cartoon dog growling showing teeth playfully",
    "guard": "a cartoon guard standing at attention",
    "hang up": "a cartoon child hanging clothes on a clothesline",
    "have": "a cartoon child holding a toy proudly",
    "heal": "a cartoon wound with a bandage getting better with sparkles",
    "hear": "a cartoon child cupping ear to listen",
    "hide": "a cartoon child hiding behind a tree playing",
    "hit, strike (with hand)": "a boy striking a drum with the flat of his hand",
    "hunt": "a cartoon archer aiming at a target",
    "imitate": "a cartoon child copying a monkey pose",
    "insult": "a cartoon angry speech bubble with scribbles",
    "join": "cartoon puzzle pieces clicking together",
    "keep": "a cartoon child putting coins in a piggy bank",
    "kiss": "a cartoon mother kissing childs forehead",
    "lack": "a cartoon empty shelf with cobwebs",
    "laugh": "a cartoon child laughing with tears of joy",
    "lick": "a cartoon child licking an ice cream cone",
    "lie (falsehood)": "a cartoon child with a growing Pinocchio nose",
    "lie down": "a cartoon child lying down on a soft mat",
    "lift": "a cartoon child lifting a box up",
    "limp": "a cartoon person walking with a limp and bandaged foot",
    "listen": "a cartoon child with headphones listening to music",
    "look at": "a cartoon child looking through a magnifying glass",
    "look for something": "a cartoon child searching under furniture for a lost toy",
    "love": "a cartoon big red heart with sparkles",
    "make": "a cartoon child making something with clay",
    "marry": "a Cameroonian bride with braided hair and a groom with a short natural afro, both with dark brown skin, standing together in wedding dress, smiling",
    "measure": "a cartoon child using a ruler to measure height",
    "melt": "a cartoon snowman melting in the sun",
    "mix": "a cartoon child stirring a bowl of colorful batter",
    "obey": "a cartoon child following instructions from teacher",
    "obtain": "a cartoon child receiving a trophy",
    "paint": "a cartoon child painting on an easel with bright colors",
    "pay": "a cartoon child handing coins to a shopkeeper",
    "peel many things": "a cartoon child peeling oranges",
    "persuade": "a cartoon child convincing friend to play",
    "pluck": "a cartoon child plucking fruit from a tree",
    "pound (with mortar)": "a cartoon person pounding food in a mortar",
    "pour": "a cartoon child pouring water from a pitcher",
    "praise": "a cartoon child clapping and cheering",
    "pray": "a cartoon child with hands together praying",
    "press": "a child pressing a big red button with one finger",
    "protect": "a cartoon shield protecting a small animal",
    "quarrel": "two cartoon children arguing with speech bubbles",
    "read": "a cartoon child reading a book under a tree",
    "refuse": "a cartoon child shaking head no with crossed arms",
    "reject": "a child pushing a bowl away with one hand",
    "remember, remind": "a cartoon child with lightbulb above head remembering",
    "remove": "a cartoon child removing items from a box",
    "repent": "a cartoon child looking sorry with head down",
    "return": "a cartoon child walking back home with arrow",
    "save": "a cartoon superhero child saving a kitten from tree",
    "say/speak": "a cartoon child speaking with colorful speech bubble",
    "scatter, spread out (maize) (tr)": "a cartoon child spreading seeds on the ground",
    "search": "a cartoon child with magnifying glass searching",
    "see": "a cartoon pair of eyes looking with wonder",
    "sell": "a cartoon child at a market stall selling fruits",
    "send": "a cartoon child sending a paper airplane message",
    "separate": "cartoon two groups of colored blocks being sorted apart",
    "serve": "a cartoon child serving food on a plate",
    "sew": "a cartoon needle and thread sewing fabric",
    "share": "two cartoon children sharing a cookie",
    "sharpen": "a cartoon pencil being sharpened in a sharpener",
    "shine": "a cartoon sun shining brightly with rays",
    "shoot": "cartoon child shooting a basketball at a hoop",
    "shout": "a cartoon child shouting through cupped hands",
    "show": "a cartoon child pointing at something excitedly",
    "shut": "a cartoon door being closed",
    "sing": "a cartoon child singing with music notes floating",
    "smell": "a cartoon child smelling a flower happily",
    "snatch": "a cartoon bird snatching a fish from water",
    "snore": "a cartoon person sleeping with ZZZ above head",
    "speak, talk": "a cartoon child talking to a friend with speech bubbles",
    "spit": "a cartoon child spitting out yucky food",
    "spoil": "a cartoon broken toy on the floor",
    "squeeze": "a girl squeezing a lemon in one hand",
    "stab": "a cartoon fork poking into food",
    "stagger": "a cartoon dizzy person wobbling",
    "startle, surprise": "a cartoon child jumping in surprise",
    "step on, stamp (with feet)": "a cartoon foot stomping in a puddle",
    "stretch": "a cartoon child stretching arms wide in the morning",
    "stumble": "a cartoon child tripping over a rock",
    "suck": "a cartoon baby sucking on a pacifier",
    "suffer": "a cartoon sad child sitting in the rain",
    "survive": "a cartoon plant growing through a crack in concrete",
    "swallow": "a cartoon child swallowing medicine",
    "sweep (with broom)": "a cartoon child sweeping the floor with a broom",
    "swing": "a cartoon child swinging on a playground swing",
    "talk": "two cartoon children talking with speech bubbles",
    "tangle": "a cartoon ball of tangled yarn",
    "teach": "a cartoon teacher writing on a blackboard",
    "thank": "a cartoon child saying thank you with a bow",
    "think": "a cartoon child thinking with thought bubble",
    "threaten": "a cartoon storm cloud with lightning looking angry",
    "tickle": "a cartoon child being tickled and laughing",
    "trample": "cartoon footprints stomping through a garden",
    "try": "a cartoon child trying to reach a high shelf",
    "twist": "a cartoon twisted rope",
    "untie": "a cartoon child untying a knot in a rope",
    "urinate": "a cartoon child running to the bathroom urgently",
    "visit": "a cartoon child knocking on friends door",
    "wander": "a cartoon child walking through a meadow exploring",
    "wake up (intr)": "a cartoon child waking up and stretching in bed",
    "weave": "a cartoon person weaving a colorful basket",
    "whip, beat up": "a cartoon whip cracking in the air",
    "whistle": "a cartoon child whistling with music notes",
    "wipe": "a cartoon child wiping a table clean",
    "yawn": "a cartoon child yawning widely and sleepy",

    # Emotions & states
    "anger": "a cartoon angry red face with steam coming from ears",
    "happiness": "a cartoon child jumping with joy and sparkles",
    "fear": "a cartoon scared child hiding under blanket",
    "shame": "a cartoon child blushing and covering face",
    "pride": "a cartoon peacock with tail feathers spread",
    "confusion, disorder": "a cartoon child with swirly eyes and question marks",
    "excitement": "a cartoon child jumping up and down with joy",
    "disappointment": "a cartoon child with drooping shoulders and frown",
    "loneliness": "a cartoon child sitting alone looking out window",
    "hate": "a cartoon broken heart in two pieces",
    "hunger": "a cartoon child with empty plate and grumbling tummy",
    "patience": "a cartoon child calmly waiting with arms crossed",
    "kindness": "a cartoon child helping a small bird",
    "hope": "a cartoon child reaching for a bright star",
    "truth": "a cartoon shining golden light beam",
    "peace": "a cartoon dove flying with olive branch over rainbow",
    "evil": "a cartoon dark shadow with glowing red eyes",
    "sin": "a cartoon child looking guilty with broken vase",
    "blessing": "a cartoon golden sparkles falling from above",
    "comfort, petting": "a cartoon child gently petting a kitten",
    "luck, fortune": "a cartoon four-leaf clover with sparkles",
    "wisdom": "a cartoon wise owl wearing glasses reading a book",
    "strength": "a cartoon strong tree with deep roots",
    "trouble": "a cartoon child tangled in a mess of yarn",
    "hardship": "a cartoon child walking uphill in rain",
    "tiredness, fatigue": "a cartoon child dragging feet looking exhausted",
    "restlessness": "a cartoon child tossing and turning in bed",
    "forgiveness": "two cartoon children making up after a fight",
    "forgetfulness": "a cartoon child with thought bubble disappearing",
    "jealousy": "a cartoon child enviously looking at anothers toy",

    # Descriptive (additional)
    "black": "a cartoon solid black circle",
    "white": "a cartoon fluffy white cloud",
    "red": "a cartoon shiny red apple",
    "blue/green/dark": "a cartoon blue and green swirly ball",
    "narrow": "a cartoon narrow alleyway between buildings",
    "wide": "a cartoon wide open field with blue sky",
    "deep": "a cartoon deep swimming pool with depth markers",
    "sharp": "a cartoon sharp pencil point",
    "raw": "a cartoon raw egg cracked open",
    "raw/uncooked": "a cartoon raw vegetable and uncooked meat",
    "ripe/ready": "a cartoon ripe red tomato",
    "mature": "a cartoon tall fully grown tree",
    "salty": "a cartoon pretzel covered in salt crystals",
    "sour/bitter": "a cartoon lemon with puckered face",
    "sweet (like honey)": "a cartoon honey dripping from honeycomb",
    "loud/noisy": "a cartoon big speaker with sound waves",
    "quiet/silent": "a cartoon child with finger to lips saying shh",
    "difficult": "a cartoon child puzzling over a hard math problem",
    "crazy": "a cartoon swirly spiral doodle pattern",
    "lazy": "a cartoon cat sleeping on a hammock",
    "native": "a cartoon person in traditional African clothing",
    "average": "a cartoon scale perfectly balanced in the middle",
    "bony": "a cartoon thin fish showing bones",
    "broken": "a cartoon cracked plate in pieces",
    "important": "a cartoon golden trophy with star on top",
    "nice": "a cartoon child giving thumbs up with sparkly smile",
    "strange": "a cartoon alien with big curious eyes",
    "unusual, strange": "a cartoon weird-shaped purple cloud",
    "vain": "a cartoon peacock looking at itself in a mirror",
    "same": "cartoon two identical red apples side by side",
    "whole, total": "a cartoon complete circle pie chart",
    "few/little": "cartoon just two small marbles",
    "many/much": "cartoon overflowing basket of colorful marbles",
    "bright/clean": "a cartoon sparkling clean diamond",
    "clever/smart": "a cartoon child solving a puzzle easily",
    "hard/strong": "a cartoon solid rock",
    "fast/quick": "a cartoon rocket zooming through space",
    "slow/careful": "a cartoon turtle walking carefully",
    "fat/thick": "a cartoon round chubby hamster",
    "new/fresh": "a cartoon freshly picked bright flower",
    "long/far": "a cartoon very long road stretching into distance",
    "good/kind": "a cartoon child sharing food with a friend",
    "light (not heavy)": "a cartoon feather floating in air",
    "thin, lanky": "a cartoon tall thin giraffe",
    "round/circular": "a cartoon collection of circles and balls",
    "straight": "a cartoon straight arrow pointing forward",
    "digusting, dirty": "a cartoon muddy puddle with flies",

    # Abstract & misc concepts
    "life": "a cartoon tree of life with colorful leaves",
    "word": "a cartoon colorful word in a speech bubble",
    "word/language": "cartoon speech bubbles in many languages",
    "language": "a cartoon globe with speech bubbles around it",
    "name": "a cartoon name tag sticker saying HELLO",
    "song": "cartoon colorful music notes floating in the air",
    "voice": "a cartoon child singing with visible sound waves",
    "noise": "a cartoon drum making loud noise with motion lines",
    "news, message": "a cartoon newspaper with headlines",
    "message": "a cartoon sealed envelope with letter inside",
    "story/tale": "a cartoon open storybook with characters",
    "dream": "a cartoon child sleeping with colorful dream cloud",
    "idea": "a cartoon bright light bulb above a childs head",
    "mystery": "a cartoon question mark inside a treasure chest",
    "magic": "a cartoon magic wand with sparkles and stars",
    "number": "cartoon colorful numbers 1 2 3 floating",
    "class": "a cartoon classroom with desks and blackboard",
    "exam": "a cartoon child writing a test with pencil",
    "fashion": "a cartoon child in stylish colorful outfit",
    "habit": "a cartoon child brushing teeth routinely",
    "profit": "a cartoon graph going up with money symbols",
    "wealth": "a cartoon treasure chest overflowing with gold",
    "wealth, property": "a cartoon house with garden and car",
    "payment": "a trader handing coins to a customer",
    "subscription": "a cartoon magazine arriving in mailbox",
    "market": "a cartoon busy colorful outdoor market",
    "market stall": "a cartoon market stall with fruits and vegetables",
    "farm": "a cartoon farm with crops and animals",
    "village": "a cartoon small village with huts and trees",
    "village/villages": "a cartoon group of village huts among trees",
    "country": "a cartoon map with flag and mountains",
    "country/land": "a cartoon landscape with green hills and river",
    "place": "a cartoon signpost pointing to different places",
    "school": "a cartoon colorful school building with flag",
    "church": "a cartoon small church building with cross on top",
    "prison. 2) penalty, pumshment": "a cartoon cage with lock",
    "christianity": "a cartoon simple cross with golden light",
    "worshipping": "a cartoon person kneeling in prayer",
    "law": "a cartoon gavel and law book",
    "punishment": "a cartoon child in timeout corner",
    "theft": "a cartoon mask and bag of stolen goods",
    "thief": "a cartoon sneaky raccoon tiptoeing",
    "battle": "cartoon two toy armies facing each other",
    "war/wars": "cartoon toy soldiers and flags on a board game",
    "journey": "a cartoon winding road leading to mountains",
    "appearance": "a cartoon mirror showing a happy reflection",
    "direction of": "a cartoon compass with arrows pointing",
    "weight": "a cartoon scale with objects being weighed",
    "height": "a cartoon measuring tape next to a growing child",
    "speed": "a cartoon speedometer needle moving fast",
    "translation": "cartoon two speech bubbles with different languages",
    "response, answer": "a cartoon child raising hand to answer a question",
    "request, question": "a cartoon child with raised hand and question mark",
    "complaint, especially in court": "a cartoon person talking to a judge",
    "gossip": "two cartoon children whispering to each other",

    # Household & daily life
    "kitchen": "a cartoon colorful kitchen with pots and pans",
    "food or drinks given to a house of mourning": "a cartoon basket of food being delivered to a house",
    "entrance": "a cartoon welcoming doorway with welcome mat",
    "entrance hut": "a cartoon small hut at a village entrance",
    "playground. 2) palace assembly ground": "a cartoon playground with slides and swings",
    "inside": "a cartoon child peeking inside a box",
    "outside": "a cartoon child playing outside in the sun",
    "outside area": "a cartoon open yard with trees",
    "top, on top": "a cartoon bird sitting on top of a pole",
    "stool/chair (traditional)": "a cartoon traditional African wooden stool",
    "cloth, tied by women": "a cartoon woman in colorful wrapped cloth",

    # Senses & bodily functions
    "breath, soul, spirit (of living person)": "a cartoon person breathing out visible air",
    "saliva": "a cartoon child drooling over delicious food",
    "sweat": "a cartoon child sweating in the hot sun",
    "excrement": "a cartoon poop emoji with flies",
    "urine": "a cartoon yellow puddle with embarrassed face",
    "odour": "a cartoon wavy green smell lines from a sock",
    "perspire, sweat": "a cartoon child wiping sweat from forehead",

    # Religion & spiritual
    "saviour": "a cartoon heroic figure with cape saving someone",
    "supreme being": "a cartoon golden light from above in clouds",
    "baptise": "a cartoon person being sprinkled with water",
    "baptism": "a cartoon baptism with water drops and light",

    # Nature processes
    "growth ( of plants)": "a cartoon seed growing stages into a flower",
    "harvest": "a cartoon child picking ripe fruit from trees",
    "sow": "a cartoon child scattering seeds in soil",
    "wither eg a plant": "a cartoon plant wilting and drooping",
    "spread, of disease": "cartoon germs spreading from one person to another",

    # Qualities & states of things
    "color, kind, pattern": "a cartoon palette with many bright colors",
    "mark of identification. 2) ritual scar": "a cartoon badge or ID card",
    "spot, speckle": "a cartoon dalmatian dog with spots",
    "equivalent": "a cartoon equal sign between two objects",
    "togetherness": "cartoon children holding hands in a circle",
    "companionship": "a cartoon child walking with a dog companion",
    "possession": "a cartoon child holding their favorite toy tight",
    "total": "a cartoon calculator showing a sum total",

    # Misc actions & verbs
    "act, do": "a cartoon child performing in a play on stage",
    "appease": "a cartoon child offering a flower to make peace",
    "bark": "a cartoon dog barking with woof speech bubble",
    "bellow": "a cartoon cow mooing loudly",
    "bend down, stoop": "a cartoon child bending down to pick up a ball",
    "boast": "a cartoon child flexing muscles and bragging",
    "break": "a cartoon glass breaking into pieces",
    "carry on head": "a cartoon African woman carrying basket on head",
    "cheat": "a cartoon child peeking at another childs paper",
    "contradict": "two cartoon speech bubbles with opposite symbols",
    "crawl": "a cartoon baby crawling happily",
    "cross, traverse, pass through": "a cartoon child crossing a bridge",
    "despise": "a cartoon child turning nose up at vegetables",
    "domesticate": "a cartoon child training a puppy",
    "drag on the grown": "a cartoon child dragging a heavy bag on ground",
    "flatten": "a cartoon rolling pin flattening dough",
    "flip over": "a cartoon pancake being flipped in a pan",
    "gnaw": "a cartoon beaver gnawing on a log",
    "go round, surround": "cartoon children forming a circle around a tree",
    "grumble, complain": "a cartoon child with crossed arms grumbling",
    "harden": "a cartoon clay pot hardening in a kiln",
    "hasten up, hurry, be fast": "a cartoon child running fast with speed lines",
    "husk (corn)": "a cartoon ear of corn being husked",
    "insist, press on": "a cartoon determined child pushing a boulder",
    "lengthen": "a cartoon rubber band being stretched long",
    "lower (tr), decrease (intr)": "a cartoon arrow pointing downward",
    "manufacture": "a cartoon factory with colorful products",
    "mumble": "a cartoon child mumbling with fuzzy speech bubble",
    "overtake": "a cartoon rabbit running past a turtle",
    "provoke, taunt": "a cartoon child sticking tongue out teasing",
    "reduce ( eg sth that is overful or much)": "a cartoon shrinking pile of blocks",
    "replant": "a cartoon child replanting a small tree",
    "straighten": "a cartoon child straightening a bent wire",
    "succeed, make it": "a cartoon child reaching the top of a mountain",
    "support": "a cartoon child helping friend stand up",
    "swamp": "a cartoon marshy wetland with reeds",
    "tether (sheep, goats)": "a cartoon goat tied to a post in a field",
    "widen": "a cartoon road getting wider",
    "wring out, sqeeze": "a cartoon child wringing water from a cloth",

    # Slash-separated variants (matching logic only splits on space, not slash)
    "dog/dogs": "a cartoon happy puppy wagging its tail",
    "bag/bags": "cartoon colorful bags and backpacks",
    "bed/beds": "a cartoon cozy bed with blanket and pillow",
    "bed/beds (alt)": "a cartoon wooden bed frame with mattress",
    "boy/son": "a cartoon happy boy waving",
    "girl/daughter": "a cartoon happy girl playing",
    "leg/legs": "cartoon pair of legs running fast",
    "pot/pots": "cartoon collection of clay pots",
    "rope/ropes": "cartoon coiled ropes",
    "neck/necks": "a cartoon giraffe with long neck",
    "road/path": "a cartoon winding road through countryside",
    "river/stream": "a cartoon flowing river with rocks",
    "tree/trees": "cartoon group of colorful trees",
    "father/fathers": "a cartoon father and children",
    "father/parent": "a cartoon loving parent holding child hand",
    "mother/mothers": "a cartoon mother with children",
    "teacher/teachers": "a cartoon teacher in front of class",
    "hammer/hammers": "a cartoon hammer tool",
    "village/villages": "cartoon small village with huts",
    "war/wars": "cartoon toy soldiers on a board game",
    "corn/maize": "a cartoon ear of yellow corn",
    "food/meal": "a cartoon plate of colorful food",
    "soup/sauce": "a cartoon bowl of soup steaming",
    "word/language": "cartoon speech bubbles with words",
    "soul/spirit": "a cartoon glowing spirit light with sparkles",
    "kick/shoot": "a cartoon child kicking a soccer ball",
    "cry/weep": "a cartoon child crying with tears",
    "edge/end": "a cartoon cliff edge overlooking a valley",
    "ground/earth": "a cartoon earth soil with grass",
    "few/little": "cartoon just a few small marbles",
    "many/much": "cartoon very many colorful objects",
    "fat/thick": "a cartoon round chubby bear",
    "hard/strong": "a cartoon solid rock",
    "fast/quick": "a cartoon cheetah running with speed lines",
    "slow/careful": "a cartoon turtle walking carefully on a path",
    "bright/clean": "a cartoon sparkling clean surface",
    "clever/smart": "a cartoon child with graduation cap thinking",
    "new/fresh": "a cartoon shiny new gift in a box",
    "long/far": "a cartoon road stretching far into the distance",
    "good/kind": "a cartoon child sharing food with friend",
    "round/circular": "a cartoon perfect circle ball",
    "book/school": "a cartoon school building with books",
    "fire/burn": "a cartoon bright orange campfire",
    "machete/cutlass": "a cartoon farming machete tool",
    "catch/harvest": "a cartoon child catching fruit from tree",
    "count/calculate": "a cartoon child counting on abacus",
    "share/divide": "two cartoon children splitting a pie",
    "want/desire": "a cartoon child wishing on a star",
    "walk/travel": "a cartoon child walking on a journey",
    "say/speak": "a cartoon child talking with speech bubbles",
    "think/reflect": "a cartoon child sitting and thinking deeply",
    "mix/stir": "a cartoon spoon stirring a colorful mixture",
    "truly/really": "a cartoon checkmark in a green circle",
    "truly, really": "a cartoon shining truth badge",
    "stranger/visitor": "a cartoon person arriving at a door",
    "letter/writing": "a cartoon handwritten letter with envelope",
    "chief/ruler": "a cartoon chief with crown sitting on throne",
    "chicken, fowl": "a cartoon hen pecking at grain",
    "cheek, jaw": "a cartoon face showing cheek and jaw",

    # Common verbs with "be" prefix (state descriptions)
    "be heavy": "a cartoon elephant standing on a tiny scale",
    "be hot": "a cartoon thermometer in the red zone",
    "be kind": "a cartoon child offering flowers to friend",
    "be mad": "a cartoon dizzy swirly-eyed character",
    "be sick, (be) ill": "a cartoon child sick in bed with thermometer",
    "be tired": "a cartoon exhausted child slumping",
    "be clean": "a cartoon sparkling clean room",
    "be red": "a cartoon bright red circle",
    "be thin": "a cartoon very thin stick figure",
    "be fat, (be) thick": "a cartoon round puffy cloud",
    "be old (not young, not new)": "a cartoon ancient crumbling castle",
    "be smart": "a cartoon child in glasses solving a puzzle",
    "be pleased": "a cartoon happy child clapping hands",
    "be mature": "a cartoon fully grown tree with fruit",
    "be heavy": "a cartoon heavy anvil",
    "be jealous, be envious": "a cartoon child looking enviously at toy",
    "be wrong": "a cartoon red X mark",
    "be wide": "a cartoon very wide river",
    "be sticky": "a cartoon honey dripping sticky",
    "be stupid": "a cartoon confused person with question marks",
    "be used up": "a cartoon empty container turned upside down",
    "be blunt, eg a knife": "a cartoon dull butter knife",
    "be abundant, be much": "a cartoon overflowing basket of fruit",
    "be frugal": "a cartoon piggy bank with coins",
    "be restless, be unsettled": "a cartoon child tossing in bed",
    "be disappointed, witness the unexpected": "a cartoon child with dropped jaw surprise",
    "be too excited": "a cartoon child bouncing with excitement",

    # Common remaining words
    "ashes": "a cartoon pile of grey wood ashes",
    "ashes, wood ash": "a cartoon fireplace with grey ashes",
    "agreement": "two cartoon people shaking hands smiling",
    "birth day": "a cartoon birthday cake with candles",
    "blame": "a cartoon finger pointing accusingly",
    "braid/plait": "a cartoon girl with braided hair",
    "break": "a cartoon glass breaking into pieces",
    "butcher": "a cartoon butcher with apron at a meat counter",
    "bunch of banana": "a cartoon bunch of yellow bananas",
    "camp, encampment": "a cartoon campsite with tent and campfire",
    "cane, walking stick, club, cudgel": "a cartoon wooden walking cane",
    "claw": "a cartoon eagle claw",
    "clearing": "a cartoon forest clearing with sunlight",
    "decoration, embelishment": "cartoon colorful party decorations and streamers",
    "end": "a cartoon finish line with checkered flag",
    "everything": "a cartoon box overflowing with all kinds of objects",
    "fan": "a cartoon colorful handheld fan",
    "frown(n)": "a cartoon child frowning with eyebrows down",
    "hammer": "a cartoon claw hammer tool",
    "handle": "a cartoon door handle being turned",
    "harp": "a cartoon golden harp instrument",
    "hearth": "a cartoon warm fireplace hearth with fire",
    "hearth stone": "a cartoon stone fireplace with warm fire",
    "herd": "a cartoon herd of cows in a green field",
    "hippopotamus": "a cartoon happy hippo in water",
    "hole/pit": "a cartoon hole in the ground",
    "hunchback": "a cartoon turtle with a big shell on its back",
    "hunting": "a cartoon bow and arrow with target",
    "intestines": "a cartoon simplified digestive system diagram",
    "jigger": "a cartoon tiny bug under magnifying glass",
    "judge": "a cartoon wise judge with gavel",
    "kind": "a cartoon child being kind helping a bird",
    "kola nut": "a cartoon brown cola nut split open",
    "lance, spear": "a cartoon African spear",
    "little": "a cartoon tiny ant next to a big leaf",
    "lock": "a cartoon padlock with key",
    "lock of hair": "a cartoon curly lock of hair",
    "mad": "a cartoon angry face with steam",
    "medicine": "a cartoon bottle of medicine with spoon",
    "misplace": "a cartoon child looking for lost keys",
    "mistake": "a cartoon oops speech bubble with eraser",
    "mourning, crying": "a cartoon person crying at a memorial",
    "musical instrument": "cartoon colorful collection of musical instruments",
    "nest": "a cartoon birds nest with eggs in a tree",
    "pit": "a cartoon deep pit in the ground",
    "poorly": "a cartoon sick child wrapped in blanket",
    "ready": "a cartoon child in starting position for a race",
    "response": "a cartoon speech bubble with reply arrow",
    "stone": "a cartoon smooth grey stone",
    "tax": "a cartoon stack of coins with receipt",
    "thing": "a cartoon mystery box with question mark",
    "thing, something": "a cartoon colorful wrapped present",
    "twins": "cartoon identical twin children smiling together",
    "venom (of snake), stinger": "a cartoon snake with drops of venom",
    "watch/wait": "a cartoon child watching and waiting patiently",
    "wise saying": "a cartoon owl with wise speech bubble",
    "worry, feel disturbed": "a cartoon child with worried thought bubble",
    "worry, restlessness": "a cartoon anxious child biting nails",
    "widowhood": "a cartoon gentle woman in remembrance",
    "spark of fire": "a cartoon bright orange spark flying from flint",
    "excrement": "a cartoon brown poop emoji with flies",
    "stool/chair (traditional)": "a cartoon traditional wooden African stool",
    "physical exercise": "a cartoon child doing jumping jacks",
    "dream": "a cartoon child sleeping with colorful dream cloud",
    "journey": "a cartoon winding road leading to sunset mountains",
    "sing": "a cartoon child singing with floating music notes",

    # ----------------------------------------------------------------
    # AWING / CAMEROONIAN FOOD - achu and the cocoyam cluster
    # ----------------------------------------------------------------
    # Dr. Sama, Oct 2026, with reference photos and
    # https://en.wikipedia.org/wiki/Achu_(soup) :
    #   "achu or achue comes from cocoyam, what we call in the west taro"
    #
    # The generic prompts were drawing a bowl of pale mush. Achu is a
    # specific dish and it looks specific: cocoyam (taro) boiled and pounded
    # to a smooth white paste, SHAPED ON A PLATE with a crater pressed into
    # the middle, and that crater filled with the yellow soup - yellow from
    # palm oil, limestone water, spices and meat stock - with beef, cow
    # skin, tripe or fish alongside. Not a bowl, not fufu, not brown stew.
    #
    # This is exactly the NACDA ask - "other objects should be things from
    # Awing" - and it cannot be solved by style tokens. Each local item
    # needs its own description. See contributions/cultural_image_review.md
    # for the rest of the list awaiting Dr. Sama's descriptions.
    "achu": _ACHU_PLATE,
    "achu soup": ("a cartoon bowl of bright yellow Cameroonian achu palm "
                  "oil soup"),
    "pounded cocoyams": _ACHU_PLATE,
    "cocoyams pounded and eaten with red": _ACHU_PLATE,
    "cocoyams that are pounded and eaten": _ACHU_PLATE,
    "cocoyams": ("cartoon taro cocoyam roots, rough brown hairy skin, "
                 "in a pile"),
    "little cocoyams": "small round cartoon taro cocoyam corms",
    "little cocoyams attached to the main": (
        "a cartoon taro cocoyam corm with small cormels attached"),
    "leave of cocoyam": _COCOYAM_LEAF,
    "the leave of a cocoyam": _COCOYAM_LEAF,
    "seed of cocoyam": "a cartoon taro cocoyam corm ready for planting",
    "plant cocoyam": _PLANT_COCOYAM,
    "plant cocoyams": _PLANT_COCOYAM,
    "plant a little": _PLANT_COCOYAM,
    "a piece of metal used for": (
        "a cartoon flat metal scraper for cleaning a wooden achu mortar"),
    "a carved piece of wood used": (
        "a cartoon carved wooden achu serving spoon"),
    "plant disease that attacks cocoyams": (
        "a cartoon cocoyam taro leaf with brown blight spots"),
    "a container for achu soup": _ACHU_BOWL,
    "container for achu soup": _ACHU_BOWL,
    "achu motar spoon": ("a cartoon carved wooden achu serving spoon"),
    "banana used for preparing achu": (
        "cartoon green plantains for preparing achu"),
    "metal used for cleaning an achu": (
        "a cartoon flat metal scraper for cleaning a wooden achu mortar"),

    # ----------------------------------------------------------------
    # ABSTRACT WORDS GET A SCENE, NOT THE WORD
    # ----------------------------------------------------------------
    # Dr. Sama, 2026-10-08: "celibate suppose to be a single girl or boy.
    # seems you are overthinking this. generate pictures based on english
    # meaning!!!!!"
    #
    # He is right and I had it wrong twice over. I reported 244 entries as
    # having "no visual referent" and proposed leaving them blank. But an
    # illustrator does not draw the NOUN, they draw the SITUATION the noun
    # names, and every one of these has one: celibate is a single person
    # standing alone with no ring; frugality is a coin going into a savings
    # tin; literacy is a child reading aloud and pointing at the words. The
    # abstraction was in my prompt, not in the meaning.
    #
    # 88 keys below, covering the whole no_visual_referent list. Written as
    # scenes with concrete objects and actions - a thing a child can look at
    # and name. No skin or nationality is stated here on purpose:
    # africanize_people() inserts "Cameroonian <skin>" before the first
    # human noun at build time, so these stay one sentence about what is
    # happening.
    #
    # A POSITIVE PROMPT CANNOT SAY "NOT". The first version of the celibate
    # three read "...standing alone and smiling, no wedding ring, a married
    # couple holding hands in the distance". SDXL has no way to render "no"
    # and it renders every noun it is given, so the card came back as a
    # couple holding hands - the one thing the word means the absence of.
    # Same reason "emptiness" said "nothing inside it" and drew a full pot.
    # Describe only what should be ON the card: one person, by themselves,
    # in an empty courtyard.
    #
    # Two written deliberately rather than literally. "deformity" is a bent
    # tree, not a person - a children's vocabulary card is not the place to
    # caricature a body. "disability" is a smiling child in a wheelchair
    # playing with friends, because the respectful depiction is the accurate
    # one.

    "a sort of sticky substance": "a blob of sticky golden tree sap stretching between two fingers",
    "bad reputation": "a boy walking past while other children whisper behind their hands and point",
    "be celibate": "one young man standing by himself in an empty village courtyard, hands at his sides, alone",
    "be impatient": "a child tapping one foot and frowning up at a wall clock",
    "be myopic": "a child squinting at a book held very close to the face",
    "bitterness": "a child pulling a sour puckered face after biting a bitter green leaf",
    "build a fence": "a man planting wooden posts to build a fence around a compound",
    "bury": "a mound of fresh earth with flowers laid on it and a carved wooden marker",
    "carelessness": "a child dropping a clay bowl, water spilling across the floor",
    "celibacy": "one young woman standing by herself in an empty village courtyard, hands at her sides, alone",
    "celibate": "one young person standing by themselves in an empty village courtyard, hands at their sides, alone",
    "cleanliness": "a child washing hands with white soap bubbles at a basin",
    "confidence": "a child standing tall with hands on hips and a big proud smile",
    "corruption": "a hand passing banknotes under a table to another waiting hand",
    "criticism": "a child frowning and pointing at another child's drawing",
    "deformity": "a bent and twisted tree trunk growing crookedly",
    "destiny": "a winding path leading away to one bright shining star",
    "disability": "a smiling child in a wheelchair playing ball with friends",
    "distruction that springs from jealousy, envy": "a child angrily knocking over another child's tower of blocks",
    "disturbance": "a noisy classroom with children shouting and loose papers flying",
    "disunity": "a thick rope snapped in two, children pulling away in opposite directions",
    "electricity": "a yellow lightning bolt beside a glowing light bulb",
    "emotional instability": "a face split down the middle, laughing on one side and crying on the other",
    "emptiness": "an overturned clay pot lying sideways on bare ground, its dark open mouth facing the viewer",
    "equivalence": "a balance scale with equal weights on both pans, perfectly level",
    "express sadness": "a child crying with tears running down both cheeks",
    "false witness": "a child pointing accusingly at another child, nose growing long",
    "fastidiousness": "a child carefully lining up pencils in a perfectly straight row",
    "foolish excitement": "a child jumping and waving both arms wildly with a silly open-mouthed grin",
    "foolishness": "a child wearing a cooking pot on the head like a hat",
    "form a relationship": "two children shaking hands and smiling at each other",
    "friendship": "two children with their arms around each other's shoulders, laughing",
    "frugality": "a child carefully dropping a coin into a savings tin, counting the few coins left",
    "good friendship": "two children happily sharing one plate of food between them",
    "good reputation": "a child receiving a prize while the other children clap",
    "goodness": "a child helping an elder carry a heavy basket on a village path",
    "greed": "a child hugging a huge pile of food with bulging cheeks while others have empty plates",
    "greediness": "a child hugging a huge pile of food with bulging cheeks",
    "harvest with impunity": "a child picking fruit from another person's tree, glancing over the shoulder",
    "holiness": "a white dove flying in a glowing halo of golden light",
    "humility": "a child bowing with lowered head and hands folded in front",
    "impatience": "a child tapping one foot and frowning up at a wall clock",
    "importance": "a gold trophy standing on a tall pedestal",
    "inheritance": "an elder handing a carved wooden stool to a young man",
    "integrity": "a child returning a found purse of coins to its owner",
    "intelligence": "a child solving a puzzle with a glowing light bulb above the head",
    "knowledge": "a child reading an open book with a glowing light bulb above the head",
    "lack patience": "a child tapping one foot and frowning up at a wall clock",
    "lance": "a long wooden spear with a pointed metal tip",
    "laziness": "a child asleep in a hammock while a hoe lies unused in the grass",
    "lie": "a child speaking with a long growing wooden nose",
    "literacy": "a child reading a book aloud and pointing at the words on the page",
    "luck": "a four leaf clover with golden sparkles around it",
    "lumbago": "an elder holding the lower back with a pained face",
    "man of integrity": "a respected elder standing tall with a kind steady face, villagers greeting him",
    "myopic": "a child squinting at a book held very close to the face",
    "nobleship": "a village chief wearing a beaded crown and an embroidered toghu robe",
    "partnership": "two traders shaking hands across a market stall",
    "pass through": "a child walking through an open doorway in a wall",
    "pensiveness": "a child sitting with chin resting on one hand, thinking quietly",
    "personality": "a child's smiling face surrounded by a small star, a heart and a music note",
    "pity": "a child kneeling to comfort a smaller crying child",
    "place of worship": "a small village church with a cross on the roof and an open door",
    "recover from illness": "a child sitting up in bed smiling, holding a bowl of hot soup",
    "redness": "a bright red hibiscus flower",
    "reduce in intensity": "a bright fire burning down to a few small glowing embers",
    "relationship": "two children standing side by side holding hands",
    "remembrance": "a child looking at an old photograph and smiling softly",
    "repentance": "a child kneeling with head bowed and hands pressed together",
    "reputation": "a child walking tall while villagers smile and nod at him",
    "resemblance": "two children with the very same face standing side by side",
    "residence": "a family house with a wooden door, a yard and a cooking fire",
    "reverence": "a child bowing low before a seated village elder",
    "righteousness": "a child standing straight beside a balance scale that is perfectly level",
    "sadness": "a child with tears on both cheeks and a downturned mouth",
    "sanctuary": "the quiet inside of a village church with a cross and lit candles",
    "satedness": "a child leaning back with a round full tummy beside an empty plate",
    "selfishness": "a child turning away hugging all the food while another child holds an empty bowl",
    "shortsighted": "a child squinting at a book held very close to the face",
    "shortsightedness": "a child squinting at a book held very close to the face",
    "sorrow": "a child crying with the head buried in both hands",
    "start a relationship": "two children meeting and shaking hands with big smiles",
    "sticky substance": "a blob of sticky golden tree sap stretching between two fingers",
    "stupidity": "a child trying to carry water in a woven basket, the water pouring out",
    "tiredness": "a child yawning widely and rubbing sleepy eyes",
    "togetherness": "a circle of children holding hands together in a ring",
    "unity": "a circle of children holding hands together in a ring",
    "wakefulness": "a child wide awake with big open eyes at night beside a small oil lamp",
    "working relationship": "two farmers hoeing one field side by side",
    "worship": "a group of people singing with raised hands inside a village church",

    # ----------------------------------------------------------------
    # fyaabə - from Dr. Sama directly, 2026-10-08
    # ----------------------------------------------------------------
    # "fyaabə is like mushmellow rusting stick" - i.e. the stick you hold
    # into a fire, like a marshmallow roasting stick. The dictionary gloss
    # ("piece of stick or iron used for controling embers") is accurate but
    # it does not tell SDXL what the thing LOOKS like, so the card drew a
    # workshop. The analogy does: a long stick, tip in the embers.
    #
    # "marshmallow" is deliberately NOT in the prompt. It was his analogy
    # for the shape, not the object, and a marshmallow is not an Awing
    # thing - putting one on the card is the "that is not an Awing thing"
    # complaint from the NACDA review.
    #
    # Six cards across four spellings (fyaabə, fyaabə̂, fyaabə̌, fyaaba) all
    # mean this, and one of them is miscategorised `body` - which is why it
    # was drawing a grandmother. An override bypasses the category template,
    # so all six now draw the stick. The spelling question stays open in
    # near_duplicate_review.md.

    "a piece of stick or iron": "a long thin wooden stick with its blackened tip resting in the glowing red embers of a small cooking fire, stirring the embers",
    "control embers using a piece": "a hand holding a long thin wooden stick, its blackened tip pushed into the glowing red embers of a small cooking fire",
    "control sth using a stick": "a hand holding a long thin wooden stick, its blackened tip pushed into the glowing red embers of a small cooking fire",
    "piece of stick or iron used": "a long thin wooden stick with its blackened tip resting in the glowing red embers of a small cooking fire, stirring the embers",
    "stick for handling sth": "a long thin wooden stick with its blackened tip resting in the glowing red embers of a small cooking fire, stirring the embers",

    # ----------------------------------------------------------------
    # THE SAMPLE RUN, 2026-10-08 - words the prompt alone could not carry
    # ----------------------------------------------------------------
    # Dr. Sama on the regenerated sample: "hump should not be a person.
    # such and many others should be fixs before we can analyze and push
    # and generate all." Right - and all of these failed for one of two
    # reasons the prompt mechanism cannot fix by itself.
    #
    # 1. THE ENGLISH IS A HOMOGRAPH and the dictionary means the rarer
    #    sense. "iron" is the metal here; SDXL drew a sewing machine and a
    #    clothes iron, which is the commoner sense and a reasonable reading
    #    of the word on its own. "crunch" is a texture word with no object,
    #    so it drew coloured tiles. No amount of prompt repair picks the
    #    right sense - only naming the object does.
    #
    # 2. THE GLOSS IS MISSPELLED. "inhygenic" is not a word, so the model
    #    dropped the prefix it did not recognise and drew a CLEAN river -
    #    the exact opposite of the entry. Worth hunting as a class: a typo
    #    in a gloss can invert the picture silently.
    #
    # "hump" is both at once: three senses sharing one headword, in
    # category `body`, where the template asks for a close-up of a person -
    # which is why the card was a girl's face.
    #
    # Dr. Sama, after the first attempt drew a hunched man: "hump should
    # not have humans in it. use camel or other animals with hump to show
    # hump. It is not that difficult."
    #
    # Right on both counts. A hunched man is the literal gloss and a bad
    # card: SDXL renders a man who looks ordinary, so the hump - the whole
    # point - is the part that does not survive. A camel's hump is the
    # clearest hump there is, a child names it instantly, and it carries no
    # suggestion that a disabled body is the illustration for a noun. Zebu
    # for the "of cow" sense, which is the one Awing children actually see.
    #
    # GENERAL RULE this is an instance of: when a feature is the word, pick
    # the creature or object where that feature is unmissable, not the one
    # the gloss happens to name.

    "a piece of rough iron used": "a rough grey iron sharpening bar held against the blade of a machete, sparks at the edge",
    "crunch": "a dog biting down hard on a bone, the bone cracking between its teeth",
    "crunch soft bone": "a dog biting down hard on a bone, the bone cracking between its teeth",
    "divide": "two hands cutting one round loaf into equal halves with a knife",
    "divide or share": "a child sharing a plate of food into two equal portions for two children",
    "hump": "a camel standing in profile on sand, two large rounded humps rising from its back",
    "hump of cow": "a zebu cow standing in profile, one large rounded hump rising from its shoulders above the front legs",
    "hump of hunchback": "a camel standing in profile on sand, two large rounded humps rising from its back",
    "inhygenic environment": "a dirty village yard with scattered rubbish, a pool of dirty standing water and flies buzzing",
    "iron": "a heavy grey bar of raw iron metal lying on a workbench, rough unpolished surface",
    "melt iron": "a blacksmith at a forge pouring glowing orange molten iron from a crucible, red hot coals below",
    "metal bar": "a heavy grey bar of raw iron metal lying on a workbench, rough unpolished surface",
    "slight injury or pain": "a small scrape on a child's knee with a plaster on it",
    "unhygienic environment": "a dirty village yard with scattered rubbish, a pool of dirty standing water and flies buzzing",

    # ----------------------------------------------------------------
    # BATCH 1 of the thin-prompt list (2026-10-08)
    # ----------------------------------------------------------------
    # 1,367 gloss words carry only ONE content word and no curated prompt,
    # covering 2,087 cards. "a curse", "a plan", "stoop" - correct English,
    # whole meaning, and nothing for a 4-step model to hold on to.
    #
    # These are written the way an illustrator would: the SITUATION the word
    # names, with objects in it. No negations and no contrast subjects - a
    # positive prompt renders every noun it is given, which is how "no
    # wedding ring, a married couple in the distance" produced a couple.
    #
    # Concrete nouns are deliberately NOT in here. "mushroom", "eagle",
    # "camel", "ankle", "gold" already draw correctly from the gloss alone;
    # an override would add nothing and would be one more string to keep
    # true.

    "accuse": "a man pointing a finger at another man across a seated gathering",
    "adult": "a grown man standing tall beside a small child for height comparison",
    "again": "a circular arrow looping back to its own starting point",
    "age-group": "a row of children of exactly the same height standing shoulder to shoulder",
    "alter": "a tailor taking in the seam of a shirt with pins along the edge",
    "announce": "a village announcer walking through the village beating a gong, mouth open calling",
    "another": "one hand setting a second identical cup beside the first",
    "answer": "a child with a raised hand standing beside a blackboard",
    "antidote": "a small glass bottle with a green leaf beside it and a snake coiled at a distance",
    "argument": "two people facing each other mid-gesture, mouths open, hands up",
    "arrive": "a traveller with a bundle stepping through a village gate",
    "assorted": "a tray holding many different fruits and vegetables side by side",
    "avoid": "a person stepping wide around a puddle on a path",
    "be alive": "a child running and laughing across a sunlit field",
    "be dreaming": "a sleeping child with a cloud above holding a flying bird",
    "be in fear": "a child crouching with both hands over the eyes",
    "be innocent": "a child with open empty hands held out, shoulders raised",
    "be proud": "a person standing tall with chest out and hands on hips",
    "be sated": "a person leaning back with a round full belly beside a cleared plate",
    "be unconscious": "a person lying flat on a mat with eyes closed and arms limp",
    "begging": "a seated person holding out both cupped hands to a passer-by",
    "bless": "an elder's open hand resting on a kneeling child's head",
    "borrow": "one hand passing a hoe to another hand, the lender still reaching after it",
    "boyfriend": "a young man and a young woman walking side by side holding hands",
    "bribe": "folded banknotes being slid across a table into a waiting hand",
    "bump": "two people colliding shoulder to shoulder on a narrow path",
    "caress": "a hand gently stroking a child's cheek",
    "certain": "a child nodding firmly with one thumb raised, standing beside a ticked list",
    "choke": "a person with both hands at their own throat, coughing",
    "clan": "a large extended family grouped together outside their compound",
    "classifier": "a set of wooden blocks sorted into three labelled boxes by shape",
    "climbing": "a boy halfway up a palm tree trunk, arms and legs gripping",
    "clue": "a magnifying glass held over a single footprint in soft earth",
    "competition": "two children running towards a finish line side by side",
    "completely": "a bowl filled right to its brim with water",
    "condole": "a hand resting on the shoulder of a seated person with bowed head",
    "confess": "a child standing before an elder with head lowered and hands open",
    "confession": "a child standing before an elder with head lowered and hands open",
    "continuously": "a stream of water pouring unbroken from a gourd into a basin",
    "cooperate": "four people lifting one heavy log together, all hands under it",
    "create": "two hands shaping a clay pot on a turning wheel",
    "cross": "a person stepping over a low wall from one side to the other",
    "cunning": "a fox crouching low behind a bush, watching a hen with narrowed eyes",
    "curse": "an angry elder pointing a carved stick at the ground, dark storm cloud gathering above",
    "deaf": "a person turning an ear forward and cupping it with one hand",
    "debt": "an open ledger with a long list of figures and a hand pointing at a total",
    "deceit": "a smiling man with one hand held behind his back hiding a stone",
    "deceive": "a smiling man with one hand held behind his back hiding a stone",
    "deception": "a smiling man with one hand held behind his back hiding a stone",
    "decide": "a path splitting in two, a child standing at the fork pointing down one way",
    "dedication": "a lit candle placed on a cloth-covered table with hands resting beside it",
    "delay": "a sand timer almost run through, a person waiting beside it on a bench",
    "description": "a hand drawing the outline of an object on paper while the object sits beside it",
    "destruction": "a collapsed mud wall with broken pieces scattered on the ground",
    "dip": "a hand lowering a piece of fufu into a bowl of soup",
    "disgrace": "a man walking away with his head down as others turn their backs",
    "disturb": "a child shaking the shoulder of another child who is trying to sleep",
    "diviner": "a seated elder casting cowrie shells onto a mat",
    "divorce": "a torn paper with two wedding rings lying apart on either half",
    "east": "a sun rising over low hills, long shadows pointing away from it",
    "enlarge": "a small circle beside a much bigger circle of the same shape",
    "entertain": "a drummer and a dancer performing while seated villagers clap",
    "everywhere": "one small symbol repeated across a whole village scene, on every roof",
    "exactly": "a balance scale perfectly level with one weight on each pan",
    "exclamation": "a child with mouth open wide and both hands up in surprise",
    "exile": "a lone figure walking down a road away from a village gate, bundle on his back",
    "exorcise": "a diviner shaking a rattle over a seated person, smoke rising from a bowl",
    "farmer": "a man with a hoe over his shoulder standing in a cultivated field",
    "fasten": "two hands tying a rope tightly around a bundle of firewood",
    "ferment": "a covered clay pot with bubbles rising through the liquid inside",
    "fine": "a hand paying coins across a table to an official with a ledger",
    "follower": "three people walking in single file along a narrow path, one leading",
    "fool": "a child wearing a cooking pot as a hat, grinning",
    "forgive": "two people embracing, one patting the other's back",
    "french": "a blue white and red flag on a pole beside an open school book",
    "frugal": "a careful hand dropping one coin into a clay savings pot",
    "galore": "a basket overflowing with maize cobs, more spilling onto the ground",
    "giant": "a very tall man standing beside a normal sized hut, his head above the roof",
    "girlfriend": "a young woman and a young man walking side by side holding hands",
    "god": "a bright beam of golden light breaking through clouds onto open ground",
    "grace": "two open hands held out together offering a small gift",
    "granddaughter": "a small girl sitting on her grandmother's knee",
    "grandson": "a small boy sitting on his grandfather's knee",
    "greetings": "two people clasping hands warmly, each with the free hand on the other's shoulder",
    "grunt": "a pig standing in mud with its mouth open",
    "hatch": "a chick breaking out of a cracked eggshell in a nest",
    "hem": "a needle and thread stitching along the folded edge of a cloth",
    "his/hers": "two hands each holding a different bag, one on the left and one on the right",
    "imitation": "a child copying the exact pose of the child in front of him",
    "inhabitant": "a woman standing in the doorway of her own house, looking out",
    "insist": "a person standing firm with arms folded, chin up",
    "introduction": "one person presenting a second person to a third with an open hand",
    "islam": "a crescent moon and a star above a domed building with a tall tower",
    "joke": "two children laughing together, one covering his mouth",
    "joyful": "a child leaping with both arms thrown up, mouth wide open laughing",
    "junior": "a small child standing beside a much taller older child",
    "justify": "a man speaking with both palms open, a balance scale beside him level",
    "lend": "one hand passing a hoe to another hand, the lender still reaching after it",
    "meet": "two people walking from opposite sides and shaking hands where the paths cross",
    "move": "two people carrying a wooden chest together across a yard",
    "much": "a tall heap of groundnuts piled high on a mat",
    "namesake": "two people shaking hands, both wearing the same name tag",
    "nobody": "an empty wooden chair in an empty swept courtyard",
    "noon": "the sun directly overhead with very short shadows beneath a tree",
    "noun": "a wooden flashcard with a picture of a house on it held up by a teacher",
    "oath": "a hand raised flat with the palm forward, the other hand on a carved staff",
    "pain": "a child wincing with one hand pressed to a bandaged arm",
    "pant": "a runner bent over with hands on knees, mouth open, breathing hard",
    "paradise": "a bright garden of fruit trees and clear water under a blue sky",
    "pass": "one hand handing a calabash sideways to another hand",
    "people": "a crowd of villagers standing together in a market square",
    "plan": "a hand drawing a simple map on paper with arrows and a marked destination",
    "polygamy": "a man seated with three wives beside him outside a compound",
    "pretend": "a child holding a painted mask in front of his own face",
    "prisoner": "a man seated behind vertical bars with his hands on them",
    "promise": "two little fingers hooked together in a pinky promise",
    "property": "a fenced compound with a house, a goat and a stack of baskets inside",
    "prophecy": "an elder holding a staff and pointing at the horizon, listeners behind",
    "punish": "a child standing facing the wall with arms folded behind",
    "put": "a hand setting a clay bowl down onto a wooden table",
    "question": "a child with one hand raised and a large question mark above",
    "real": "a solid round stone held in an open palm",
    "reasoning": "two people seated facing each other, one counting points on his fingers",
    "rebuke": "an elder wagging one finger at a child who looks down",
    "reduce": "a tall pile of grain beside a much smaller pile of the same grain",
    "rejoicing": "a group of villagers dancing in a circle with raised arms",
    "religion": "an open book on a wooden stand with a lit candle beside it",
    "resurrection": "an empty stone tomb with the round stone rolled aside and light streaming in",
    "reward": "an open hand holding out a small cloth bag of coins to a smiling child",
    "salvation": "a hand reaching down to pull another hand up out of a deep hole",
    "saw": "a hand saw cutting through a wooden plank, sawdust falling",
    "saying": "an elder seated on a stool speaking, a listening child beside him",
    "secretary": "a person at a desk writing in a large notebook beside a telephone",
    "shake": "two hands gripping a basket and shaking it, beans jumping inside",
    "shepherd": "a man with a long staff walking behind a small flock of sheep",
    "sign": "a painted wooden signboard on a post beside a village path, an arrow on it",
    "slander": "two people whispering behind a hand while a third walks past",
    "slice": "a knife cutting a tomato into even round slices on a board",
    "slip": "a person's foot sliding out from under them on wet ground, arms flying up",
    "soldier": "a uniformed man standing at attention with a cap and boots",
    "some": "a bowl holding a small handful of beans while a larger sack sits closed beside it",
    "something": "a cloth-covered lump on a table with the cloth half lifted",
    "sound": "a drum being struck, curved sound waves rippling outward from the drumskin",
    "south": "a compass lying on a wooden table, its needle pointing down the page",
    "sovereign": "a village chief seated on a carved wooden throne holding a staff",
    "sprinkle": "a hand scattering white powder over a bowl of food",
    "sprout": "a small green shoot pushing up through dark soil",
    "statement": "a person standing and speaking, one hand flat and forward",
    "stir": "a wooden spoon turning thick soup in a cooking pot",
    "stoop": "a woman bending forward at the waist to pick a gourd off the ground",
    "straddle": "a child sitting astride a low wooden bench, one leg each side",
    "suckle": "a calf feeding at its mother cow's udder",
    "supplication": "two cupped hands raised together, head bowed",
    "swear": "a hand raised flat with the palm forward, the other hand on a carved staff",
    "taboo": "a bundle of leaves tied to a stick planted in front of a closed doorway",
    "tempt": "a hand holding a ripe mango out towards a hesitating child",
    "test": "a person tapping a clay pot with one knuckle and listening",
    "this day": "a wall calendar with today's square circled in red",
    "thought": "a child looking up with a thought bubble holding a question mark",
    "traitor": "a man slipping away behind a hut while others sit talking at the fire",
    "traverse": "a person walking across a log bridge over a stream, halfway over",
    "treasurer": "a person at a table counting coins into neat stacks beside a ledger",
    "trickle": "a thin thread of water running down a rock face",
    "true": "a child holding up a mirror that shows exactly the same face",
    "wail": "a seated woman with her head thrown back and mouth open, tears on her face",
    "weed": "a hand pulling weeds out from between rows of young maize",
    "whichever": "two identical mangoes side by side with a hand hovering between them",
    "whole": "one complete round orange, uncut, beside a knife laid down",
    "worry": "a child sitting with hands on cheeks, forehead creased, looking at the ground",
    "youngster": "a lively child of about eight running with a stick and hoop",

    # ----------------------------------------------------------------
    # QUESTION WORDS
    # ----------------------------------------------------------------
    # Dr. Sama: "ake for instance meaning what has people in it. instead of
    # image of what". Two faults in one card. The people came from the skin
    # clause, fixed above. But "a what" was never a picture of anything
    # either - there is no object called a what, so the model drew whatever
    # noun it could find in the prompt.
    #
    # An interrogative does have a picture: the SITUATION of asking it. A
    # question mark beside a box you cannot see into is "what"; a signpost
    # at a crossroads is "where"; a clock and a calendar is "when". Same
    # principle as celibate being a person standing alone.
    #
    # "no text, no words" is in the style suffix and a question mark is a
    # mark rather than a word, so it survives where a caption would not.

    "how": "a open instruction sheet showing three numbered steps with small diagrams",
    "how many": "a row of five mangoes with a question mark above the row",
    "how many?": "a row of five mangoes with a question mark above the row",
    "how?": "a open instruction sheet showing three numbered steps with small diagrams",
    "know": "an open book with a glowing light bulb rising from its pages",
    "know how": "an open instruction sheet showing three numbered steps with small diagrams",
    "what": "a large bold question mark beside a closed wooden box with its lid ajar",
    "what?": "a large bold question mark beside a closed wooden box with its lid ajar",
    "when": "a wall clock and a calendar side by side, a question mark above them",
    "when?": "a wall clock and a calendar side by side, a question mark above them",
    "where": "a signpost at a crossroads with arrows pointing three different ways",
    "where?": "a signpost at a crossroads with arrows pointing three different ways",
    "which": "two identical calabashes side by side with a question mark between them",
    "which?": "two identical calabashes side by side with a question mark between them",
    "who": "an empty silhouette outline of a head and shoulders with a question mark inside",
    "who?": "an empty silhouette outline of a head and shoulders with a question mark inside",
    "why": "a large bold question mark standing alone on plain ground",
    "why?": "a large bold question mark standing alone on plain ground",

    # ----------------------------------------------------------------
    # CLOTHED BY CONSTRUCTION
    # ----------------------------------------------------------------
    # Dr. Sama found a naked card: "I just hope the naked picture will not
    # be shown to kids."
    #
    # The words that caused it are now gated out entirely (see
    # _ADULT_ENTRY). These are the OTHER ones - swim, bathe, waist, thigh,
    # pregnant - which are ordinary vocabulary a child should have, and
    # which a 4-step model will happily draw unclothed if the prompt says
    # only "bathe".
    #
    # So every one of them names the clothing explicitly: a full swimming
    # costume, shorts, a full-length wrapper, a hospital gown. The negative
    # prompt bans nudity on every prompt as well, but a negative is a
    # preference and the positive is an instruction. Both, for these.

    "abdomen": "a simple labelled outline diagram of a torso wearing a t-shirt, an arrow pointing to the middle",
    "bath": "a tin bucket of water with a sponge and a bar of soap beside it",
    "bath room or any shade for bathing": "a small woven grass bathing shelter beside a house, a bucket inside",
    "bath, room or any shade for bathing": "a small woven grass bathing shelter beside a house, a bucket inside",
    "bathe": "a Cameroonian child in shorts washing their arms with a sponge beside a bucket of water",
    "bathing": "a Cameroonian child in shorts washing their arms with a sponge beside a bucket of water",
    "be pregnant": "a Cameroonian woman in a loose full-length dress with a rounded belly, both hands resting on it",
    "bottom": "a wooden stool seen from the side, its flat underside facing the viewer",
    "conceive a child": "a Cameroonian woman in a loose full-length dress with a rounded belly, both hands resting on it",
    "give birth": "a Cameroonian mother in a hospital gown holding a newborn wrapped in a blanket",
    "tradition of bathing": "a tin bucket of water with a sponge and a bar of soap beside it",
    "bathe wash body": "a Cameroonian child in shorts washing their arms with a sponge beside a bucket of water",
    "swimming": "a Cameroonian boy in a full swimming costume swimming in a river, water up to his shoulders",
    "gird up": "two hands tightening a cloth belt around a full-length robe",
    "loincloth": "a folded length of patterned cloth laid out on a wooden bench",
    "loincloth of some sort worn in the olden days": "a folded length of patterned cloth laid out on a wooden bench",

    # ----------------------------------------------------------------
    # GRAMMAR WORDS GET AN OBJECT, NOT A SKIPPED CARD
    # ----------------------------------------------------------------
    # Dr. Sama: "every work must have an image still stand. it must not be
    # human but has the object in the image match the word. any human in
    # any image must be black or brown."
    #
    # I had gated these out instead, because "the personal pronoun 'he'"
    # was drawing a classroom of white Europeans. Skipping was the easy
    # answer and the wrong one. The reason that card failed is that its
    # prompt named NOTHING - no person, no object - so the model invented a
    # scene and invented the people in it.
    #
    # Give the word an object and the problem disappears at the source:
    #   this   a hand pointing at a calabash right beside it
    #   that   the same hand pointing at a calabash across the yard
    #   and    two mangoes with a plus sign between them
    #   but    an arrow bouncing back off a wall
    #   from   an arrow curving OUT of a pot; "to" curves IN
    #
    # Where a person is unavoidable (we, they, reflexive) the prompt says
    # Cameroonian so africanize_people() colours them, and hands are named
    # "dark brown" directly.

    "a dance group": "a group of Cameroonian dancers in matching dress with drummers behind them",
    "above": "one calabash floating directly over another calabash, a gap between them",
    "at": "a red map pin standing upright on a small drawn map",
    "be": "an empty wooden chair standing in a swept courtyard",
    "because": "one wooden domino falling and knocking the next one over",
    "biggest dance group in awing based": "a large group of Cameroonian dancers in matching dress with drummers",
    "but": "an arrow travelling forward and bouncing back off a brick wall",
    "from": "an arrow curving out of an open clay pot towards a basket",
    "future tense marker": "a calendar with tomorrow circled in red and an arrow pointing forward to it",
    "he": "a Cameroonian boy with very dark brown skin and a short natural afro standing alone on a mat, a bold arrow pointing at him",
    "he/him pronoun": "a Cameroonian boy with very dark brown skin and a short natural afro standing alone on a mat, a bold arrow pointing at him",
    "here": "a bright X marked on the ground with a stone on it, close to the viewer",
    "hers": "a girl's bright headscarf folded on a basket of maize beside a stool",
    "his": "a boy's woven hat resting on a basket of maize beside a stool",
    "if": "a path splitting into two, a signpost standing at the fork",
    "intensifier": "a small drum beside a very large drum of the same shape, a bold arrow growing from small to large",
    "it": "one clay pot standing alone in the middle of a plain mat",
    "mine": "a basket of mangoes with a red ribbon tied to its handle, a dark brown hand resting on it",
    "my": "a basket of mangoes with a red ribbon tied to its handle, a dark brown hand resting on it",
    "name of a quarter in awing": "a painted wooden village signboard on a post beside a red earth road",
    "negation marker": "a red circle with a diagonal line drawn across a mango",
    "no": "a bold red cross mark on a white card",
    "not": "a red circle with a diagonal line drawn across a mango",
    "noun class marker": "three baskets of different shapes, each with a different coloured tag tied to it",
    "of": "a bunch of bananas with one single banana drawn separately beside it",
    "or": "two mangoes with a forked arrow pointing to one and then the other",
    "ours": "one large basket of groundnuts with four dark brown hands resting on its rim",
    "perhaps": "a coin spinning in mid-air above an open palm",
    "prefix of awing gerunds": "a row of wooden blocks with one extra block being fitted onto the front end",
    "reflexive pronoun": "a Cameroonian child looking at their own face in a hand mirror",
    "so": "a dark rain cloud with an arrow leading down to a puddle below",
    "tense marker": "a calendar with yesterday, today and tomorrow marked by three coloured dots",
    "that": "a dark brown hand pointing across a yard at one calabash far away on a stool",
    "theirs": "a basket of yams standing apart, two baskets of its own kind behind it",
    "then": "two clocks side by side, the left showing an earlier time than the right",
    "there": "a bright X marked on the ground on a far hillside, a path leading to it",
    "these": "a dark brown hand held over three calabashes together on a mat in front",
    "they": "a group of Cameroonian children standing together, seen from behind",
    "this": "a dark brown hand pointing down at one calabash right beside it on a mat",
    "this is": "a dark brown hand resting on one calabash on a mat, the calabash lit brightly",
    "those": "a dark brown hand pointing at three calabashes far away on a distant hill",
    "to": "an arrow curving from a basket into an open clay pot",
    "us": "a circle of Cameroonian children standing together holding hands",
    "we": "a circle of Cameroonian children standing together holding hands",
    "whom": "an empty silhouette outline of a head and shoulders with a question mark inside",
    "with": "a spoon and a bowl tied together with a short cord",
    "women dance group": "a group of Cameroonian women in matching wrappers dancing in a circle",
    "yes": "a bold green tick mark on a white card",
    "yours": "a basket of mangoes held out towards the viewer by two dark brown hands",
    "at preposition point in time": "a red map pin standing on a calendar page, one date circled",
    "class marker": "three baskets of different shapes, each with a different coloured tag tied to it",
    "complement": "a row of wooden blocks with one extra block fitted onto the end",
    "demonstrative": "a dark brown hand pointing down at one calabash right beside it on a mat",
    "from starting source preposition": "an arrow curving out of an open clay pot towards a basket",
    "impersonal animal pronoun": "a goat standing alone on a mat with an arrow pointing at it",
    "it impersonal animal pronoun": "a goat standing alone on a mat with an arrow pointing at it",
    "personal pronoun": "a Cameroonian boy with a short natural afro and a Cameroonian girl with cornrow braids, both with very dark brown skin, standing side by side, a bold arrow pointing at each of them",
    "plural marker": "one mango beside a heap of five mangoes, an arrow from the one to the heap",
    "preposition at": "a red map pin standing upright on a small drawn map",
    "question marker": "a large bold question mark beside a closed wooden box with its lid ajar",
    "singular pronoun you": "a basket of mangoes held out towards the viewer by two dark brown hands",
    "the impersonal or animal pronoun": "a goat standing alone on a mat with an arrow pointing at it",
    "the personal pronoun": "a Cameroonian boy with a short natural afro and a Cameroonian girl with cornrow braids, both with very dark brown skin, standing side by side, a bold arrow pointing at each of them",
    "the singular pronoun you": "a basket of mangoes held out towards the viewer by two dark brown hands",
    "verb complement": "a row of wooden blocks with one extra block fitted onto the end",
    "lord's supper article": "a Cameroonian congregation with dark brown skin and natural hair seated around a long table sharing bread and a cup, a village church behind them",
    "lord's supper articles": "a Cameroonian congregation with dark brown skin and natural hair seated around a long table sharing bread and a cup, a village church behind them",
    "lord's supper": "a Cameroonian congregation with dark brown skin and natural hair seated around a long table sharing bread and a cup, a village church behind them",
    "personal pronoun 'them'": "a group of Cameroonian children with very dark brown skin and natural afro hair standing together, a bold arrow sweeping across all of them",
    "fastidiousness, pride, the habit of considering one's self special or more important": "a Cameroonian man with dark brown skin and a short afro brushing a speck from his spotless shirt, chin lifted, looking down his nose at a neighbour",
    "fastidiousness, pride; considering one's self special": "a Cameroonian man with dark brown skin and a short afro brushing a speck from his spotless shirt, chin lifted, looking down his nose at a neighbour",
    "good sign, happening when blood twitches somebody's eye in a particular spot depending on the person": "a close-up of the face of a Cameroonian woman with dark brown skin and a head wrap smiling, one hand touching just below her eye, small sparkle marks drawn there",
    'good sign blood twitches eye': "a close-up of the face of a Cameroonian woman with dark brown skin and a head wrap smiling, one hand touching just below her eye, small sparkle marks drawn there",
    'good sign when blood twitches near the eye': "a close-up of the face of a Cameroonian woman with dark brown skin and a head wrap smiling, one hand touching just below her eye, small sparkle marks drawn there",
    'good friday, day of jesus death': "Cameroonian worshippers with dark brown skin and natural hair kneeling quietly in a village church, a plain wooden cross on the wall, no figure on it",
    'good friday': "Cameroonian worshippers with dark brown skin and natural hair kneeling quietly in a village church, a plain wooden cross on the wall, no figure on it",
    'gods will': "a Cameroonian elder with dark brown skin and grey twists kneeling with open hands raised, a shaft of golden light coming down over a Grassfields hillside",
    "god's will": "a Cameroonian elder with dark brown skin and grey twists kneeling with open hands raised, a shaft of golden light coming down over a Grassfields hillside",
    'lords supper': "a Cameroonian congregation with dark brown skin and natural hair seated around a long table sharing bread and a cup, a village church behind them",
    'lords supper article': "a Cameroonian congregation with dark brown skin and natural hair seated around a long table sharing bread and a cup, a village church behind them",
    'fastidiousness': "a Cameroonian man with dark brown skin and a short afro brushing a speck from his spotless shirt, chin lifted, standing very upright",
    'fastidiousness, pride': "a Cameroonian man with dark brown skin and a short afro brushing a speck from his spotless shirt, chin lifted, standing very upright",
    'ancestor': "a tall carved dark wooden ancestral shrine post from the Cameroon Grassfields standing on a low platform, cowrie shells and a calabash at its base",
    'ancestors': "a row of tall carved dark wooden ancestral shrine posts from the Cameroon Grassfields standing on a low platform, cowrie shells and calabashes at their base",
    'disease of the scalp (sticky in nature)': "a simple labelled outline diagram of the back of a Black African head with short natural afro hair, a circle drawn around one patch of scalp",
    'disease of the scalp': "a simple labelled outline diagram of the back of a Black African head with short natural afro hair, a circle drawn around one patch of scalp",
    'behaviour': "a Cameroonian boy with dark brown skin and a short afro turning his face away with a disgusted expression from an overturned bowl of spoiled food on a mat",
    'speech': "a Cameroonian elder with dark brown skin and grey twists standing on a low wooden platform speaking, one hand raised, a seated crowd of Cameroonian villagers listening",
    'the like hard work but likes to enjoy the proceeds thereof': "a Cameroonian man with dark brown skin and a short afro sitting in the shade eating from a bowl while a full basket of harvested maize stands beside him and a hoe lies unused on the ground",
    'the like hard work but likes': "a Cameroonian man with dark brown skin and a short afro sitting in the shade eating from a bowl while a full basket of harvested maize stands beside him and a hoe lies unused on the ground",
    'marriage ceremony': "a Cameroonian bride with braided hair and a groom with a short afro, both with dark brown skin, standing under a decorated canopy while villagers clap",
    'obscene behaviour': "a Cameroonian elder with dark brown skin and grey twists frowning and holding up both palms in refusal, a bold red cross drawn in the air in front of him",
    'growth, in the armpit': "a simple labelled outline diagram of a person wearing a t-shirt with one arm raised, a circle drawn around the underarm area",
    'growth, in the armpit as a sign that one has a wound': "a simple labelled outline diagram of a person wearing a t-shirt with one arm raised, a circle drawn around the underarm area",
    'masses': "a very large crowd of Cameroonian people with dark brown skin and natural hair filling a village square",
    'awake': "a Cameroonian boy with dark brown skin and a short afro sitting upright on a mat at night with wide open eyes, a lamp burning beside him",
    'behaved': "a Cameroonian boy with dark brown skin and a short afro with folded arms and a scowl, an upturned stool and spilled basket behind him",
    # ---- Session 66v, round 2: the 73 glosses the first reshoot proved
    # could not be fixed by reshooting ----
    #
    # I flagged these as "a white person is in it" and put them in a
    # --keys-file. 73 of the 94 prompts NAMED NOBODY:
    #
    #     "a partnership work, partnership work clearly visible in the
    #      picture, ... plain white background"
    #
    # SDXL cannot draw an abstract noun, so it draws a scene, and its
    # default scene is an office of white people. The whiteness was a
    # SYMPTOM; the defect was a prompt with no subject. Reshooting
    # changed the seed and nothing else, and the second batch came back
    # whiter than the first.
    #
    # I had written the rule - print the prompt before claiming an
    # image problem is fixed - and then did not apply it to my own
    # list. Each of these now has a written scene, and every one names
    # dark brown skin and Black hair where it names a person at all.
    'behaviour, disgusting': "a Cameroonian boy with dark brown skin and a short afro turning his face away with a disgusted expression from an overturned bowl of spoiled food on a mat",
    'prayers': "a Cameroonian woman with dark brown skin and a patterned head wrap kneeling on a mat with her eyes closed and her hands pressed together",
    'fasting; intensive and serious prayer': "a Cameroonian man with dark brown skin and short twists kneeling beside an empty wooden bowl and a closed calabash, his hands pressed together, eyes closed",
    'provocative act': "a Cameroonian boy with dark brown skin and a short afro pointing and sticking out his tongue at another boy who is frowning",
    'partnership work': "two Cameroonian farmers with dark brown skin, one with cornrow braids and one with a short afro, carrying one large basket of maize between them across a field",
    'speech, sort of': "a Cameroonian elder with dark brown skin and grey twists standing on a low wooden platform speaking, one hand raised, a seated crowd of Cameroonian villagers listening",
    'the like hardwork but likes to enjoy the proceeds thereof': "a Cameroonian man with dark brown skin and a short afro sitting in the shade eating from a bowl while a full basket of harvested maize stands beside him and a hoe lies unused on the ground",
    'uninfluential': "a Cameroonian boy with dark brown skin and a short afro standing alone with his hand raised while a group of children behind him look the other way",
    'charm, of protective': "a small carved wooden amulet on a leather cord lying on a woven mat, cowrie shells around it",
    'land dealer': "a Cameroonian man with dark brown skin and short twists in a shirt standing at the edge of a marked-out field, holding a rolled paper and pointing at a boundary post",
    'marriage ceremony, sort of': "a Cameroonian bride with braided hair and a groom with a short afro, both with dark brown skin, standing under a decorated canopy while villagers clap",
    'fear, trembling on hearing of death': "a Cameroonian woman with dark brown skin and a head wrap sitting on a mat with both hands over her mouth, eyes wide, shaking",
    'foolish excitement, uncontrolled and often misguided excitement': "a Cameroonian boy with dark brown skin and a short afro jumping with both arms flung up, his basket tipped over and spilling behind him",
    'heartburn': "a simple labelled outline diagram of a person in a t-shirt with an orange glow drawn over the centre of the chest",
    'cold, of a disease': "a Cameroonian child with dark brown skin and a short afro wrapped in a blanket, holding a cloth to a runny nose, a steaming cup beside them",
    'influenza': "a Cameroonian child with dark brown skin and cornrow braids in bed under a blanket with a cloth on the forehead and a steaming cup on a stool",
    'breath': "a Cameroonian child with dark brown skin and a short afro outdoors on a cold morning, a visible puff of white breath in front of their mouth",
    'the spirit of god': "a single white dove descending in a shaft of golden light over an open Grassfields landscape, no people",
    'generation': "three Cameroonian people with dark brown skin standing in a row - a grandmother with a head wrap, a mother with braids and a small child with a short afro",
    'obscene behaviour, immoral behaviour': "a Cameroonian elder with dark brown skin and grey twists frowning and holding up both palms in refusal, a bold red cross drawn in the air in front of him",
    'new generation': "a group of young Cameroonian children with dark brown skin and natural afro hair running forward together across a field, an older generation watching from behind",
    'cain': "two carved wooden figures standing apart on a bare hill, one turned away from the other, long shadows between them",
    'foolish talk': "a Cameroonian man with dark brown skin and a short afro talking with a large empty speech bubble over his head while two listeners look away",
    'bliss, of wedded couples': "a Cameroonian husband with a short afro and wife with braided hair, both with dark brown skin, sitting side by side on a mat smiling, hands joined",
    'asthmatic cough': "a Cameroonian child with dark brown skin and a short afro sitting upright with a hand on the chest, mouth open, shoulders raised",
    'idea, thought': "a Cameroonian girl with dark brown skin and cornrow braids looking up with a bright glowing lamp drawn above her head",
    'idea': "a Cameroonian boy with dark brown skin and a short afro looking up with a bright glowing lamp drawn above his head",
    'suspicion': "a Cameroonian woman with dark brown skin and a head wrap glancing sideways with narrowed eyes at a closed basket behind her",
    'terrible lie': "a Cameroonian boy with dark brown skin and a short afro with one hand behind his back and a very long nose, a broken calabash on the ground",
    'collaboration': "four Cameroonian villagers with dark brown skin and natural hair lifting one long roof beam together onto a hut",
    'a whisper': "a Cameroonian girl with dark brown skin and cornrow braids cupping her hand to the ear of another girl, both smiling",
    'public order': "a Cameroonian village crowd with dark brown skin seated in neat rows on benches facing an elder who is speaking",
    'how? á pə̌ sé? how much?': "a Cameroonian market trader with dark brown skin and a head wrap holding up a tomato while a customer holds out coins, a large question mark above them",
    'accident, big injury': "a Cameroonian boy with dark brown skin and a short afro sitting on the ground holding his bandaged knee, an overturned bicycle beside him",
    'the first day of the week': "a calendar page with the first square of the week circled in bold red",
    'a difficult task or job': "a Cameroonian man with dark brown skin and short twists straining to push a very large boulder up a slope, sweat drops drawn",
    'traditional hospital, mostly to consult mediums': "a Cameroonian healer with dark brown skin and grey locs seated on a mat outside a thatched hut with calabashes, dried herbs and a patient seated opposite",
    'cold weather': "a Cameroonian child with dark brown skin and a short afro in a thick jumper and wrapper, arms crossed, breath visible, bare hills behind",
    'story teller': "a Cameroonian elder with dark brown skin and grey twists sitting by a fire at night, hands raised mid-tale, children with afro hair listening",
    'demonstration': "a Cameroonian teacher with dark brown skin and a head wrap showing a group of children how to plant a seedling, her hands in the soil",
    'theft done in a stealthy way': "a hand with dark brown skin quietly lifting a single yam from a basket in the dark, the owner asleep in the background",
    'concern': "a Cameroonian mother with dark brown skin and a head wrap resting the back of her hand on a child's forehead, her brow furrowed",
    'event that involves everybody': "the whole of a Cameroonian village with dark brown skin gathered in a circle in the square, drummers in the middle",
    'important event': "a Cameroonian chief with dark brown skin in a patterned gown seated under a decorated canopy while the village stands around",
    'burden': "a Cameroonian woman with dark brown skin and a head wrap walking bent forward under a very large bundle of firewood on her back",
    'hunt': "a Cameroonian hunter with dark brown skin and short twists crouching in tall grass with a wooden spear, watching an antelope in the distance",
    'command': "a Cameroonian chief with dark brown skin and a beaded cap pointing firmly with one arm outstretched while a young man listens",
    'exaggeration, giving of false value': "a Cameroonian trader with dark brown skin and a head wrap holding up one small tomato beside a drawn outline of a tomato ten times its size",
    'story/tale': "a Cameroonian elder with dark brown skin and grey twists telling a story by firelight to seated children with afro hair",
    'criticism, the act of diminishing the value of something, the act of making': "a Cameroonian man with dark brown skin and a short afro pointing dismissively at a well-made carved stool while the carver looks down",
    'english language': "an open book with the alphabet A B C written large on the page, a small Union flag in the corner",
    'parable': "a Cameroonian elder with dark brown skin and grey twists seated under a tree speaking, a small picture of a sower drawn in a thought bubble above",
    'hair of a dead close relation': "a small bundle of short dark curly hair bound with red thread, lying on a folded white cloth beside a carved wooden memorial post",
    'masses, the': "a very large crowd of Cameroonian people with dark brown skin and natural hair filling a village square",
    'the habit of giving too many assignments or too much burden on other people': "a Cameroonian man with dark brown skin and a short afro standing with folded arms while piling a fourth basket onto the back of a bent, overloaded worker",
    'intelligence, high learning ability': "a Cameroonian girl with dark brown skin and cornrow braids at a desk solving a problem on a slate, a bright lamp drawn above her head",
    'headache': "a Cameroonian woman with dark brown skin and a head wrap pressing both hands to her temples, jagged lines drawn around her head",
    'self control; patience': "a Cameroonian boy with dark brown skin and a short afro sitting calmly with his hands in his lap beside a bowl of mangoes he is not taking",
    'self control': "a Cameroonian boy with dark brown skin and a short afro sitting calmly with his hands in his lap beside a bowl of mangoes he is not taking",
    'who': "an empty silhouette outline of a head and shoulders with a large question mark inside",
    'possessive': "a Cameroonian girl with dark brown skin and cornrow braids holding a basket close to her chest with both arms, a bold arrow pointing from her to the basket",
    'awake, stay': "a Cameroonian boy with dark brown skin and a short afro sitting upright on a mat at night with wide open eyes, a lamp burning beside him",
    'terrible, evil, scandal, taboo': "a Cameroonian elder with dark brown skin and grey twists holding up both palms in refusal, a bold red cross drawn in the air in front of him",
    'behaved, poorly': "a Cameroonian boy with dark brown skin and a short afro with folded arms and a scowl, an upturned stool and spilled basket behind him",
    'growth, in the ampit': "a simple labelled outline diagram of a person wearing a t-shirt with one arm raised, a circle drawn around the underarm area",
    'growth, in the ampit as a sign that one has a wound': "a simple labelled outline diagram of a person wearing a t-shirt with one arm raised, a circle drawn around the underarm area",
    # ---- found by eye in the rendered pack, Session 66v ----
    # Each of these was SAFE as a gloss and UNSAFE as a picture, which
    # is why the gate never saw them. Only looking at the output finds
    # this class.
    #
    # "muscle" -> a white bodybuilder in briefs.
    "muscle": "a close-up of the upper arm of a Cameroonian farmer with dark brown skin in a short-sleeved shirt, the arm bent and the muscle raised",
    "muscles": "a close-up of the upper arm of a Cameroonian farmer with dark brown skin in a short-sleeved shirt, the arm bent and the muscle raised",
    # "growth in the armpit" -> a bare torso. A labelled diagram says
    # the same thing with a t-shirt on.
    "growth in the armpit": "a simple labelled outline diagram of a person wearing a t-shirt with one arm raised, a circle drawn around the underarm area",
    "growth in the ampit": "a simple labelled outline diagram of a person wearing a t-shirt with one arm raised, a circle drawn around the underarm area",
    # "sound that intensifies the sound" -> SDXL drew a REVOLVER, from
    # the headword "bum" and the word "sound". A weapon on a card in a
    # children's app. The negative prompt lists gun, pistol and rifle and
    # it was drawn anyway, which is the whole argument for looking at
    # the pictures rather than trusting the prompt.
    "sound that intensifies the sound": "a Cameroonian talking drum with bold curved sound waves radiating out from it, the waves getting larger",
    "sound that intensifies": "a Cameroonian talking drum with bold curved sound waves radiating out from it, the waves getting larger",
    "she": "a Cameroonian girl with very dark brown skin and cornrow braids standing alone on a mat, a bold arrow pointing at her",
    "she/her pronoun": "a Cameroonian girl with very dark brown skin and cornrow braids standing alone on a mat, a bold arrow pointing at her",
    "her": "a Cameroonian girl with very dark brown skin and cornrow braids standing alone on a mat, a bold arrow pointing at her",
    "him": "a Cameroonian boy with very dark brown skin and a short natural afro standing alone on a mat, a bold arrow pointing at him",
    "the personal pronoun he": "a Cameroonian boy with very dark brown skin and a short natural afro standing alone on a mat, a bold arrow pointing at him",
    "the personal pronoun she": "a Cameroonian girl with very dark brown skin and cornrow braids standing alone on a mat, a bold arrow pointing at her",
    "he she personal pronoun": "a Cameroonian boy with a short natural afro and a Cameroonian girl with cornrow braids, both with very dark brown skin, standing side by side, a bold arrow pointing at each of them",
    "the personal pronoun he the personal pronoun she": "a Cameroonian boy with a short natural afro and a Cameroonian girl with cornrow braids, both with very dark brown skin, standing side by side, a bold arrow pointing at each of them",
    "personal pronoun he": "a Cameroonian boy with very dark brown skin and a short natural afro standing alone on a mat, a bold arrow pointing at him",
    "personal pronoun she": "a Cameroonian girl with very dark brown skin and cornrow braids standing alone on a mat, a bold arrow pointing at her",
    "personal pronoun them": "a group of Cameroonian children with very dark brown skin and natural afro hair standing together, a bold arrow sweeping across all of them",
    "you": "a Cameroonian child with very dark brown skin and a short natural afro facing the viewer, a bold arrow pointing out of the picture at the viewer",
    "the pronoun you": "a Cameroonian child with very dark brown skin and a short natural afro facing the viewer, a bold arrow pointing out of the picture at the viewer",
    "you plural": "a Cameroonian child with very dark brown skin and a short natural afro facing the viewer, a bold arrow pointing out of the picture at the viewer",
    "i": "a Cameroonian child with very dark brown skin and a short natural afro pointing at their own chest with both hands",
    "me": "a Cameroonian child with very dark brown skin and a short natural afro pointing at their own chest with both hands",
    "the pronoun i": "a Cameroonian child with very dark brown skin and a short natural afro pointing at their own chest with both hands",
}


# ============================================================
# EMOJI FALLBACK
# ============================================================

CATEGORY_FALLBACK_EMOJI = {
    "body": "1f9b4",
    "animals": "1f43e",
    "nature": "1f33f",
    "food": "1f37d-fe0f",
    "actions": "26a1",
    "things": "1f4e6",
    "family": "1f465",
    "descriptive": "1f4a1",
    "numbers": "1f522",
    "default": "2753",
}

EMOJI_CODEPOINTS = {
    # Body parts
    "hand": "270b", "head": "1f3a9", "nose": "1f443", "neck": "1f9e3",
    "back": "1f9ce", "shoulder": "1f933", "blood": "1fa78", "leg": "1f9b5",
    "tongue": "1f445", "body": "1f3cb-fe0f", "eye": "1f441-fe0f", "ear": "1f442",
    "liver": "2695-fe0f", "intestine": "1f9ec", "chest": "1f3bd", "breastbone": "1f9b4",
    "mouth": "1f444", "tooth": "1f9b7", "hair": "1f487", "bone": "1f9b4",
    "stomach": "1f95e", "hip": "1f57a", "foot": "1f9b6", "crown": "1f451",
    "beard": "1f9d4", "breast": "1f476", "knee": "1fa7c", "wing": "1fab6",
    "navel": "1faa2", "thigh": "1f356", "soul": "1f4ab", "spirit": "1f54a-fe0f",
    "heart": "2764-fe0f", "cheek": "1f48b", "chin": "1f910", "elbow": "1f4a2",
    "finger": "1f446", "jaw": "1f62c", "forehead": "1f9e0", "rib": "1f9b4",
    "palm": "1f91a", "throat": "1f3a4", "skin": "270d-fe0f", "waist": "1fa73",

    # Animals
    "fish": "1f41f", "owl": "1f989", "snake": "1f40d", "ram": "1f40f",
    "goat": "1f410", "dog": "1f415", "duck": "1f986", "cricket": "1f997",
    "chicken": "1f414", "cat": "1f408", "bird": "1f426", "elephant": "1f418",
    "lion": "1f981", "hippo": "1f99b", "antelope": "1f98c", "mosquito": "1f99f",
    "tortoise": "1f422", "pig": "1f437", "frog": "1f438", "toad": "1f438",
    "giraffe": "1f992", "donkey": "1facf", "leopard": "1f406", "butterfly": "1f98b",
    "rat": "1f400", "louse": "1fab3", "shrimp": "1f990", "locust": "1f997",
    "squirrel": "1f43f-fe0f", "rooster": "1f413", "bee": "1f41d", "ant": "1f41c",
    "spider": "1f577-fe0f", "cow": "1f404", "sheep": "1f411", "horse": "1f40e",
    "monkey": "1f435", "snail": "1f40c", "turtle": "1f422", "rabbit": "1f407",
    "mouse": "1f401", "bat": "1f987", "parrot": "1f99c", "whale": "1f40b",

    # Nature
    "river": "1f3de-fe0f", "water": "1f4a7", "sky": "1f30c", "sun": "2600-fe0f",
    "rain": "1f327-fe0f", "wind": "1f4a8", "grass": "1f33f", "thunder": "26a1",
    "night": "1f319", "morning": "1f305", "evening": "1f307", "road": "1f6e3-fe0f",
    "waterfall": "1f4a6", "ground": "1f3d5-fe0f", "shadow": "1f311",
    "valley": "1f304", "mountain": "1f3d4-fe0f", "moonlight": "1f31c",
    "forest": "1f332", "tree": "1f333", "flower": "1f338", "leaf": "1f343",
    "rock": "1faa8", "stone": "1faa8", "moon": "1f319", "star": "2b50",
    "cloud": "2601-fe0f", "lightning": "26a1", "storm": "26c8-fe0f",
    "snow": "2744-fe0f", "ice": "1f9ca", "lake": "1f30a", "sea": "1f30a",
    "stream": "1f30a", "dust": "1f32b-fe0f", "sand": "1f3d6-fe0f",
    "soil": "1f331", "hill": "26f0-fe0f",

    # Food
    "food": "1f37d-fe0f", "meal": "1f958", "banana": "1f34c", "yam": "1f360",
    "cocoyam": "1f96e", "corn": "1f33d", "honey": "1f36f", "vegetable": "1f96c",
    "potato": "1f954", "pawpaw": "1f348", "egg": "1f95a", "meat": "1f357",
    "rice": "1f35a", "milk": "1f95b", "orange": "1f34a", "tomato": "1f345",
    "soup": "1f372", "guava": "1f34f", "pineapple": "1f34d", "coffee": "2615",
    "avocado": "1f951", "onion": "1f9c5", "cassava": "1f96f", "grape": "1f347",
    "pepper": "1f336-fe0f", "bread": "1f35e", "salt": "1f9c2", "bean": "1fad8",
    "mango": "1f96d", "coconut": "1f965", "mushroom": "1f344", "nut": "1f330",
    "oil": "1fad7", "wine": "1f377", "beer": "1f37a", "tea": "1f375",

    # Actions
    "eat": "1f374", "sleep": "1f634", "rest": "1f6cb-fe0f", "buy": "1f6d2",
    "catch": "1f932", "walk": "1f6b6", "kick": "1f94b", "say": "1f5e3-fe0f",
    "laugh": "1f602", "smile": "1f604", "cry": "1f62d", "sing": "1f3b5",
    "write": "270f-fe0f", "teach": "1f468-200d-1f3eb", "learn": "1f4da",
    "goodbye": "1f44b", "wash": "1f6bf", "prepare": "1f373",
    "want": "1f914", "remember": "1f4cc", "believe": "1f64f", "forget": "1f635",
    "run": "1f3c3", "jump": "1f938", "give": "1f381", "take": "1f4e5",
    "come": "1f449", "go": "1f448", "sit": "1fa91", "stand": "1f9cd",
    "play": "1f3ae", "work": "1f4bc", "dance": "1f483", "swim": "1f3ca",
    "climb": "1f9d7", "fall": "2b07-fe0f", "drink": "1f964", "cook": "1f373",
    "fight": "1f94a", "die": "1f480", "love": "2764-fe0f", "hate": "1f620",
    "know": "1f393", "think": "1f4ad", "see": "1f440", "hear": "1f442",
    "call": "1f4de", "send": "1f4e8", "open": "1f513", "close": "274c",
    "begin": "25b6-fe0f", "finish": "1f3c1", "help": "1f198",
    "build": "1f3d7-fe0f", "break": "1f4a5", "cut": "2702-fe0f",
    "pull": "1f3a3", "push": "1f91b", "carry": "1f4e6", "throw": "1f93e",
    "pour": "1fad6", "sew": "1f9f5", "grind": "2699-fe0f", "dig": "26cf-fe0f",
    "plant": "1f331", "harvest": "1f33e", "hunt": "1f3f9", "kill": "1f5e1-fe0f",
    "steal": "1f977", "borrow": "1f91d", "lend": "1f4b3", "pay": "1f4b5",
    "sell": "1f3ea", "count": "1f522", "measure": "1f4cf",

    # Things
    "house": "1f3e0", "hut": "1f6d6", "room": "1f6aa", "soap": "1f9fc",
    "clothes": "1f455", "car": "1f697", "book": "1f4da", "school": "1f3eb",
    "fire": "1f525", "chain": "26d3-fe0f", "rope": "1f9f6", "box": "1f4e6",
    "ball": "26bd", "door": "1f6aa", "basket": "1f9fa", "plate": "1f37d-fe0f",
    "trousers": "1f456", "money": "1f4b0", "instrument": "1f3b8", "horn": "1f4ef",
    "mat": "1f9f1", "machete": "1fa93", "bamboo": "1f38b", "tax": "1f4b8",
    "table": "1f4cb", "chair": "1fa91", "bed": "1f6cf-fe0f", "pot": "1fad5",
    "cup": "1f943", "spoon": "1f944", "knife": "1f52a", "candle": "1f56f-fe0f",
    "hammer": "1f528", "axe": "1fa93", "needle": "1faa1", "bucket": "1faa3",
    "key": "1f511", "lock": "1f512", "mirror": "1fa9e", "broom": "1f9f9",
    "bag": "1f45c", "hat": "1f452", "shoe": "1f45f", "ring": "1f48d",
    "bell": "1f514", "drum": "1fa98", "flute": "1fa88", "gun": "1f52b",
    "bow": "1f3f9", "arrow": "1f3f9", "shield": "1f6e1-fe0f", "spear": "1fa93",
    "lamp": "1f4a1", "radio": "1f4fb", "phone": "1f4f1", "clock": "1f552",
    "picture": "1f5bc-fe0f", "flag": "1f3f3-fe0f", "cross": "271d-fe0f",
    "medicine": "1f48a", "pen": "1f58a-fe0f", "paper": "1f4c4",

    # Family
    "father": "1f468", "mother": "1f469", "friend": "1f46b", "husband": "1f468",
    "wife": "1f469", "elder": "1f474", "chief": "1f468-200d-2696-fe0f",
    "person": "1f9d1", "boy": "1f466", "son": "1f466", "girl": "1f467",
    "daughter": "1f467", "child": "1f476", "owner": "1f3e0", "servant": "1f9d1",
    "butcher": "1f52a", "country": "1f30d", "farm": "1f69c",
    "compound": "1f3d8-fe0f", "place": "1f4cd", "hospital": "1f3e5",
    "church": "26ea", "grandmother": "1f475", "grandfather": "1f474",
    "uncle": "1f468", "aunt": "1f469", "brother": "1f466", "sister": "1f467",
    "baby": "1f9d2", "teacher": "1f468-200d-1f3eb",
    "doctor": "1f468-200d-2695-fe0f", "king": "1f451", "queen": "1f478",
    "thief": "1f977", "stranger": "1f47e", "enemy": "1f47f",
    "neighbor": "1f3e1", "twin": "1f46c", "orphan": "1f97a",
    "widow": "1f469", "warrior": "1f93a", "judge": "1f468-200d-2696-fe0f",
    "woman": "1f469", "man": "1f468", "people": "1f465",

    # Descriptive
    "black": "2b1b", "white": "2b1c", "red": "1f534", "blue": "1f535",
    "green": "1f7e2", "big": "1f418", "small": "1f90f", "long": "27a1-fe0f",
    "short": "2b06-fe0f", "fat": "1f4a3", "thin": "1faa1", "good": "1f44d",
    "beautiful": "2728", "hot": "1f525", "cold": "2744-fe0f", "hard": "1faa8",
    "strong": "1f4aa", "new": "1f195", "old": "1f474", "many": "1f4ca",
    "few": "1f447", "today": "1f4c5", "tomorrow": "1f4c6", "yesterday": "1f4c3",
    "often": "1f504", "ugly": "1f616", "alone": "1f9cd", "truly": "2705",
    "clever": "1f9d0", "light": "2600-fe0f", "empty": "1fad9", "full": "1fad8",
    "clean": "1f9f9", "dirty": "1f922", "tall": "1f3e2", "dark": "1f319",
    "bright": "1f31e", "soft": "1fab6", "heavy": "1f3cb-fe0f", "fast": "1f3c3",
    "slow": "1f422", "happy": "1f60a", "sad": "1f622", "angry": "1f620",
    "afraid": "1f628", "tired": "1f62b", "hungry": "1f924", "sick": "1f912",
    "alive": "1f33b", "dead": "1f480", "rich": "1f911", "poor": "1f614",
    "young": "1f476", "sweet": "1f36c", "bitter": "1f43b", "dry": "1f3dc-fe0f",
    "wet": "1f4a6", "round": "1f7e0", "straight": "1f4d0",

    # Numbers
    "one": "31-fe0f-20e3", "two": "32-fe0f-20e3", "three": "33-fe0f-20e3",
    "four": "34-fe0f-20e3", "five": "35-fe0f-20e3", "six": "36-fe0f-20e3",
    "seven": "37-fe0f-20e3", "eight": "38-fe0f-20e3", "nine": "39-fe0f-20e3",
    "ten": "1f51f", "zero": "30-fe0f-20e3",
}


# ============================================================
# UTILITY FUNCTIONS
# ============================================================

def audio_key(awing_word: str) -> str:
    """Delegates to scripts/awing_key.py — the single derivation shared with
    Dart's PronunciationService._audioKey().

    v1.24.2 (Session 66p): this held its own char_map, the FIFTH copy of the
    derivation in this repo. After the Dart side was fixed to stop deleting
    pre-composed letters, this one still produced the old keys, so [4/7] saw
    'aeo__cave' missing and generated it again. 92 orphan images went into
    the pack that the app can never request, and CI failed with
    "92 image file(s) in the pack are NOT in assets/image_manifest.json".

    For IMAGE filenames use image_key(awing, english): it appends a slug of
    the English gloss so homonyms each get their own illustration.
    """
    import os as _os, sys as _sys
    _d = _os.path.dirname(_os.path.abspath(__file__))
    if _d not in _sys.path:
        _sys.path.insert(0, _d)
    from awing_key import audio_key as _ak
    return _ak(awing_word)


def english_slug(english: str) -> str:
    """Delegates to scripts/awing_key.py — the single derivation.

    v1.24.5: moved there so apply_contributions.py could use the same one.
    It had been computing a contributor's image filename itself, without
    the English suffix, so every approved photo landed under a name the app
    never asks for. Equivalence with the previous local implementation was
    asserted over all 7,180 (awing, english) pairs before this delegation
    was committed.
    """
    from awing_key import english_slug as _es
    return _es(english)


# Maximum chars of the english slug appended to image filenames. Keeps
# `{audio_key}__{english_slug}.png` filenames well under common filesystem
# limits (Windows MAX_PATH + PAD asset name sanity) even when audio_key is
# itself long (phrase_*/sentence_*/story_* namespaces already cap at 60).
#
# v1.24.2 (Session 66p): this was deleted by accident when audio_key()
# above was replaced - the patch ran to the next "def", swallowing the
# constant that sat between the two functions. The file still COMPILED
# and still ended with a newline, so neither py_compile nor
# check_script_integrity.py caught it; the build died at [4/7] with
# NameError: name 'ENGLISH_SLUG_MAX' is not defined.
#
# v1.24.5: the value now lives in awing_key.py with the slug function it
# belongs to. Re-exported here, not redefined, so there is still exactly
# one number — and so the NameError above cannot come back.
from awing_key import ENGLISH_SLUG_MAX  # noqa: E402  (re-export)


def image_key(awing_word: str, english: str) -> str:
    """Delegates to scripts/awing_key.py — the single derivation.

    '{audio_key(awing)}__{english_slug(english)}'. See english_slug above
    for why this moved.
    """
    from awing_key import image_key as _ik
    return _ik(awing_word, english)


def parse_vocabulary() -> dict:
    """Parse Dart vocabulary file and extract all AwingWord entries.

    Notes:
    - Dart strings can be single- or double-quoted and contain escape
      sequences like \\' inside a single-quoted string. The previous regex
      (`[^'\\\"]+`) silently dropped any entry whose english field contained
      an escaped apostrophe — that was ~700 entries from the merged
      dictionary block.
    - Keys are built via `image_key(awing, english)` so each literal in the
      Dart source produces its OWN filename. Homonyms (té1 "learn" vs té2
      "sit"), low/high-tone pairs that collapse under the lossy audio_key,
      and near-homographs all survive as independent images.
    - When two literals share BOTH awing spelling AND english gloss (a true
      source-data duplicate in awing_vocabulary.dart), we still give each its
      own unique image key by appending `__N` where N is the 2-based ordinal
      of the duplicate (first occurrence = base key, second = `__2`, etc.).
      The Dart-side `imageKey(awing, english)` lookup computes the BASE key
      only, so the app always displays the first-occurrence image; the
      indexed variants exist on disk to satisfy "one image per literal"
      bookkeeping but are not consumed by the app until/unless a smarter
      picker is added. If you'd prefer one image per unique (awing, english)
      pair instead, de-dupe the Dart file and this function will naturally
      stop emitting `__N` suffixes.
    """
    vocabulary: dict = {}
    if not VOCAB_FILE.exists():
        print(f"ERROR: Vocabulary file not found: {VOCAB_FILE}")
        sys.exit(1)

    with open(VOCAB_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    # Dart string body: single-quoted (allows \\') OR double-quoted (allows \\").
    sq = r"'((?:\\.|[^'\\])*)'"      # 'foo bar', 'don\'t'
    dq = r'"((?:\\.|[^"\\])*)"'      # "foo bar"
    s = rf"(?:{sq}|{dq})"

    # Build full pattern. Each string slot has TWO capture groups (sq, dq); we
    # take whichever matched. dotall lets multi-line AwingWord(...) entries match.
    pattern = (
        r"AwingWord\(\s*"
        r"awing:\s*" + s + r"\s*,\s*"
        r"english:\s*" + s + r"\s*,\s*"
        r"category:\s*" + s
    )

    def _unescape(s: str) -> str:
        return re.sub(r"\\(.)", r"\1", s)

    total_literals = 0
    commented_skipped = 0
    duplicates_skipped = 0
    seen_base_keys: set = set()
    for match in re.finditer(pattern, content, flags=re.DOTALL):
        # Session 60 fix: skip commented-out lines (avoid ~466 wasted images
        # from commented entries left over from prior audits/regressions).
        line_start = content.rfind('\n', 0, match.start()) + 1
        line_prefix = content[line_start:match.start()]
        if '//' in line_prefix:
            commented_skipped += 1
            continue

        g = match.groups()
        # groups: (awing_sq, awing_dq, english_sq, english_dq, category_sq, category_dq)
        awing = _unescape(g[0] if g[0] is not None else g[1]).strip()
        english = _unescape(g[2] if g[2] is not None else g[3]).strip()
        category = _unescape(g[4] if g[4] is not None else g[5]).strip()
        if not awing or not english or not category:
            continue

        total_literals += 1
        base = image_key(awing, english)
        # Session 60 fix: previously we appended __2, __3 for exact-duplicate
        # (awing, english) pairs in the source Dart. Those filenames were
        # NEVER read by the app (imageKey() returns only the base key) — they
        # were pure disk noise and the largest single cause of bloated runs
        # (11,829 wasted images out of 21,536). Skip duplicates entirely.
        if base in seen_base_keys:
            duplicates_skipped += 1
            continue
        seen_base_keys.add(base)

        vocabulary[base] = {
            "awing": awing,
            "english": english,
            "category": category,
        }

    if total_literals or commented_skipped or duplicates_skipped:
        msg = (f"Parsed {total_literals} active AwingWord literals -> "
               f"{len(vocabulary)} unique image keys")
        if commented_skipped:
            msg += f"  [skipped {commented_skipped} commented-out lines]"
        if duplicates_skipped:
            msg += f"  [skipped {duplicates_skipped} exact (awing,english) duplicates]"
        print(msg)
    return vocabulary


# Dart string body: single-quoted (allows \\') OR double-quoted (allows \\").
_DART_SQ = r"'((?:\\.|[^'\\])*)'"
_DART_DQ = r'"((?:\\.|[^"\\])*)"'
_DART_STR = rf"(?:{_DART_SQ}|{_DART_DQ})"


def _dart_unescape(s: str) -> str:
    return re.sub(r"\\(.)", r"\1", s)


def _pick(groups: tuple, idx: int) -> str:
    """Pick whichever of two adjacent (sq, dq) capture groups matched."""
    return _dart_unescape(groups[idx] if groups[idx] is not None else groups[idx + 1]).strip()


def _multi_word_key(prefix: str, awing: str) -> str:
    """Build namespaced key for phrase/sentence/story.

    Format: '{prefix}_{audio_key(awing)[:MULTI_WORD_KEY_MAX]}'
    The cap keeps Play Asset Pack filenames sane (max path length + reasonable
    filesystem hygiene) while remaining deterministic under reorderings —
    two sentences with the same first ~60 ASCII-normalized chars would
    collide, but that's vanishingly unlikely across our 70-item corpus.
    """
    k = audio_key(awing)
    if len(k) > MULTI_WORD_KEY_MAX:
        k = k[:MULTI_WORD_KEY_MAX]
    return f"{prefix}_{k}"


def parse_phrases() -> dict:
    """Parse AwingPhrase literals from awing_vocabulary.dart.

    Keys are prefixed 'phrase_' to avoid colliding with AwingWord image keys.
    Returns: {key: {awing, english, category}}. The 'category' slot uses the
    phrase's own category field (greeting/daily/question/classroom/farewell)
    so get_ai_prompt() can branch on it.
    """
    if not PHRASES_FILE.exists():
        return {}

    with open(PHRASES_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    # AwingPhrase(awing: '...', english: '...', ...category: '...'...)
    # The category field is optional. The trailing-comma requirement after
    # `english:` previously excluded 27 compact entries that have only
    # (awing, english) — most of them Bible-mined phrases added in
    # Session 57+. Accept either `,` (more fields follow) or the closing `)`
    # so both compact and full forms parse.
    pattern = (
        r"AwingPhrase\(\s*"
        r"awing:\s*" + _DART_STR + r"\s*,\s*"
        r"english:\s*" + _DART_STR + r"\s*[,)]"
        r"(?:[^)]*?category:\s*" + _DART_STR + r")?"
    )

    phrases: dict = {}
    total = 0
    for match in re.finditer(pattern, content, flags=re.DOTALL):
        g = match.groups()
        # groups: (awing_sq, awing_dq, english_sq, english_dq, category_sq?, category_dq?)
        awing = _pick(g, 0)
        english = _pick(g, 2)
        if not awing or not english:
            continue
        # Category may be missing from the regex match; default to "phrase".
        category = ""
        if len(g) >= 6 and (g[4] is not None or g[5] is not None):
            category = _pick(g, 4)
        total += 1
        key = _multi_word_key("phrase", awing)
        phrases[key] = {
            "awing": awing,
            "english": english,
            "category": "phrase",  # always route through phrase prompt
            "subcategory": category,  # greeting/daily/question/...
        }

    if total:
        print(f"Parsed {total} AwingPhrase literals -> {len(phrases)} unique phrase keys")
    return phrases


def parse_sentences() -> dict:
    """Parse AwingSentence literals from sentences_screen.dart.

    Keys are prefixed 'sentence_' to avoid colliding with any other image keys.
    AwingSentence schema: {awing: String, english: String, words: List<AwingWord>}.
    """
    if not SENTENCES_FILE.exists():
        return {}

    with open(SENTENCES_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    pattern = (
        r"AwingSentence\(\s*"
        r"awing:\s*" + _DART_STR + r"\s*,\s*"
        r"english:\s*" + _DART_STR
    )

    sentences: dict = {}
    total = 0
    for match in re.finditer(pattern, content, flags=re.DOTALL):
        g = match.groups()
        awing = _pick(g, 0)
        english = _pick(g, 2)
        if not awing or not english:
            continue
        total += 1
        key = _multi_word_key("sentence", awing)
        sentences[key] = {
            "awing": awing,
            "english": english,
            "category": "sentence",
        }

    if total:
        print(f"Parsed {total} AwingSentence literals -> {len(sentences)} unique sentence keys")
    return sentences


def parse_stories() -> dict:
    """Parse StorySentence literals from stories_screen.dart.

    Keys are prefixed 'story_' to avoid colliding with any other image keys.
    StorySentence schema: {awing: String, english: String}.
    """
    if not STORIES_FILE.exists():
        return {}

    with open(STORIES_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    pattern = (
        r"StorySentence\(\s*"
        r"awing:\s*" + _DART_STR + r"\s*,\s*"
        r"english:\s*" + _DART_STR
    )

    stories: dict = {}
    total = 0
    for match in re.finditer(pattern, content, flags=re.DOTALL):
        g = match.groups()
        awing = _pick(g, 0)
        english = _pick(g, 2)
        if not awing or not english:
            continue
        total += 1
        key = _multi_word_key("story", awing)
        stories[key] = {
            "awing": awing,
            "english": english,
            "category": "story",
        }

    if total:
        print(f"Parsed {total} StorySentence literals -> {len(stories)} unique story keys")
    return stories


def shorten_english_for_prompt(english_word: str) -> str:
    """Reduce a (possibly long) dictionary definition to a short noun/verb phrase
    suitable for SDXL/CLIP. CLIP truncates at 77 tokens, so feeding it a full
    definition like "ya. some children are very greedy such that you give
    something to a child and ask for it the same moment and he hardens the
    hand. v. s : ńtyantə" both wastes prompt budget AND drops the actual word.
    Goal: extract the first short concrete English gloss.
    """
    s = english_word.strip().lower()

    # 1. Strip parentheticals: "hand (body part)" -> "hand"
    s = re.sub(r"\s*\(.*?\)", "", s).strip()

    # 2. Drop everything after cross-reference markers or heavy punctuation.
    #    "foo; see bar" -> "foo". Include "v. s" / "n. s" as cross-ref cues
    #    (Awing dict uses them to point at a synonym in another entry).
    s = re.split(
        r"[;:]|\bsee\b|\bcf\b|\bsyn\b|\bant\b|\be\.?g\.?\b|\bi\.?e\.?\b|\bv\.\s*s\b|\bn\.\s*s\b",
        s, maxsplit=1)[0].strip()

    # 3. Drop leading part-of-speech tags (BEFORE splitting on period — the
    #    "n." in "n. house" is a POS abbreviation, not a sentence boundary).
    s = re.sub(r"^(?:n\.p|v\.p|n\.|v\.|adj\.|adv\.|pron\.|prep\.|conj\.|interj\.|num\.|ideo\.|c\.n)\s+",
               "", s).strip()

    # 4. Drop leading interjection-style prefix like "ya.", "oh,", "well,".
    #    Must come BEFORE sentence-boundary split so "ya. children are greedy"
    #    becomes "children are greedy" not "ya".
    s = re.sub(r"^(?:ya|oh|well|hey|ah|er|um|hmm)[,.\s]+", "", s).strip()

    # 5. Split on sentence boundary — keep first sentence only, to drop long
    #    example clauses. BUT: if the first sentence is 2 words or fewer, it's
    #    probably a headword repetition like "house." and we want the rest.
    parts = re.split(r"\.\s+", s, maxsplit=1)
    if len(parts) == 2 and len(parts[0].split()) <= 2 and len(parts[1].strip()) >= 3:
        s = parts[1]
    else:
        s = parts[0]
    s = s.rstrip(".").strip()

    # 6. Strip leading POS again in case it was embedded: "v. walk quickly"
    #    after cross-ref split becomes "v. walk quickly".
    s = re.sub(r"^(?:n\.p|v\.p|n\.|v\.|adj\.|adv\.|pron\.|prep\.|conj\.|interj\.|num\.|ideo\.|c\.n)\s+",
               "", s).strip()

    # 7. Numbered glosses: "1) abdomen 2) buttock" -> "abdomen"
    m = re.match(r"^\s*\d+\)\s*([^0-9)]+?)(?:\s*\d+\)|$)", s)
    if m:
        s = m.group(1).strip()

    # 8. Comma-separated synonym lists: "go, went" -> "go",
    #    "cane, walking stick" -> "cane", "food, drinks given to" -> "food".
    #
    #    The Awing dictionary glosses many entries as alternatives rather than
    #    a single word, and SDXL draws the whole string literally: "a cartoon
    #    cane, walking stick" is two subjects competing for one image. Keeping
    #    only the head also raises the PROMPT_OVERRIDES hit rate, because the
    #    overrides are keyed on single headwords ("baby, child" misses, "baby"
    #    hits a curated prompt).
    #
    #    Guarded: only when the head is 1-4 words, so a real clause whose
    #    first comma falls early ("in the morning, before dawn" -> fine) is
    #    kept but a one-token head of a longer description is not discarded
    #    into meaninglessness.
    if "," in s:
        head = s.split(",", 1)[0].strip()
        if 1 <= len(head.split()) <= 4:
            s = head

    # 9. Collapse whitespace, cap at first 6 words. CLIP token budget after
    #    the STYLE_SUFFIX is ~30 tokens; 6 short English words fits comfortably.
    s = re.sub(r"\s+", " ", s).strip(",.;: ")
    words = s.split()
    if len(words) > 6:
        s = " ".join(words[:6])

    # 10. Trim a trailing function word. Step 9 cuts at a word count, not at
    #     a phrase boundary, so 256 glosses arrived at SDXL ending mid-phrase:
    #       "a sort of white substance from"
    #       "school children's game played with a"
    #       "men dance group led by an"
    #       "third day of the week and"
    #     A dangling preposition is not just untidy - it is a prompt asking
    #     for a relationship whose object was cut off, and the model fills
    #     the gap with whatever it likes. Trimming back to the last content
    #     word asks for less and gets it right more often.
    #
    #     Trim is skipped if it would empty the gloss; a gloss that is ALL
    #     function words is caught by is_illustratable() and drawn blank.
    trimmed = list(words if len(words) <= 6 else words[:6])
    while trimmed and trimmed[-1].strip(",.;:'\"").lower() in _FUNCTION_WORDS:
        trimmed.pop()
    if trimmed:
        s = " ".join(trimmed)

    return s or english_word.strip().lower()


# --------------------------------------------------------------------------
# THE PICTURE GETS THE WHOLE MEANING, NOT THE HEADWORD
# --------------------------------------------------------------------------
# Dr. Sama: "if you already know what a word is in english why will you
# generate a picture without the things in it?"
#
# He is right, and shorten_english_for_prompt() was the reason. It exists to
# distil a gloss down to a single headword so that PROMPT_OVERRIDES can be
# looked up by headword - 1,108 overrides are keyed that way. That is correct
# for the LOOKUP and wrong for the PICTURE, because the thing it throws away
# is the only concrete part of the entry:
#
#   "crunch eg soft bone; a dog crunching a bone"  ->  "crunch"
#   "a piece of rough iron used for making knives" ->  "a piece of rough
#                                                       iron used"
#
# "crunch" is not a picture of anything. "a dog crunching a bone" is, and the
# dictionary already wrote it down. "a piece of rough iron used" asks for a
# relationship whose object was cut off, and the model fills the gap itself.
#
# So the two jobs are now split: shorten_english_for_prompt() still feeds the
# override lookup unchanged, and this feeds the prompt body.
_EXAMPLE_SPLIT = re.compile(
    r"\b(?:e\.?\s?g\.?|for example|such as)\b[.,:;]?\s*", re.I)

_DETERMINER_RE = re.compile(
    r"^(?:a|an|the|some|one|two|three|four|five|his|her|their|its|"
    r"this|that|these|those)\b", re.I)

_XREF_SPLIT = re.compile(
    r"\bv\.\s*s\b|\bn\.\s*s\b|\bsee\b|\bcf\b|\bsyn\b|\bant\b", re.I)

_POS_PREFIX = re.compile(
    r"^(?:n\.p|v\.p|n\.|v\.|adj\.|adv\.|pron\.|prep\.|conj\.|"
    r"interj\.|num\.|ideo\.|c\.n)\s+", re.I)

_INTERJ_PREFIX = re.compile(r"^(?:ya|oh|well|hey|ah|er|um|hmm)[,.\s]+", re.I)

_GRAMMAR_PAREN = re.compile(
    r"\s*\(\s*(?:intr|tr|intrans|trans|intransitive|transitive|n|v|adj|adv|"
    r"pron|prep|conj|interj|num|pl|sg|sing|plural|singular|sth|sb|"
    r"someone|something|lit|fig|idiom|idiomatic|arch|obs|dial|"
    r"nominal|verbal|stative|causative|reciprocal|reflexive)\s*\.?\s*\)",
    re.I)

# "cloth, piece of" -> "piece of cloth". The quantifier is part of the
# picture, so it is put back in front.
_INVERTED_GLOSS = re.compile(
    r"^(.+?),\s*(?:a|an)?\s*(piece|part|pair|group|bunch|heap|bundle|"
    r"handful|drop|grain)\s+of$", re.I)

# "disease, sort of" -> "disease". "sort of" / "manner of" / "kind of" is a
# lexicographer's hedge, not something that can appear in a drawing, and as
# the leading tokens of the prompt it was stealing weight from the only word
# that could be drawn.
# A comma tail that QUALIFIES the head rather than restating it.
_QUALIFIER_TAIL = re.compile(
    r"^(?:for|of|in|on|at|with|without|from|to|by|as|like|used|using|"
    r"made|worn|kept|found|grown|eaten|done|that|which|who|whose|when|"
    r"where|especially|usually|normally|generally|often|only|mostly|"
    r"the|a|an)\b", re.I)

_LEADING_HEDGE = re.compile(
    r"^(?:a|an|the)?\s*(?:sort|kind|type|manner|way)\s+of\s+", re.I)

_HEDGE_INVERTED = re.compile(
    r"^(.+?),\s*(?:a|an)?\s*(?:kind|sort|type|manner|way|habit|method|"
    r"state|act|sign)\s+of$", re.I)


def _content_tokens(phrase: str):
    toks = [t.strip(",.;:'\"") for t in phrase.split()]
    return [t for t in toks if t and t.lower() not in _FUNCTION_WORDS]


def _trim_to_phrase(s: str, max_words: int) -> str:
    """Cut to at most `max_words`, never ending on a function word.

    Step 9 of shorten_english_for_prompt() cut at a word count, which is how
    256 glosses reached SDXL as "a sort of white substance from". Same idea
    here, applied to a longer budget.
    """
    words = s.split()
    if len(words) <= max_words:
        return s
    kept = words[:max_words]
    while kept and kept[-1].strip(",.;:'\"\u2018\u2019").lower() in _FUNCTION_WORDS:
        kept.pop()
    return " ".join(kept) if kept else " ".join(words[:max_words])


# --------------------------------------------------------------------------
# TYPOS IN THE GLOSS, CORRECTED FOR THE PROMPT ONLY
# --------------------------------------------------------------------------
# Dr. Sama, on the sample: "such and many others should be fixs before we
# can analyze and push and generate all."
#
# One whole class of those is a misspelled gloss. `nafena` is glossed
# "inhygenic environment"; SDXL does not know "inhygenic", so it dropped
# the prefix it could not parse and drew a CLEAN river - the exact opposite
# of the entry, and nothing in the prompt mechanism can catch that.
#
# A spellcheck over all 8,605 glosses found 242 unrecognised forms. Most are
# not errors: British spellings (honour, behaviour, baptise), Awing and
# Cameroonian words (fon, achu, egusi, njangi), proper names (Njom,
# Mbachia), and dictionary abbreviations (esp, prn, colloq). The list below
# is only the ones where the intended English word is not in doubt.
#
# These are applied to the PROMPT, not to the card. The gloss on screen is
# still what the dictionary says - changing that is a lexicon edit and
# Dr. Sama's call. Full list of suspects, including the ones I was not sure
# enough about to include here, is in
# contributions/gloss_spelling_suspects.json.
_GLOSS_TYPOS = {
    "matchetes": "machetes", "matchete": "machete",
    "mbecile": "imbecile", "controling": "controlling",
    "matress": "mattress", "sinagogue": "synagogue",
    "scabbies": "scabies", "unhygenic": "unhygienic",
    "inhygenic": "unhygienic", "exzema": "eczema",
    "motar": "mortar", "distruction": "destruction",
    "ampit": "armpit", "refered": "referred",
    "refering": "referring", "commiting": "committing",
    "overful": "overfull", "colanuts": "kolanuts",
    "delapidation": "dilapidation", "millett": "millet",
    "dieing": "dying", "ressurrection": "resurrection",
    "earings": "earrings", "digusting": "disgusting",
    "adultry": "adultery", "continously": "continuously",
    "continous": "continuous", "someting": "something",
    "sometning": "something", "alchoholic": "alcoholic",
    "ressemble": "resemble", "adress": "address",
    "aproximately": "approximately", "commplement": "complement",
    "menstration": "menstruation", "ocassion": "occasion",
    "mushoom": "mushroom", "phleme": "phlegm",
    "shuve": "shove", "symtom": "symptom",
    "beewax": "beeswax", "embelishment": "embellishment",
    "influencial": "influential", "descriminating": "discriminating",
    "gabbage": "garbage", "immitation": "imitation",
    "deliever": "deliver", "catabash": "calabash",
    "savana": "savanna", "demishing": "diminishing",
    "deminishing": "diminishing", "scritching": "scratching",
    "scritch": "scratch", "achache": "ache",
    "exageration": "exaggeration", "decieve": "deceive",
    "annoint": "anoint", "stupify": "stupefy",
    "potatoe": "potato", "unfertile": "infertile",
    "infront": "in front", "lier": "liar",
    "hardwork": "hard work", "alot": "a lot",
    "diagnos": "diagnose", "grinded": "ground",
    "unhealing": "non-healing", "strongness": "strength",
    "beforeuse": "before use", "headpad": "head pad",
    "childrens": "children's", "somebodys": "somebody's",
    "ladt": "lady", "ston": "stone", "anothern": "another",
}

_TYPO_RE = re.compile(
    r"\b(" + "|".join(sorted(_GLOSS_TYPOS, key=len, reverse=True)) + r")\b", re.I)


def fix_gloss_typos(text: str) -> str:
    """Correct known misspellings before the gloss becomes a prompt."""
    return _TYPO_RE.sub(lambda m: _GLOSS_TYPOS[m.group(1).lower()], text)


def concrete_gloss_for_prompt(english_word: str, max_words: int = 12) -> str:
    """The most DRAWABLE rendering of an English gloss.

    Picks the clause of the entry that names actual things, keeps the
    parenthetical disambiguator, and cuts at a phrase boundary rather than a
    word count. 12 words is ~16 CLIP tokens; with the template and
    STYLE_SUFFIX_OBJECT the prompt lands near 35 of the 77 available.
    """
    raw = fix_gloss_typos((english_word or "").strip().lower())
    if not raw:
        return ""
    _SYNONYM_HEADS = set()

    raw = _POS_PREFIX.sub("", raw).strip()
    raw = _INTERJ_PREFIX.sub("", raw).strip()
    # Dictionary shorthand. "wake sb from sleep" asks SDXL to draw an "sb".
    raw = re.sub(r"\bsb\b", "somebody", raw)
    raw = re.sub(r"\bsth\b", "something", raw)
    raw = re.sub(r"\bs\.?o\.?\b", "somebody", raw)
    # A cross-reference points at another entry; it does not describe this one.
    raw = _XREF_SPLIT.split(raw, maxsplit=1)[0].strip()
    # Keep what is inside the parentheses - in this dictionary it is almost
    # always the disambiguator ("hump (on the back)", "plant (cocoyams)").
    # EXCEPT when it is a grammar tag: "break in little pieces (intr)" was
    # reaching SDXL as "breaking in little pieces intr".
    raw = _GRAMMAR_PAREN.sub(" ", raw)
    raw = re.sub(r"\s*\(([^)]*)\)", r" \1", raw)
    raw = re.sub(r"\s+", " ", raw).strip()

    # Candidate clauses: every semicolon / sentence clause, and each side of
    # an "eg" marker.
    clauses = []
    for chunk in re.split(r"[;.]\s*", raw):
        chunk = chunk.strip().strip(",;:. ")
        if not chunk:
            continue
        for part in _EXAMPLE_SPLIT.split(chunk):
            part = part.strip().strip(",;:. ")
            if part:
                clauses.append(part)
                # Many entries gloss a word as two alternatives: "take good
                # care of, show love and concern". Drawn literally that is
                # two pictures competing for one card, so the first clause
                # is offered as a candidate too - but only when it stands on
                # its own (2+ content words). "gizzard, considered to
                # belong to elders" has a one-word head and keeps its
                # qualifier.
                if "," in part:
                    head, rest = (x.strip() for x in part.split(",", 1))
                    # ONLY when the remainder is an ALTERNATIVE gloss. When
                    # it is a qualifier the distinction IS the entry, and
                    # dropping it collapsed 14 different trees onto one
                    # picture:
                    #   "tree, for boundaries"  -> "tree"
                    #   "tree, of colanuts"     -> "tree"
                    #   "clean a little, using a hoe" -> "clean a little"
                    # A qualifier announces itself with a preposition or a
                    # relative word; an alternative gloss starts with its
                    # own noun or verb.
                    if (len(_content_tokens(head)) >= 2
                            and not _QUALIFIER_TAIL.match(rest)):
                        _SYNONYM_HEADS.add(head)
                        clauses.append(head)
    if not clauses:
        clauses = [raw]

    def _score(phrase: str):
        n = len(_content_tokens(phrase))
        bonus = 0
        # Its own subject ("a dog ...") beats a bare verb ("crunch").
        if _DETERMINER_RE.match(phrase):
            bonus += 2
        # A participle means something is happening in it.
        if re.search(r"\b\w{3,}ing\b", phrase):
            bonus += 1
        if phrase in _SYNONYM_HEADS:
            bonus += 3
        # Prefer a clause that fits the budget over one that must be cut,
        # then the SHORTER of two equally concrete clauses - fewer competing
        # nouns is a cleaner picture.
        return (n + bonus,
                -max(0, len(phrase.split()) - max_words),
                -len(phrase.split()))

    best = max(clauses, key=_score)
    best = _trim_to_phrase(best.strip(",.;:'\" "), max_words)

    # This dictionary inverts a lot of glosses so the headword files first:
    #   "cloth, piece of"      "disease, sort of"      "chewing, manner of"
    # Read straight through, those end on a dangling "of" - a prompt asking
    # for a relationship whose object is missing. Turn them back round.
    # "a sort of white substance from the eye" -> "white substance from the
    # eye". Same hedge as _HEDGE_INVERTED, written the normal way round.
    best = _LEADING_HEDGE.sub("", best).strip()

    m = _INVERTED_GLOSS.match(best)
    if m:
        best = f"{m.group(2)} of {m.group(1)}".strip()
    else:
        m = _HEDGE_INVERTED.match(best)
        if m:
            best = m.group(1).strip()

    # Trim trailing function words UNCONDITIONALLY. The same trim in
    # shorten_english_for_prompt() only runs when the gloss exceeded the word
    # cap, so "care for", "direction of" and "deaf in" went to SDXL with the
    # preposition still dangling.
    toks = best.split()
    while toks and toks[-1].strip(",.;:'\"").lower() in _FUNCTION_WORDS:
        toks.pop()
    best = " ".join(toks).strip(",.;:'\" ")

    # After that trim a stranded one-word tail is left over:
    #   "association, start an" -> "association, start" -> "association"
    best = re.sub(r",\s*\S+$", "", best) if re.search(r",\s*\S+$", best) and \
        len(best.split(",")[-1].split()) == 1 else best
    best = best.replace("~", " ")
    best = re.sub(r"\s+", " ", best).strip(",.;:'\" ")

    # All function words -> nothing was gained; fall back to the headword so
    # behaviour never gets WORSE than before this function existed.
    if not _content_tokens(best):
        return shorten_english_for_prompt(english_word)
    return best


_IRREGULAR_ING = {
    "be": "being", "have": "having", "go": "going", "do": "doing",
    "lie": "lying", "die": "dying", "tie": "tying", "see": "seeing",
    "run": "running", "sit": "sitting", "put": "putting", "cut": "cutting",
    "get": "getting", "set": "setting", "let": "letting", "shut": "shutting",
    "swim": "swimming", "begin": "beginning", "win": "winning",
    "dig": "digging", "hit": "hitting", "forget": "forgetting",
    "prefer": "preferring", "occur": "occurring", "travel": "travelling",
}


def _as_gerund(phrase: str) -> str:
    """"crunch" -> "crunching".

    "a Cameroonian boy ... doing crunch" was the old actions template. It is
    not English, and a prompt the model cannot parse is a prompt it ignores
    in favour of the 20 tokens of persona in front of it.
    """
    toks = phrase.split()
    if not toks:
        return phrase
    v = toks[0].lower().strip(",.;:")
    if v.endswith("ing"):
        return phrase
    if v in _IRREGULAR_ING:
        g = _IRREGULAR_ING[v]
    elif v.endswith("ie"):
        g = v[:-2] + "ying"
    elif v.endswith("e") and not v.endswith(("ee", "ye", "oe")):
        g = v[:-1] + "ing"
    elif len(v) <= 4 and re.search(r"[^aeiou][aeiou][bcdfgklmnprstvz]$", v):
        g = v + v[-1] + "ing"          # CVC doubling: stop -> stopping
    else:
        g = v + "ing"
    return " ".join([g] + toks[1:])


# An uncountable noun takes no article. "an emptiness" and "a hunger" are
# not English, and a prompt the model has to repair is a prompt it rewrites.
_MASS_SUFFIX = re.compile(
    r"(?:ness|ity|hood|ship|ism|ance|ence|ment|dom|tude|ery)$", re.I)

_MASS_NOUNS = {
    "water", "dust", "sand", "salt", "sugar", "rice", "maize", "corn",
    "oil", "milk", "blood", "smoke", "mud", "rain", "wind", "fire", "food",
    "meat", "wood", "grass", "hair", "money", "work", "music", "sleep",
    "death", "life", "love", "hunger", "thirst", "fear", "joy", "peace",
    "dirt", "soil", "ash", "flour", "honey", "soup", "beer", "wine", "air",
    "light", "time", "truth", "noise", "advice", "news", "weather",
    "vomit", "saliva", "sweat", "urine", "dung", "smoke", "steam",
    # Materials - mass in the sense the dictionary uses them.
    "iron", "metal", "clay", "cotton", "leather", "rubber", "bamboo",
    "charcoal", "firewood", "palm", "raffia",
}

_ORDINAL_RE = re.compile(
    r"^(?:first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|"
    r"tenth|last|next|\d+(?:st|nd|rd|th))\b", re.I)


# A gloss that opens with a bare verb is not a noun phrase, and "a have
# sexual relations with" is what prepending an article to one looks like.
_VERB_HEADS = {
    "have", "has", "had", "make", "makes", "take", "takes", "give", "gives",
    "go", "goes", "come", "comes", "get", "gets", "put", "puts", "let",
    "do", "does", "be", "been", "help", "care", "look", "see", "hear",
    "feel", "keep", "hold", "bring", "send", "find", "leave", "move",
    "turn", "start", "stop", "open", "close", "carry", "throw", "catch",
    "cut", "break", "build", "buy", "sell", "pay", "eat", "drink", "sleep",
    "walk", "run", "sit", "stand", "speak", "talk", "say", "tell", "ask",
    "answer", "work", "play", "wash", "clean", "cook", "plant", "harvest",
    "abstain", "avoid", "refuse", "accept", "allow", "cause", "become",
    "belong", "remain", "stay", "wait", "try", "want", "need", "like",
    "love", "hate", "know", "think", "believe", "remember", "forget",
    "beat", "push", "pull", "lift", "drop", "pour", "fill", "empty",
    "tie", "untie", "wear", "remove", "hide", "show", "point", "touch",
    "scrub", "rub", "dash", "peel", "scratch", "imply", "mean", "means",
    "squeeze", "stir", "pound", "grind", "sweep", "scrape", "bend",
}

# Session 66v. The list above was a hand-written whitelist, so _is_verbish()
# answered False for "shave", "borrow", "curse", "clear" - for almost every
# verb in the dictionary - and the last-resort person injection in
# get_ai_prompt() never fired. Those glosses went to SDXL as "a shave",
# naming no subject at all, and the model invented one: the white man with
# the razor, the office of white workers for "from". That was the engine
# behind every white card, not the negative prompt and not the guidance.
#
# Why it was not caught by the category: 5,392 of 8,227 rows carry
# category "things" because that is what the dictionary import defaulted to.
# "shave" is things. "she" is things. The category cannot be trusted to say
# whether a gloss is an action, so the gloss head has to.
#
# UNAMBIGUOUS VERBS ONLY. A lemma that is also a common concrete noun
# ("work", "trap", "dress", "fight", "cross", "curse", "trip") is left out:
# routing one of those to the person path would put a person on a card whose
# subject is an object, which is the mistake the retired _SKIN_CLAUSE made.
# A verb-only lemma cannot be an object, so this direction is safe.
_VERB_HEADS |= {
    "abandon", "abstain", "accompany", "accumulate", "admire", "admit",
    "admonish", "alter", "announce", "apply", "approach", "attack", "bake",
    "baptise", "bathe", "befit", "beg", "begin", "behave", "belch",
    "bellow", "bewail", "bewitch", "blacken", "blame", "blaspheme",
    "bleed", "bless", "blink", "blow", "borrow", "brag", "burst", "cancel",
    "capsize", "caress", "castrate", "celebrate", "change", "chat", "chew",
    "choke", "choose", "claim", "clap", "climb", "clot", "collect",
    "complain", "conceive", "condemn", "confess", "congratulate",
    "connect", "console", "consult", "contaminate", "continue",
    "contradict", "convert", "cooperate", "correct", "cough", "crawl",
    "create", "criticise", "crunch", "crush", "cry", "cultivate", "dance",
    "daub", "deceive", "decide", "decorate", "decrease", "dedicate",
    "defeat", "defecate", "defend", "degrade", "delay", "deliver",
    "demand", "demonstrate", "depend", "describe", "despise", "destroy",
    "develop", "die", "disappear", "disperse", "distress", "disturb",
    "divide", "divorce", "domesticate", "drag", "draw", "dream", "drip",
    "drive", "drizzle", "drown", "dry", "embrace", "entertain", "escape",
    "escort", "evaporate", "exaggerate", "exchange", "exile", "exorcise",
    "expel", "explain", "explode", "expose", "express", "extinguish",
    "fade", "fail", "faint", "fall", "fasten", "feed", "fetch", "finalise",
    "flash", "float", "flow", "fold", "follow", "forge", "forgive",
    "frown", "fry", "fulfill", "fumble", "gather", "generate", "germinate",
    "gird", "glue", "grasp", "grow", "grunt", "gush", "hang", "harden",
    "hasten", "heal", "hit", "hope", "hunt", "hurt", "imagine", "imitate",
    "immerse", "imprison", "increase", "incubate", "inhabit", "inherit",
    "initiate", "inquire", "insist", "insult", "intend", "invite", "join",
    "judge", "jump", "justify", "kill", "kiss", "knock", "lack", "laugh",
    "launder", "lay", "lead", "leak", "leap", "learn", "lend", "lengthen",
    "lick", "link", "listen", "live", "lock", "lose", "lurk", "marry",
    "measure", "meet", "melt", "mix", "moan", "mold", "moor", "mourn",
    "mumble", "murder", "nip", "notice", "obey", "obstruct", "offer",
    "order", "overflow", "overtake", "paddle", "pass", "peck", "perch",
    "perspire", "pick", "pierce", "pile", "pity", "plaster", "plunder",
    "polish", "pray", "prepare", "press", "pretend", "prosper", "protect",
    "protrude", "provoke", "puff", "punish", "purge", "quarrel", "quench",
    "raise", "rap", "rape", "read", "receive", "recover", "redeem",
    "reduce", "rejoice", "rescue", "resemble", "resist", "respect", "rest",
    "return", "reward", "ripen", "rise", "roast", "rob", "ruminate",
    "sacrifice", "save", "scare", "scoop", "scramble", "scream", "screech",
    "scrutinise", "search", "settle", "sew", "shake", "share", "sharpen",
    "shave", "shiver", "shoot", "shorten", "shout", "shut", "sift", "sigh",
    "sin", "sing", "skip", "slander", "slash", "slice", "smash", "smear",
    "smell", "smile", "sneeze", "soar", "soften", "solidify", "spit",
    "spoil", "sprinkle", "sprout", "spy", "squat", "stab", "stagger",
    "stamp", "startle", "steer", "step", "stoop", "stretch", "stumble",
    "stutter", "succeed", "suckle", "support", "surround", "survive",
    "swear", "swim", "tame", "taste", "teach", "tear", "tempt", "thank",
    "threaten", "thresh", "throb", "translate", "transplant", "travel",
    "traverse", "treat", "tremble", "trickle", "twist", "twitch",
    "ululate", "unearth", "unload", "urinate", "verify", "visit", "vomit",
    "wag", "wail", "wave", "weave", "whistle", "whitewash", "wink",
    "winnow", "wipe", "wither", "wonder", "worry", "worship", "wrap",
    "wring", "yawn", "yell",
}


def _as_noun_phrase(phrase: str) -> str:
    """Grammatical noun phrase - an article only when there is not one.

    "a cartoon a piece of rough iron used" came from unconditionally
    prepending "a cartoon" to a phrase that already had its determiner.
    """
    p = phrase.strip()
    if not p or _DETERMINER_RE.match(p):
        return p
    if _ORDINAL_RE.match(p):
        return f"the {p}"               # "third day of the week"
    first = p.split()[0].lower().strip(",.;:")
    if first.endswith("ing") or first in _VERB_HEADS:
        return p
    # "scrub out", "throw away", "cut off" - a verb plus its particle, not a
    # noun phrase.
    toks = p.split()
    if (len(toks) >= 2
            and toks[-1].lower() in {"out", "up", "off", "away",
                                     "down", "over", "apart", "back"}):
        return p
    # An adverb is not a noun: "a quickly", "a scrub accidentally".
    if toks[0].lower().endswith("ly") or toks[-1].lower().endswith("ly"):
        return p
    # A participle is not a noun: "a trapped in evil".
    if len(first) >= 5 and first.endswith(("ed", "en")):
        return p
    # Past 3 words the article buys nothing and the risk of fronting a verb
    # ("a scrub, rub or dash, usually accidentally, causing ...") is real.
    if len(toks) > 3:
        return p
    if first.endswith("s") and not first.endswith(("ss", "us", "is")):
        return p                        # plural takes no article
    # Only for a bare noun: "dust" stays "dust", but "dust cloud" is
    # countable and still wants "a".
    if len(p.split()) == 1 and (first in _MASS_NOUNS
                                or _MASS_SUFFIX.search(first)):
        return p
    return f"{'an' if p[0] in 'aeiou' else 'a'} {p}"


_PARTICLES = {"out", "up", "off", "away", "down", "over", "apart", "back",
              "together", "through", "across", "along"}


def _is_verbish(phrase: str) -> bool:
    """Is this gloss an action rather than a quality or a thing?"""
    toks = phrase.split()
    if not toks:
        return False
    first = toks[0].lower().strip(",.;:")
    if first.endswith("ing") or first in _VERB_HEADS:
        return True
    return len(toks) >= 2 and toks[-1].lower().strip(",.;:") in _PARTICLES


def _is_abstract_noun(phrase: str) -> bool:
    """"friendship", "hunger" - a noun, not an adjective."""
    w = phrase.split()[0].lower().strip(",.;:") if phrase.split() else ""
    return bool(w) and (w in _MASS_NOUNS or bool(_MASS_SUFFIX.search(w)))


def _focus_phrase(phrase: str, max_words: int = 5) -> str:
    """The head noun phrase of the English meaning, for the presence clause.

    Dr. Sama: "simply use the english meaning and ensure the object is in the
    picture." Naming the subject once at the front is not enough - SDXL
    drops it when the rest of the prompt is longer, which is how "a piece of
    rough iron used for making knives" came back as a workshop with no iron
    in it. Saying it again, at the end, as a requirement, is the one lever
    that works at 4 steps.
    """
    toks = []
    for t in phrase.split():
        c = t.strip(",.;:'\"")
        if not c:
            continue
        if not toks and c.lower() in _FUNCTION_WORDS:
            continue                    # skip a leading article
        toks.append(c)
        if len(toks) >= max_words:
            break
    while toks and toks[-1].lower() in _FUNCTION_WORDS:
        toks.pop()
    return " ".join(toks)


def _has_own_subject(phrase: str) -> bool:
    """Does the gloss already say who or what is doing it?"""
    if _DETERMINER_RE.match(phrase.strip()):
        return True
    return bool(_HUMAN_NOUN_RE.search(phrase))


# Tokens that do not change what is being depicted, so the head word's
# override still describes the whole gloss.
_PROMPT_STOPWORDS = {
    "a", "an", "the", "of", "to", "with", "in", "on", "at", "for", "and",
    "or", "it", "its", "his", "her", "their", "them", "him", "someone",
    "somebody", "something", "one", "s",
}

_PROMPT_MODIFIERS = {
    "hastily", "quickly", "slowly", "away", "down", "up", "out", "off",
    "over", "again", "well", "badly", "together", "apart", "around",
    "hard", "softly", "loudly", "quietly", "carefully", "suddenly",
    "repeatedly", "continuously", "first", "last", "much", "little",
}


def _safe_first_word(clean_word: str):
    """First token of `clean_word`, but only when the rest adds no meaning.

    Returns None when a trailing token is a content word, so the caller falls
    through to a literal prompt instead of an override that describes a
    different thing. See the comment at the call site.
    """
    toks = clean_word.split()
    if len(toks) < 2:
        return None
    for t in toks[1:]:
        t = t.strip(",.;:'\"")
        if not t:
            continue
        # Any -ly adverb is manner, not subject. "announce publicly" was
        # failing this test and falling through to a literal prompt, which
        # drew a crowd of pale cartoon figures instead of using the written
        # "announce" scene. _PROMPT_MODIFIERS lists adverbs one at a time;
        # the suffix covers the ones nobody thought to add.
        if (t not in _PROMPT_STOPWORDS and t not in _PROMPT_MODIFIERS
                and not (len(t) > 4 and t.endswith("ly"))):
            return None
    return toks[0]


# --------------------------------------------------------------------------
# WHICH WORDS GET AN IMAGE AT ALL
# --------------------------------------------------------------------------
# Dr. Sama, on the first sample: "ensure the pictures match the words".
# Some entries CANNOT be matched. "at (preposition - point in time)", "from",
# "the personal pronoun 'he'" - there is no picture of "from". The generator
# drew them anyway, so the app showed a child standing in a field captioned
# "a__from", which teaches nothing and looks like a mistake.
#
# This mirrors the decision already taken for audio: a word with no native
# recording is left SILENT rather than given a synthetic voice. A word with
# no depictable meaning is left with no image rather than a decorative one.
# The app already handles a missing image - hasImageSync() filters such words
# out of games and quizzes, and PackImage falls back - so a gap is safe.
# v1.24.5 — images a native speaker submitted and Dr. Sama approved are
# off limits to this script. apply_contributions.py records each key in
# contributions/contributed_images.json when it installs the photo.
#
# Without this the pipeline quietly undoes itself: the generator writes
# `{key}.webp`, _save_image() deletes the other format at the same stem,
# and the contributed `{key}.png` is gone. Nothing errors, nothing logs,
# the card just goes back to the AI picture on the next build.
CONTRIBUTED_IMAGES_FILE = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    'contributions', 'contributed_images.json')


def _contributed_keys():
    """Image keys installed from an approved contribution. Never touched."""
    try:
        if not os.path.exists(CONTRIBUTED_IMAGES_FILE):
            return set()
        import json as _json
        with open(CONTRIBUTED_IMAGES_FILE, 'r', encoding='utf-8') as f:
            return {e.get('key') for e in _json.load(f) if e.get('key')}
    except Exception as exc:
        # Fail CLOSED: if the list cannot be read, protect nothing is the
        # wrong answer — but so is crashing the build. Warn loudly and
        # protect nothing, because a stale protection set would be worse.
        print(f"  ! could not read {CONTRIBUTED_IMAGES_FILE}: {exc}")
        return set()


# No picture at all. The first list was sexual acts; Dr. Sama then found a
# NAKED card, which came from "be naked" - an ordinary dictionary entry that
# SDXL renders literally. A 4-step model given "naked", "undress", "breast"
# or "buttock" draws exactly that, and a negative prompt is a preference,
# not a guarantee. For a children's vocabulary card the only safe answer is
# no image: hasImageSync() filters the word out of games and quizzes, so
# the word still exists, still has its audio, and simply shows no picture.
#
# Innocuous-but-risky words - swim, bathe, navel, waist - are NOT here.
# They get a clothed, explicit override below instead, so the card survives.
_ADULT_ENTRY = re.compile(
    r"\b(prostitut\w*|adultery|pudenda|sexual\w*|penis|vagina|genital\w*|"
    r"brothel|fornicat\w*|copulat\w*|incest\w*|rape|have sex|"
    r"naked|nakedness|nude|nudity|undress|strip off|"
    r"breast|breasts|nipple|buttock|buttocks|"
    r"circumcis\w*|menstruat\w*|menstrat\w*|mestruat\w*|virgin|womb|puberty|"
    r"private part\w*|groin|loin|"
    # Session 66v: four more that slipped through. "close-up of the
    # clitoris of a Cameroonian young boy" is what the `body` category
    # path would otherwise have built.
    # Found by looking at the rendered pack, not by reading glosses:
    # "lust (n), strong desire" came back as a white woman in a bikini.
    r"clitoris|testicle\w*|scrotum|semen|sperm|concubine|anus|lust|lustful|seduc\w*|erotic\w*|contracted through sex)\b", re.I)

_UNILLUSTRATABLE_MARKERS = re.compile(
    r"\b(preposition|pronoun|conjunction|interjection|particle|auxiliary|"
    r"determiner|demonstrative|article|ideophone|intensifier|"
    r"grammatical|morpheme|affix|prefix|suffix|clitic|"
    r"noun class|class marker|concord|agreement marker|tense marker|"
    r"plural marker|negation marker|negative marker|question marker|"
    r"variant of|variant spelling|alternative form|short form of|"
    r"same as|see entry|cross[- ]reference)\b",
    re.I,
)

# An entry whose gloss is "verb stem of chaakə̌" is a morphological
# cross-reference with no English content at all. 21 of them were being
# drawn as a cartoon of the literal string.
_STEM_ENTRY = re.compile(r"\b(verb|verbal|noun|nominal|adjective)\s+stem\b", re.I)

# Dr. Sama's dictionary records named local institutions - "Women dance
# group based in Tame Tangwing's compound", "name of a quarter in Awing".
# These name one specific group or place in Awing, several of them defunct.
# No generic cartoon is a picture of them, and a generic one is exactly the
# "that is not an Awing thing" complaint from the NACDA DMV review. 19
# entries; they get no image rather than a wrong one.
_NAMED_INSTITUTION = re.compile(
    r"'s\s+compound|\bbased in\b|\bname of a quarter\b", re.I)

# Awing orthography surviving into the SHORTENED gloss means the English
# field holds Awing text, not English - a sentence left untranslated, or an
# entry glossed only by another Awing word. Tested AFTER shortening on
# purpose: "neck (synonym of ndě)" shortens to "neck", which is perfectly
# drawable, and testing the raw gloss would have thrown it away.
_NON_ASCII = re.compile(r"[^\x00-\x7f]")

# Bare function words: nothing to draw even without a marker word in the
# gloss. Kept explicit rather than inferred - a short gloss is not by itself
# a reason to skip ("yam", "hoe", "sun" are all short and all drawable).
_FUNCTION_WORDS = {
    "a", "an", "the", "at", "from", "to", "of", "in", "on", "by", "for",
    "with", "into", "onto", "upon", "about", "above", "below", "under",
    "over", "and", "but", "or", "nor", "so", "if", "then", "than", "that",
    "this", "these", "those", "as", "because", "while", "when", "where",
    "who", "whom", "whose", "what", "which", "why", "how",
    "he", "she", "it", "they", "we", "you", "i", "me", "him", "her", "us",
    "them", "his", "hers", "its", "their", "theirs", "our", "ours", "my",
    "mine", "your", "yours", "myself", "himself", "herself", "itself",
    "is", "are", "was", "were", "be", "been", "being", "am",
    "not", "no", "yes", "very", "too", "also", "just", "only", "even",
    "here", "there", "now", "thus", "hence", "indeed", "perhaps", "maybe",
}


def is_illustratable(english_word: str, category: str) -> bool:
    """False when no honest picture of this entry exists.

    Phrases, sentences and stories are always illustratable - they describe
    a scene by construction.
    """
    # THE SAFETY GATE RUNS FIRST, before the phrase/sentence shortcut.
    # That shortcut used to return True immediately, so three sentences
    # sailed past the adult filter - "A woman who has problems with her
    # womb cannot give birth", "A ceremony in which the bride and groom are
    # shaven of their private parts". A sentence is exactly as capable of
    # producing a nude image as a single word, and more likely to, because
    # the whole sentence goes into the prompt.
    if _ADULT_ENTRY.search(fix_gloss_typos((english_word or "").lower())):
        return False

    if category in ("phrase", "sentence", "story"):
        return True

    raw = (english_word or "").strip().lower()
    if not raw:
        return False
    # Adult entries are left with NO picture, whatever the prompt would be.
    # The dictionary is a complete record of an adult language and rightly
    # includes these; a vocabulary card in a children's app is not the place
    # to illustrate them, and an SDXL attempt at any of them is worse than a
    # blank. hasImageSync() already filters an image-less word out of games
    # and quizzes, so the gap is safe. 32 entries; listed in
    # contributions/adult_entries.json. Dr. Sama can overrule any of these
    # with a PROMPT_OVERRIDES line or an approved photo - both run ahead of
    # this gate for a contributed image, and neither is something a script
    # should decide on its own.
    if _ADULT_ENTRY.search(raw):
        return False
    if _UNILLUSTRATABLE_MARKERS.search(raw):
        return False
    if _STEM_ENTRY.search(raw):
        return False
    if _NAMED_INSTITUTION.search(raw):
        return False

    short = shorten_english_for_prompt(english_word)
    clean = re.sub(r"\s*\(.*?\)", "", short).strip().strip(",.;:'\"")
    if not clean:
        return False
    if _NON_ASCII.search(clean):
        return False
    # Every token is a function word -> nothing concrete in the gloss.
    toks = [t.strip(",.;:'\"") for t in clean.split()]
    toks = [t for t in toks if t]
    if toks and all(t in _FUNCTION_WORDS for t in toks):
        return False
    return True


def get_ai_prompt(english_word: str, category: str, seed_key: str = "") -> str:
    """Build an AI image generation prompt for a word/phrase/sentence/story.

    `seed_key` is the image key. It only picks the persona (hair, skin,
    clothes, subject) so every word gets a different-looking person while
    staying stable across regenerations. Pass "" and you get one fixed
    persona - which is exactly the uniformity this parameter exists to fix,
    so callers should always pass the key.
    """

    # Multi-word content (phrase / sentence / story) takes a different prompt
    # path. Their english field is a full translation like "He went to the
    # market" or "Mbachia, Apena and Mbyaabo are climbing a tree" — running
    # those through shorten_english_for_prompt() (which is tuned to distil
    # dictionary entries down to a single gloss word) would mangle the
    # meaning. Use the full sentence, capped at ~15 words so the final
    # prompt (with STYLE_SUFFIX appended) stays under CLIP's 77-token budget.
    if category in ("phrase", "sentence", "story"):
        text = fix_gloss_typos(english_word.strip()).rstrip(".!?\"'").strip()
        # Cut at a phrase boundary, not at word 15. "...that can lift it in"
        # and "...if their child turns out to" are prompts asking for a
        # relationship whose object was cut off, and the model fills the gap
        # itself - the same defect that was fixed on the word path.
        text = _trim_to_phrase(text, 15).rstrip(",;: ")
        templates = {
            "phrase": f"a cartoon scene of a child saying: {text}",
            "sentence": f"a cartoon scene illustrating: {text}",
            "story": f"a cartoon storybook scene showing: {text}",
        }
        body = africanize_people(templates[category], seed_key)
        return f"{body}, {_style_suffix_for(body, category)}"

    word_lower = english_word.lower().strip()

    # Reduce long dictionary definitions to short gloss BEFORE override lookup
    # so the override check actually matches the headword (not the long defn).
    english_word = fix_gloss_typos(english_word)
    short_word = shorten_english_for_prompt(english_word)

    # Strip parenthetical disambiguations like "(body part)" or "(drink)"
    clean_word = re.sub(r'\s*\(.*?\)', '', short_word).strip()

    # Check overrides: exact gloss first, then the cleaned word, then - only
    # if it is safe - the first word alone.
    #
    # The first-word fallback is where the WRONG pictures came from. "open
    # gourd" matched the override for "open" and drew a child opening a
    # door; "sweet potato" matched "sweet" and drew candies and lollipops;
    # "oil palm" drew a bottle of cooking oil; "mother tongue" drew a mother
    # hugging a child. 820 glosses reached an override this way and the head
    # word was carrying only part of the meaning.
    #
    # Rule: take the first word's override only when every remaining token is
    # a stopword or a modifier - "eat hastily", "throw away". If a trailing
    # token is a content word, the gloss means something the head word does
    # not, so fall through to the literal category prompt. A plain "a cartoon
    # sweet potato" is always better than a confidently wrong lollipop.
    # "plant (cocoyams)" shortens to "plant" because step 1 strips the
    # parenthetical - and then matches the generic "plant a seed in soil"
    # override, losing the cocoyam entirely. The parenthetical is usually the
    # DISAMBIGUATOR, so try putting it back before falling further down.
    disambiguated = None
    _paren = re.findall(r"\(([^)]*)\)", english_word or "")
    if _paren:
        cand = f"{clean_word} {_paren[0].strip()}".lower().strip()
        cand = re.sub(r"\s+", " ", cand)
        if cand != clean_word:
            disambiguated = cand

    # Most specific FIRST. "plant (cocoyams)" shortens to "plant", which is
    # itself an override key, so unless the disambiguated form is tried ahead
    # of it the generic "planting a seed in soil" wins and the cocoyam is
    # lost. Safe to put first: it only ever matches a key written
    # deliberately for disambiguation - "work (n)" yields "work n", which is
    # not a key, and falls straight through.
    # A QUALIFIED gloss must not match the override for its bare head.
    # "tree, for boundaries", "tree, of kolanuts" and "tree, for building
    # bridges" are three different trees; all three shortened to "tree",
    # hit the generic tree override, and came back as one picture. 14 cards,
    # one image. Same failure shape as "sweet potato" matching "sweet",
    # which _safe_first_word() already guards - this is that guard applied
    # one level up, to the head of a qualified gloss.
    #
    # The disambiguated form is still tried first, so a deliberately written
    # key like "plant (cocoyams)" keeps working.
    _concrete = concrete_gloss_for_prompt(english_word)
    _qualified = len(_content_tokens(_concrete)) > len(_content_tokens(clean_word))

    _candidates = [disambiguated, short_word, clean_word,
                   _safe_first_word(clean_word)]
    if _qualified:
        _candidates = [disambiguated, english_word.strip().lower(), _concrete]
        # ...but a SHORT gloss is not really "qualified". The guard exists
        # to stop "tree, for boundaries" matching the generic tree
        # override; it was also blocking "from, starting source
        # (preposition)" from reaching the override written for "from",
        # so that card got a literal prompt naming nothing and SDXL drew an
        # office full of white people. Three content words or fewer: trust
        # the head.
        if len(_content_tokens(_concrete)) <= 3:
            _candidates.append(clean_word)
            _candidates.append(short_word)
        # A multi-word override key is not a generic head - it was written
        # for a specific gloss ("a piece of rough iron used"). Keep it.
        if len(_content_tokens(short_word)) >= 3:
            _candidates.append(short_word)

    for w in _candidates:
        if w and w in PROMPT_OVERRIDES:
            body = africanize_people(PROMPT_OVERRIDES[w], seed_key)
            return f"{body}, {_style_suffix_for(body, category)}"

    # No override. Build the prompt from the gloss's OWN content.
    #
    # v1.24.5. Two things changed here, both of them answers to "why is the
    # picture of hump a child".
    #
    # 1. THE SUBJECT GOES FIRST AND THE PERSONA GOES LAST. The old templates
    #    opened with people_style(), which is ~20 tokens of child:
    #
    #      "a Cameroonian little boy with dark brown skin, a neatly shaved
    #       head, wearing a plain school uniform, showing their hump"
    #
    #    CLIP weights early tokens most. The prompt was 90% a description of
    #    a boy and 1 word of subject, so SDXL drew the boy faithfully and
    #    dropped the hump - and that is the picture Dr. Sama saw on his
    #    phone. Hair and clothes are gone from the generated templates
    #    (they were decoration, and they were crowding out the word);
    #    persona and skin stay, because the NACDA request was about skin.
    #
    # 2. THE GLOSS IS USED WHOLE. clean_word is now the concrete clause of
    #    the entry, not the headword - see concrete_gloss_for_prompt(). When
    #    that clause already names its own subject ("a dog crunching a
    #    bone") no persona is added at all: the dictionary said what is in
    #    the picture, so the picture is that.
    clean_word = concrete_gloss_for_prompt(english_word)
    _hair, skin, _clothes, persona = _persona_bits(seed_key)
    who = f"a Cameroonian {persona} with {skin}"
    subject_np = _as_noun_phrase(clean_word)
    owns_subject = _has_own_subject(clean_word)

    category_prompts = {
        # Body part first, close-up, person as the context it hangs on -
        # but only when the gloss IS a short body-part phrase. 337 `body`
        # entries are whole descriptions ("a sort of white substance from
        # the eye that comes out usually after sleep"), and wrapping one in
        # "close-up of the ... of a Cameroonian girl" produced "close-up of
        # the a sort of white substance ... of a Cameroonian teenage girl".
        # ...and not when the gloss is an ACTION. "shave (of hair)
        # improperly" is filed under `body`, and the close-up frame turned
        # it into "close-up of the shave one's self improperly of a
        # Cameroonian teenage girl". A verb is something a person DOES, so
        # it belongs on the action path below, not in a body-part frame.
        "body": (f"close-up of the {clean_word} of {who}"
                 if (len(clean_word.split()) <= 4 and not owns_subject
                     and not _is_verbish(clean_word))
                 else f"{_as_gerund(clean_word)}, done by {who}"
                 if (_is_verbish(clean_word) and not owns_subject)
                 else f"{clean_word}, {who}"),
        "animals": f"{subject_np}, animal",
        "nature": f"{subject_np}, nature scene",
        "food": f"{subject_np}, West African food",
        "actions": (clean_word if owns_subject
                    else f"{_as_gerund(clean_word)}, done by {who}"),
        "things": subject_np,
        "family": (clean_word if owns_subject
                   else f"{clean_word}, a Cameroonian family with {skin}"),
        # An adjective is something a person LOOKS; an abstract noun is
        # something a person SHOWS. "a Cameroonian girl ..., friendship" let
        # the noun float free of the subject.
        "descriptive": (
            clean_word if owns_subject
            else f"{_as_gerund(clean_word)}, done by {who}"
            if _is_verbish(clean_word)              # "connect together"
            else f"{who} showing {clean_word}"
            if (_is_abstract_noun(clean_word)
                or len(clean_word.split()) > 1)     # "bad company"
            else f"{who} looking {clean_word}"),    # "sour", "tired"
        # Reached only for entries the data files under `numbers` that are
        # NOT numerals ("road, of dusty one", "prepare one's self") - real
        # numerals never get here, they are composed by
        # generate_counting_image() instead.
        "numbers": subject_np,
    }
    base = category_prompts.get(category, subject_np)
    body = africanize_people(base, seed_key)

    # Say the thing again, as a requirement. This is the general rule Dr.
    # Sama asked for - "simply use the english meaning and ensure the object
    # is in the picture" - and it applies to every word that reaches this
    # path, not to a hand-picked list. Skipped when the phrase is already
    # the whole body (nothing to reinforce) so a one-word gloss does not
    # become "a hump, hump clearly visible".
    # LAST RESORT: a prompt that names neither a person nor a thing.
    #
    # "shave, as with a blade" is categorised `numbers` in the data, so it
    # took the object path, and the object path had no object to offer. The
    # prompt went to SDXL naming nothing at all, and the model filled the
    # empty space with an invented scene - a white man being shaved, an
    # office of white workers for "from". Every white card Dr. Sama has
    # sent has been one of these.
    #
    # A verb needs somebody to do it. If nothing in the body is a person
    # and the gloss reads as an action, give it one, named and coloured, so
    # the model is not left to invent both the subject and its skin.
    if (not _HUMAN_REF_RE.search(body)
            and _is_verbish(clean_word)
            and not _has_own_subject(clean_word)):
        _h, _skin, _c, _who = _persona_bits(seed_key)
        # Hair as well as skin. _persona_bits() always returned it; this
        # branch threw it away, so the one path that INVENTS a person -
        # the verbs, the largest group - described their colour and left
        # their hair to the model. PERSONA_HAIR is all Black hair:
        # afros, locs, twists, cornrows, head wraps.
        body = (f"a Cameroonian {_who} with {_skin} and {_h} "
                f"{_as_gerund(clean_word)}")

    focus = _focus_phrase(clean_word)
    suffix = _style_suffix_for(body, category)
    if (focus and focus.lower() != body.strip().lower()
            and len(body.split()) >= 2
            # The clause sits at the end, so it is the first thing CLIP drops
            # when a prompt runs past 77 tokens. Past this length it would be
            # truncated anyway, and the tokens are better spent on the body.
            and len(body.split()) + len(suffix.split()) + 6 <= 48):
        body = f"{body}, {focus} clearly visible in the picture"
    return f"{body}, {suffix}"


# ============================================================
# LOCAL GPU IMAGE GENERATION (SDXL Turbo via diffusers)
# ============================================================

_pipeline = None  # Global pipeline — loaded once, reused for all images


def load_pipeline():
    """Load SDXL Turbo pipeline on GPU. Called once at start of generation."""
    global _pipeline
    if _pipeline is not None:
        return _pipeline

    try:
        import torch
        from diffusers import AutoPipelineForText2Image

        if not torch.cuda.is_available():
            print("ERROR: CUDA GPU not available. Use --emoji-only or install CUDA.")
            return None

        gpu_name = torch.cuda.get_device_name(0)
        vram_gb = torch.cuda.get_device_properties(0).total_memory / (1024**3)
        cap = torch.cuda.get_device_capability(0)
        print(f"GPU: {gpu_name} ({vram_gb:.1f} GB VRAM, compute capability sm_{cap[0]}{cap[1]})")
        print(f"PyTorch: {torch.__version__} (CUDA build: {torch.version.cuda})")

        # Detect compute-capability mismatch up front. The "no kernel image"
        # error happens silently per-tensor otherwise.
        try:
            _probe = torch.zeros(1, device="cuda")
            _probe = _probe + 1.0
            torch.cuda.synchronize()
        except Exception as e:
            msg = str(e)
            if "no kernel image" in msg.lower() or "kernel image" in msg.lower():
                print()
                print("=" * 70)
                print("ERROR: PyTorch wheel does not support your GPU.")
                print(f"  GPU compute capability: sm_{cap[0]}{cap[1]}")
                print(f"  PyTorch CUDA build:     {torch.version.cuda}")
                print()
                print("Likely fix (newer GPU like RTX 50-series, Blackwell sm_120):")
                print("  venv\\Scripts\\pip install --upgrade --force-reinstall \\")
                print("    torch torchvision torchaudio \\")
                print("    --index-url https://download.pytorch.org/whl/cu128")
                print()
                print("Older GPU (Maxwell sm_50, Pascal sm_61, etc.) — try nightly:")
                print("  venv\\Scripts\\pip install --upgrade --force-reinstall \\")
                print("    --pre torch torchvision torchaudio \\")
                print("    --index-url https://download.pytorch.org/whl/nightly/cu124")
                print()
                print("Or skip GPU generation (uses emoji fallback for new words):")
                print("  python scripts\\generate_images.py generate --emoji-only")
                print("=" * 70)
                return None
            raise

        print(f"Loading SDXL Turbo model (first time downloads ~5GB)...")
        _pipeline = AutoPipelineForText2Image.from_pretrained(
            SDXL_TURBO_MODEL,
            torch_dtype=torch.float16,
            variant="fp16",
        )
        _pipeline = _pipeline.to("cuda")

        # Optimize memory. A full run is thousands of generations in one
        # process and VRAM fragments: the 5,000th image OOMs on a card that
        # drew the first 4,000 fine. VAE slicing is the one that matters -
        # decoding is the peak - and attention slicing trades a little speed
        # for headroom.
        _pipeline.set_progress_bar_config(disable=True)
        for opt in ("enable_attention_slicing", "enable_vae_slicing",
                    "enable_vae_tiling"):
            try:
                getattr(_pipeline, opt)()
            except Exception:
                pass

        print(f"Model loaded successfully!\n")
        return _pipeline

    except ImportError as e:
        print(f"ERROR: Missing packages. Run:")
        print(f"  pip install diffusers transformers accelerate")
        print(f"  (Error: {e})")
        return None
    except Exception as e:
        print(f"ERROR loading model: {e}")
        return None


# ---- output format ------------------------------------------------------
# Set by main() from --format / --quality.
#
# Why this matters: 9,570 PNGs average 83 KB, which is 776 MB and the
# overwhelming bulk of a 931 MB AAB. These are flat cartoon illustrations on
# a solid background - exactly what WebP is good at - and q82 typically
# lands them at 10-25 KB. PNG stays the default so nothing changes by
# accident; the build passes --format webp explicitly.
OUTPUT_FORMAT = "png"
OUTPUT_QUALITY = 82


# Every extension an image may be on disk as. Lookup order does not matter
# here (these are local-filesystem checks, not asset-pack lookups), but the
# SET must match ImageService._imageExtensions and the extensions accepted by
# scripts/build_image_manifest.py.
IMAGE_EXTENSIONS = (".webp", ".png")


def _strip_ext(path_like) -> str:
    """Drop a trailing IMAGE_EXTENSIONS entry, if there is one.

    String slicing rather than Path.with_suffix("") because a key can contain
    a dot - cmd_test names files after the English gloss, and glosses like
    "etc." or "No. 1" exist - and with_suffix would eat that as the suffix.
    """
    s = str(path_like)
    for ext in IMAGE_EXTENSIONS:
        if s.endswith(ext):
            return s[: -len(ext)]
    return s


def _target_path(key_or_path) -> "Path":
    """The path this key WILL be written to, in the current OUTPUT_FORMAT."""
    from pathlib import Path as _P
    return _P(_strip_ext(key_or_path) + "." + OUTPUT_FORMAT)


def _existing_image(stem_path):
    """First existing file for this extension-less path, or None.

    Used for *reporting* coverage (status, counts) where a PNG from an older
    run counts as "we have an illustration". NOT used for the generate
    skip-check: during a PNG -> WebP migration a stale PNG must not stop the
    WebP from being written, so that check looks at _target_path only.
    """
    from pathlib import Path as _P
    base = _strip_ext(stem_path)
    for ext in IMAGE_EXTENSIONS:
        cand = _P(base + ext)
        if cand.exists():
            return cand
    return None


def _save_image(img, output_path) -> None:
    """Write `img` honouring OUTPUT_FORMAT, fixing up the extension.

    Also removes the same stem in the OTHER format. Without this a PNG ->
    WebP migration leaves both files behind: build_image_manifest.py and the
    app both cope (stems are deduped, WebP wins the lookup), but the asset
    pack would still ship the PNG and the whole point of the migration -
    getting 776 MB down to ~150 MB - would be lost.
    """
    from pathlib import Path as _P
    out = _target_path(output_path)
    base = _strip_ext(out)
    if OUTPUT_FORMAT == "webp":
        # method=6 is the slowest/best encoder setting. At ~9,000 images the
        # extra encode time is noise next to SDXL inference, and it buys a
        # few percent.
        img.save(str(out), "WEBP", quality=OUTPUT_QUALITY, method=6)
    else:
        img.save(str(out), "PNG", optimize=True)

    for ext in IMAGE_EXTENSIONS:
        stale = _P(base + ext)
        if stale != out and stale.exists():
            try:
                stale.unlink()
            except OSError as exc:
                print(f"  ! could not remove stale {stale.name}: {exc}")


# THE reason pictures did not match their words.
#
# The old settings were num_inference_steps=1, guidance_scale=0.0, with a
# comment saying "1 step is enough" and "no guidance needed". Those are the
# settings SDXL Turbo is *benchmarked* at, and they produce a plausible
# image fast - but prompt ADHERENCE at 1 step with no guidance is poor. The
# model locks onto whatever dominates the prompt semantically. Our prompt is
# ~3 tokens of subject ("vomit") against ~40 tokens of style ("cute cartoon
# illustration FOR CHILDREN... FRIENDLY AND CHEERFUL... Grassfields"), so
# the style won every time and the subject was ignored. That is exactly what
# the contact sheet showed: the style rendered faithfully, a cheerful child
# in a field, and no vomit anywhere.
#
# 4 steps is still within Turbo's design range. guidance_scale above 1.0 is
# off-label for Turbo but it is what makes the subject stick, and it is also
# what ACTIVATES the negative prompt - at guidance 0 negatives are ignored
# entirely, which is why "no text" never worked either.
#
# Both are CLI-tunable (--steps, --guidance) so they can be A/B'd on one
# word instead of argued about.
# 2026-10-08: raised from 1.5. The negative prompt has named "caucasian,
# white person, pale skin" all day and has been ignored all day. Evidence,
# from one run:
#
#   koole__shave          prompt names no person  -> a white bearded man
#   sentence_koome...     prompt names children   -> two Black children
#
# Same model, same negative, same minute. Where the positive prompt says
# who is in the picture the skin is right; where it does not, the model
# invents a person and the negative does not stop it being white. At
# guidance 1.5 a negative prompt barely participates - that is a property
# of classifier-free guidance, not a quirk of this model - so no amount of
# extra wording in the negative was ever going to win.
#
# Turbo is designed for guidance 0-1 and 1.5 was already off-label, chosen
# so the SUBJECT would stick. 3.0 is further off-label; it makes both the
# prompt and the negative count for more, at some cost in the soft cartoon
# look. Steps go 4 -> 6 because higher guidance needs a little more room
# to resolve.
#
# Both are CLI-tunable (--guidance, --steps). If this trade is wrong, it
# is one constant to change back, not a list to maintain.
INFERENCE_STEPS = 6
GUIDANCE_SCALE = 3.0

_NEGATIVE_COMMON = (
    # FIRST, on every single prompt, because this is a children's app and
    # no amount of clever gating is worth one nude card. Dr. Sama, on
    # finding one: "I just hope the naked picture will not be shown to
    # kids."
    "nude, naked, nudity, topless, bare chest, bare breasts, underwear, "
    "lingerie, undressed, exposed body, suggestive, sexual, "
    # Found while reviewing the pack: ajwigotapenge "bad company" came back
    # as a man holding a pistol, and nothing in that prompt asked for one
    # ("a smiling man with one hand held behind his back hiding a stone").
    # A diffusion model adds props the prompt never mentioned, so the ones
    # that must never appear are named here rather than hoped against.
    "gun, pistol, rifle, weapon, knife held as a weapon, blood, violence, "
    "cigarette, alcohol bottle, "
    "caucasian, white person, white man, white woman, white child, "
    "pale skin, light skin, fair skin, tan skin, peach skin, olive skin, "
    "light brown skin, beige skin, european features, "
    # Session 66v, Dr. Sama: "ensuring the people or persons are black
    # with black hair styles." Skin was only half of it. SDXL will
    # happily give a dark-skinned child long straight blonde hair,
    # which reads as wrong to every parent who will see this app.
    "blonde hair, blond hair, red hair, ginger hair, light brown hair, "
    "straight hair, long straight hair, silky straight hair, "
    "wavy hair, flowing hair, ponytail, pigtails, bangs, fringe, "
    "european hairstyle, caucasian hair, "
    "text, words, letters, numbers, watermark, signature, caption, "
    "blurry, deformed, extra limbs, extra fingers, ugly, "
    "photograph, photorealistic, 3d render"
)

# For an object prompt, "person" is the failure mode, so name it.
_NEGATIVE_OBJECT = (
    "person, people, child, boy, girl, man, woman, face, portrait, crowd, "
    + _NEGATIVE_COMMON
)


def get_negative_prompt(prompt: str, category: str) -> str:
    """Negative prompt matching the positive one. Only has effect when
    GUIDANCE_SCALE > 1.0."""
    if _is_person_prompt(prompt, category):
        return _NEGATIVE_COMMON
    return _NEGATIVE_OBJECT


def generate_ai_image(prompt: str, seed: int,
                      negative_prompt: str = "", _retry: int = 0):
    """Generate an image using SDXL Turbo on local GPU.

    Returns the image, None if the pipeline is unavailable or the prompt
    genuinely failed, or the string "OOM" when the GPU ran out of memory -
    which is transient and must not be treated as "this word cannot be
    drawn". See the caller.
    """
    import torch, time

    pipe = load_pipeline()
    if pipe is None:
        return None

    try:
        generator = torch.Generator("cuda").manual_seed(seed)

        kwargs = dict(
            prompt=prompt,
            num_inference_steps=INFERENCE_STEPS,
            guidance_scale=GUIDANCE_SCALE,
            width=GENERATION_SIZE,
            height=GENERATION_SIZE,
            generator=generator,
        )
        # A negative prompt is only meaningful with classifier-free guidance.
        if GUIDANCE_SCALE > 1.0 and negative_prompt:
            kwargs["negative_prompt"] = negative_prompt

        result = pipe(**kwargs)

        img = result.images[0]
        return img.convert("RGB")

    except Exception as e:
        msg = str(e)
        oom = ("out of memory" in msg.lower()
               or "cuda error" in msg.lower()
               or e.__class__.__name__ == "OutOfMemoryError")
        if oom and _retry < 2:
            # VRAM fragments over a long run. Freeing the cache and waiting
            # a moment recovers it most of the time, and an OOM is transient
            # - it says nothing about whether this word can be drawn.
            try:
                import gc
                gc.collect()
                torch.cuda.empty_cache()
                torch.cuda.synchronize()
            except Exception:
                pass
            time.sleep(3)
            print(f"    GPU out of memory, freed cache, retry {_retry + 1}/2")
            return generate_ai_image(prompt, seed, negative_prompt,
                                     _retry=_retry + 1)
        print(f"    GPU generation failed: {e}")
        # Signalled separately from "this word has no picture": the caller
        # must NOT substitute an emoji for a transient GPU fault.
        return "OOM" if oom else None


# ============================================================
# EMOJI FALLBACK
# ============================================================

def get_emoji_codepoint(english_word: str, category: str) -> str:
    """Get Twemoji codepoint for an English word, with category fallback."""
    word_lower = english_word.lower().strip()
    if word_lower in EMOJI_CODEPOINTS:
        return EMOJI_CODEPOINTS[word_lower]
    first_word = word_lower.split()[0] if ' ' in word_lower else None
    if first_word and first_word in EMOJI_CODEPOINTS:
        return EMOJI_CODEPOINTS[first_word]
    last_word = word_lower.split()[-1] if ' ' in word_lower else None
    if last_word and last_word in EMOJI_CODEPOINTS:
        return EMOJI_CODEPOINTS[last_word]
    base_word = re.sub(r'\s*\(.*?\)', '', word_lower).strip()
    if base_word in EMOJI_CODEPOINTS:
        return EMOJI_CODEPOINTS[base_word]
    return CATEGORY_FALLBACK_EMOJI.get(category, CATEGORY_FALLBACK_EMOJI["default"])


def download_twemoji(codepoint: str) -> Image.Image | None:
    """Download a Twemoji PNG and return as PIL Image. Caches locally."""
    from urllib.request import urlopen, Request
    from urllib.error import HTTPError, URLError

    EMOJI_CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cache_file = EMOJI_CACHE_DIR / f"{codepoint}.png"

    if cache_file.exists() and cache_file.stat().st_size > 0:
        try:
            return Image.open(cache_file).convert("RGBA")
        except Exception:
            cache_file.unlink(missing_ok=True)

    url = f"{TWEMOJI_BASE}/{codepoint}.png"
    try:
        req = Request(url, headers={"User-Agent": "AwingAILearning/1.2"})
        with urlopen(req, timeout=10) as response:
            data = response.read()
        cache_file.write_bytes(data)
        return Image.open(cache_file).convert("RGBA")
    except (HTTPError, URLError, Exception):
        if "-fe0f" in codepoint:
            return download_twemoji(codepoint.replace("-fe0f", ""))
        return None


# ============================================================
# IMAGE POST-PROCESSING
# ============================================================

def create_rounded_rect_mask(size, radius):
    """Create a rounded rectangle alpha mask."""
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (size[0]-1, size[1]-1)], radius=radius, fill=255)
    return mask


def crop_center_square(img: Image.Image) -> Image.Image:
    """Crop image to center square."""
    w, h = img.size
    size = min(w, h)
    left = (w - size) // 2
    top = (h - size) // 2
    return img.crop((left, top, left + size, top + size))


def finalize_image(img: Image.Image, category: str, output_path: Path) -> bool:
    """Apply category border, rounded corners, and save."""
    try:
        color = CATEGORY_COLORS.get(category, CATEGORY_COLORS["default"])

        # Crop to square and resize to final size
        square = crop_center_square(img)
        resized = square.resize((IMAGE_SIZE, IMAGE_SIZE), Image.LANCZOS)

        # Create canvas with colored border
        border_size = IMAGE_SIZE + BORDER_WIDTH * 2
        canvas = Image.new("RGB", (border_size, border_size), color)
        canvas.paste(resized, (BORDER_WIDTH, BORDER_WIDTH))

        # Resize back to IMAGE_SIZE (border included)
        final = canvas.resize((IMAGE_SIZE, IMAGE_SIZE), Image.LANCZOS)

        # Apply rounded corners
        mask = create_rounded_rect_mask((IMAGE_SIZE, IMAGE_SIZE), CORNER_RADIUS)
        result_rgba = final.convert("RGBA")
        bg = Image.new("RGBA", (IMAGE_SIZE, IMAGE_SIZE), (245, 245, 250, 255))
        result_rgba.putalpha(mask)
        bg.paste(result_rgba, (0, 0), result_rgba)
        final_rgb = bg.convert("RGB")

        output_path.parent.mkdir(parents=True, exist_ok=True)
        _save_image(final_rgb, output_path)
        return True

    except Exception as e:
        print(f"  ERROR finalizing image: {e}")
        return False


# ============================================================
# COUNTING IMAGES (numbers never go through the diffusion model)
# ============================================================
# "seven" generated a picture with about twenty birds in it. That is not a
# tuning problem - diffusion models cannot count. Asking SDXL for exactly N
# objects is unreliable past about three, and on a NUMBER card the count IS
# the content. A card captioned "seven" showing twenty birds teaches the
# child the wrong thing, which is worse than no card.
#
# So numerals are composed deterministically instead: N copies of one sprite,
# placed by arithmetic. Exact by construction, no GPU, instant.

_NUMBER_WORDS = {
    "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
    "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
    "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14,
    "fifteen": 15, "sixteen": 16, "seventeen": 17, "eighteen": 18,
    "nineteen": 19, "twenty": 20, "thirty": 30, "forty": 40, "fourty": 40,
    "fifty": 50, "sixty": 60, "seventy": 70, "eighty": 80, "ninety": 90,
    "hundred": 100, "thousand": 1000,
}

# Twemoji codepoints that read clearly when small and repeated.
_COUNTABLE_EMOJI = [
    "1f34e",  # red apple
    "2b50",   # star
    "1f34c",  # banana
    "26bd",   # football
    "1f338",  # blossom
    "1f41f",  # fish
    "1f95a",  # egg
    "1f350",  # pear
]

# At most this many sprites get tiled. Above it, counting 70 apples on a
# 256px card helps nobody - show the numeral instead.
_MAX_TILED_COUNT = 12


def parse_count(english_word: str):
    """Exact cardinal value of this gloss, or None.

    Requires the WHOLE cleaned gloss to be a number - so "road, of dusty
    one" (which the data files under `numbers`) does not match, and neither
    do ordinals like "first" or "second", which need a different picture
    entirely.
    """
    s = (english_word or "").strip().lower()
    s = re.sub(r"\s*\(.*?\)", "", s).strip()
    s = s.split(",")[0].split(";")[0].strip()
    s = s.strip(".!? ")
    if not s:
        return None
    if re.fullmatch(r"\d{1,4}", s):
        return int(s)
    # "twenty-one", "twenty one"
    parts = re.split(r"[-\s]+", s)
    if not parts or not all(p in _NUMBER_WORDS for p in parts):
        return None
    if len(parts) == 1:
        return _NUMBER_WORDS[parts[0]]
    if len(parts) == 2:
        tens, units = _NUMBER_WORDS[parts[0]], _NUMBER_WORDS[parts[1]]
        # "twenty one" = 21, but "one hundred" = 100.
        if tens >= 20 and units < 10:
            return tens + units
        if units >= 100:
            return tens * units
    return None


_FALLBACK_SPRITE_COLORS = [
    (232, 93, 84), (247, 181, 56), (76, 163, 110),
    (69, 137, 204), (150, 101, 196), (240, 138, 93),
]


def _fallback_sprite(color_byte: int) -> "Image.Image":
    """A flat coloured disc, used when Twemoji cannot be downloaded."""
    size = 192
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    color = _FALLBACK_SPRITE_COLORS[color_byte % len(_FALLBACK_SPRITE_COLORS)]
    d.ellipse([6, 6, size - 7, size - 7], fill=color + (255,),
              outline=(255, 255, 255, 255), width=6)
    return img


def _big_font(size: int):
    """A bold TrueType face if one is findable, else PIL's bitmap default."""
    for candidate in (
        r"C:\Windows\Fonts\arialbd.ttf",
        r"C:\Windows\Fonts\segoeuib.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    ):
        try:
            return ImageFont.truetype(candidate, size)
        except Exception:
            continue
    try:
        return ImageFont.load_default(size)
    except Exception:
        return ImageFont.load_default()


def generate_counting_image(count: int, english_word: str, category: str,
                            output_path: Path, seed_key: str = "") -> bool:
    """Compose a card showing EXACTLY `count` identical objects.

    Above _MAX_TILED_COUNT, draws the numeral instead - 70 sprites on a
    256px card is a smear, not a counting exercise.
    """
    try:
        card = Image.new("RGB", (IMAGE_SIZE, IMAGE_SIZE), (255, 255, 255))

        if 1 <= count <= _MAX_TILED_COUNT:
            h = hashlib.md5(("count:" + (seed_key or english_word)).encode()).digest()
            # Try every sprite starting from the hashed one. A single failed
            # Twemoji download must NOT abort the card: the caller would fall
            # through to the diffusion model, which is the twenty-birds bug
            # this whole function exists to prevent.
            sprite = None
            start = h[0] % len(_COUNTABLE_EMOJI)
            for off in range(len(_COUNTABLE_EMOJI)):
                sprite = download_twemoji(
                    _COUNTABLE_EMOJI[(start + off) % len(_COUNTABLE_EMOJI)])
                if sprite is not None:
                    break
            if sprite is None:
                # Offline: draw our own. Plain, but the count is still exact,
                # which is the only thing that matters on a number card.
                sprite = _fallback_sprite(h[1])

            cols = math.ceil(math.sqrt(count))
            rows = math.ceil(count / cols)
            margin = 18
            cell_w = (IMAGE_SIZE - 2 * margin) / cols
            cell_h = (IMAGE_SIZE - 2 * margin) / rows
            size = int(min(cell_w, cell_h) * 0.78)
            size = max(16, min(size, 96))
            sprite = sprite.resize((size, size), Image.LANCZOS)

            placed = 0
            for r in range(rows):
                # Centre the last, possibly short, row.
                in_row = min(cols, count - placed)
                row_w = in_row * cell_w
                x0 = (IMAGE_SIZE - row_w) / 2
                for c in range(in_row):
                    x = int(x0 + c * cell_w + (cell_w - size) / 2)
                    y = int(margin + r * cell_h + (cell_h - size) / 2)
                    card.paste(sprite, (x, y), sprite)
                    placed += 1
            assert placed == count, f"placed {placed} != {count}"
        else:
            draw = ImageDraw.Draw(card)
            text = str(count)
            font = _big_font(140 if len(text) <= 2 else 100)
            box = draw.textbbox((0, 0), text, font=font)
            tw, th = box[2] - box[0], box[3] - box[1]
            draw.text(((IMAGE_SIZE - tw) / 2 - box[0],
                       (IMAGE_SIZE - th) / 2 - box[1]),
                      text, font=font, fill=(40, 60, 120))

        # Same border / rounded-corner treatment as every other card.
        color = CATEGORY_COLORS.get(category, CATEGORY_COLORS["default"])
        border_size = IMAGE_SIZE + BORDER_WIDTH * 2
        canvas = Image.new("RGB", (border_size, border_size), color)
        canvas.paste(card, (BORDER_WIDTH, BORDER_WIDTH))
        final = canvas.resize((IMAGE_SIZE, IMAGE_SIZE), Image.LANCZOS)

        mask = create_rounded_rect_mask((IMAGE_SIZE, IMAGE_SIZE), CORNER_RADIUS)
        rgba = final.convert("RGBA")
        bg = Image.new("RGBA", (IMAGE_SIZE, IMAGE_SIZE), (245, 245, 250, 255))
        rgba.putalpha(mask)
        bg.paste(rgba, (0, 0), rgba)

        output_path.parent.mkdir(parents=True, exist_ok=True)
        _save_image(bg.convert("RGB"), output_path)
        return True

    except Exception as e:
        print(f"  ERROR creating counting image: {e}")
        return False


def generate_emoji_image(english_word: str, category: str, output_path: Path) -> bool:
    """Generate a vocabulary image from Twemoji emoji (fallback)."""
    try:
        color = CATEGORY_COLORS.get(category, CATEGORY_COLORS["default"])
        top_color = tuple(min(255, c + 60) for c in color)

        # Create gradient card
        card = Image.new("RGB", (IMAGE_SIZE, IMAGE_SIZE), top_color)
        draw = ImageDraw.Draw(card)
        for y in range(IMAGE_SIZE):
            t = y / IMAGE_SIZE
            t_curved = t * t * (3 - 2 * t)
            r = int(top_color[0] + (color[0] - top_color[0]) * t_curved)
            g = int(top_color[1] + (color[1] - top_color[1]) * t_curved)
            b = int(top_color[2] + (color[2] - top_color[2]) * t_curved)
            draw.line([(0, y), (IMAGE_SIZE - 1, y)], fill=(r, g, b))

        # Get and paste emoji
        codepoint = get_emoji_codepoint(english_word, category)
        emoji_img = download_twemoji(codepoint)
        if emoji_img:
            emoji_resized = emoji_img.resize((150, 150), Image.LANCZOS)
            ex = (IMAGE_SIZE - 150) // 2
            ey = (IMAGE_SIZE - 150) // 2
            card.paste(emoji_resized, (ex, ey), emoji_resized)

        # Apply rounded corners
        mask = create_rounded_rect_mask((IMAGE_SIZE, IMAGE_SIZE), CORNER_RADIUS)
        card_rgba = card.convert("RGBA")
        card_rgba.putalpha(mask)
        bg = Image.new("RGBA", (IMAGE_SIZE, IMAGE_SIZE), (245, 245, 250, 255))
        bg.paste(card_rgba, (0, 0), card_rgba)
        final_rgb = bg.convert("RGB")

        output_path.parent.mkdir(parents=True, exist_ok=True)
        _save_image(final_rgb, output_path)
        return True

    except Exception as e:
        print(f"  ERROR creating emoji image: {e}")
        return False


# ============================================================
# COMMANDS
# ============================================================

def cmd_generate(args):
    """Generate vocabulary images (plus phrases, sentences, stories)."""
    vocabulary = parse_vocabulary()
    if not vocabulary:
        print("ERROR: No vocabulary found in Dart file")
        sys.exit(1)

    # Merge phrases, sentences, and stories into the same generation pass.
    # Their parsers emit namespaced keys (phrase_*, sentence_*, story_*) so
    # they can't collide with word keys, and their category slot routes them
    # through the multi-word branch of get_ai_prompt().
    phrase_count = sentence_count = story_count = 0
    phrases = parse_phrases()
    if phrases:
        phrase_count = len(phrases)
        vocabulary.update(phrases)
    sentences = parse_sentences()
    if sentences:
        sentence_count = len(sentences)
        vocabulary.update(sentences)
    stories = parse_stories()
    if stories:
        story_count = len(stories)
        vocabulary.update(stories)

    word_count = len(vocabulary) - phrase_count - sentence_count - story_count
    print(f"Sources:  {word_count} words + {phrase_count} phrases + "
          f"{sentence_count} sentences + {story_count} stories "
          f"= {len(vocabulary)} total")

    if getattr(args, "keys_file", None):
        wanted = set()
        with open(args.keys_file, encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                # Only the first field is the key. A regen list is far more
                # useful to a reviewer when each key carries the reason it is
                # on the list, and a tab-annotated file used to match nothing
                # at all because the whole line was compared.
                wanted.add(line.split("\t")[0].split()[0])
        missing = wanted - set(vocabulary)
        if missing:
            print(f"WARNING: {len(missing)} key(s) in {args.keys_file} match "
                  f"no vocabulary entry and will be skipped, e.g. "
                  f"{sorted(missing)[:3]}")
        vocabulary = {k: v for k, v in vocabulary.items() if k in wanted}
        if not vocabulary:
            print(f"ERROR: no vocabulary entries matched {args.keys_file}")
            sys.exit(1)
        args.force = True
        print(f"--keys-file {args.keys_file}: regenerating "
              f"{len(vocabulary)} image(s).")

    if args.category:
        # Comma-separated so a prompt-change sample can span several
        # categories in ONE run. Loading the SDXL pipeline costs ~40s, so
        # five single-category runs waste more time than they generate.
        wanted = {c.strip() for c in args.category.split(",") if c.strip()}
        known = {v["category"] for v in vocabulary.values()}
        unknown = wanted - known
        if unknown:
            print(f"ERROR: unknown category/categories: {', '.join(sorted(unknown))}")
            print(f"  known: {', '.join(sorted(known))}")
            sys.exit(1)
        vocabulary = {k: v for k, v in vocabulary.items()
                      if v["category"] in wanted}
        print(f"Generating {len(vocabulary)} images for "
              f"category/categories '{', '.join(sorted(wanted))}'...")

    # --word filter: match against audio_key, english_slug, full compound key, english gloss,
    # or Awing word (case-insensitive, substring OK for gloss and compound key).
    # Use when SDXL Turbo drifts off-prompt and you need to regenerate a handful of specific
    # words without rerunning the full 15-min pipeline. Implicit --force: matched words
    # always overwrite their existing images.
    #
    # Since image keys are now compound ({audio_key}__{english_slug}), bare "ap" no longer
    # equals any key. We match against the audio_key component AND the english_slug component
    # AND the full compound key via substring, so users can target words by any unambiguous
    # fragment they remember.
    if getattr(args, "word", None):
        needles = [w.strip().lower() for w in args.word.split(",") if w.strip()]
        filtered = {}
        for k, v in vocabulary.items():
            eng_lc = v["english"].lower()
            awing_lc = v.get("awing", "").lower()
            ak = audio_key(v["awing"])
            es = english_slug(v["english"])
            match = False
            for n in needles:
                if n == ak or n == es or n == awing_lc:
                    match = True
                    break
                if n in k or n in eng_lc:
                    match = True
                    break
            if match:
                filtered[k] = v
        if not filtered:
            print(f"ERROR: No vocabulary matched --word={args.word}")
            print(f"       Tried matching against audio_key, english_slug, compound key,")
            print(f"       english gloss (substring), and Awing word.")
            sys.exit(1)
        vocabulary = filtered
        args.force = True  # implicit — user asked for these specific words
        print(f"Regenerating {len(vocabulary)} image(s) matching --word={args.word}:")
        for k, v in sorted(vocabulary.items()):
            print(f"  {k:40}  {v['awing']:20}  ({v['english']})")
        print()
    elif not args.category:
        print(f"Generating {len(vocabulary)} vocabulary images...")

    use_ai = not args.emoji_only

    if use_ai:
        print(f"Image source: SDXL Turbo on local GPU + emoji fallback")
        pipe = load_pipeline()
        if pipe is None:
            print("Falling back to emoji-only mode.")
            use_ai = False
    if not use_ai:
        print(f"Image source: Twemoji (emoji graphics)")

    print(f"Output: {OUTPUT_DIR}\n")

    generated = 0
    skipped = 0
    failed = 0
    ai_hits = 0
    emoji_used = 0
    oom_keys = []
    emoji_fallback = bool(getattr(args, "emoji_fallback", False)
                          or getattr(args, "emoji_only", False))
    ai_attempts = 0
    not_depictable = 0
    protected_skipped = 0
    protected_keys = _contributed_keys()
    counted = 0
    removed_stale = 0
    start_time = time.time()

    limit = getattr(args, "limit", None)
    items = sorted(vocabulary.items())
    if limit:
        # Round-robin by category so a capped sample SPANS the categories
        # instead of taking 30 consecutive keys, which alphabetical order
        # would draw almost entirely from one of them.
        buckets = {}
        for key, word_data in items:
            buckets.setdefault(word_data["category"], []).append((key, word_data))
        items = []
        for row in itertools.zip_longest(*(buckets[c] for c in sorted(buckets))):
            items.extend(x for x in row if x is not None)
        print(f"--limit {limit}: stopping after {limit} newly written "
              f"image(s), round-robin across "
              f"{len(buckets)} categor{'y' if len(buckets) == 1 else 'ies'}.\n")

    for i, (key, word_data) in enumerate(items):
        # Counts images WRITTEN, not words examined, so --limit still yields a
        # full sample on a run where most words are already done.
        if limit and generated >= limit:
            print(f"\nReached --limit {limit} - stopping "
                  f"({len(vocabulary) - i} word(s) left unexamined).")
            break

        # Target format only - see _existing_image(). A leftover PNG must
        # NOT make a WebP run skip the word.
        output_file = _target_path(OUTPUT_DIR / key)

        if output_file.exists() and not args.force:
            skipped += 1
            continue

        english = word_data["english"]
        category = word_data["category"]

        # No honest picture exists for "from" or "the personal pronoun 'he'".
        # Leave the image blank rather than draw a decorative child in a
        # field - the same call already made for audio. --all-words overrides
        # this if you want to see what it would have drawn.
        # A contributor's photo outranks anything this script would draw,
        # and outranks the blank-by-design rule below. Skip the key whole:
        # no generate, no delete, no counting it as missing.
        if key in protected_keys:
            protected_skipped += 1
            continue

        # v1.24.5 — Dr. Sama: "all words and numbers basically everything
        # should have images". The default is now to draw for every entry.
        # The earlier call was to leave grammar words blank rather than show
        # a child in a field captioned "from"; --only-depictable restores
        # that if the drawings turn out worse than nothing.
        # THE SAFETY GATE IS NOT OPTIONAL AND RUNS FIRST.
        #
        # Everything below used to sit behind --only-depictable, which has
        # defaulted to OFF since Dr. Sama asked for every word to have an
        # image. That made is_illustratable() dead code in a normal run -
        # and _ADULT_ENTRY lives inside it. So the whole nudity gate I added
        # today never executed once, and "be naked" was redrawn as a topless
        # woman on the very next run after I reported it fixed.
        #
        # Whether a grammar word gets a picture is a preference, and keeps
        # its flag. Whether a children's app draws a nude is not a
        # preference. This check is unconditional.
        # Run the gate on the TYPO-CORRECTED gloss. The dictionary spells it
        # "menstration", which _ADULT_ENTRY's "menstruat\w*" does not match,
        # so it sailed through on the very test that caught "be naked".
        if _ADULT_ENTRY.search(fix_gloss_typos((english or "").lower())):
            not_depictable += 1
            stale = _existing_image(OUTPUT_DIR / key)
            if stale is not None:
                try:
                    stale.unlink()
                    print(f"  removed unsafe image for {english[:40]!r}")
                except Exception as exc:
                    print(f"  ! could not remove {stale.name}: {exc}")
            continue

        # ON BY DEFAULT since 2026-10-08. --draw-everything turns it off.
        #
        # This morning Dr. Sama asked for every word to have an image, so
        # the check was made opt-in. Every white-person card he has found
        # since has been a word this check would have stopped:
        #
        #   "the personal pronoun 'he'; the personal pronoun 'she'"
        #     -> prompt: "the personal pronoun, personal pronoun clearly
        #        visible in the picture"
        #     -> a red-haired woman and two boys at laptops
        #
        # There is no person in that prompt to attach a skin tone to, and no
        # object either, so SDXL invents a scene and invents the people in
        # it. The same words produced the grid of random cars for "he" and
        # the jumble for "that". A blank card teaches nothing; a classroom
        # of white Europeans captioned with an Awing pronoun teaches
        # something worse.
        # DRAW EVERYTHING. Dr. Sama, restating it after I had gated the
        # grammar words out: "every work must have an image still stand. it
        # must not be human but has the object in the image match the word.
        # any human in any image must be black or brown."
        #
        # So the answer to "the personal pronoun 'he'" drawing a classroom
        # of white Europeans is NOT to skip the word. It is to give the word
        # a real picture made of OBJECTS - see the grammar-word overrides.
        # A pronoun has a picture: a hand pointing at a near calabash is
        # "this", the same hand pointing at a far one is "that". Skipping is
        # what I reached for because it was easy; it is not what was asked.
        #
        # --only-depictable restores the skip for anyone who wants it. The
        # adult gate above is separate and stays unconditional.
        if getattr(args, "only_depictable", False) and \
                not is_illustratable(english, category):
            not_depictable += 1
            # Skipping is not enough. These entries ALREADY have an image on
            # disk from earlier runs - the child-in-a-field drawn for "from"
            # and "the personal pronoun 'he'". Leaving it there means the
            # pack still ships it and the decision to go blank is undone
            # silently. Remove any existing image for this key.
            stale = _existing_image(OUTPUT_DIR / key)
            if stale is not None:
                try:
                    stale.unlink()
                    removed_stale += 1
                except OSError as exc:
                    print(f"    ! could not remove stale {stale.name}: {exc}")
            continue

        # Numerals never touch the diffusion model - see
        # generate_counting_image(). Exact count by construction.
        count = parse_count(english)
        if count is not None:
            if generate_counting_image(count, english, category,
                                       output_file, key):
                generated += 1
                counted += 1
            else:
                # Do NOT fall through to the diffusion model - it cannot
                # count, and a number card with the wrong number of things
                # on it is worse than no card. Leave it blank.
                failed += 1
                print(f"    ! could not compose counting card for "
                      f"{english!r} ({count}) - left blank")
            continue

        used_ai = False

        # Try GPU AI generation first
        if use_ai:
            prompt = get_ai_prompt(english, category, key)
            seed = int(hashlib.md5(prompt.encode()).hexdigest()[:8], 16) % 2**31

            ai_img = generate_ai_image(
                prompt, seed, get_negative_prompt(prompt, category))

            # Housekeeping every 200 images. Cheap, and it keeps the
            # allocator from fragmenting its way into the failure above.
            if generated and generated % 200 == 0:
                try:
                    import torch as _t
                    _t.cuda.empty_cache()
                except Exception:
                    pass

            ai_attempts += 1

            if ai_img == "OOM":
                # The GPU ran out of memory, twice, after freeing the cache.
                # That is a fact about the machine, not about this word.
                # Writing the emoji fallback here would bake a wrong picture
                # into the pack and look finished - a run that OOM'd on 300
                # words would ship 300 emoji with nothing to distinguish
                # them from a deliberate choice. Leave whatever is on disk
                # and record the key so the run can be finished later.
                oom_keys.append(key)
                used_ai = True          # suppress the emoji fallback below
                continue

            if ai_img:
                if finalize_image(ai_img, category, output_file):
                    generated += 1
                    ai_hits += 1
                    used_ai = True
                    if generated % 50 == 0 or generated <= 3:
                        elapsed = time.time() - start_time
                        rate = generated / elapsed if elapsed > 0 else 0
                        remaining = (len(items) - skipped - generated) / rate if rate > 0 else 0
                        print(f"  [{generated:4d}/{len(vocabulary)}] {english:30} (GPU) "
                              f"[{rate:.1f} img/s, ~{remaining/60:.0f}m left]")

        # ABORT if the GPU is producing nothing at all.
        #
        # Three separate full runs today each produced 0 AI images and
        # thousands of files anyway - twice from a real CUDA OOM, once from
        # a bug of mine that dropped the save branch so every image was
        # generated correctly and thrown away. In all three the run said
        # "Generation complete". Whatever the cause, 20 attempts with no
        # output means something is broken, and continuing for another
        # 5,400 words only makes the mess bigger.
        if use_ai and ai_attempts >= 20 and ai_hits == 0:
            print()
            print("ABORTING: 20 GPU attempts, 0 images saved.")
            print("  Something is wrong with generation, not with the words.")
            print("  Nothing further will be written. Check the errors above,")
            print("  or run the one-image probe:")
            print("    python scripts/generate_images.py test")
            sys.exit(1)

        # Fall back to emoji - ONLY when asked for.
        #
        # 2026-10-08: a GPU failure early in a full run sent 5,314 of 5,445
        # words down this path and the pack silently became Twemoji on
        # gradient squares. Right filenames, right folder, "Generation
        # complete". Nothing said it had happened.
        #
        # Mirrors the v1.24.0 audio decision: a word with no native
        # recording is left SILENT rather than given a synthetic voice. A
        # word the GPU could not draw is left with no image rather than a
        # generic emoji. hasImageSync() filters an image-less word out of
        # games and quizzes, so a gap is safe - and a gap is VISIBLE, where
        # an emoji looks like somebody's decision.
        if not used_ai and emoji_fallback:
            if generate_emoji_image(english, category, output_file):
                generated += 1
                emoji_used += 1
                if generated % 50 == 0 or (use_ai and emoji_used <= 3):
                    print(f"  [{generated:4d}/{len(vocabulary)}] {english:30} (emoji fallback)")
            else:
                failed += 1
        elif not used_ai:
            failed += 1

    elapsed = time.time() - start_time
    print(f"\nGeneration complete in {elapsed:.0f}s ({elapsed/60:.1f} min):")
    print(f"  Generated: {generated}")
    print(f"  Skipped:   {skipped} (existing)")
    if protected_skipped:
        print(f"  Contributed: {protected_skipped} (a native speaker's "
              f"approved photo - left untouched)")
    print(f"  No image:  {not_depictable} (nothing depictable - "
          f"grammar words, markers; left blank on purpose)")
    if removed_stale:
        print(f"  Removed:   {removed_stale} stale image(s) for entries that "
              f"are now left blank")
    print(f"  Failed:    {failed}")
    if counted:
        print(f"  Counted:   {counted} (numerals composed exactly, no GPU)")
    if use_ai:
        print(f"  AI images: {ai_hits}")
        print(f"  Emoji:     {emoji_used} (AI failed)")
    if oom_keys:
        _oom_file = os.path.join("contributions", "oom_keys.txt")
        try:
            os.makedirs("contributions", exist_ok=True)
            with open(_oom_file, "w", encoding="utf-8") as fh:
                fh.write("\n".join(oom_keys) + "\n")
        except Exception as exc:
            print(f"  ! could not write {_oom_file}: {exc}")
        print(f"  GPU OUT OF MEMORY on {len(oom_keys)} words. These were "
              f"SKIPPED, not drawn and not given an emoji.")
        print(f"  Keys written to {_oom_file}. Finish them with:")
        print(f"      python scripts/generate_images.py generate --force "
              f"--format webp --keys-file {_oom_file}")
    if generated > 0:
        print(f"  Speed:     {generated / elapsed:.1f} images/second")
    print(f"  Output:    {OUTPUT_DIR}")


def cmd_test(args):
    """Generate a few test images to verify GPU pipeline works."""
    test_words = [
        ("elephant", "animals"),
        ("banana", "food"),
        ("house", "things"),
        ("happy", "descriptive"),
        ("mother", "family"),
    ]

    print("Generating 5 test images to verify GPU pipeline...\n")

    pipe = load_pipeline()
    if pipe is None:
        print("GPU not available. Cannot run test.")
        return

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    for english, category in test_words:
        prompt = get_ai_prompt(english, category, english)
        negative = get_negative_prompt(prompt, category)
        seed = int(hashlib.md5(prompt.encode()).hexdigest()[:8], 16) % 2**31
        output_file = _target_path(OUTPUT_DIR / f"_test_{english}")

        print(f"  Generating: {english} ...")
        start = time.time()
        img = generate_ai_image(prompt, seed, negative)
        elapsed = time.time() - start

        if img:
            finalize_image(img, category, output_file)
            print(f"    OK ({elapsed:.1f}s) -> {output_file.name}")
        else:
            print(f"    FAILED ({elapsed:.1f}s)")

    print(f"\nTest images saved to: {OUTPUT_DIR}")
    print(f"Check _test_*.{OUTPUT_FORMAT} files to verify quality "
          f"before generating all images.")


def cmd_list(args):
    """List status of generated images across all 4 namespaces."""
    words = parse_vocabulary()
    phrases = parse_phrases()
    sentences = parse_sentences()
    stories = parse_stories()

    if not words:
        print("ERROR: No vocabulary found")
        sys.exit(1)

    def _status(label: str, source: dict) -> None:
        if not source:
            print(f"  {label:12}: (none)")
            return
        existing = sum(1 for k in source if _existing_image(OUTPUT_DIR / k))
        print(f"  {label:12}: {existing:4}/{len(source):4}  ({len(source) - existing} missing)")

    print(f"Image Status (by namespace):")
    _status("Words",     words)
    _status("Phrases",   phrases)
    _status("Sentences", sentences)
    _status("Stories",   stories)

    total_source = len(words) + len(phrases) + len(sentences) + len(stories)
    total_generated = (
        sum(1 for k in words     if _existing_image(OUTPUT_DIR / k))
        + sum(1 for k in phrases   if _existing_image(OUTPUT_DIR / k))
        + sum(1 for k in sentences if _existing_image(OUTPUT_DIR / k))
        + sum(1 for k in stories   if _existing_image(OUTPUT_DIR / k))
    )
    print(f"\nTotal: {total_generated}/{total_source} images generated "
          f"({total_source - total_generated} missing)")

    categories = {}
    for word_data in words.values():
        cat = word_data["category"]
        categories[cat] = categories.get(cat, 0) + 1

    print(f"\nWord categories:")
    for cat in sorted(categories):
        count = categories[cat]
        existing = sum(1 for k, v in words.items()
                       if v["category"] == cat and _existing_image(OUTPUT_DIR / k))
        print(f"  {cat:15} : {existing:4}/{count:4}")

    print(f"\nImage source: SDXL Turbo (local GPU)")

    # Check GPU availability
    try:
        import torch
        if torch.cuda.is_available():
            gpu = torch.cuda.get_device_name(0)
            vram = torch.cuda.get_device_properties(0).total_memory / (1024**3)
            print(f"GPU: {gpu} ({vram:.1f} GB VRAM) - READY")
        else:
            print("GPU: CUDA not available - will use emoji fallback")
    except ImportError:
        print("GPU: diffusers not installed - will use emoji fallback")

    if EMOJI_CACHE_DIR.exists():
        cached = len(list(EMOJI_CACHE_DIR.glob("*.png")))
        print(f"Emoji cache: {cached} files")


def _all_image_keys():
    """Every key that SHOULD have an image, across all four namespaces.

    DANGEROUS TO GET WRONG. parse_vocabulary() returns WORDS ONLY - phrases,
    sentences and stories live in their own namespaces and are merged in
    separately by cmd_generate. An orphan check written against
    parse_vocabulary() alone counts all 775 phrase/sentence/story images as
    orphans and offers to delete them. Raises instead of returning a short
    set, because a silent undercount here deletes good files.
    """
    keys = parse_vocabulary()
    if not keys:
        raise RuntimeError("parse_vocabulary() returned nothing - refusing "
                           "to compute orphans from an empty word list")
    for fn in (parse_phrases, parse_sentences, parse_stories):
        part = fn() or {}
        if not part:
            raise RuntimeError(
                f"{fn.__name__}() returned nothing. Either the data file "
                f"moved or the parser broke. Refusing to continue - every "
                f"image in that namespace would look like an orphan.")
        keys.update(part)
    return keys


def cmd_prune(args):
    """Delete images that no longer correspond to a vocabulary entry.

    Two kinds, both of which survive a regeneration untouched because the
    generate loop only ever writes keys it is currently producing:

      ORPHANS  the entry was deleted or its gloss edited, so the old
               filename matches nothing. 484 of these, left behind by the
               duplicate removal and gloss edits.
      BLANKS   the entry is now classed unillustratable, so nothing will be
               written for it - but the old decorative picture is still
               sitting there ("from" drawn as a child in a field).

    Dry run unless --yes is passed.
    """
    if not OUTPUT_DIR.is_dir():
        print(f"Image dir not found: {OUTPUT_DIR}")
        return

    try:
        keys = _all_image_keys()
    except RuntimeError as exc:
        print(f"ABORT: {exc}")
        sys.exit(1)

    files = [f for f in OUTPUT_DIR.iterdir()
             if f.is_file() and f.suffix.lower() in IMAGE_EXTENSIONS]
    by_stem = {}
    for f in files:
        by_stem.setdefault(f.stem, []).append(f)

    # A photo a native speaker submitted and Dr. Sama approved is NEVER
    # deleted by this command, even when its key has gone out of the
    # vocabulary. The generate loop has honoured this list since v1.24.5
    # (protected_keys, below in cmd_generate) but prune did not, and prune
    # is the destructive one.
    #
    # It matters most right after a duplicate merge: apply_contributions.py
    # installs one contributor's photo under EVERY gloss of that spelling,
    # so collapsing eight `tsentə` rows into one turns seven contributed
    # copies into orphans. Deleting them would throw away a person's work
    # to reclaim a few hundred KB.
    _protected = _contributed_keys()
    orphans = {st for st in by_stem
               if st not in keys and _strip_ext(st) not in _protected}
    _kept_contributed = sum(1 for st in by_stem
                            if st not in keys and _strip_ext(st) in _protected)
    blanks = {st for st in by_stem
              if st in keys
              and not is_illustratable(keys[st]["english"], keys[st]["category"])}

    doomed = sorted(orphans | blanks)
    doomed_files = [f for st in doomed for f in by_stem[st]]
    mb = sum(f.stat().st_size for f in doomed_files) / 1024 / 1024

    print(f"Image dir : {OUTPUT_DIR}")
    print(f"On disk   : {len(files)} files, {len(by_stem)} stems")
    print(f"Expected  : {len(keys)} keys across words/phrases/sentences/stories")
    print()
    print(f"  orphans (no entry at all)        {len(orphans):5}")
    if _kept_contributed:
        print(f"  contributed, protected from prune{_kept_contributed:5}")
    print(f"  blanks  (entry now unillustratable) {len(blanks):5}")
    print(f"  ----------------------------------------")
    print(f"  to delete                        {len(doomed_files):5} files, "
          f"{mb:.1f} MB")
    print()

    # A parser regression would show up here as a wildly high number. Make
    # the operator confirm rather than silently gutting the pack.
    share = len(doomed) / max(1, len(by_stem))
    if share > 0.25 and not args.force:
        print(f"REFUSING: that is {share:.0%} of the pack. This usually means "
              f"a parser broke,\n  not that the images are really stale. "
              f"Re-run with --force if you are sure.")
        sys.exit(1)

    listing = Path(SCRIPT_DIR) / "images_to_delete.txt"
    listing.write_text("\n".join(f.name for f in doomed_files) + "\n",
                       encoding="utf-8")
    print(f"Wrote the exact list to {listing}")

    if not args.yes:
        print()
        print("DRY RUN - nothing deleted. Examples:")
        for f in doomed_files[:15]:
            why = "orphan" if f.stem in orphans else "blank"
            print(f"   [{why}] {f.name}")
        print()
        print("Re-run with --yes to delete.")
        return

    ok = failed = 0
    for f in doomed_files:
        try:
            f.unlink()
            ok += 1
        except OSError as exc:
            print(f"  ! {f.name}: {exc}")
            failed += 1
    print(f"Deleted {ok} file(s), {failed} failed. "
          f"{len(files) - ok} image(s) remain.")


def cmd_clean(args):
    """Remove generated images."""
    count = 0
    if OUTPUT_DIR.exists():
        for ext in IMAGE_EXTENSIONS:
            for f in OUTPUT_DIR.glob(f"*{ext}"):
                if f.name != ".gitkeep":
                    f.unlink()
                    count += 1
    print(f"Cleaned {count} images from {OUTPUT_DIR}")

    if args.cache:
        for cache_dir in [EMOJI_CACHE_DIR]:
            cache_count = 0
            if cache_dir.exists():
                for f in cache_dir.glob("*.png"):
                    f.unlink()
                    cache_count += 1
            print(f"Cleaned {cache_count} cached files from {cache_dir}")


# ============================================================
# AUTO-VENV ACTIVATION
# ============================================================

def ensure_venv():
    """Auto-activate venv if not already active."""
    if sys.prefix != sys.base_prefix:
        return
    venv_dir = SCRIPT_DIR.parent / "venv"
    if venv_dir.exists():
        venv_python = venv_dir / ("Scripts" if sys.platform == "win32" else "bin") / ("python.exe" if sys.platform == "win32" else "python")
        if venv_python.exists():
            import subprocess
            result = subprocess.run([str(venv_python), __file__] + sys.argv[1:])
            sys.exit(result.returncode)


# ============================================================
# MAIN
# ============================================================

def main():
    # All module-level knobs main() can rebind, declared up front - the help
    # strings below READ them, and Python forbids a `global` after a read.
    global OUTPUT_DIR, INFERENCE_STEPS, GUIDANCE_SCALE
    global OUTPUT_FORMAT, OUTPUT_QUALITY
    ensure_venv()

    parser = argparse.ArgumentParser(
        description="Generate vocabulary images for Awing AI Learning (GPU AI + emoji)"
    )
    parser.add_argument("--output-dir", type=str, default=None,
                        help="Override image output directory")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")

    gen_parser = subparsers.add_parser("generate", help="Generate vocabulary images")
    gen_parser.add_argument("--category",
                            help="Generate for specific categories only "
                                 "(comma-separated). "
                                 "Example: --category=body,actions,family")
    gen_parser.add_argument("--force", action="store_true", help="Regenerate existing images")
    gen_parser.add_argument("--emoji-only", action="store_true", help="Use only emoji (skip GPU)")
    gen_parser.add_argument("--emoji-fallback", action="store_true",
                            help="When GPU generation fails, write a Twemoji "
                                 "graphic instead of leaving the word without "
                                 "an image. OFF by default since 2026-10-08: "
                                 "a CUDA OOM early in a full run turned 5,314 "
                                 "of 5,445 cards into emoji and the run still "
                                 "reported success.")
    gen_parser.add_argument("--word",
                            help="Only regenerate specific words (comma-separated). "
                                 "Matches against audio_key, Awing word, or English gloss. "
                                 "Implies --force. Examples: --word=bird  --word=sange,mbene,goat")
    gen_parser.add_argument("--format", choices=["png", "webp"], default="png",
                            help="Output image format. webp is ~4-8x smaller "
                                 "for this kind of flat art (default: png)")
    gen_parser.add_argument("--quality", type=int, default=82,
                            help="WebP quality 1-100 (default: 82)")
    gen_parser.add_argument("--keys-file",
                            help="Regenerate exactly the image keys listed in "
                                 "this file, one per line. Implies --force. "
                                 "For re-shooting a computed subset - a "
                                 "comma-separated --word list does not scale "
                                 "to hundreds of keys.")
    gen_parser.add_argument("--steps", type=int, default=None,
                            help=f"Diffusion steps (default "
                                 f"{INFERENCE_STEPS}). 1 is fast but ignores "
                                 f"the subject; 4 is why the pictures now "
                                 f"match the words.")
    gen_parser.add_argument("--guidance", type=float, default=None,
                            help=f"Guidance scale (default {GUIDANCE_SCALE}). "
                                 f"Above 1.0 also activates the negative "
                                 f"prompt; at 0 negatives are ignored.")
    gen_parser.add_argument("--all-words", action="store_true",
                            help=argparse.SUPPRESS)  # now the default; kept
                            # so older invocations keep working
    gen_parser.add_argument("--draw-everything", action="store_true",
                            help="Draw even entries with nothing depictable "
                                 "(prepositions, pronouns, grammar markers). "
                                 "OFF by default: those prompts have no "
                                 "subject, so SDXL invents a scene and "
                                 "invents the people in it - every "
                                 "white-person card found on 2026-10-08 was "
                                 "one of these.")
    gen_parser.add_argument("--only-depictable", action="store_true",
                            help="Leave entries with nothing depictable "
                                 "(prepositions, pronouns, grammatical "
                                 "markers) without an image. This was the "
                                 "default until v1.24.5.")
    gen_parser.add_argument("--limit", type=int, default=None,
                            help="Stop after N images. For sampling a prompt "
                                 "change before committing hours of GPU.")
    gen_parser.set_defaults(func=cmd_generate)

    test_parser = subparsers.add_parser("test", help="Generate 5 test images")
    test_parser.set_defaults(func=cmd_test)

    list_parser = subparsers.add_parser("list", help="Show generation status")
    list_parser.set_defaults(func=cmd_list)

    prune_parser = subparsers.add_parser(
        "prune", help="Delete orphan / now-blank images (dry run by default)")
    prune_parser.add_argument("--yes", action="store_true",
                              help="Actually delete. Without it, dry run.")
    prune_parser.add_argument("--force", action="store_true",
                              help="Proceed even if the list exceeds 25%% of "
                                   "the pack (normally a sign a parser broke)")
    prune_parser.set_defaults(func=cmd_prune)

    clean_parser = subparsers.add_parser("clean", help="Remove generated images")
    clean_parser.add_argument("--cache", action="store_true", help="Also clear emoji cache")
    clean_parser.set_defaults(func=cmd_clean)

    args = parser.parse_args()

    # Override output directory if specified
    if args.output_dir:
        OUTPUT_DIR = Path(args.output_dir)
    if getattr(args, "steps", None):
        INFERENCE_STEPS = args.steps
    if getattr(args, "guidance", None) is not None:
        GUIDANCE_SCALE = args.guidance
    if args.command == "generate":
        print(f"Inference: {INFERENCE_STEPS} steps, guidance {GUIDANCE_SCALE}")
    if getattr(args, "format", None):
        OUTPUT_FORMAT = args.format
        OUTPUT_QUALITY = args.quality
        print(f"Output format: {OUTPUT_FORMAT}"
              + (f" (quality {OUTPUT_QUALITY})" if OUTPUT_FORMAT == "webp" else ""))

    if not args.command:
        parser.print_help()
        sys.exit(1)

    args.func(args)


if __name__ == "__main__":
    main()
