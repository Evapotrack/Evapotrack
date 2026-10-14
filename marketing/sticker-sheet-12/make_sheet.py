"""Generate the Evapotrack 12-sticker sheet (US Letter, 8.5 x 11 in), front and back.

Front: 12 stickers, each 1.8333 in (11/6 in) square, showing evapotrack.com at
the top, the app icon in the middle, and "Optimize Plant Watering" at the bottom.
Back: a QR code behind each sticker that opens the Evapotrack App Store page.

The grid (3 columns x 4 rows, 0.25 in gaps) is centered on the page and
symmetric. When a sheet is flipped to print the back, column 1 lands behind
column 3 and row 1 behind row 4 (or the reverse). Every back cell holds the same
QR code, so each QR sits behind a sticker whether the printer flips on the long
or the short edge.

Outputs (next to this script):
  evapotrack-stickers-12-front-and-back.pdf  page 1 front, page 2 back (duplex)
  evapotrack-stickers-12-front.pdf           front only
  evapotrack-stickers-12-back.pdf            back only (feed the printed sheet back in)
  evapotrack-stickers-12-alignment-test.pdf  both pages with cut outlines, for plain paper
  preview-front.png, preview-back.png

Requires: pip install segno reportlab pillow pymupdf
"""

import os

import segno
from PIL import Image, ImageDraw
from reportlab.lib.colors import HexColor, white
from reportlab.lib.units import inch
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas
from reportlab.pdfgen.canvas import FILL_NON_ZERO

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
ICON = os.path.join(REPO, "Evapotrack/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png")

APP_STORE_URL = "https://apps.apple.com/app/evapotrack/id6761138265"
TOP_TEXT = "evapotrack.com"
BOTTOM_TEXT = "Optimize Plant Watering"

NAVY = HexColor("#1F3A5F")
BLUE = HexColor("#2F6DBD")
QR_DARK = HexColor("#1B2A33")
MARK = HexColor("#9AA5B1")

PAGE_W, PAGE_H = 8.5 * inch, 11 * inch
SIZE = 11 / 6 * inch            # 1.8333 in
COLS, ROWS = 3, 4
GAP = 0.25 * inch
GRID_W = COLS * SIZE + (COLS - 1) * GAP
GRID_H = ROWS * SIZE + (ROWS - 1) * GAP
X0 = (PAGE_W - GRID_W) / 2
Y0 = (PAGE_H - GRID_H) / 2
SAFE = 0.1 * inch               # artwork stays this far inside the cut line


def cells():
    for r in range(ROWS):
        for c in range(COLS):
            yield X0 + c * (SIZE + GAP), Y0 + r * (SIZE + GAP)


def rounded_icon(size_px=1024):
    icon = Image.open(ICON).convert("RGBA").resize((size_px, size_px), Image.LANCZOS)
    mask = Image.new("L", (size_px, size_px), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size_px - 1, size_px - 1),
                                           radius=int(size_px * 0.2237), fill=255)
    icon.putalpha(mask)
    return ImageReader(icon)


def fit_size(c, text, font, max_size, max_width):
    size = max_size
    while c.stringWidth(text, font, size) > max_width and size > 5:
        size -= 0.25
    return size


def crop_marks(c):
    """Short marks in the gaps and margins at every cut line; none touch a sticker."""
    c.setStrokeColor(MARK)
    c.setLineWidth(0.4)
    L = 0.12 * inch
    xs = sorted({X0 + i * (SIZE + GAP) for i in range(COLS)} | {X0 + i * (SIZE + GAP) + SIZE for i in range(COLS)})
    ys = sorted({Y0 + i * (SIZE + GAP) for i in range(ROWS)} | {Y0 + i * (SIZE + GAP) + SIZE for i in range(ROWS)})
    for x in xs:
        c.line(x, Y0 - 0.06 * inch - L, x, Y0 - 0.06 * inch)
        c.line(x, Y0 + GRID_H + 0.06 * inch, x, Y0 + GRID_H + 0.06 * inch + L)
    for y in ys:
        c.line(X0 - 0.06 * inch - L, y, X0 - 0.06 * inch, y)
        c.line(X0 + GRID_W + 0.06 * inch, y, X0 + GRID_W + 0.06 * inch + L, y)


def outlines(c):
    c.setStrokeColor(MARK)
    c.setLineWidth(0.5)
    c.setDash(2, 2)
    for x, y in cells():
        c.rect(x, y, SIZE, SIZE)
    c.setDash()


