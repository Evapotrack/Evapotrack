# EvapoTrack change log

Every change made to the repository is recorded here, together with **what it replaced** and **how to get the prior state back**. Git keeps every version of every file. These notes say where to look and why each change was made.

| Period | Record |
|---|---|
| 2026-03-01 → 2026-04-08 | Commit history on `main` up to `89cc8c8` (summarized in [`../releases/README.md`](../releases/README.md)) |
| 2026-07-26 | Branch `claude/matts-hydroponics-outreach-vwiicq` (camera photos; not merged) |
| 2026-09-27 → 2026-09-30 | Branch `claude/wonderful-edison-i0ukly` ("revision 2"), with its own file-by-file record in `engineering/revision-2/CHANGELOG-DETAILED.md` |
| **2026-10-05 → 2026-10-07** | [`2026-10-05_to_2026-10-07.md`](2026-10-05_to_2026-10-07.md): QR sticker, reviews and plans, research, version record, website corrections, `release/1.2` |

## Terms used in these records

| Term | Meaning |
|---|---|
| **Next** | The app's **suggested amount for the next watering** (an amount of water, not a time) |
| Expected (1.2) | Revision 2's estimate of how much water the plant will retain at the next watering; Next = Expected ÷ (1 − goal runoff) |
| Retained | Water added − runoff collected, for one watering |
| Runoff % | Runoff collected ÷ water added |
| Goal runoff | The runoff % the grower aims for (default 15%) |
| Max Retention Capacity | The most water the pot's medium takes in during one watering before runoff begins |

## Website hosting (evapotrack.com)

- **Domain:** evapotrack.com is registered at **Namecheap**, and its DNS records there point the domain at GitHub Pages.
- **Hosting:** GitHub Pages publishes the `docs/` folder of `main`. `docs/CNAME` contains `evapotrack.com`.
- **Publishing:** merging into `main` changes the live site within minutes. Reverting that merge restores the previous site.
- **DNS:** no planned step changes DNS, the Namecheap settings or `docs/CNAME`. If the site ever stops loading after a merge, check:
  - GitHub › repository Settings › Pages: source `main` / `/docs`, custom domain `evapotrack.com`, HTTPS enforced.
  - Namecheap › Domain List › evapotrack.com › Advanced DNS, compared with GitHub's documented Pages values. For an apex domain these are A records 185.199.108.153, 185.199.109.153, 185.199.110.153 and 185.199.111.153, and usually a `www` CNAME to the account's `github.io` host.

## How prior states are preserved

- Nothing has been deleted from history. No force-push, no rebase of a pushed branch, no deleted branch.
- The prior state of every changed file is the parent commit of the change. To see it: `git show <commit>^:<path>`. To restore one file: `git checkout <commit>^ -- <path>`, then commit. To undo a whole change: `git revert <commit>`.
- **Archive tags** mark the important prior states, so they stay findable even if branches are later cleaned up. They are listed in the period record.
