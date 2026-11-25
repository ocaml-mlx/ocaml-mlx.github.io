# ocaml-mlx website

Landing page and documentation for `mlx`, generated with YOCaml and Ochre.
Pagefind provides browser search.

## Local development

Use Node.js 22.22 or later, opam 2.2 or later, and the Oniguruma development
library with `pkg-config`. The opam lock file uses OCaml 5.4.0.

```sh
opam switch create . 5.4.0
eval "$(opam env)"
opam install ocamlformat.0.29.0 -y
opam install . --locked --deps-only -y
npm ci
npm run dev
```

Open `http://127.0.0.1:4321`. The server rebuilds when content, templates,
styles, browser scripts, or generator sources change. Reload the page after
the build completes.

Useful scripts:

- `npm run dev` - build, watch sources, and serve the site
- `npm run build` - build the static site into `dist/`
- `npm run preview` - preview the production build locally
- `npm run check` - check TypeScript, OCaml, formatting, and generator tests
- `npm test` - check build recovery, preview serving, release input, and the parity runner
- `npm run test:parity` - compare `dist/` with the saved reference site

Both servers accept `-- --port 4322`.

## Verify output

Install the test browser, then build with the saved release response:

```sh
npx playwright install chromium
npm run check
npm test
RELEASES_FILE=tests/fixtures/releases.json npm run build
npm run test:parity
```

On supported Linux CI images, use `npx playwright install chromium --with-deps`.

The comparison covers all 12 pages in both themes, mobile and desktop layouts,
print, links, metadata, Markdown exports, sitemaps, search, code copying, menus,
themes, and link prefetch. The report is written to `.workplace/parity/latest/`.
See [the reference fixture notes](tests/fixtures/README.md) for the measured
browser raster exception.

## Structure

- `/` - custom landing page
- `/docs/` - documentation
- `/changelog/` - simple release history page sourced from GitHub Releases
- `*.md` docs mirrors - raw Markdown with normalized frontmatter

Main source locations:

- `site/` - YOCaml generation, Markdown rendering, and Ochre integration
- `templates/` - shared page layouts and components
- `assets/landing.json` - landing-page lists and code examples
- `assets/js/` - theme, navigation, search, copying, and prefetch behavior
- `assets/highlight/` - fixed grammars and processed light/dark themes
- `src/content/docs/docs/` - documentation source
- `src/styles/` - authored styles and shared tokens
- `scripts/build.ts` - assets, release input, search indexing, and publication

Builds use a private staging directory. A failed build preserves the last
successful `dist/`; successful builds remove output for deleted source pages.
Astro and Starlight are not build dependencies. Retained styles and licenses
are documented in [assets/LICENSES.md](assets/LICENSES.md).

Ochre is pinned to `c8d6ca1ce6769462f72907689cbba604f2351931`.
The published 1.1.0 release produces different token colors.

## Cloudflare Pages

Build in an environment with the Node and OCaml dependencies above, then upload
`dist/`. Set `CLOUDFLARE_PROJECT_NAME`, `CLOUDFLARE_ACCOUNT_ID`, and
`CLOUDFLARE_API_TOKEN` in your CI environment.

```sh
npm run build
npx wrangler pages deploy dist --project-name="$CLOUDFLARE_PROJECT_NAME" --branch=main
```

For preview deployments, pass the pull-request branch name with `--branch`.
Keep `main` as the Pages production branch.

For an existing Git-integrated Pages project, disable automatic production and
preview builds before using an external CI builder. Cloudflare supports
[Wrangler uploads to existing Git-integrated projects](https://developers.cloudflare.com/pages/configuration/git-integration/#disable-automatic-deployments).
The build needs the OCaml toolchain, so the former Astro framework preset is
not sufficient.

Production builds fetch public releases from `ocaml-mlx/mlx`. Set `GH_API_TOKEN`
to increase the GitHub API limit. `RELEASES_FILE` is for deterministic test builds.
