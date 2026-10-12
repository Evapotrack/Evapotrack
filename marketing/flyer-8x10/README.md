# Evapotrack 8" × 10" booth flyer

Contents: the app icon, **EVAPOTRACK**, "Optimize Plant Watering", a QR code that opens the Evapotrack page in the App Store (https://apps.apple.com/app/evapotrack/id6761138265), "Scan to download on the App Store", and **evapotrack.com**.

| File | Use |
|---|---|
| `evapotrack-flyer-8x10.pdf` | **Print this.** 8 × 10 in, vector text and QR code (sharp at any size) |
| `evapotrack-flyer-8x10-300dpi.png` | The same at 300 dpi (2400 × 3000 px), for print shops that ask for an image |
| `evapotrack-flyer-preview.png` | Small preview |
| `make_flyer.py` | Regenerates all three (`pip install segno reportlab pillow pymupdf`) |

## Printing
- Print at **100% / Actual Size** on 8 × 10 photo or cardstock (or 8.5 × 11 and trim). The white background means no bleed is needed.
- Everything sits at least 0.5 in from the edge, so a frame mat won't cover any of it.
- **Test before the booth:** scan the printed QR from about 1 m (3 ft) away with an iPhone camera. It should offer to open the App Store. The code is 3.7 in wide, with 2.3 mm modules, so it reads from a few metres away.

## Matches the live app and website
- **Live app:** v1.1. **Live website:** `main`.
- The flyer only names things that are true today: the app name, the tagline, the App Store link and the website address. It mentions no features, so it stays correct after 1.2 too.
- It is **not** part of the website (`docs/`), so making or printing it changes nothing on evapotrack.com.
- `docs/flyer.html` on the website, the 8.5 × 11 desk flyer from April, is left as it is.
