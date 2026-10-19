"""Read-only contact sheet of the eight current runtime portrait images."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
ROSTER = ['f01_clutch','f02_sunstruck','f03_heavy_duty','f04_deadfall',
          'f05_fine_print','f06_rugged_explorer','f07_urban_sentinel','f08_midnight_gentleman']
sheet = Image.new('RGB', (1536,832), '#141a23')
draw = ImageDraw.Draw(sheet)
font_path = Path('C:/Windows/Fonts/segoeui.ttf')
font = ImageFont.truetype(str(font_path),20) if font_path.exists() else ImageFont.load_default()
for index, fighter in enumerate(ROSTER):
    source = ROOT/'Game File/assets/portraits'/(fighter+'.png')
    x,y = index%4*384,index//4*416
    portrait = Image.open(source).convert('RGB').resize((384,384),Image.Resampling.LANCZOS)
    sheet.paste(portrait,(x,y))
    draw.text((x+14,y+390),fighter[4:].replace('_',' ').title(),font=font,fill='#e6edf4')
output = ROOT/'evidence/characters/hero_rebuild/final_portrait_roster.jpg'
sheet.save(output,quality=94)
print(output)
