# mlx website

The static website for [ocaml-mlx.github.io](https://ocaml-mlx.github.io).

Use Node.js 22.18 or newer. Run `npm install`, then `npm run build` to generate the static site in `dist/`. Run `npm start` to build and preview it at `http://localhost:4327`. Run `npm run check` to type-check and test it. The preview serves `dist/`, redirects directory paths to trailing slashes, and returns the generated 404 page for unknown paths.

Edit the source on `main`: `site.js` defines the HTML content and page metadata; `routes.js` defines canonical routes and legacy query URL redirects; `index.html` is the shared document template; `scripts/build.ts` creates one complete HTML file per route and the sitemap, robots file, and 404 page. `style.css`, `app.js`, and `assets/` provide the shared styles, clipboard behavior, and images. Pages are readable without JavaScript. Existing `?page=...` links at the root redirect to clean canonical paths in browsers.

GitHub Pages serves the repository root of `gh-pages`. Publish **only the contents of `dist/`** to that branch, not the source files. Use a separate clean worktree for `gh-pages`, replace its published files with the freshly built output, then commit and push a new commit without force-pushing. Keep the branch history and leave Pages configured for `gh-pages` at `/`.
