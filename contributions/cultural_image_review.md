# Cultural image review — items that still get a generic cartoon

Generated 2026-10-04 by scripts/generate_images.py analysis.
**296 entries.**

## Why this file exists

Achu was the example. `scripts/generate_images.py` was drawing it as a
generic bowl of pale mush, because the prompt was built from the English
gloss alone. Once Dr. Sama supplied the reference — pounded cocoyam
(taro) shaped on a plate with a crater of yellow palm-oil soup — the
whole achu/cocoyam cluster could be given accurate prompts.

No amount of style tuning fixes this class of problem. Each locally
specific item needs someone who knows it to describe what it looks like.
That is this list.

## Update 2026-10-05 — read this first

Working through this list showed that most of it was not a culture
problem at all. Three mechanical defects in the prompt builder accounted
for the bulk of the bad pictures, and all three are now fixed in
`scripts/generate_images.py`:

1. **Truncated glosses (248 entries).** The 6-word cap cut mid-phrase,
   so SDXL was asked for "a sort of white substance from" and
   "men dance group led by an". A dangling preposition asks for a
   relationship whose object was cut off, and the model invents one.
   The shortener now trims back to the last content word.

2. **Ghanaian clothing (192 entries).** One of the persona outfits was
   "bright kente-pattern cloth". Kente is Ashanti and Ewe — Ghana,
   about 1,000 km west of Awing. It is now **toghu**: black velvet
   embroidered in red and white, the regalia of the Bamenda Grassfields.

3. **Entries with no honest picture (68 entries).** "verb stem of
   chaakə̌" was being drawn as a cartoon of that literal string; so were
   glosses left in Awing, and named local institutions like "Women dance
   group based in Tame Tangwing's compound" — one specific group, several
   of them defunct. These now get no image at all, which is the same
   call already made for "from" and "the pronoun he".

**492 images are queued for regeneration** in
`contributions/regen_keys_v1240b.txt`, with the reason beside each key.

### What is still genuinely yours to answer

A much shorter list than 296. The rows below that remain are the ones
where the English gloss is fine and drawable but the *thing* is local
and a generic cartoon would be wrong: raffia baskets, bamboo chairs and
cupboards, gourds, the peace plant, achu equipment. Those still need a
description from someone who knows them — nothing in a prompt builder
can supply it.

There is no deadline on this. The app ships without it; a generic basket
is a weak picture, not a wrong one, and the confidently-wrong class is
what is now gone.

## How to use it

Only fill in the rows that are actually WRONG. A plain cartoon basket is
a fine picture of a basket; an Awing raffia basket drawn as a European
wicker hamper is not. Write what the thing looks like, plainly, as if
describing it to someone who has never seen one:

    - shape, colour, material
    - how it is used or held, if that identifies it
    - what it is NOT, if there is an obvious wrong guess

Add the description in the **Should look like** column. Anything left
blank keeps its current prompt.

These become `PROMPT_OVERRIDES` entries keyed on the **Prompt key**
column, exactly as the achu ones were.

## Counts by category

| category | entries |
|---|---|
| things | 180 |
| nature | 33 |
| family | 18 |
| body | 17 |
| actions | 15 |
| descriptive | 15 |
| food | 12 |
| animals | 5 |
| numbers | 1 |


## actions

| English gloss | Prompt key | Currently drawn as | Should look like |
|---|---|---|---|
| a Njom dance group which is no longer active | `a njom dance group which is` | a Cameroonian little girl with rich dark skin, two puff buns, wearing a simple bright t-shirt,  | |
| a sort of dance for twins | `a sort of dance for twins` | a Cameroonian grandfather with warm brown skin, short grey hair, wearing a colorful Ankara prin | |
| be crowned, take title of a noble through a ceremony in the palace | `be crowned` | a Cameroonian man with dark brown skin, short natural afro hair, wearing bright kente-pattern c | |
| dance for twins | `dance for twins` | a Cameroonian little boy with deep brown skin, a neatly shaved head, wearing a plain school uni | |
| dance group of veiled men | `dance group of veiled men` | a Cameroonian young boy with warm brown skin, long locs, wearing a simple bright t-shirt, doing | |
| dress of the same pattern used to identify people of the same group eg | `dress of the same pattern used` | a Cameroonian young boy with warm brown skin, a neatly shaved head, wearing a simple bright t-s | |
| harvest fruits with impunity | `harvest fruits with impunity` | a Cameroonian teenage boy with warm brown skin, short twists, wearing a plain school uniform, d | |
| harvest with impunity | `harvest with impunity` | a Cameroonian grandfather with dark brown skin, grey-flecked short afro hair, wearing bright ke | |
| large maggot-like insect that grows in rotting raffia palm | `large maggot-like insect that grows in` | a Cameroonian little girl with rich dark skin, cornrow braids, wearing a simple bright t-shirt, | |
| music; dance | `music` | a Cameroonian grandfather with warm brown skin, short grey hair, wearing a colorful Ankara prin | |
| open gourd | `open gourd` | a Cameroonian young girl with deep brown skin, short natural afro hair, wearing a colorful Anka | |
| pay dowry; marry | `pay dowry` | a Cameroonian young boy with rich dark skin, a high-top afro, wearing a colorful Ankara print s | |
| pound (with mortar) | `pound` | a Cameroonian little girl with warm brown skin, braided hair with colorful beads, wearing a col | |
| sacrifice to the dead | `sacrifice to the dead` | a Cameroonian young boy with dark brown skin, a neatly shaved head, wearing a simple bright t-s | |
| take title of nobleship | `take title of nobleship` | a Cameroonian young girl with dark brown skin, a bright patterned head wrap, wearing a plain sc | |

