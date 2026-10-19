"""Read-only QA thumbnails of genuine engine captures, not replacement artwork.

Original screenshots remain untouched. Run with an evidence directory argument.
"""
from pathlib import Path
import json
import math
import sys
from PIL import Image, ImageDraw, ImageFont

folder = Path(sys.argv[1])
report = json.loads((folder / 'presentation_scenarios.json').read_text())
rows = report['captures']
out = folder / 'qa_sheets'
out.mkdir(exist_ok=True)
font = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 16)
for page in range(math.ceil(len(rows) / 9)):
    image = Image.new('RGB', (1920, 1200), '#151a21')
    draw = ImageDraw.Draw(image)
    for index, row in enumerate(rows[page * 9:(page + 1) * 9]):
        x, y = (index % 3) * 640, (index // 3) * 400
        original = Image.open(row['file']).convert('RGB')
        original.thumbnail((640, 360), Image.Resampling.LANCZOS)
        image.paste(original, (x, y))
        draw.text((x + 7, y + 362), row['name'], font=font, fill='#e1e6eb')
        draw.text((x + 7, y + 381), f"tick {row['world_tick']}  |  camera {row['camera_size']:.2f}", font=font, fill='#9eabb8')
    image.save(out / f'page_{page + 1:02d}.jpg', quality=94)
print(f'{len(rows)} untouched source captures indexed across {page + 1} QA sheets: {out}')
