import random, statistics as st
g=0.15
def current(h):   # h: list of (W,R) oldest first
    rets=[w-r for w,r in h]; last=rets[-1]
    if last<=0: return None
    return ((last+sum(rets)/len(rets))/2)/(1-g)
def last_only(h):
    w,r=h[-1]; return (w-r)/(1-g) if w>r else None
def ewma(h,a=0.5):
    e=None
    for w,r in h:
        x=w-r; e=x if e is None else a*x+(1-a)*e
    return e/(1-g)
def ewma_cens(h,a=0.5,bump=0.15):
    # same as ewma, but a zero/near-zero-runoff log is a lower bound: never recommend
    # less than last water*(1+bump) after a watering that produced no runoff
    n=ewma(h,a); w,r=h[-1]
    if r/w < 0.02: n=max(n, w*(1+bump))
    return n
def run(alg, demand, W0, noise=0.0, seed=1):
    random.seed(seed); h=[]; W=W0; out=[]
    for D in demand:
        Dn=D*(1+random.uniform(-noise,noise))
        R=max(0,W-Dn); h.append((W,R)); out.append(R/W)
        n=alg(h); W=n if n else W
    return out
def score(out, skip=3):
    o=out[skip:]
    return f"mean|rp-15%|={st.mean(abs(x-g) for x in o)*100:5.1f}pp  zeroRunoff={sum(1 for x in o if x<0.005):2d}/{len(o)}  meanRP={st.mean(o)*100:4.1f}%"
algs=[('current(50/50 last+all-mean)',current),('last-only',last_only),('EWMA a=0.5',ewma),('EWMA a=0.5 + censor bump',ewma_cens)]
scen={
 'constant D=1.2, start 0.6':([1.2]*25,0.6,0.0),
 'constant D=1.2 +/-20% noise':([1.2]*25,1.2,0.2),
 'rising +6%/watering (veg), +/-10% noise':([0.6*1.06**i for i in range(25)],0.7,0.1),
 'demand drops 40% at #12 (flip/stress)':([1.2]*12+[0.72]*13,1.4,0.05),
}
for s,(d,w0,nz) in scen.items():
    print('==',s)
    for name,a in algs:
        sc=[run(a,d,w0,nz,seed) for seed in range(20)]
        flat=[x for o in sc for x in o[3:]]
        print(f"  {name:30s} mean|rp-15%|={st.mean(abs(x-g) for x in flat)*100:5.1f}pp  zero-runoff waterings={sum(1 for x in flat if x<0.005)/len(flat)*100:5.1f}%  mean runoff={st.mean(flat)*100:5.1f}%")
print("\n##### additional candidates #####")
def holt(h,a=0.5,b=0.3):
    lvl=None;tr=0
    for w,r in h:
        x=w-r
        if lvl is None: lvl=x; continue
        p=lvl; lvl=a*x+(1-a)*(lvl+tr); tr=b*(lvl-p)+(1-b)*tr
    n=(lvl+tr)/(1-g); w,r=h[-1]
    if r/w<0.02: n=max(n,w*1.15)
    return n
def feedback(h,k=1.0):
    w,r=h[-1]; return w*(1+k*(g-r/w))
for s,(d,w0,nz) in scen.items():
    print('==',s)
    for name,a in [('Holt(level+trend)+censor',holt),('runoff feedback k=1',feedback)]:
        sc=[run(a,d,w0,nz,seed) for seed in range(20)]
        flat=[x for o in sc for x in o[3:]]
        print(f"  {name:30s} mean|rp-15%|={st.mean(abs(x-g) for x in flat)*100:5.1f}pp  zero-runoff waterings={sum(1 for x in flat if x<0.005)/len(flat)*100:5.1f}%  mean runoff={st.mean(flat)*100:5.1f}%")