def front(c, icon):
    inner = SIZE - 2 * SAFE
    top_size = fit_size(c, TOP_TEXT, "Helvetica-Bold", 13, inner)
    bottom_size = fit_size(c, BOTTOM_TEXT, "Helvetica-Bold", 10, inner)
    for x, y in cells():
        cx = x + SIZE / 2
        # top line: evapotrack.com
        c.setFillColor(NAVY)
        c.setFont("Helvetica-Bold", top_size)
        c.drawCentredString(cx, y + SIZE - SAFE - top_size * 0.80, TOP_TEXT)
        # bottom line: Optimize Plant Watering
        c.setFillColor(BLUE)
        c.setFont("Helvetica-Bold", bottom_size)
        c.drawCentredString(cx, y + SAFE + bottom_size * 0.25, BOTTOM_TEXT)
        # icon centered between the two lines
        band_top = y + SIZE - SAFE - top_size * 1.05 - 0.06 * inch
        band_bottom = y + SAFE + bottom_size * 1.15 + 0.06 * inch
        s = min(band_top - band_bottom, inner)
        c.drawImage(icon, cx - s / 2, band_bottom + (band_top - band_bottom - s) / 2, s, s, mask="auto")
    crop_marks(c)


def qr_matrix():
    qr = segno.make(APP_STORE_URL, error="h", micro=False)
    return list(qr.matrix_iter(border=0))


def back(c, icon):
    matrix = qr_matrix()
    n = len(matrix)
    module = SIZE / (n + 8)            # 4-module white quiet zone on every side, inside the sticker
    q = n * module
    pad_modules = 11 if n % 2 else 10
    for x, y in cells():
        qx, qy = x + (SIZE - q) / 2, y + (SIZE - q) / 2
        c.setFillColor(QR_DARK)
        path = c.beginPath()
        for r, row in enumerate(matrix):
            col = 0
            while col < n:
                if row[col]:
                    start = col
                    while col < n and row[col]:
                        col += 1
                    path.rect(qx + start * module, qy + (n - 1 - r) * module,
                              (col - start) * module, module * 1.02)
                else:
                    col += 1
        c.drawPath(path, stroke=0, fill=1, fillMode=FILL_NON_ZERO)
        pad = pad_modules * module
        px, py = qx + (q - pad) / 2, qy + (q - pad) / 2
        c.setFillColor(white)
        c.roundRect(px, py, pad, pad, pad * 0.2, stroke=0, fill=1)
        c.drawImage(icon, px + module, py + module, pad - 2 * module, pad - 2 * module, mask="auto")
    crop_marks(c)
    return n, module, q


def build():
    icon = rounded_icon()
    out = lambda name: os.path.join(HERE, name)

    c = canvas.Canvas(out("evapotrack-stickers-12-front-and-back.pdf"), pagesize=(PAGE_W, PAGE_H))
    c.setTitle("Evapotrack stickers (12 per sheet), front and back")
    front(c, icon); c.showPage()
    n, module, q = back(c, icon); c.showPage()
    c.save()

    for name, fn in (("evapotrack-stickers-12-front.pdf", front), ("evapotrack-stickers-12-back.pdf", back)):
        c = canvas.Canvas(out(name), pagesize=(PAGE_W, PAGE_H))
        fn(c, icon); c.showPage(); c.save()

    c = canvas.Canvas(out("evapotrack-stickers-12-alignment-test.pdf"), pagesize=(PAGE_W, PAGE_H))
    c.setTitle("Evapotrack stickers - alignment test (plain paper)")
    for fn in (front, back):
        fn(c, icon); outlines(c)
        c.setFont("Helvetica", 8); c.setFillColor(MARK)
        c.drawCentredString(PAGE_W / 2, 0.35 * inch,
                            "ALIGNMENT TEST - print double-sided on plain paper at 100% / Actual Size, then hold up to a light")
        c.showPage()
    c.save()

    import pymupdf
    doc = pymupdf.open(out("evapotrack-stickers-12-front-and-back.pdf"))
    doc[0].get_pixmap(dpi=72).save(out("preview-front.png"))
    doc[1].get_pixmap(dpi=72).save(out("preview-back.png"))
    print(f"grid {GRID_W / inch:.3f} x {GRID_H / inch:.3f} in at ({X0 / inch:.3f}, {Y0 / inch:.3f}); "
          f"sticker {SIZE / inch:.4f} in; QR {n}x{n}, {q / inch:.2f} in, module {module / inch * 25.4:.2f} mm")


if __name__ == "__main__":
    build()
