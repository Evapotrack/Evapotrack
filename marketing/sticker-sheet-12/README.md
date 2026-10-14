# Evapotrack sticker sheet: 12 per page, front and back

**Front:** 12 square stickers, each **1.8333 in** (11/6 in) once cut. Each shows **evapotrack.com** at the top, the Evapotrack app icon in the middle, and **Optimize Plant Watering** at the bottom.
**Back:** a QR code behind each sticker that opens the Evapotrack App Store page (https://apps.apple.com/app/evapotrack/id6761138265). All 12 were checked with a decoder.

| File | Use |
|---|---|
| `evapotrack-stickers-12-front-and-back.pdf` | **Print this double-sided.** Page 1 = front, page 2 = back |
| `evapotrack-stickers-12-front.pdf` / `-back.pdf` | Single pages, for printing one side, then feeding the sheet back in |
| `evapotrack-stickers-12-alignment-test.pdf` | The same two pages with dashed cut outlines, for a test on plain paper |
| `preview-front.png`, `preview-back.png` | Previews |
| `make_sheet.py` | Regenerates everything (`pip install segno reportlab pillow pymupdf`) |

## Layout
- **Grid:** 3 columns × 4 rows, 0.25 in gaps, centered on the US Letter page. Margins are 1.25 in left/right and 1.458 in top/bottom, inside every printer's non-printable edge.
- **Front and back line up whichever way the printer flips.** The grid is symmetric and every back square holds the same QR code. A long-edge flip puts column 1's back behind column 3's front; a short-edge flip swaps the top and bottom rows. In both cases each sticker has a QR code exactly behind it.
- **Crop marks** sit only in the gaps and margins, at every cut line, so they never show on a sticker. Text and icon stay at least 0.1 in inside each cut line, and the QR codes have their white margin inside the square.

## Printing
1. **Test first on plain paper.** Print `…-alignment-test.pdf` double-sided at **100% / Actual Size** (not "Fit to page"), then hold it up to a light. Each QR square should sit behind a dashed sticker square. Duplex printers can be off by 1–2 mm, and the 0.1 in safe margin covers that.
2. **Print the real sheet:** `…-front-and-back.pdf`, double-sided, 100%. If your printer can't print double-sided: print `…-front.pdf`, put the sheet back in so the back gets printed, then print `…-back.pdf`. Check your printer's feed direction with a marked plain sheet first.
3. **Cut** along the crop marks with a paper trimmer or a craft knife and ruler.

## Before buying paper
On ordinary sticker paper, the back side is the **peel-off backing (liner)**. A QR code printed there comes off with the liner when the sticker is applied, and most liners don't hold inkjet ink well. Options:
- Use the stickers as **handouts**: people scan the back, then peel and stick the front. This works with printable-back sticker paper.
- Use **double-sided printable** label stock, or print the back on the liner only if your paper's liner is printable.
- For a QR code on the **stuck-down sticker itself**, use the 3×3 in sticker in `../sticker/`, which has the QR on its front.

These stickers name no app features, so they stay accurate for v1.1 now and 1.2 later. Nothing here is part of the website (`docs/`).
