#!/bin/sh
set -eu
generator=$(realpath "$1")
root=$(realpath "$2")
scratch=$(mktemp -d "${TMPDIR:-/tmp}/mlx-generator.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/src/content/docs/docs" "$scratch/assets/js" "$scratch/templates" "$scratch/site"
ln -s "$root/assets/highlight" "$scratch/assets/highlight"
printf '{}\n' > "$scratch/assets/landing.json"
: > "$scratch/assets/js/theme.js"
for file in content.ml highlight.ml markdown.ml main.ml; do
  ln -s "$root/site/$file" "$scratch/site/$file"
done
printf '%s\n' '{{ title }}|{{ body | safe }}|P:{{ previous.url }}:N:{{ next.url }}' > "$scratch/templates/page.html"
printf '%s\n' '{{ kind }}' > "$scratch/templates/landing.html"
printf '%s\n' '<article>{{ body | safe }}</article>' > "$scratch/templates/card.html"
printf '%s\n' '<h{{ depth }} id="{{ id }}">{{ text | safe }}</h{{ depth }}>' > "$scratch/templates/heading.html"
printf '%s\n' '{"releases":[],"error":null}' > "$scratch/releases.json"
cat > "$scratch/src/content/docs/docs/installation.md" <<'MD'
---
title: First title
description: Initial description.
slug: docs/installation
---

## First heading

TyXML's typed HTML model and "quoted" prose. Wait... -- now, but `it's-code` stays literal.

```ocaml
let value = 42
```
MD
cat > "$scratch/src/content/docs/docs/index.mdx" <<'MD'
---
title: Documentation home
description: Select a guide.
slug: docs
template: splash
hero:
  title: Documentation home
  tagline: Select a guide.
  actions: []
---

import { Card, CardGrid } from '@astrojs/starlight/components';

## Choose

<CardGrid stagger>
	<Card title="Setup" icon="download">
		[Read setup](/docs/installation/).
	</Card>
	<Card title="Next" icon="code">
		[Read next](/docs/installation/).
	</Card>
</CardGrid>
MD
(
  cd "$scratch"
  "$generator" --output "$scratch/output" --releases "$scratch/releases.json"
)
grep -Fq 'First title' "$scratch/output/docs/installation/index.html"
grep -Fq 'id="first-heading"' "$scratch/output/docs/installation/index.html"
grep -Fq 'data-code="let value = 42"' "$scratch/output/docs/installation/index.html"
grep -Fq 'title: First title' "$scratch/output/docs/installation.md"
grep -Fq 'TyXML’s typed HTML model and “quoted” prose' "$scratch/output/docs/installation/index.html"
grep -Fq 'Wait… — now' "$scratch/output/docs/installation/index.html"
grep -Fq "it's-code" "$scratch/output/docs/installation/index.html"
grep -Fq '|P::N:' "$scratch/output/docs/installation/index.html"
test -f "$scratch/output.yocaml-cache"
test ! -e "$scratch/output/.yocaml-cache"
test "$(grep -o '<article>' "$scratch/output/docs/index.html" | wc -l | tr -d ' ')" = 2
if grep -Fq 'data-language="text"' "$scratch/output/docs/index.html"; then exit 1; fi
before=$(shasum -a 256 "$scratch/output/docs/installation/index.html")
(
  cd "$scratch"
  "$generator" --output "$scratch/output" --releases "$scratch/releases.json"
)
after=$(shasum -a 256 "$scratch/output/docs/installation/index.html")
test "$before" = "$after"
cat > "$scratch/src/content/docs/docs/installation.md" <<'MD'
---
title: Updated title
description: Initial description.
slug: docs/installation
---

## Updated heading

```ocaml
let value = "changed"
```
MD
(
  cd "$scratch"
  "$generator" --output "$scratch/output" --releases "$scratch/releases.json"
)
grep -Fq 'Updated title' "$scratch/output/docs/installation/index.html"
grep -Fq 'id="updated-heading"' "$scratch/output/docs/installation/index.html"
grep -Fq 'data-code="let value = &#x22;changed&#x22;"' "$scratch/output/docs/installation/index.html"
grep -Fq 'title: Updated title' "$scratch/output/docs/installation.md"
if grep -Fq 'First heading' "$scratch/output/docs/installation/index.html"; then exit 1; fi
cat > "$scratch/src/content/docs/docs/installation.md" <<'MD'
---
title: "Setup: \"quotes\" #1"
description: "Use #hash: value"
slug: docs/installation
---

## Updated heading
MD
(
  cd "$scratch"
  "$generator" --output "$scratch/output" --releases "$scratch/releases.json"
)
grep -Fq 'title: "Setup: \"quotes\" #1"' "$scratch/output/docs/installation.md"
grep -Fq 'description: "Use #hash: value"' "$scratch/output/docs/installation.md"
cat > "$scratch/src/content/docs/docs/installation.md" <<'MD'
---
title: "Multi\nline"
description: "Use #hash: value"
slug: docs/installation
---

## Updated heading
MD
(
  cd "$scratch"
  "$generator" --output "$scratch/output" --releases "$scratch/releases.json"
)
grep -Fq 'title: "Multi\nline"' "$scratch/output/docs/installation.md"
cat >> "$scratch/src/content/docs/docs/installation.md" <<'MD'

```ocaml
let amount = 7
```
MD
rm "$scratch/assets/highlight"
cp -R "$root/assets/highlight" "$scratch/assets/highlight"
sed 's/"tokenColors":\[/"tokenColors":[{"scope":"source.ocaml","settings":{"fontStyle":"bold"}},/' "$scratch/assets/highlight/night-owl-dark.json" > "$scratch/styled-theme.json"
chmod u+w "$scratch/assets/highlight/night-owl-dark.json"
cp "$scratch/styled-theme.json" "$scratch/assets/highlight/night-owl-dark.json"
(
  cd "$scratch"
  "$generator" --output "$scratch/styled-output" --releases "$scratch/releases.json"
)
grep -Fq 'class="ochre-font"' "$scratch/styled-output/docs/installation/index.html"
grep -Fq -- '--0-font-weight:bold' "$scratch/styled-output/docs/installation/index.html"
cat > "$scratch/src/content/docs/docs/new-guide.md" <<'MD'
---
title: Added guide
description: A new source document.
slug: docs/new-guide
---

## Fresh content
MD
(
  cd "$scratch"
  "$generator" --output "$scratch/expanded-output" --releases "$scratch/releases.json"
)
grep -Fq 'Added guide' "$scratch/expanded-output/docs/new-guide/index.html"
grep -Fq '<loc>https://ocaml-mlx.pages.dev/docs/new-guide/</loc>' "$scratch/expanded-output/sitemap-0.xml"
printf '%s\n' '{"releases":[{"name":"1.2","tagName":"v1.2","slug":"1-2","publishedAt":"2026-01-02T00:00:00Z","date":"Jan 2, 2026","htmlUrl":"https://example.com/release","bodyHtml":"<p>Notes</p>","prerelease":false}],"error":null}' > "$scratch/release.json"
(
  cd "$scratch"
  "$generator" --output "$scratch/release-output" --releases "$scratch/release.json"
)
grep -Fq 'repository.</p></div> <div class="release-list"> <section' "$scratch/release-output/changelog/index.html"
grep -Fq '<h2>1.2</h2> <p> <code>v1.2</code>' "$scratch/release-output/changelog/index.html"
grep -Fq 'Jan 2, 2026</time> <a' "$scratch/release-output/changelog/index.html"
printf '%s\n' '{"releases":[{"prerelease":false,"name":8}],"error":null}' > "$scratch/invalid-releases.json"
if (
  cd "$scratch"
  "$generator" --output "$scratch/invalid-releases-output" --releases "$scratch/invalid-releases.json"
) > "$scratch/releases-error.log" 2>&1; then
  echo "Malformed release input was accepted" >&2
  exit 1
fi
grep -Fq 'releases[0].name must be a string' "$scratch/releases-error.log"
sed 's|slug: docs/installation|slug: docs/../escape|' "$scratch/src/content/docs/docs/installation.md" > "$scratch/invalid.md"
cp "$scratch/invalid.md" "$scratch/src/content/docs/docs/installation.md"
if (
  cd "$scratch"
  "$generator" --output "$scratch/invalid-output" --releases "$scratch/releases.json"
) > "$scratch/error.log" 2>&1; then
  echo "Invalid route was accepted" >&2
  exit 1
fi
grep -Fq 'unsafe route' "$scratch/error.log"
sed 's|slug: docs/../escape|slug: docs/installation|' "$scratch/invalid.md" > "$scratch/src/content/docs/docs/installation.mdx"
rm "$scratch/src/content/docs/docs/installation.md"
printf '\n<Mystery />\n' >> "$scratch/src/content/docs/docs/installation.mdx"
if (
  cd "$scratch"
  "$generator" --output "$scratch/invalid-mdx-output" --releases "$scratch/releases.json"
) > "$scratch/mdx-error.log" 2>&1; then
  echo "Unsupported MDX was accepted" >&2
  exit 1
fi
grep -Fq 'unsupported MDX' "$scratch/mdx-error.log"
rm "$scratch/src/content/docs/docs/installation.mdx"
sed 's|slug: docs/../escape|slug: docs/installation|' "$scratch/invalid.md" > "$scratch/src/content/docs/docs/installation.md"
rm "$scratch/assets/js/theme.js"
if (
  cd "$scratch"
  "$generator" --output "$scratch/missing-theme-output" --releases "$scratch/releases.json"
) > "$scratch/theme-error.log" 2>&1; then
  echo "Missing theme script was accepted" >&2
  exit 1
fi
grep -Fq 'required asset missing: assets/js/theme.js' "$scratch/theme-error.log"
test ! -e "$scratch/missing-theme-output/docs/installation/index.html"
