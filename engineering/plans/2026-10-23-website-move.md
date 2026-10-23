# Moving evapotrack.com to its own public repository, then making this one private (option C1, approved 2026-10-23)

**Why:** the privacy audit ([`../reviews/2026-10-22-privacy-audit.md`](../reviews/2026-10-22-privacy-audit.md)) recommends making this repository private, which hides the source code and the old items in history without rewriting history. On GitHub's free plan, a private repository can't publish GitHub Pages, so the website moves first. The App Store privacy-policy and support URLs, and the in-app Watering Protocol link, all point at evapotrack.com, so the site has to stay up.

## Prepared (2026-10-23, cloud session)

- The contents of the new repository `Evapotrack/evapotrack-website` are ready: one commit with `docs/` exactly as live on `main` (`6094e32`), plus a short README.
  - The six internal documents that `main` also publishes are left out: Architecture, DataModel, NavigationMap, Requirements, Specification, video plan. They stay here in `engineering/app-docs/`.
  - Every page, image, the video, `CNAME` and the Search Console file are byte-for-byte the same.
- GitHub doesn't let the cloud session create repositories (HTTP 403), so you create the empty one.

## Steps (you, about 20 minutes; do 4 and 5 back to back)

1. **Create the repository:** GitHub › New repository › Owner `Evapotrack`, name **`evapotrack-website`**, **Public**. Leave it empty: no README, license or .gitignore.
2. **Tell the cloud session.** It pushes the prepared commit.
3. **(Recommended) Verify the domain:** GitHub › your profile Settings › Pages › Add a domain › `evapotrack.com`. GitHub shows a TXT record; add it at Namecheap › Domain List › evapotrack.com › Advanced DNS, then click Verify. This only *adds* a record; leave the existing A and CNAME records alone. It stops anyone else claiming the domain while it moves.
4. **Release the domain from this repository:** `Evapotrack/Evapotrack` › Settings › Pages › Custom domain › **Remove**. The site is offline from here until step 5 finishes.
5. **Publish from the new repository:** `Evapotrack/evapotrack-website` › Settings › Pages:
   - Source: **Deploy from a branch**, branch `main`, folder **`/docs`** › Save.
   - Custom domain: `evapotrack.com` › Save. Wait for the DNS check to pass.
   - Tick **Enforce HTTPS** once it's offered (the certificate can take minutes to an hour).
6. **Check** https://evapotrack.com, `/privacy-policy`, `/support`, `/watering-protocol` and `/reference`. Also check that the internal pages, such as `/Architecture`, are gone.
7. **Make the repositories private:** `Evapotrack/Evapotrack` › Settings › General › Danger Zone › Change visibility › **Private**. Do the same for `Evapotrack/cantillon-crush` (your decision, 2026-10-23).
8. **Tell the cloud session.** It updates `CLAUDE.md`, the runbook's release-day steps and the status note.

**DNS at Namecheap doesn't change** (apart from the optional TXT record): the A records point at GitHub Pages' shared addresses, and `www` points at `evapotrack.github.io`; both serve whichever repository holds the custom domain.

**If something goes wrong in step 5:** put the custom domain back on `Evapotrack/Evapotrack` (Settings › Pages), which is still public until step 7. The old site returns as it was.

## What changes afterwards

- **Release day** (runbook F4, plan Phase 7): copy `release/1.2`'s `docs/` pages into `evapotrack-website`'s `docs/` and push. This replaces "merge into `main`". Merging into `main` here will no longer change the website.
- PR #1's and `release/1.2`'s website text stays held exactly as before. It is copied over only when the matching app version is live.
- The Claude GitHub app keeps working with private repositories.
