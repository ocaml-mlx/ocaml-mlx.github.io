# Migration references

`site-baseline.tar.gz` contains the original 12-page Astro/Starlight build.
The OCaml parity runner extracts it into a content-addressed directory under `.build`.
It is test input only. The YOCaml generator does not read it.

`releases.json` is the public GitHub release response used for that build.
Set `RELEASES_FILE=tests/fixtures/releases.json` for repeatable comparisons.

Baseline versions: Astro 6.0.4, Starlight 0.38.1, Expressive Code 0.41.7,
Pagefind 1.4.0, and starlight-dot-md 0.2.0.

The comparison checks structure, links, public Markdown, sitemaps, responsive
screenshots, print, themes, search, navigation, and code copying. It excludes
generator metadata. The only pixel exception is the measured Chromium rounding
variation on the mobile TOC chevron: at most two pixels at x141–142, y78, with
channel differences at most one. Each occurrence is recorded in the report.
