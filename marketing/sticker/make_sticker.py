"""Generate the Evapotrack 3" x 3" App Store QR sticker.

Outputs (next to this script):
  evapotrack-sticker-OL177.pdf   Letter sheet, 6 stickers laid out for OnlineLabels OL177WJ
  evapotrack-sticker-single.pdf  One 3" x 3" sticker
  evapotrack-sticker-preview.png Preview of one sticker

Requires: pip install segno reportlab pillow
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

NAVY = HexColor("#1F3A5F")
QR_DARK = HexColor("#1B2A33")

# OnlineLabels OL177 (3" x 3" square, 6 per sheet, 2 across x 3 down, US Letter).
PAGE_W, PAGE_H = 8.5 * inch, 11 * inch
LABEL = 3 * inch
COLS, ROWS = 2, 3
LEFT_MARGIN = 1.0 * inch
TOP_MARGIN = 0.75 * inch
H_PITCH = 3.5 * inch   # 0.5" gap between columns
V_PITCH = 3.25 * inch  # 0.25" gap between rows

# Keep artwork away from the die-cut edge so small printer drift never clips it.
SAFE = 0.15 * inch


def rounded_icon(size_px=1024):
    """App icon with iOS-style rounded corners and transparent outside."""
    icon = Image.open(ICON).convert("RGBA").resize((size_px, size_px), Image.LANCZOS)
    mask = Image.new("L", (size_px, size_px), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size_px - 1, size_px - 1), radius=int(size_px * 0.2237), fill=255
    )
    icon.putalpha(mask)
    return ImageReader(icon)


def draw_sticker(c, x, y, icon, outline=False):
    """Draw one sticker with its bottom-left corner at (x, y)."""
    if outline:
        c.setStrokeColor(HexColor("#BBBBBB"))
        c.setLineWidth(0.5)
        c.setDash(2, 2)
        c.rect(x, y, LABEL, LABEL)
        c.setDash()

    # Title
    title_size = 26
    c.setFillColor(NAVY)
    c.setFont("Helvetica-Bold", title_size)
    c.drawCentredString(x + LABEL / 2, y + LABEL - SAFE - title_size * 0.78, "EVAPOTRACK")
    title_bottom = y + LABEL - SAFE - title_size * 0.78 - 0.08 * inch

    # QR code, error correction H so the center logo does not hurt scanning.
    qr = segno.make(APP_STORE_URL, error="h", micro=False)
    matrix = list(qr.matrix_iter(border=0))
    n = len(matrix)
    # Leave a 4-module quiet zone inside the label, in case it is stuck on a dark surface.
    module = (title_bottom - y) / (n + 4)
    qr_size = n * module
    qx = x + (LABEL - qr_size) / 2
    qy = y + 4 * module

    c.setFillColor(QR_DARK)
    # Draw each row as merged horizontal runs in one path; the slight vertical
    # overlap stops viewers and printers showing hairline seams between rows.
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

    # Center logo: white pad on a whole-module grid, then the app icon.
    pad_modules = 11 if n % 2 else 10
    pad = pad_modules * module
    px = qx + (qr_size - pad) / 2
    py = qy + (qr_size - pad) / 2
    c.setFillColor(white)
    c.roundRect(px, py, pad, pad, pad * 0.2, stroke=0, fill=1)
    logo = pad - 2 * module
    c.drawImage(icon, px + module, py + module, logo, logo, mask="auto")

    return n, module, qr_size


def build():
    icon = rounded_icon()

    sheet = os.path.join(HERE, "evapotrack-sticker-OL177.pdf")
    c = canvas.Canvas(sheet, pagesize=(PAGE_W, PAGE_H))
    c.setTitle("Evapotrack App Store Sticker - OL177WJ")
    for row in range(ROWS):
        for col in range(COLS):
            x = LEFT_MARGIN + col * H_PITCH
            y = PAGE_H - TOP_MARGIN - LABEL - row * V_PITCH
            n, module, qr_size = draw_sticker(c, x, y, icon)
    c.showPage()

    # Page 2: alignment test, print on plain paper and hold against a label sheet.
    for row in range(ROWS):
        for col in range(COLS):
            x = LEFT_MARGIN + col * H_PITCH
            y = PAGE_H - TOP_MARGIN - LABEL - row * V_PITCH
            draw_sticker(c, x, y, icon, outline=True)
    c.setFont("Helvetica", 9)
    c.setFillColor(HexColor("#777777"))
    c.drawCentredString(PAGE_W / 2, 0.3 * inch,
                        "ALIGNMENT TEST - print on plain paper at 100% / Actual Size and hold against an OL177 sheet")
    c.showPage()
    c.save()

    single = os.path.join(HERE, "evapotrack-sticker-single.pdf")
    c = canvas.Canvas(single, pagesize=(LABEL, LABEL))
    c.setTitle("Evapotrack App Store Sticker")
    draw_sticker(c, 0, 0, icon)
    c.showPage()
    c.save()

    print(f"QR: {n}x{n} modules, module {module / inch * 25.4:.2f} mm, "
          f"code {qr_size / inch:.2f} in")
    print(sheet)
    print(single)


if __name__ == "__main__":
    build()
