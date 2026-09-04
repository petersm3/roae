import sys, random
sys.path.insert(0, __import__('os').path.join(__import__('os').path.dirname(__file__), '..', '..', '..'))
import solve
from functools import lru_cache
KW = list(solve.binary_hexagrams)
PAIRS = [(KW[2*i], KW[2*i+1]) for i in range(32)]
def d(a, b): return bin(a ^ b).count("1")
def rev6(h):
    r=0
    for b in range(6): r|=((h>>b)&1)<<(5-b)
    return r
# pair-level classes via the phase-1 result: recompute stable partition at PAIR level directly
# (initial split: palindrome pair / anti-symmetric pair / generic; refine by counts)
def pair_class(p):
    a,b = PAIRS[p]
    if rev6(a)==a: return 'pal'
    if (a^b)==63: return 'anti'
    return 'gen'
cls = {p: pair_class(p) for p in range(1,32)}
from collections import Counter
print("pair-level classes:", Counter(cls.values()))
def count(pair_indices, start_exit=0):
    n=len(pair_indices); pl=list(pair_indices)
    @lru_cache(maxsize=None)
    def rec(mask,last):
        if mask==(1<<n)-1: return 1
        t=0
        for i,p in enumerate(pl):
            if mask>>i&1: continue
            for o in (0,1):
                f=PAIRS[p][1] if o else PAIRS[p][0]; s=PAIRS[p][0] if o else PAIRS[p][1]
                if d(last,f)==5: continue
                t+=rec(mask|1<<i,s)
        return t
    v=rec(0,start_exit); rec.cache_clear(); return v
random.seed(7)
fails=0; trials=0
for _ in range(12):
    base=random.sample(range(1,32),10)
    x=random.choice(base)
    same=[y for y in range(1,32) if y not in base and cls[y]==cls[x]]
    if not same: continue
    y=random.choice(same)
    alt=[y if p==x else p for p in base]
    c1,c2=count(base),count(alt)
    trials+=1
    ok = c1==c2
    if not ok: fails+=1
    print(f"swap {x}({cls[x]})->{y}: {c1} vs {c2} {'==' if ok else '!= EXCHANGEABILITY FAILS'}")
print(f"\n{trials-fails}/{trials} swaps exchangeable")
