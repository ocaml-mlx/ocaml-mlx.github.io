# Asset provenance

- `public/css/vendor-base.css` and `public/css/print.css` derive from the
  Starlight 0.38.1 stylesheet distributed under the MIT license. The readable
  vendor source retains the selectors, layer order, and scoped component
  selectors used by the previous site. It also includes styles for the official
  Pagefind 1.4.0 UI. Licenses: `licenses/starlight-MIT.txt` and
  `licenses/pagefind-MIT.txt`.
- `public/css/code.css` and `public/css/expressive-code.css` derive from
  Expressive Code 0.41.7, MIT license. Copyright © 2023 Tibor Schiemann.
  License: `licenses/expressive-code-MIT.txt`.
- The authored styles import IBM Plex Sans, IBM Plex Mono, and Newsreader
  from the locked `@fontsource` packages. They use SIL Open Font License 1.1;
  full licenses are under `licenses/`.
- `public/css/theme-select.css` and the authored CSS in `src/styles/` come from
  this site's components. `assets/js/site.ts` maintains the prior UI behavior
  using the Pagefind 1.4.0 official UI.

The build does not read the saved Astro baseline. Font files are bundled from
the installed packages without changing their contents.

`js/prefetch.ts` preserves the site's Astro 6.0.4 hover, focus, and slow-connection
tap behavior. The upstream license is in `licenses/astro-MIT.txt`.

The docs-home `code` icon uses the Wikimedia Commons Codicons code SVG,
copyright © Microsoft Corporation et al., licensed under MIT/CC BY 4.0:
https://commons.wikimedia.org/wiki/File:Codicons_%E2%80%93_code.svg .
The `seti:vim` fallback uses Starlight's MIT-licensed `vim` path.
