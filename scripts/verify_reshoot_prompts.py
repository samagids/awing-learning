import importlib.util,sys,io,re,json,os
sys.path.insert(0,'.')
sp=importlib.util.spec_from_file_location('g','generate_images.py')
m=importlib.util.module_from_spec(sp); sp.loader.exec_module(m)
from awing_key import image_key
t=io.open('../lib/data/awing_vocabulary.dart',encoding='utf-8').read()
live="\n".join(l for l in t.splitlines() if not l.lstrip().startswith('//'))
# BOTH quote styles, on BOTH fields. 293 glosses are double-quoted.
pat = (r"AwingWord\(\s*awing:\s*(?:'((?:[^'\\]|\\.)*?)'|\"([^\"]*?)\")\s*,"
       r"\s*english:\s*(?:'((?:[^'\\]|\\.)*?)'|\"([^\"]*?)\").*?category:\s*'(\w+)'")
meta={}
for a,b,e1,e2,c in re.findall(pat,live):
    aw=(a or b).replace("\\'","'"); en=(e1 or e2).replace("\\'","'")
    meta[image_key(aw,en)]=(aw,en,c)
idx=json.load(open('../contributions/_sheets/reshoot2_index.json'))
HUM=re.compile(r"\b(cameroonian|black african|dark brown|deep brown|warm brown|very dark|grassfields)\b",re.I)
PERSON=re.compile(r"\b(person|people|man|men|woman|women|boy|girl|child|children|crowd|congregation|worshippers|villagers?|couple|bride|groom|trader|elder|farmer|hunter|chief|teacher|healer|mother|father|figure)\b",re.I)
ok=obj=0; bad=[]; missing=[]
for n in sorted(idx,key=int):
    k=os.path.splitext(idx[n])[0]
    if k not in meta: missing.append((n,k)); continue
    aw,en,c=meta[k]; p=m.get_ai_prompt(en,c,aw)
    if HUM.search(p): ok+=1
    elif PERSON.search(p): bad.append((n,en,p[:85]))
    else: obj+=1
print(f"  resolved {len(idx)-len(missing)}/{len(idx)} keys to vocabulary rows")
print(f"  {ok:>3}  name a dark-skinned Cameroonian / Grassfields subject")
print(f"  {obj:>3}  deliberate object or diagram scene, no person")
print(f"  {len(bad):>3}  name a person with NO tone   <-- must be 0")
for n,e,p in bad: print("    ",n,repr(e)[:40],"|",p)
for n,k in missing: print("     UNRESOLVED",n,k)
