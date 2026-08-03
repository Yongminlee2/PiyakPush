from pathlib import Path
from PIL import Image, ImageDraw
import colorsys
from collections import deque

ROOT=Path(r"C:\workAndroid\PiyakPush\tmp\icon11")
OUT=Path(r"C:\workAndroid\PiyakAssets\icon")
OUT.mkdir(parents=True,exist_ok=True)
GEN=Path.home()/'.codex'/'generated_images'/'019fc2fb-f5b1-7801-9958-de3da83db5f9'
SOURCES={
    'a':GEN/'exec-f1a93008-6c9f-4940-b905-b338cf79c935.png',
    'b':GEN/'exec-3addccc7-0af5-4c4e-aa38-9b50f6610f78.png',
    'c':GEN/'exec-5b842b65-8b96-4b44-b79b-771a42b6f199.png',
}

PALETTE=[
    (93,64,55),      # outline
    (255,224,130),   # chick
    (255,167,38),    # beak/feet
    (248,187,208),   # cheeks
    (255,253,242),   # egg/highlight
    (224,184,120),   # nest light
    (194,154,88),    # nest dark
    (0,0,0),         # eyes
]

def remove_magenta(im):
    im=im.convert('RGBA')
    px=im.load()
    w,h=im.size
    bg=bytearray(w*h)
    q=deque()
    for x in range(w): q.append((x,0)); q.append((x,h-1))
    for y in range(h): q.append((0,y)); q.append((w-1,y))
    def is_key(x,y):
        r,g,b,_=px[x,y]
        hh,ss,vv=colorsys.rgb_to_hsv(r/255,g/255,b/255)
        hue=hh*360
        return 275<hue<350 and ss>.28 and r>150 and b>130
    while q:
        x,y=q.popleft(); i=y*w+x
        if bg[i] or not is_key(x,y): continue
        bg[i]=1
        if x:q.append((x-1,y))
        if x+1<w:q.append((x+1,y))
        if y:q.append((x,y-1))
        if y+1<h:q.append((x,y+1))
    for y in range(im.height):
        for x in range(im.width):
            r,g,b,_=px[x,y]
            if bg[y*w+x]:
                px[x,y]=(0,0,0,0)
            else:
                px[x,y]=(r,g,b,255)
    return im

def flatten(im,key):
    im=remove_magenta(im)
    px=im.load()
    w,h=im.size
    for y in range(im.height):
        for x in range(im.width):
            r,g,b,a=px[x,y]
            if a==0:
                px[x,y]=(0,0,0,0); continue
            hh,ss,vv=colorsys.rgb_to_hsv(r/255,g/255,b/255)
            hue=hh*360
            # Preserve the bold eye and outline shapes first.
            if max(r,g,b)<72: c=(0,0,0)
            elif r<145 and g<120 and b<110: c=(93,64,55)
            # Pink cheeks.
            elif key=='a' and r>180 and b>105 and (r-g)>20 and (b-g)>5: c=(248,187,208)
            elif key=='a':
                # Face-only asset: center-lower warm patch is the beak; the rest is chick yellow.
                if .39 < x/w < .61 and .52 < y/h < .76 and hue < 42 and ss>.25: c=(255,167,38)
                else: c=(255,224,130)
            elif key=='b':
                # Lower portion is the straw nest; upper portion is the chick.
                if y/h>.62 and hue<43 and ss>.25 and vv<.96:
                    c=(194,154,88) if vv<.78 else (224,184,120)
                elif .39 < x/w < .61 and .32 < y/h < .56 and hue<42 and ss>.25:
                    c=(255,167,38)
                else: c=(255,224,130)
            else:
                # Right half is the egg. Left half is the chick; strong orange patches are beak/feet.
                if x/w>.50 and ss<.20 and vv>.65: c=(255,253,242)
                elif (hue<38 and ss>.32): c=(255,167,38)
                else: c=(255,224,130)
            px[x,y]=(*c,a)
    return im

def crop_subject(im):
    a=im.getchannel('A')
    bbox=a.getbbox()
    return im.crop(bbox)

def add_cheeks(im,key):
    if key not in ('b','c'): return im
    d=ImageDraw.Draw(im)
    w,h=im.size
    if key=='b':
        for cx in (.23,.77):
            d.ellipse((int((cx-.045)*w),int(.43*h),int((cx+.045)*w),int(.50*h)),fill=(248,187,208,255))
    else:
        d.ellipse((int(.27*w),int(.40*h),int(.40*w),int(.55*h)),fill=(255,224,130,255))
        d.ellipse((int(.27*w),int(.44*h),int(.34*w),int(.51*h)),fill=(248,187,208,255))
    return im

def place(subject,max_dim,bg=None):
    scale=max_dim/max(subject.size)
    size=(round(subject.width*scale),round(subject.height*scale))
    subject=subject.resize(size,Image.Resampling.LANCZOS)
    if bg is None:
        dst=Image.new('RGBA',(512,512),(0,0,0,0))
    else:
        dst=Image.new('RGB',(512,512),bg)
    x=(512-size[0])//2; y=(512-size[1])//2
    if bg is None: dst.alpha_composite(subject,(x,y))
    else: dst.paste(subject.convert('RGB'),(x,y),subject.getchannel('A'))
    return dst

specs={
    'a':('#FFF8E1',420),
    'b':('#FFF8E1',420),
    'c':('#C5E8B0',420),
}
for key,(bg,opaque_size) in specs.items():
    subject=add_cheeks(crop_subject(flatten(Image.open(SOURCES[key]),key)),key)
    place(subject,opaque_size,bg).save(OUT/f'icon_{key}.png','PNG',optimize=True)
    place(subject,320,None).save(OUT/f'icon_{key}_fg.png','PNG',optimize=True)
    place(subject,opaque_size,bg).resize((100,100),Image.Resampling.LANCZOS).save(ROOT/f'icon_{key}_100.png','PNG')
print('saved 6 final icons and 3 previews')
