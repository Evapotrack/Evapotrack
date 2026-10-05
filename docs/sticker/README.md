# Evapotrack App Store QR Sticker (3" x 3")

Scanning opens the Evapotrack page in the App Store app on iPhone/iPad:
https://apps.apple.com/app/evapotrack/id6761138265

| File | Use |
|---|---|
| `evapotrack-sticker-OL177.pdf` | **Page 1:** 6 stickers laid out for OnlineLabels **OL177WJ** (Waterproof Matte Inkjet, 3" x 3", 6 per sheet). **Page 2:** the same layout with dashed outlines, for an alignment test. |
| `evapotrack-sticker-single.pdf` | One 3" x 3" sticker, for print shops or Maestro Label Designer. |
| `evapotrack-sticker-preview.png` | Preview image. |
| `make_sticker.py` | Regenerates everything (`pip install segno reportlab pillow`). |

## Printing on OL177WJ
1. Print **page 2 only** on plain paper. Hold it against a label sheet up to a light and check that the dashed boxes line up with the labels.
2. Print **page 1** on the OL177WJ sheet. Load it so the printer prints on the matte face. Settings:
   - Scale: **100% / Actual Size** (not "Fit to page")
   - Paper type: **Matte Photo Paper** (or "Premium Presentation Matte"); quality: **High**
3. Let the ink dry for about 15 minutes before handling. Waterproof inkjet film can smudge until the ink has set.

If the stickers are shifted, adjust `LEFT_MARGIN` / `TOP_MARGIN` in `make_sticker.py` and run it again.
The artwork stays at least 0.15" inside each label edge to allow for small printer drift.

## Design notes
- QR error correction is **H (30%)**, so the center droplet icon does not affect scanning.
- Each module is about 1.4 mm. That scans easily from roughly 10–25 cm (4–10 in) away.
- The white quiet zone is inside the sticker, so the code still scans on dark surfaces.
- Every code on the sheet was checked with a decoder and opens the App Store link.
