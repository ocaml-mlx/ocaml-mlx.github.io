# ocaml-mlx website plan

## Product goal

Build a quiet, technical website for `mlx` with:

- a custom landing page at `/`
- a documentation site at `/docs`
- a changelog at `/changelog`
- raw markdown exports for docs pages
- Cloudflare Pages preview deploys on PRs and production deploys on `main`

## Chosen direction

- Audience: OCaml developers first
- Tone: quiet technical, like a premium README or language manual
- Theme: balanced light/dark
- Structure: separate landing page plus docs
- Branding: typographic `mlx` wordmark for v1
- Hero CTA: install first, docs second
- Syntax docs: deep reference, not only tutorial content
- Guides: all guide tracks matter equally
- Changelog source: GitHub Releases

## Technical approach

- Generator: YOCaml with reusable Jingoo templates
- Syntax highlighting: Ochre with fixed grammars and light/dark themes
- Landing and docs: shared design tokens and preserved page layouts
- Changelog: GitHub Releases rendered with `marked`
- Raw Markdown: source-driven exports from the generator
- Search: Pagefind
- Hosting: static output uploaded to Cloudflare Pages from an OCaml-capable builder

The migration preserves the original appearance and behavior. The commands and
deployment steps are in `README.md`. The execution phases below record the
original Astro/Starlight rollout.

## Information architecture

- `/`
- `/docs`
- `/docs/installation`
- `/docs/editors`
- `/docs/formal-syntax`
- `/docs/guides/melange-reason-react`
- `/docs/guides/dream-html-of-jsx`
- `/docs/guides/tyxml`
- `/docs/templates`
- `/docs/projects-using-mlx`
- `/changelog`

## Execution plan

### Phase 1 - Bootstrap the site

1. Scaffold Astro + Starlight in the empty repo.
2. Set up package manager, scripts, formatting, and basic project metadata.
3. Configure site URL, base navigation, and content collections.
4. Verify local build and local docs search.

Done when:

- `npm run dev` works
- `npm run build` succeeds
- Starlight renders a minimal docs shell

### Phase 2 - Define the shared design system

1. Create global tokens for color, type, spacing, radii, borders, and code surfaces.
2. Build a light theme that feels paper-like and a dark theme that feels terminal-like.
3. Choose the exact font pairing for headings, body, and mono.
4. Define reusable primitives for buttons, code frames, section dividers, grids, and link lists.

Done when:

- landing and docs share one visual system
- both themes pass basic contrast and readability checks

### Phase 3 - Build the landing page

1. Build the hero with install CTA, docs CTA, and a real `.mlx` example.
2. Add a `What's JSX` section with side-by-side code examples.
3. Add ecosystem support with tooling notes and the `dune-project` snippet.
4. Add editors support with links to VS Code, Neovim, issues, and tree-sitter.
5. Add guides, templates, and projects-using-mlx sections.
6. Add footer links to the repo and org.

Done when:

- the page clearly explains what `mlx` is within one screen and a short scroll
- the install path is obvious
- the homepage hands off naturally into `/docs`

### Phase 4 - Build the docs structure

1. Write `Installation` with fast path and optional extra packages.
2. Write `Editors` with setup instructions and troubleshooting notes.
3. Write `Formal syntax` as a deeper reference with examples and edge cases.
4. Write the three guide tracks with equal weight.
5. Add `Templates` and `Projects using mlx` pages.

Done when:

- sidebar structure is stable
- search surfaces the expected key topics
- every homepage section maps to a docs destination

### Phase 5 - Add Starlight theme customization

1. Add a local theme layer via custom CSS first.
2. Override Starlight components only where CSS is not enough.
3. Polish sidebar, TOC, code blocks, headings, callouts, and pagination.
4. Ensure the landing page and docs feel related without making docs overly marketing-heavy.

Done when:

- docs chrome feels intentional and branded
- code blocks and prose rhythm feel consistent with the landing page

### Phase 6 - Add changelog and markdown export

1. Install and configure `starlight-changelogs`.
2. Connect changelog pages to GitHub Releases.
3. Add a changelog entry point to navigation.
4. Install and configure `starlight-dot-md`.
5. Verify `.md` output routes for a few docs pages.

Done when:

- `/changelog` renders correctly
- docs pages are available as raw markdown

### Phase 7 - Prepare deployment

1. Add repo metadata and a short README for contributors.
2. Confirm Cloudflare Pages build settings: `npm run build` and output `dist`.
3. Connect GitHub repo to Cloudflare Pages.
4. Verify preview URLs for PR branches.
5. Verify production deploy on `main`.

Done when:

- PRs create preview deployments
- `main` updates production

### Phase 8 - QA and polish

1. Check desktop and mobile layouts.
2. Check both themes.
3. Check link integrity and 404 handling.
4. Validate code block readability and copy-paste quality.
5. Verify no section feels too glossy or too generic.

Done when:

- mobile layout is clean
- docs are readable and searchable
- homepage feels calm, sharp, and developer-first

## Open validation task

The live browser pass is still blocked until the Playwriter Chrome extension is enabled on a tab. Once connected, validate these URLs in-browser:

- `https://www.ultracite.ai`
- `https://voidzero.dev/`
- `https://x.ai/`
- `https://hex.tech/`
- `https://viteplus.dev/guide/`
- `https://v0.app/chat/mlx-landing-page-but-oxidise-n3WzxYI7uAw`

The `v0` link may still require auth or may remain private even after browser access is enabled.
