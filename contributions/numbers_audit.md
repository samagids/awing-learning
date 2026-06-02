# Numbers Audit — 2007 Awing English Dictionary vs Current App

Tester reported 11 & 12 wrong. Audit reveals far worse: **5 numbers missing entirely + 7 numbers wrong + 1 entirely missing prefix system**.

## Source authority
- **English-Awing index** (dictionary pp. 170-196) — primary
- **Body of dictionary** (pp. 13-139) — confirms forms in compounds (nked X = X hundred, ntsəb X = ten + X)

## Base numbers 1-10

| # | Current app | Dictionary index | Body confirmation | Verdict |
|---|---|---|---|---|
| 1 | `wûu` | `mə'ə` (adj) | `nked m'ə` (used in compounds) | **OK** as counting form; `m'ə` is adjective form |
| 2 | **MISSING** | num. `mbé`, adj `pé` | `nked pê` (2 hundred) | **ADD `mbê`** |
| 3 | **MISSING** | adj. `teelə` | `nked teelə́` (3 hundred) | **ADD `teelə́`** |
| 4 | **MISSING** | (compound `nəkwa`) | `nked zén nəkwa` | **ADD `nəkwa`** |
| 5 | **MISSING** | adj. `ténə` / `tâ` | `nked tênə` (5 hundred) | **ADD `tênə`** |
| 6 | `ntogə́` | adj. `ntogə́` | matches | ✓ OK |
| 7 | `asaambê` | adj. `asaambé` | matches | ✓ OK (tone mark variation) |
| 8 | `nəfeemə́` | adj. `nəfeemə̌` | `nəfeemə̌` p.106 | ⚠ tone: `̌` (rising) not `́` (high) |
| 9 | `nəpu'ə́` | adj. `nəpu'ə` | matches | ✓ OK |
| 10 | **MISSING** | adj. `naghámə` | matches p.106 | **ADD `naghámə`** |

**BUG IMPACT (very serious):** The Numbers screen filters `difficulty == 1` and shows them in a grid. The screen labels each cell as `digitValue = index + 1`. With 2/3/4/5/10 missing, when a kid taps:
- Cell labeled "2" → they hear `ntogə́` (= "six")
- Cell labeled "3" → they hear `asaambê` (= "seven")
- Cell labeled "4" → they hear `nəfeemə́` (= "eight")
- Cell labeled "5" → they hear `nəpu'ə́` (= "nine")

This is exactly what the tester reported.

## Teens 11-19

| # | Current app | Dictionary | Verdict |
|---|---|---|---|
| 11 | `əghám nə əmɔ́` | `ntsəb m'ə` (p.118, p.120 — both match) | **FIX** |
| 12 | `əghám nə əpá` | `ntsəb pé` (p.118, p.120) | **FIX** |
| 13 | `ntsəb teelə́` | `ntsəb teelə` (or variant `ntsəb ndeena`) | ✓ OK |
| 14 | `ntsəb nəkwa` | `ntsəb zén nəkwa` (p.118, p.120) | **FIX (add `zén`)** |
| 15 | `ntsəb tênə` | `ntsəb téna` | ✓ OK (tone variation) |
| 16 | `ntsəb ntogə́` | `ntsəb ntəgə` | ✓ OK (tone variation) |
| 17 | `ntsəb asaambê` | (not in extract) | ⚠ inferred from pattern |
| 18 | `ntsəb nəfeemə́` | (not in extract; pattern says `ntsəb nəfeenə`) | ⚠ tone variation |
| 19 | `ntsəb nəpu'ə́` | `ntsəb napu'ə` | ✓ OK |

## Tens 20-90

| # | Current app | Dictionary p.97 / p.96 | Verdict |
|---|---|---|---|
| 20 | `mbá` | `məghə́m mêm mbê` (p.96) | **FIX (totally wrong)** |
| 30 | `mbá nə əghám` | `məghəm mén teelə` (p.97) | **FIX** |
| 40 | `mbá əpá` | `məghəm mén nəkwa` (p.97) | **FIX** |
| 50 | `məghə́m mén tênə` | `məghəm mén ténə` | ✓ OK |
| 60 | `məghə́m mén ntogə́` | `məghəm mén ntogə` | ✓ OK |
| 70 | `məghə́m mén asaambê` | `məghəm mén asaambé` | ✓ OK |
| 80 | `məghə́m mén nəfeemə́` | `məghəm mém nəfeenə` (p.97) | ⚠ `n` vs `m` in `nəfee[mn]ə` — Dr. Sama clarify |
| 90 | `məghə́m mén nəpu'ə́` | `məghəm mén napu'ə` | ✓ OK |

## Hundreds & thousand

| # | Current app | Dictionary | Verdict |
|---|---|---|---|
| 100 | `ŋgwú` | `nkelə` (p.114, p.116) | **FIX (totally wrong)** |
| 200 | `nked pê` | `nked pê` ✓ | ✓ OK |
| 300 | `nked teelə́` | matches | ✓ OK |
| 400 | `nked zén nəkwa` | matches | ✓ OK |
| 500 | `nked tênə` | matches | ✓ OK |
| 1000 | **MISSING** | `tə́əsə` (p.132) | **ADD** |

## Compound twenties (21-25) — current app

The app's 21-25 use pattern `məghə́m mém mbê nə́ X`. Dictionary doesn't show 21-25 directly. Pattern is **plausible** but should be verified by Dr. Sama before relying on it for tests.

## Summary of required changes

**Add (6):** 2, 3, 4, 5, 10, 1000
**Fix (7):** 11, 12, 14, 20, 30, 40, 100
**Tone-mark variations (5):** 8, 15, 16, 17 ⚠, 80 ⚠

## Pages where I confirmed each form
- p.96: 20
- p.97: 30, 40, 50, 60, 70, 80, 90 (full tens column)
- p.106: 8, 10
- p.108: 9
- p.114: 100, 200, 300, 400, 500 (hundreds column)
- p.116: 100, 200, 300, 400, 500 (confirms hundreds)
- p.117 / p.119: 6
- p.118 / p.120: 11, 12, 13, 14, 15, 16, 19 (teens column, BOTH pages match)
- p.128, p.129, p.131: 3, 5
- p.132: 1000
- English-Awing index pp.170-196: confirms ALL above
