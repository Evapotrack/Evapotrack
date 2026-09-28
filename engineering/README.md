# engineering/

Internal engineering material for EvapoTrack, kept in the repository for future reference.

This folder is **outside `docs/`**, so GitHub Pages does not publish it on evapotrack.com. The repository itself is public, though, so anything here can be read on GitHub.

| Folder | Contents |
|---|---|
| [`reviews/`](reviews/) | The full periodic engineering review of 2026-09-27 (website, iOS app, algorithm audit, photo feature design), as the original HTML report and a Markdown version |
| [`revision-2/`](revision-2/) | The next revision's implementation: [`IMPLEMENTATION-REPORT.md`](revision-2/IMPLEMENTATION-REPORT.md) (Phase 36 final report, test counts, remaining issues, device checklist) and [`CHANGELOG-DETAILED.md`](revision-2/CHANGELOG-DETAILED.md) (every file: what existed before, what exists now, why) |
| [`research/algorithm/`](research/algorithm/) | Closed-loop simulation study used to choose the new Next recommendation model, with raw results |
| [`research/numeric-input/`](research/numeric-input/) | Python reference for `NumericInput.parse`, used to write its test vectors |
| [`research/export-snapshot/`](research/export-snapshot/) | Python reference for `DataExportService`, used to write the export snapshot tests |
| [`app-docs/`](app-docs/) | Architecture, data model, navigation map, requirements, specification and video plan. These used to be published from `docs/` and were moved here and updated |
| [`tools/`](tools/) | `swiftsyntax.py` (tree-sitter Swift syntax check: `pip install tree-sitter tree-sitter-swift`, then `python3 swiftsyntax.py <files>`) and `html2md.py` (converts the review HTML to Markdown) |

The Python scripts need only Python 3.9+ (plus the two tree-sitter packages for `swiftsyntax.py`). The reference models were needed because this revision was written in an environment without a Swift toolchain. The Swift code and tests have **not** been compiled or run; see the implementation report.
