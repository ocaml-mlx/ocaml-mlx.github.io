The four grammar JSON files (`html`, `lisp`, `ocaml`, `shellscript`) come from
Shikijs grammars 3.23.0 installed with Expressive Code 0.41.7.
The two `night-owl` JSON files come from Starlight 0.38.1's
`integrations/expressive-code/themes/night-owl-{dark,light}.jsonc`.
Expressive Code applied its 5.5:1 minimum token contrast against `#23262f`
(dark) and `#f6f7f9` (light), with underline styles for link rules.

The migration compared all 20 documentation code blocks, at each source byte,
in both themes. The pinned Ochre source matched every color and font style.
`npm run test:parity` checks the rendered blocks against the saved reference.
Production reads these vendored files without Shiki or Starlight installed.

Original Night Owl theme: Sarah Drasner, MIT license.
Shiki and Shikijs grammar distributions: MIT license. See `LICENSE` here.
