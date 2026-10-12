"""Generate the Evapotrack 8" x 10" booth display flyer.

Outputs (next to this script):
  evapotrack-flyer-8x10.pdf      8 x 10 in, vector text and QR code (print this)
  evapotrack-flyer-8x10-300dpi.png  the same at 300 dpi, for print shops that want an image
  evapotrack-flyer-preview.png   small preview

The QR code opens the Evapotrack page in the App Store. It is not part of the
website (docs/), so generating or printing it changes nothing on evapotrack.com.

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
WEBSITE = "evapotrack.com"
NAME = "EVAPOTRACK"
TAGLINE = "Optimize Plant Watering"
CALL = "Scan to download on the App Store"

NAVY = HexColor("#1F3A5F")
BLUE = HexColor("#2F6DBD")      # readable on white (5.2:1)
SLATE = HexColor("#4B5563")
QR_DARK = HexColor("#1B2A33")

W, H = 8 * inch, 10 * inch
MARGIN = 0.5 * inch             # keep everything inside a frame mat or trim edge


def rounded_icon(size_px=1024):
    icon = Image.open(ICON).convert("RGBA").resize((size_px, size_px), Image.LANCZOS)
    mask = Image.new("L", (size_px, size_px), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size_px - 1, size_px - 1),
                                           radius=int(size_px * 0.2237), fill=255)
    icon.putalpha(mask)
    return ImageReader(icon)


def centered(c, text, y, font, size, color, kerning=0):
    c.setFillColor(color)
    c.setFont(font, size)
    if kerning:
        # Letter spacing is drawing state; save and restore it so it doesn't leak into later lines.
        c.saveState()
        width = c.stringWidth(text, font, size) + kerning * (len(text) - 1)
        x = (W - width) / 2
        t = c.beginText(x, y)
        t.setFont(font, size)
        t.setCharSpace(kerning)
        t.textOut(text)
        c.drawText(t)
        c.restoreState()
    else:
        c.drawCentredString(W / 2, y, text)


def draw_qr(c, x, y, size, icon):
    """QR code with error correction H and the app icon in the middle."""
    qr = segno.make(APP_STORE_URL, error="h", micro=False)
    matrix = list(qr.matrix_iter(border=0))
    n = len(matrix)
    module = size / n
    c.setFillColor(QR_DARK)
    path = c.beginPath()
    for r, row in enumerate(matrix):
        col = 0
        while col < n:
            if row[col]:
                start = col
                while col < n and row[col]:
                    col += 1
                path.rect(x + start * module, y + (n - 1 - r) * module,
                          (col - start) * module, module * 1.02)
            else:
                col += 1
    c.drawPath(path, stroke=0, fill=1, fillMode=FILL_NON_ZERO)
    pad_modules = 11 if n % 2 else 10
    pad = pad_modules * module
    px, py = x + (size - pad) / 2, y + (size - pad) / 2
    c.setFillColor(white)
    c.roundRect(px, py, pad, pad, pad * 0.2, stroke=0, fill=1)
    c.drawImage(icon, px + module, py + module, pad - 2 * module, pad - 2 * module, mask="auto")
    return n, module


def build():
    icon = rounded_icon()
    pdf = os.path.join(HERE, "evapotrack-flyer-8x10.pdf")
    c = canvas.Canvas(pdf, pagesize=(W, H))
    c.setTitle("Evapotrack - Optimize Plant Watering (8x10 booth flyer)")

    # Top: app icon
    icon_size = 1.45 * inch
    top = H - MARGIN - 0.1 * inch
    c.drawImage(icon, (W - icon_size) / 2, top - icon_size, icon_size, icon_size, mask="auto")

    # Name and tagline
    y = top - icon_size - 0.92 * inch
    centered(c, NAME, y, "Helvetica-Bold", 58, NAVY, kerning=4)
    y -= 0.62 * inch
    centered(c, TAGLINE, y, "Helvetica", 30, BLUE)

    # QR code, with a white quiet zone of 4 modules built in
    qr_size = 3.7 * inch
    qr_y = y - 0.45 * inch - qr_size
    n, module = draw_qr(c, (W - qr_size) / 2, qr_y, qr_size, icon)

    # Call to action and website
    y = qr_y - 0.55 * inch
    centered(c, CALL, y, "Helvetica-Bold", 24, NAVY)
    c.setStrokeColor(HexColor("#D5DEE9"))
    c.setLineWidth(1)
    c.line(W / 2 - 1.6 * inch, y - 0.42 * inch, W / 2 + 1.6 * inch, y - 0.42 * inch)
    centered(c, WEBSITE, MARGIN + 0.25 * inch, "Helvetica-Bold", 36, BLUE)

    c.showPage()
    c.save()

    import pymupdf
    doc = pymupdf.open(pdf)
    doc[0].get_pixmap(dpi=300).save(os.path.join(HERE, "evapotrack-flyer-8x10-300dpi.png"))
    doc[0].get_pixmap(dpi=60).save(os.path.join(HERE, "evapotrack-flyer-preview.png"))
    print(f"QR: {n}x{n} modules, module {module / inch * 25.4:.2f} mm, code {qr_size / inch:.2f} in")
    print(pdf)


if __name__ == "__main__":
    build()
