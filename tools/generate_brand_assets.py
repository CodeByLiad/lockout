"""Export the user-approved Last rep vector geometry. Requires local Pillow."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, PngImagePlugin

ROOT = Path(__file__).resolve().parents[1]
BRAND = ROOT / 'assets/branding'
RES = ROOT / 'android/app/src/main/res'
INK = '#1F2E00'
LIME = '#C2EE7B'
# x0, y0, x1, y1, corner radius; centered, before the upward 22-degree rotation.
RECTS = [(-14, -4, 14, 4, 1), (-27, -24, -14, 24, 6.5),
         (14, -24, 27, 24, 6.5), (-37, -18, -29, 18, 4),
         (29, -18, 37, 18, 4), (-43, -8, -39, 8, 2),
         (39, -8, 43, 8, 2)]
SIZES = [16, 24, 32, 48, 64, 72, 96, 108, 128, 144, 162, 192, 216, 256, 324, 384, 432, 512, 1024]
PROMPT = 'User-approved The last rep from docs/design/icon-preview/concept-03.png: upward-angled dumbbell with chunky rounded plates; production reconstruction as flat vector geometry.'

def svg(kind):
    background = '' if kind in ('foreground', 'monochrome') else (
        f'<circle cx="54" cy="54" r="54" fill="{LIME}"/>' if kind == 'round' else
        f'<rect width="108" height="108" rx="{24 if kind == "rounded-square" else 0}" fill="{LIME}"/>')
    rects = ''.join(f'<rect x="{x0}" y="{y0}" width="{x1-x0}" height="{y1-y0}" rx="{r}"/>' for x0,y0,x1,y1,r in RECTS)
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 108 108"><title>Lockout — The last rep</title>{background}<g fill="{INK if kind != "monochrome" else "currentColor"}" transform="translate(54 54) rotate(-22) scale(.7)">{rects}</g></svg>\n'

def round_path(rect):
    x0,y0,x1,y1,r=rect
    return f'M{x0+r},{y0} H{x1-r} A{r},{r} 0 0 1 {x1},{y0+r} V{y1-r} A{r},{r} 0 0 1 {x1-r},{y1} H{x0+r} A{r},{r} 0 0 1 {x0},{y1-r} V{y0+r} A{r},{r} 0 0 1 {x0+r},{y0} Z'

def vector(color):
    paths='\n'.join(f'      <path android:fillColor="{color}" android:pathData="{round_path(rect)}"/>' for rect in RECTS)
    return f'''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
  <group android:translateX="54" android:translateY="54">
    <group android:rotation="-22" android:scaleX="0.7" android:scaleY="0.7">
{paths}
    </group>
  </group>
</vector>
'''

def main():
    BRAND.mkdir(parents=True,exist_ok=True)
    # Render geometry at 4x largest export before downsampling. No concept pixels copied.
    side=4096
    unit=side/108*.7
    fore=Image.new('RGBA',(side,side))
    draw=ImageDraw.Draw(fore)
    for x0,y0,x1,y1,r in RECTS:
        draw.rounded_rectangle((side/2+x0*unit,side/2+y0*unit,side/2+x1*unit,side/2+y1*unit),radius=r*unit,fill=INK)
    fore=fore.rotate(22,resample=Image.Resampling.BICUBIC)
    meta=PngImagePlugin.PngInfo()
    meta.add_text('Source','Lockout approved The last rep; tools/generate_brand_assets.py; vector reconstruction')
    meta.add_text('Prompt',PROMPT)
    for kind in ['square','rounded-square','round','foreground','monochrome']:
        (BRAND/f'lockout-{kind}.svg').write_text(svg(kind),encoding='utf-8')
        folder=BRAND/'exports'/kind
        folder.mkdir(parents=True,exist_ok=True)
        for size in SIZES:
            symbol=fore.resize((size,size),Image.Resampling.LANCZOS)
            image=Image.new('RGBA',(size,size))
            if kind in ('square','round','rounded-square'):
                mask=Image.new('L',(size*4,size*4))
                pen=ImageDraw.Draw(mask)
                if kind=='round': pen.ellipse((0,0,size*4-1,size*4-1),fill=255)
                elif kind=='rounded-square': pen.rounded_rectangle((0,0,size*4-1,size*4-1),radius=size*4*24/108,fill=255)
                else: pen.rectangle((0,0,size*4-1,size*4-1),fill=255)
                image.paste(Image.new('RGBA',(size,size),LIME),(0,0),mask.resize((size,size),Image.Resampling.LANCZOS))
            if kind=='monochrome':
                alpha=symbol.getchannel('A')
                symbol=Image.new('RGBA',(size,size),(0,0,0,0))
                symbol.putalpha(alpha)
            image=Image.alpha_composite(image,symbol)
            image.save(folder/f'{size}.png',pnginfo=meta,optimize=True)
    for density,size in {'mdpi':48,'hdpi':72,'xhdpi':96,'xxhdpi':144,'xxxhdpi':192}.items():
        dest=RES/f'mipmap-{density}'
        dest.mkdir(parents=True,exist_ok=True)
        for kind,name in [('rounded-square','ic_launcher'),('round','ic_launcher_round')]:
            (dest/f'{name}.png').write_bytes((BRAND/f'exports/{kind}/{size}.png').read_bytes())
    drawable=RES/'drawable'
    drawable.mkdir(parents=True,exist_ok=True)
    (drawable/'ic_launcher_foreground.xml').write_text(vector(INK),encoding='utf-8')
    (drawable/'ic_launcher_monochrome.xml').write_text(vector('#FFFFFFFF'),encoding='utf-8')
    (RES/'values/launcher_colors.xml').write_text(f'<resources><color name="ic_launcher_background">{LIME}</color></resources>\n',encoding='utf-8')
    for version in [26,33]:
        dest=RES/f'mipmap-anydpi-v{version}'
        dest.mkdir(parents=True,exist_ok=True)
        mono='\n  <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>' if version==33 else ''
        xml=f'<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n  <background android:drawable="@color/ic_launcher_background"/>\n  <foreground android:drawable="@drawable/ic_launcher_foreground"/>{mono}\n</adaptive-icon>\n'
        for name in ['ic_launcher','ic_launcher_round']:
            (dest/f'{name}.xml').write_text(xml,encoding='utf-8')
    (BRAND/'provenance.json').write_text(json.dumps({'approvedConcept':'docs/design/icon-preview/concept-03.png, center: The last rep','approval':'2026-11-04: I like the last rep one. so use that','method':'Deterministic native vector reconstruction and resolution exports; no new generated logo variant.','generator':'tools/generate_brand_assets.py','prompt':PROMPT,'sizes':SIZES,'types':['square','rounded-square','round','foreground','monochrome'],'colors':{'ink':INK,'lime':LIME}},indent=2)+'\n',encoding='utf-8')
    print(f'Exported {len(SIZES)*5} PNGs, five SVG masters and Android launcher resources.')

if __name__=='__main__': main()