## animals

| English gloss | Prompt key | Currently drawn as | Should look like |
|---|---|---|---|
| Half horn of a cow used for drilling blood or pus from the | `half horn of a cow used` | a cute cartoon half horn of a cow used animal | |
| crow, of rooster; blow, of horn | `crow` | a cute cartoon crow animal | |
| horn of animals; flute made from a goat's horn | `horn of animals` | a cute cartoon horn of animals animal | |
| maggot-like insect in raffia palm | `maggot-like insect in raffia palm` | a cute cartoon maggot-like insect in raffia palm animal | |
| men dance group led by an elephant-like masked person | `men dance group led by an` | a cute cartoon Cameroonian dark brown skin men dance group led by an animal, a neatly shaved he | |

## body

| English gloss | Prompt key | Currently drawn as | Should look like |
|---|---|---|---|
| A sort of wild grass that grows in the farm, it spreads around the sto | `a sort of wild grass that` | a Cameroonian grandmother with dark brown skin, grey cornrow braids, wearing a bright headscarf | |
| a ceremony in memory of somebody who died; remembrance | `a ceremony in memory of somebody` | a Cameroonian grandmother with warm brown skin, a bright patterned head wrap over grey hair, we | |
| a knife used for tapping raffia palm | `a knife used for tapping raffia` | a Cameroonian young boy with rich dark skin, long locs, wearing a colorful Ankara print shirt,  | |
| a sort of thread produced from raffia palm stumps | `a sort of thread produced from` | a Cameroonian man with rich dark skin, long locs, wearing bright kente-pattern cloth, showing t | |
| bamboo-skin (often fresh) used as rope | `bamboo-skin used as rope` | a Cameroonian man with warm brown skin, a high-top afro, wearing a colorful Ankara print shirt, | |
| clean the furrows of a farm bed a little using a hoe | `clean the furrows of a farm` | a Cameroonian man with warm brown skin, short twists, wearing bright kente-pattern cloth, showi | |
| clean the furrows of a farm bed thoroughly | `clean the furrows of a farm` | a Cameroonian young girl with deep brown skin, a bright patterned head wrap, wearing a colorful | |
| farm bed | `farm bed` | a Cameroonian young girl with deep brown skin, cornrow braids, wearing a plain school uniform,  | |
| kind of bag used to carry products from the farm | `kind of bag used to carry` | a Cameroonian teenage boy with deep brown skin, short twists, wearing a colorful Ankara print s | |
| large bed of farm formed by putting soil on compost | `large bed of farm formed by` | a Cameroonian little boy with dark brown skin, a high-top afro, wearing a colorful Ankara print | |
| scare away shouting eg of animals or birds in a farm; yell out curses  | `scare away shouting` | a Cameroonian little girl with rich dark skin, braided hair with colorful beads, wearing a colo | |
| somebody who investigates issues and report to the fon | `somebody who investigates issues and report` | a Cameroonian grandmother with rich dark skin, short grey afro hair, wearing a bright headscarf | |
| steal palm wine from another person's palm bush | `steal palm wine from another person's` | a Cameroonian grandfather with rich dark skin, grey-flecked short afro hair, wearing a colorful | |
| steal, of palm wine | `steal` | a Cameroonian grandmother with rich dark skin, grey cornrow braids, wearing a colorful Ankara p | |
| sweet palm wine, very | `sweet palm wine` | a Cameroonian teenage girl with warm brown skin, cornrow braids, wearing a plain school uniform | |
| very sweet palm wine | `very sweet palm wine` | a Cameroonian teenage boy with deep brown skin, a neatly shaved head, wearing a plain school un | |
| yeast, the substance that makes raffia palm turn alchoholic | `yeast` | a Cameroonian man with deep brown skin, short twists, wearing a plain work shirt, showing their | |

## descriptive

| English gloss | Prompt key | Currently drawn as | Should look like |
|---|---|---|---|
| A dance group in Njom | `a dance group in njom` | a Cameroonian grandmother with rich dark skin, short grey afro hair, wearing a patterned wrappe | |
| A long drum | `a long drum` | a Cameroonian teenage girl with warm brown skin, cornrow braids, wearing a plain school uniform | |
| a flat covering (of door, window, hut etc.) | `a flat covering` | a Cameroonian woman with dark brown skin, braided hair with colorful beads, wearing a colorful  | |
| a kind of basket weaved using the hard covering of raffia bamboo | `a kind of basket weaved using` | a Cameroonian woman with rich dark skin, cornrow braids, wearing a colorful Ankara print dress, | |
| an open bamboo cupboard attached to the wall of the house used for put | `an open bamboo cupboard attached to` | a Cameroonian woman with warm brown skin, two puff buns, wearing a colorful Ankara print dress, | |
| bamboo cupboard, kind of | `bamboo cupboard` | a Cameroonian woman with rich dark skin, two puff buns, wearing a colorful Ankara print dress,  | |
| big drum | `big drum` | a Cameroonian young girl with warm brown skin, long twists, wearing a simple bright t-shirt, sh | |
| kind of basket weaved using soft interior of raffia bamboo | `kind of basket weaved using soft` | a Cameroonian young boy with warm brown skin, a high-top afro, wearing a simple bright t-shirt, | |
| modern wedding ceremony; sexual intercourse | `modern wedding ceremony` | a Cameroonian woman with dark brown skin, cornrow braids, wearing a colorful Ankara print dress | |
| open gourd for washing twins | `open gourd for washing twins` | a Cameroonian grandfather with warm brown skin, grey-flecked short afro hair, wearing a colorfu | |
| quarter or small unit of administration | `quarter or small unit of administration` | a Cameroonian young girl with warm brown skin, two puff buns, wearing a colorful Ankara print d | |
| sacrifice for the dead, libation | `sacrifice for the dead` | a Cameroonian young boy with rich dark skin, a neatly shaved head, wearing a colorful Ankara pr | |
| sacrifice to the dead | `sacrifice to the dead` | a Cameroonian young boy with rich dark skin, long locs, wearing a plain school uniform, showing | |
| small drum | `small drum` | a Cameroonian little boy with warm brown skin, long locs, wearing a colorful Ankara print shirt | |
| the first fon of Awing | `the first fon of awing` | a Cameroonian young boy with rich dark skin, short natural afro hair, wearing a plain school un | |

## family

| English gloss | Prompt key | Currently drawn as | Should look like |
|---|---|---|---|
| Chief Priest | `chief priest` | a Cameroonian man with deep brown skin, a neatly shaved head, wearing a colorful Ankara print s | |
| Chief Priest; High Priest | `chief priest` | a Cameroonian young girl with rich dark skin, two puff buns, wearing a simple bright t-shirt, c | |
| Chief Priest; High Priest | `chief priest` | a Cameroonian teenage girl with dark brown skin, two puff buns, wearing a plain school uniform, | |
| Women dance group based in Ta Mbah Ta's compound | `women dance group based in ta` | a Cameroonian grandmother with rich dark skin, grey cornrow braids, wearing a bright headscarf  | |
| a name used only for the fon or village chief | `a name used only for the` | a Cameroonian teenage boy with warm brown skin, short twists, wearing a colorful Ankara print s | |
| ancestor | `ancestor` | a Cameroonian grandmother with rich dark skin, a bright patterned head wrap over grey hair, wea | |
| ancestor | `ancestor` | a Cameroonian young girl with dark brown skin, two puff buns, wearing a plain school uniform, a | |
| ancestor | `ancestor` | a Cameroonian young boy with dark brown skin, a neatly shaved head, wearing a simple bright t-s | |
| flute, for rallying people | `flute` | a Cameroonian woman with deep brown skin, short natural afro hair, wearing a colorful Ankara pr | |
| fon's messenger | `fon's messenger` | a Cameroonian young girl with deep brown skin, short natural afro hair, wearing a simple bright | |
| highest point, tip, chief, headman | `highest point` | a Cameroonian young boy with rich dark skin, a high-top afro, wearing a colorful Ankara print s | |
| initiate (into secret society such as kwifon) | `initiate` | a Cameroonian young girl with deep brown skin, braided hair with colorful beads, wearing a plai | |
| name used only for fon or village chief | `name used only for fon or` | a Cameroonian teenage girl with rich dark skin, braided hair with colorful beads, wearing a sim | |
| name used only for the son or village chief | `name used only for the son` | a Cameroonian man with deep brown skin, a high-top afro, wearing a colorful Ankara print shirt, | |
| paramount fon, king, chief | `paramount fon` | a Cameroonian teenage girl with warm brown skin, two puff buns, wearing a colorful Ankara print | |
| sub-chief | `sub-chief` | a Cameroonian grandfather with warm brown skin, a bald head with grey stubble, wearing bright k | |
| title of sub-chief | `title of sub-chief` | a Cameroonian young girl with warm brown skin, short natural afro hair, wearing a colorful Anka | |
| tribe, village | `tribe` | a Cameroonian little girl with warm brown skin, short natural afro hair, wearing a simple brigh | |

