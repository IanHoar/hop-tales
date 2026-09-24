import numpy as np, json
from PIL import Image
from scipy import ndimage as ndi
OUT='../wordhop/project/collage/sprites'
def cut(path):
    a=np.asarray(Image.open(path).convert('RGB')).astype(np.float32)
    bg=np.median(a[:10].reshape(-1,3),0); d=np.sqrt(((a-bg)**2).sum(2))
    cand=d<22; lab,_=ndi.label(cand); tl=np.unique(lab[:4][cand[:4]]); tl=tl[tl>0]
    fg=ndi.binary_fill_holes(~np.isin(lab,tl)); fg=ndi.binary_opening(fg,iterations=2)
    lab,n=ndi.label(fg); parts=[]
    for i in range(1,n+1):
        m=lab==i
        if m.sum()<20000: continue
        al=ndi.gaussian_filter(m.astype(np.float32),0.8); al[ndi.binary_erosion(m,iterations=2)]=1
        ys,xs=np.nonzero(m); y0,y1,x0,x1=ys.min(),ys.max()+1,xs.min(),xs.max()+1
        parts.append(((y0+y1)/2,(x0+x1)/2,np.dstack([a,al*255])[y0:y1,x0:x1]))
    parts.sort(key=lambda t:(round(t[0]/700),t[1]))
    return [p[2] for p in parts]
def best_shift(ref,f):
    ra=ref[...,3]>128; fa=f[...,3]>128
    H=max(ra.shape[0],fa.shape[0])+60; W=max(ra.shape[1],fa.shape[1])+60
    R=np.zeros((H,W),bool); R[H-ra.shape[0]:,30:30+ra.shape[1]]=ra
    best=None
    for dx in range(-40,41,2):
        for dy in range(-16,17,2):
            y0=H-fa.shape[0]+dy; x0=dx+30
            if y0<0 or x0<0 or x0+fa.shape[1]>W or y0+fa.shape[0]>H: continue
            F=np.zeros((H,W),bool); F[y0:y0+fa.shape[0],x0:x0+fa.shape[1]]=fa
            s=(R&F).sum()-(R^F).sum()*0.5
            if best is None or s>best[0]: best=(s,dx+30,dy)
    return best[1],best[2]
def place(frames,offs,pad=24):
    W=max(f.shape[1]+ox for f,(ox,oy) in zip(frames,offs))+pad*2
    H=max(f.shape[0]-oy for f,(ox,oy) in zip(frames,offs))+pad*2
    out=[]
    for f,(ox,oy) in zip(frames,offs):
        c=np.zeros((H,W,4),np.float32); y0=H-pad-f.shape[0]+oy; x0=pad+ox
        c[y0:y0+f.shape[0],x0:x0+f.shape[1]]=f; out.append(c)
    return out,W,H
S=0.5
def strip(cells,W,H,name):
    w,h=int(W*S),int(H*S); sheet=Image.new('RGBA',(w*len(cells),h))
    for i,c in enumerate(cells):
        sheet.alpha_composite(Image.fromarray(c.clip(0,255).astype(np.uint8),'RGBA').resize((w,h),Image.LANCZOS),(i*w,0))
    sheet.save(f'{OUT}/{name}.png',optimize=True); sheet.save(f'{OUT}/{name}.webp',quality=90,method=6)
    print(name,sheet.size,w,h); return w,h
idle=cut('nb/sprites/idle-sheet.png'); jump=cut('nb/sprites/jump-sheet.png')
keys=(2,3,4,6,7); base=idle[1]
offs=[(30,0) if k==2 else best_shift(base,idle[k-1]) for k in keys]
cells,W,H=place([idle[k-1] for k in keys],offs); cell=dict(zip(keys,cells))
seq=[2,2,2,2,3,3,2,2,4,4,2,2,2,6,2,2,7,7,7,2]
lift=[0,0,-60,-80,-40,0,0,0]
cen=[np.nonzero(f[...,3]>128)[1].mean() for f in jump]; maxw=max(f.shape[1] for f in jump)
jo=[(int(maxw/2-c),l) for c,l in zip(cen,lift)]; mn=min(o[0] for o in jo); jo=[(o[0]-mn,o[1]) for o in jo]
jc,JW,JH=place(jump,jo)
iw,ih=strip([cell[k] for k in seq],W,H,'hare-idle')
jw,jh=strip(jc,JW,JH,'hare-hop')
strip([cell[k] for k in keys],W,H,'hare-idle-keys')
json.dump({"idle":{"frame":[iw,ih],"frames":len(seq),"fps":10,"loop":True,"note":"sheet is already in playback order; keys sheet holds the 5 unique drawings"},
           "hop":{"frame":[jw,jh],"frames":8,"fps":14,"loop":False,"contact_frames":[1,2,6,7,8],"note":"body-centred; move the node forward by one word during frames 2-7"}},
          open(f'{OUT}/sprites.json','w'),indent=1)