## food

| English gloss | Prompt key | Currently drawn as | Should look like |
|---|---|---|---|
| A bamboo ceiling in kitchens used for drying maize, beans, potatoes | `a bamboo ceiling in kitchens used` | a cartoon a bamboo ceiling in kitchens used, West African food | |
| a raffia fruit with a hard smooth surface | `a raffia fruit with a hard` | a cartoon a raffia fruit with a hard, West African food | |
| a raffia fruit with a hard smooth surface | `a raffia fruit with a hard` | a cartoon a raffia fruit with a hard, West African food | |
| bunch of plantain | `bunch of plantain` | a cartoon bunch of plantain, West African food | |
| do without drinking palm wine because it is abundant in the village | `do without drinking palm wine because` | a cartoon do without drinking palm wine because, West African food | |
| ground corn fufu, softened with water and steamed | `ground corn fufu` | a cartoon ground corn fufu, West African food | |
| groundnut | `groundnut` | a cartoon groundnut, West African food | |
| millet (of the rainy season) | `millet` | a cartoon millet, West African food | |
| of a raffia fruit (clear its hard surface), peel raffia fruit | `of a raffia fruit` | a cartoon of a raffia fruit, West African food | |
| raffia fruit | `raffia fruit` | a cartoon raffia fruit, West African food | |
| shell(n), of groundnut | `shell` | a cartoon shell, West African food | |
| stalk (of maize, millet, etc.) | `stalk` | a cartoon stalk, West African food | |

## nature

| English gloss | Prompt key | Currently drawn as | Should look like |
|---|---|---|---|
| Traditional peace plant, planted in places of worship and used in cere | `traditional peace plant` | a cartoon traditional peace plant nature scene | |
| a kind of bag used to carry products from the farm | `a kind of bag used to` | a cartoon a kind of bag used to nature scene | |
| a long kind of basket used for carrying farm products and firewood | `a long kind of basket used` | a cartoon a long kind of basket used nature scene | |
| bed of farm, sort of | `bed of farm` | a cartoon bed of farm nature scene | |
| carved piece of wood | `carved piece of wood` | a cartoon carved piece of wood nature scene | |
| clean the furrows of a farm bed a little (using a hoe) | `clean the furrows of a farm` | a cartoon clean the furrows of a farm nature scene | |
| cola nut tree | `cola nut tree` | a cartoon cola nut tree nature scene | |
| corn cob from horn scanty number of grains | `corn cob from horn scanty number` | a cartoon corn cob from horn scanty number nature scene | |
| farm bed | `farm bed` | a cartoon farm bed nature scene | |
| farm bed (animal-related) | `farm bed` | a cartoon farm bed nature scene | |
| furrow between farm beds | `furrow between farm beds` | a cartoon furrow between farm beds nature scene | |
| indian bamboo bush | `indian bamboo bush` | a cartoon indian bamboo bush nature scene | |
| indian bamboo bush | `indian bamboo bush` | a cartoon indian bamboo bush nature scene | |
| main market day in Awing; the seventh day of the week in Awing | `main market day in awing` | a cartoon main market day in awing nature scene | |
| market day | `market day` | a cartoon market day nature scene | |
| market day, main | `market day` | a cartoon market day nature scene | |
| millet of the rainy season | `millet of the rainy season` | a cartoon millet of the rainy season nature scene | |
| millet, of the dry season | `millet` | a cartoon millet nature scene | |
| millet, of the rainy season | `millet` | a cartoon millet nature scene | |
| name used only for the fon or village chief | `name used only for the fon` | a cartoon name used only for the Cameroonian deep brown skin fon nature scene, short natural af | |
| palace assembly ground | `palace assembly ground` | a cartoon palace assembly ground nature scene | |
| peel, of raffia fruit | `peel` | a cartoon peel nature scene | |
| playground; palace assembly ground | `playground` | a cartoon playground nature scene | |
| raffia bush | `raffia bush` | a cartoon raffia bush nature scene | |
| raffia bush | `raffia bush` | a cartoon raffia bush nature scene | |
| raffia fruit, sort of | `raffia fruit` | a cartoon raffia fruit nature scene | |
| scare away by shouting eg of animals or birds in a farm | `scare away by shouting` | a cartoon scare away by shouting nature scene | |
| the fourth day of the week; day of rest and also for carrying out trad | `the fourth day of the week` | a cartoon the fourth day of the week nature scene | |
| the second day of the week and minor market day | `the second day of the week` | a cartoon the second day of the week nature scene | |
| third day of the week and minor market day | `third day of the week and` | a cartoon third day of the week and nature scene | |
| traditional juju (blesses farm during planting season) | `traditional juju` | a cartoon traditional juju nature scene | |
| use one's labour in exchange for farm products | `use one's labour in exchange for` | a cartoon use one's labour in exchange for nature scene | |
| wild grass that grows in the farm | `wild grass that grows in the` | a cartoon wild grass that grows in the nature scene | |

## numbers

| English gloss | Prompt key | Currently drawn as | Should look like |
|---|---|---|---|
| eat first fruit, ceremony | `eat first fruit` | a cartoon eat first fruit | |

## things

| English gloss | Prompt key | Currently drawn as | Should look like |
|---|---|---|---|
| A Njom dance group which is no longer active | `a njom dance group which is` | a cartoon a njom dance group which is | |
| A dance group in Njom | `a dance group in njom` | a cartoon a dance group in njom | |
| A dance group in Tame Efoomba's compound | `a dance group in tame efoomba's` | a cartoon a dance group in tame efoomba's | |
| A women dance group in Akuhle quarter, based in Tata Mofolo's compound | `a women dance group in akuhle` | a cartoon a Cameroonian deep brown skin women dance group in akuhle, two puff buns | |
| Atsəmatsamə̌ tə̌ Mbah Ta'a's compound | `atsəmatsamə̌ tə̌ mbah ta'a's compound` | a cartoon atsəmatsamə̌ tə̌ mbah ta'a's compound | |
| Indian bamboo | `indian bamboo` | a cartoon indian bamboo | |
| Traditional peace plant | `traditional peace plant` | a cartoon traditional peace plant | |
| Women dance group based in Sam Sunyewe's compound | `women dance group based in sam` | a cartoon Cameroonian rich dark skin women dance group based in sam, short natural afro hair | |
| Women dance group based in Ta Mbah Ta's compound | `women dance group based in ta` | a cartoon Cameroonian warm brown skin women dance group based in ta, a bright patterned head wr | |
| Women dance group based in Tame Tangwing's compound | `women dance group based in tame` | a cartoon Cameroonian deep brown skin women dance group based in tame, a bright patterned head  | |
| Women dance group in Njom, no longer active | `women dance group in njom, no` | a cartoon Cameroonian rich dark skin women dance group in njom, no, short natural afro hair | |
| Women dance group in Njom, no longer active, but still have their drum | `women dance group in njom, no` | a cartoon Cameroonian rich dark skin women dance group in njom, no, short natural afro hair | |
| a courtyard in the palace where the fon sits with his subjects to deba | `a courtyard in the palace where` | a cartoon a courtyard in the palace where | |
| a courtyard in the palace where the fon sits with his subjects to deli | `a courtyard in the palace where` | a cartoon a courtyard in the palace where | |
| a dance group in Tame Fonka's compound | `a dance group in tame fonka's` | a cartoon a dance group in tame fonka's | |
| a kind of basket weaved using the hard covering of raffia bamboo | `a kind of basket weaved using` | a cartoon a kind of basket weaved using | |
| a kind of basket weaved using the soft interior of raffia bamboo | `a kind of basket weaved using` | a cartoon a kind of basket weaved using | |
| a secret place, especially in the fon's palace | `a secret place` | a cartoon a secret place | |
| a secret place, especially in the fon's palace | `a secret place` | a cartoon a secret place | |
| an open bamboo cupboard | `an open bamboo cupboard` | a cartoon an open bamboo cupboard | |
| an open bamboo cupboard attached to the wall of the house used for put | `an open bamboo cupboard attached to` | a cartoon an open bamboo cupboard attached to | |
| an open gourd for washing twins | `an open gourd for washing twins` | a cartoon an open gourd for washing Cameroonian deep brown skin twins | |
| ancestor | `ancestor` | a cartoon ancestor | |
| bamboo chair | `bamboo chair` | a cartoon bamboo chair | |
| bamboo chair | `bamboo chair` | a cartoon bamboo chair | |
| bamboo chair | `bamboo chair` | a cartoon bamboo chair | |
| be crowned, take the title of a noble through a ceremony in the palace | `be crowned` | a cartoon be crowned | |
| biggest dance group in Awing based in Njom | `biggest dance group in awing based` | a cartoon biggest dance group in awing based | |
| birth ceremony | `birth ceremony` | a cartoon birth ceremony | |
| birth ceremony, naming ceremony | `birth ceremony` | a cartoon birth ceremony | |
| cain; indian bamboo ropes | `cain` | a cartoon cain | |
| cancel a set rendezvous or an arranged public ceremony | `cancel a set rendezvous or an` | a cartoon cancel a set rendezvous or an | |
| ceiling of bamboo-made | `ceiling of bamboo-made` | a cartoon ceiling of bamboo-made | |
| ceremony in memory of somebody who died; remembrance; reminder | `ceremony in memory of somebody who` | a cartoon ceremony in memory of Cameroonian warm brown skin somebody who | |
| ceremony in which the bride and groom are shaved of private parts | `ceremony in which the bride and` | a cartoon ceremony in which the Cameroonian warm brown skin bride and, long twists | |
| courtyard in the palace | `courtyard in the palace` | a cartoon courtyard in the palace | |
| courtyard in the palace where the fon sits with his | `courtyard in the palace where the` | a cartoon courtyard in the palace where the | |
| covering (of door, cupboard, car, hut, blanket etc.) | `covering` | a cartoon covering | |
| crow, of rooster, blow, of horn, cry out loud, shout | `crow` | a cartoon crow | |
| dance group in Njom, no longer active | `dance group in njom` | a cartoon dance group in njom | |
| dowry | `dowry` | a cartoon dowry | |
| dowry | `dowry` | a cartoon dowry | |
| dowry | `dowry` | a cartoon dowry | |
| dowry (v) | `dowry` | a cartoon dowry | |
| drum musical instrument | `drum musical instrument` | a cartoon drum musical instrument | |
| egusi | `egusi` | a cartoon egusi | |
| flat covering of door, window, hut | `flat covering of door` | a cartoon flat covering of door | |
| flute, sort of | `flute` | a cartoon flute | |
| fon | `fon` | a cartoon Cameroonian warm brown skin fon, short twists | |
| fon of Awing, the 10th | `fon of awing` | a cartoon Cameroonian dark brown skin fon of awing, short natural afro hair | |
| fon of Awing, the 11th | `fon of awing` | a cartoon Cameroonian dark brown skin fon of awing, long locs | |
| fon of Awing, the 12th | `fon of awing` | a cartoon Cameroonian warm brown skin fon of awing, a high-top afro | |
| fon of Awing, the 13th | `fon of awing` | a cartoon Cameroonian warm brown skin fon of awing, a high-top afro | |
| fon of Awing, the 1st | `fon of awing` | a cartoon Cameroonian deep brown skin fon of awing, a neatly shaved head | |
| fon of Awing, the 2nd | `fon of awing` | a cartoon Cameroonian dark brown skin fon of awing, short natural afro hair | |
| fon of Awing, the 3rd | `fon of awing` | a cartoon Cameroonian warm brown skin fon of awing, a neatly shaved head | |
| fon of Awing, the 4th | `fon of awing` | a cartoon Cameroonian dark brown skin fon of awing, a neatly shaved head | |
| fon of Awing, the 5th | `fon of awing` | a cartoon Cameroonian dark brown skin fon of awing, long locs | |
| fon of Awing, the 6th | `fon of awing` | a cartoon Cameroonian warm brown skin fon of awing, short twists | |
| fon of Awing, the 7th | `fon of awing` | a cartoon Cameroonian warm brown skin fon of awing, a high-top afro | |
| fon of Awing, the 8th | `fon of awing` | a cartoon Cameroonian dark brown skin fon of awing, short natural afro hair | |
| fon of Awing, the 9th | `fon of awing` | a cartoon Cameroonian rich dark skin fon of awing, a high-top afro | |
| fon's investigator | `fon's investigator` | a cartoon Cameroonian dark brown skin fon's investigator, short twists | |
| fon's messenger | `fon's messenger` | a cartoon Cameroonian warm brown skin fon's messenger, short natural afro hair | |
| fon's name (fon of the palace) | `fon's name` | a cartoon Cameroonian warm brown skin fon's name, long locs | |
| fon; highest ruler in a land | `fon` | a cartoon Cameroonian rich dark skin fon, short natural afro hair | |
| fourth fon of Awing | `fourth fon of awing` | a cartoon fourth Cameroonian rich dark skin fon of awing, a neatly shaved head | |
| garri (food made from cassava) | `garri` | a cartoon garri | |
| god; ancestor | `god` | a cartoon god | |
| good corn fufu, sieves are of different kinds | `good corn fufu` | a cartoon good corn fufu | |
| gourd | `gourd` | a cartoon gourd | |
| groundnut | `groundnut` | a cartoon groundnut | |
| home, village; tribe | `home` | a cartoon home | |
| horn of animals | `horn of animals` | a cartoon horn of animals | |
| host, owner of compound | `host` | a cartoon host | |
| host, owner of the compound | `host` | a cartoon host | |
| hut built for collecting termite | `hut built for collecting termite` | a cartoon hut built for collecting termite | |
| in this compound, this place, here (nominal) | `in this compound` | a cartoon in this compound | |
| in this compound, this place, here (nominal) | `in this compound` | a cartoon in this compound | |
| indian bamboo | `indian bamboo` | a cartoon indian bamboo | |
| indian bamboo | `indian bamboo` | a cartoon indian bamboo | |
| indian bamboo bush | `indian bamboo bush` | a cartoon indian bamboo bush | |
| indian bamboo bush | `indian bamboo bush` | a cartoon indian bamboo bush | |
| indian bamboo ropes | `indian bamboo ropes` | a cartoon indian bamboo ropes | |
| indian bamboo ropes | `indian bamboo ropes` | a cartoon indian bamboo ropes | |
| juju, traditional | `juju` | a cartoon juju | |
| knife for tapping raffia palm | `knife for tapping raffia palm` | a cartoon knife for tapping raffia palm | |
| main market day in Awing | `main market day in awing` | a cartoon main market day in awing | |
| mark of identification; ritual scar | `mark of identification` | a cartoon mark of identification | |
| marriage ceremony, sort of | `marriage ceremony` | a cartoon marriage ceremony | |
| masquerader, dance group | `masquerader` | a cartoon masquerader | |
| masquerader, dance group uniquely made up of men and totally veiled | `masquerader` | a cartoon masquerader | |
| masqueraders based in Tame Mbah Ako's compound | `masqueraders based in tame mbah ako's` | a cartoon masqueraders based in tame mbah ako's | |
| masqueraders based in Tame Ndong's compound, no longer active | `masqueraders based in tame ndong's compound,` | a cartoon masqueraders based in tame ndong's compound, | |
| masquerades based in Tame Mbah Ako's compound | `masquerades based in tame mbah ako's` | a cartoon masquerades based in tame mbah ako's | |
| masquerades based in Tame Ndong's compound, no longer active | `masquerades based in tame ndong's compound,` | a cartoon masquerades based in tame ndong's compound, | |
| medical instrument, traditional | `medical instrument` | a cartoon medical instrument | |
| medicine man, traditional healer | `medicine man` | a cartoon medicine Cameroonian rich dark skin man, short twists | |
| medicine man, traditional healer | `medicine man` | a cartoon medicine Cameroonian warm brown skin man, a high-top afro | |
| medium sized drum | `medium sized drum` | a cartoon medium sized drum | |
| medium sized drum | `medium sized drum` | a cartoon medium sized drum | |
| musical instrument made from a horn | `musical instrument made from a horn` | a cartoon musical instrument made from a horn | |
| musical instrument made from a horn | `musical instrument made from a horn` | a cartoon musical instrument made from a horn | |
| name of a quarter in Awing | `name of a quarter in awing` | a cartoon name of a quarter in awing | |
| name of a quarter in Awing | `name of a quarter in awing` | a cartoon name of a quarter in awing | |
| name of a quarter in Mbiwiŋ | `name of a quarter in mbiwiŋ` | a cartoon name of a quarter in mbiwiŋ | |
| name of the fon, used only by the young and unmarried | `name of the fon` | a cartoon name of the Cameroonian dark brown skin fon, a high-top afro | |
| naming ceremony | `naming ceremony` | a cartoon naming ceremony | |
| owner of the compound | `owner of the compound` | a cartoon owner of the compound | |
| plural of kyíbə (basket of raffia) | `plural of kyíbə` | a cartoon plural of kyíbə | |
| quarter (unit of administration) | `quarter` | a cartoon quarter | |
| quarter name in Awing | `quarter name in awing` | a cartoon quarter name in awing | |
| quarter name in Awing | `quarter name in awing` | a cartoon quarter name in awing | |
| quarter or small unit of administration | `quarter or small unit of administration` | a cartoon quarter or small unit of administration | |
| rattle (musical instrument) | `rattle` | a cartoon rattle | |
| ritual place | `ritual place` | a cartoon ritual place | |
| ritual place | `ritual place` | a cartoon ritual place | |
| ruler, traditional | `ruler` | a cartoon ruler | |
| sacrifice | `sacrifice` | a cartoon sacrifice | |
| sacrifice (n) | `sacrifice` | a cartoon sacrifice | |
| sacrifice (v) | `sacrifice` | a cartoon sacrifice | |
| secret place in fon's palace | `secret place in fon's palace` | a cartoon secret place in Cameroonian deep brown skin fon's palace, short twists | |
| shell (of groundnut) | `shell` | a cartoon shell | |
| shell, of groundnuts and egusi | `shell` | a cartoon shell | |
| small drum | `small drum` | a cartoon small drum | |
| small drum | `small drum` | a cartoon small drum | |
| somebody who investigates issues and report to the fon | `somebody who investigates issues and report` | a cartoon Cameroonian rich dark skin somebody who investigates issues and report | |
| son of the fon | `son of the fon` | a cartoon son of the Cameroonian warm brown skin fon, short twists | |
| sorghum; millet of the dry season | `sorghum` | a cartoon sorghum | |
| steal palm wine from anothers palm bush | `steal palm wine from anothers palm` | a cartoon steal palm wine from anothers palm | |
| stem, stalk (of maize, millet etc.) | `stem` | a cartoon stem | |
| stem, stalk of maize, millet | `stem` | a cartoon stem | |
| stool/chair (traditional) | `stool/chair` | a cartoon stool/chair | |
| summit, highest point, tip, chief, headman | `summit` | a cartoon summit | |
| temple hut | `temple hut` | a cartoon temple hut | |
| the eighth fon of Awing | `the eighth fon of awing` | a cartoon the eighth Cameroonian deep brown skin fon of awing, a high-top afro | |
| the eleventh fon of Awing (disappeared 1950) | `the eleventh fon of awing` | a cartoon the eleventh Cameroonian dark brown skin fon of awing, short natural afro hair | |
| the fifth fon of Awing | `the fifth fon of awing` | a cartoon the fifth Cameroonian deep brown skin fon of awing, a neatly shaved head | |
| the fifth fon of Awing | `the fifth fon of awing` | a cartoon the fifth Cameroonian rich dark skin fon of awing, long locs | |
| the name of a quarter in Mbɨ̌iwiŋə in Awing | `the name of a quarter in` | a cartoon the name of a quarter in | |
| the ninth fon of Awing | `the ninth fon of awing` | a cartoon the ninth Cameroonian dark brown skin fon of awing, short twists | |
| the second fon of Awing | `the second fon of awing` | a cartoon the second Cameroonian deep brown skin fon of awing, short natural afro hair | |
| the second fon of Awing | `the second fon of awing` | a cartoon the second Cameroonian dark brown skin fon of awing, long locs | |
| the seventh fon of Awing | `the seventh fon of awing` | a cartoon the seventh Cameroonian warm brown skin fon of awing, short natural afro hair | |
| the seventh fon of Awing | `the seventh fon of awing` | a cartoon the seventh Cameroonian warm brown skin fon of awing, a neatly shaved head | |
| the sixth fon of Awing | `the sixth fon of awing` | a cartoon the sixth Cameroonian dark brown skin fon of awing, a neatly shaved head | |
| the sixth fon of Awing | `the sixth fon of awing` | a cartoon the sixth Cameroonian warm brown skin fon of awing, short twists | |
| the tenth fon of Awing | `the tenth fon of awing` | a cartoon the tenth Cameroonian warm brown skin fon of awing, short twists | |
| the tenth fon of Awing | `the tenth fon of awing` | a cartoon the tenth Cameroonian rich dark skin fon of awing, long locs | |
| the thirteenth fon of Awing | `the thirteenth fon of awing` | a cartoon the thirteenth Cameroonian warm brown skin fon of awing, long locs | |
| the thirteenth fon of Awing (enthroned 4th may 1998) | `the thirteenth fon of awing` | a cartoon the thirteenth Cameroonian dark brown skin fon of awing, long locs | |
| the twelfth fon of Awing (1950 to 1998) | `the twelfth fon of awing` | a cartoon the twelfth Cameroonian dark brown skin fon of awing, short twists | |
| the twelfth fon of Awing (1950 to 1998) | `the twelfth fon of awing` | a cartoon the twelfth Cameroonian deep brown skin fon of awing, short natural afro hair | |
| third fon of Awing | `third fon of awing` | a cartoon third Cameroonian dark brown skin fon of awing, long locs | |
| third fon of Awing | `third fon of awing` | a cartoon third Cameroonian deep brown skin fon of awing, a high-top afro | |
| this compound | `this compound` | a cartoon this compound | |
| this compound, this place | `this compound` | a cartoon this compound | |
| this compound, this place, here (nominal) | `this compound` | a cartoon this compound | |
| this compound, this place, here (nominal) | `this compound` | a cartoon this compound | |
| tip of bottle or calabash | `tip of bottle or calabash` | a cartoon tip of bottle or calabash | |
| title of sub-chief; sub-chief | `title of sub-chief` | a cartoon title of sub-Cameroonian rich dark skin chief, short natural afro hair | |
| traditional healer | `traditional healer` | a cartoon traditional healer | |
| traditional hospital | `traditional hospital` | a cartoon traditional hospital | |
| traditional hospital, mostly to consult mediums | `traditional hospital` | a cartoon traditional hospital | |
| traditional juju | `traditional juju` | a cartoon traditional juju | |
| traditional juju, blessings | `traditional juju` | a cartoon traditional juju | |
| traditional juju, something secret | `traditional juju` | a cartoon traditional juju | |
| traditional marriage | `traditional marriage` | a cartoon traditional marriage | |
| traditional marriage | `traditional marriage` | a cartoon traditional marriage | |
| traditional wedding ceremony | `traditional wedding ceremony` | a cartoon traditional wedding ceremony | |
| very sweet palm wine | `very sweet palm wine` | a cartoon very sweet palm wine | |
| wedding ceremony | `wedding ceremony` | a cartoon wedding ceremony | |
| wedding ceremony, modern | `wedding ceremony` | a cartoon wedding ceremony | |
| wedding ceremony, traditional | `wedding ceremony` | a cartoon wedding ceremony | |
| wickerwork, basket for drying wet pepper | `wickerwork` | a cartoon wickerwork | |
| women dance group | `women dance group` | a cartoon Cameroonian deep brown skin women dance group, short natural afro hair | |
| women dance group (originally based in Tata Alota's compound, no longe | `women dance group` | a cartoon Cameroonian dark brown skin women dance group, braided hair with colorful beads | |
| women dance group based in Tata Alotas compound | `women dance group based in tata` | a cartoon Cameroonian rich dark skin women dance group based in tata, a bright patterned head w | |
| women dance group based in Tata Ngonyo's compound (from English) | `women dance group based in tata` | a cartoon Cameroonian deep brown skin women dance group based in tata, cornrow braids | |
| women dance group in Akuhle quarter, based in Tata Mofolos compound | `women dance group in akuhle quarter,` | a cartoon Cameroonian warm brown skin women dance group in akuhle quarter,, short natural afro  | |
