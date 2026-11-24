import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync, readFileSync, readdirSync, statSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { test } from "node:test";
import { documentationUrl, legacyLocation } from "../routes.js";

const origin = "https://ocaml-mlx.github.io";
const output = resolve("dist");
const routes = [
  ["/", "OCaml + JSX"],
  ["/docs/", "Installation"],
  ["/docs/jsx-syntax/", "JSX syntax"],
  ["/docs/how-it-works/", "How it works"],
  ["/docs/for-your-agent/", "For your agent"],
  ["/docs/editor-support/", "Editor support"],
  ["/docs/ecosystem/", "Ecosystem"],
  ["/docs/libraries/", "Libraries"],
  ["/blog/", "Blog"],
  ["/blog/hello-world/", "<Hello /> <World />"],
  ["/blog/melange-playground/", "Melange Playground supports mlx"],
  ["/blog/fragments-0-12/", "mlx 0.12 supports fragments"],
  ["/blog/ocaml-5-4/", "mlx supports OCaml 5.4"],
] as const;
const decode = (text: string) => text.replace(/&(amp|lt|gt|quot|#39);/g, entity =>
  ({ "&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": '"', "&#39;": "'" })[entity] ?? entity);
const htmlAt = (path: string) => readFileSync(join(output, path, "index.html"), "utf8");
const capture = (html: string, pattern: RegExp) => {
  const match = html.match(pattern);
  assert.ok(match, `Missing ${pattern}`);
  return decode(match[1]);
};

test("all canonical routes contain full content and unique metadata in the response HTML", () => {
  const titles = new Set<string>();
  const descriptions = new Set<string>();
  for (const [path, heading] of routes) {
    const html = htmlAt(path);
    assert.equal(capture(html, /<h1\b[^>]*>([\s\S]*?)<\/h1>/), heading);
    assert.equal([...html.matchAll(/<h1\b/g)].length, 1);
    const title = capture(html, /<title>([\s\S]*?)<\/title>/);
    const description = capture(html, /<meta name="description" content="([^"]+)"/);
    assert.ok(title.includes("mlx"));
    assert.ok(description.length > 20);
    titles.add(title);
    descriptions.add(description);
    assert.equal(capture(html, /<link rel="canonical" href="([^"]+)"/), origin + path);
    assert.equal(capture(html, /<meta property="og:url" content="([^"]+)"/), origin + path);
    assert.equal(capture(html, /<meta property="og:title" content="([^"]+)"/), title);
    assert.equal(capture(html, /<meta property="og:description" content="([^"]+)"/), description);
    assert.doesNotMatch(html, /<main\b[^>]*>\s*<\/main>/);
    assert.doesNotMatch(html, /content="noindex/);
    assert.doesNotMatch(html, /\{\{(?:title|description|canonical|content|docsActive|blogActive|openGraph)\}\}/);
  }
  assert.equal(titles.size, routes.length);
  assert.equal(descriptions.size, routes.length);
});

test("documentation and article content is present without running the browser script", () => {
  assert.match(htmlAt("/docs/"), /Prerequisites/);
  assert.match(htmlAt("/docs/"), /Unbound value div/);
  assert.doesNotMatch(htmlAt("/docs/"), /className/);
  assert.match(htmlAt("/docs/jsx-syntax/"), /Spread one children value/);
  assert.match(htmlAt("/docs/how-it-works/"), /ocamlc -pp mlx-pp -impl example\.mlx/);
  assert.match(htmlAt("/docs/ecosystem/"), /ocaml-lsp-server/);
  assert.match(htmlAt("/docs/for-your-agent/"), /skills\/setup-mlx\/SKILL\.md/);
  assert.match(htmlAt("/docs/for-your-agent/"), /skills\/mlx-syntax\/SKILL\.md/);
  assert.match(htmlAt("/blog/hello-world/"), /Welcome to the mlx website/);
  assert.match(htmlAt("/blog/fragments-0-12/"), /datetime="2026-11-02"/);
  assert.match(htmlAt("/blog/ocaml-5-4/"), /datetime="2025-12-25"/);
  for (const [path] of routes.filter(([path]) => path.startsWith("/blog/") && path !== "/blog/")) {
    assert.equal(capture(htmlAt(path), /<meta property="og:type" content="([^"]+)"/), "article");
  }
});

test("pages use versioned client assets instead of a cached query-page renderer", () => {
  const html = htmlAt("/docs/how-it-works/");
  const script = capture(html, /<script type="module" src="([^"]+)"/);
  assert.match(script, /^\/app\.[a-f0-9]{12}\.js$/);
  assert.match(html, /href="\/style\.[a-f0-9]{12}\.css"/);
  const client = readFileSync(join(output, script), "utf8");
  const routesImport = capture(client, /from "(\/routes\.[a-f0-9]{12}\.js)"/);
  assert.ok(existsSync(join(output, routesImport)));
  assert.doesNotMatch(client, /main\.innerHTML\s*=/);
  const oldEntry = readFileSync(join(output, "app.js"), "utf8");
  assert.ok(oldEntry.includes(script));
  assert.match(oldEntry, /main\.childElementCount === 0/);
});

test("every internal link and asset resolves, including cross-page fragments", () => {
  for (const [path] of routes) {
    const html = htmlAt(path);
    for (const match of html.matchAll(/\b(?:href|src)="([^"]+)"/g)) {
      const raw = decode(match[1]);
      const url = new URL(raw, origin + path);
      if (url.origin !== origin) continue;
      assert.ok(raw.startsWith("/") || raw.startsWith("#") || raw.startsWith(origin), `${path}: relative URL ${raw}`);
      assert.equal(url.searchParams.has("page"), false, `${path}: legacy navigation ${raw}`);
      const filename = join(output, url.pathname, url.pathname.endsWith("/") ? "index.html" : "");
      assert.ok(existsSync(filename), `${path}: missing ${raw}`);
      if (url.hash && filename.endsWith(".html")) {
        const target = readFileSync(filename, "utf8");
        assert.ok(target.includes(`id="${decodeURIComponent(url.hash.slice(1))}"`), `${path}: missing anchor ${raw}`);
      }
    }
    assert.match(html, /href="\/docs\/"/);
    assert.match(html, /href="\/blog\/"/);
  }
  assert.equal(documentationUrl("libraries#libraries-5"), "/docs/libraries/#libraries-5");
});

test("sitemap and robots expose canonical pages, excluding errors and legacy URLs", () => {
  const xml = readFileSync(join(output, "sitemap.xml"), "utf8");
  const locations = [...xml.matchAll(/<loc>(.*?)<\/loc>/g)].map(match => decode(match[1]));
  assert.deepEqual(locations.sort(), routes.map(([path]) => origin + path).sort());
  assert.equal(new Set(locations).size, routes.length);
  assert.doesNotMatch(xml, /\?page=|404\.html/);
  const robots = readFileSync(join(output, "robots.txt"), "utf8");
  assert.match(robots, /User-agent: \*/);
  assert.ok(robots.includes(`Sitemap: ${origin}/sitemap.xml`));
  assert.doesNotMatch(robots, /^Disallow:\s*\/\s*$/m);
  assert.ok(existsSync(join(output, ".nojekyll")));
  const missing = readFileSync(join(output, "404.html"), "utf8");
  assert.match(missing, /name="robots" content="noindex/);
  assert.match(missing, /<h1\b[^>]*>[\s\S]*?(?:404|not found)/i);
  assert.ok(missing.includes('href="/"'));
});

test("legacy URLs retain destinations, fragments, and unrelated parameters", () => {
  assert.equal(legacyLocation("?page=docs", ""), "/docs/");
  assert.equal(legacyLocation("?page=docs&topic=syntax", "#syntax-2"), "/docs/jsx-syntax/#syntax-2");
  assert.equal(legacyLocation("?page=docs&topic=agents", ""), "/docs/for-your-agent/");
  assert.equal(legacyLocation("?page=docs&topic=libraries", "#libraries-5"), "/docs/libraries/#libraries-5");
  assert.equal(legacyLocation("?page=blog&article=hello-world", ""), "/blog/hello-world/");
  assert.equal(legacyLocation("?page=landing&utm_source=old-link", "#projects"), "/?utm_source=old-link#projects");
  assert.equal(legacyLocation("?page=blog&article=missing", ""), "/blog/");
  assert.equal(legacyLocation("?page=docs&topic=constructor", ""), "/docs/");
  assert.equal(legacyLocation("?page=blog&article=__proto__", ""), "/blog/");
  assert.equal(legacyLocation("?page=https://example.com", ""), null);
  assert.equal(legacyLocation("?utm_source=search", ""), null);
});

test("rebuilding removes stale generated files and produces identical artifacts", () => {
  const fingerprint = () => {
    const files: string[] = [];
    const walk = (directory: string) => {
      for (const name of readdirSync(directory).sort()) {
        const file = join(directory, name);
        if (statSync(file).isDirectory()) walk(file);
        else files.push(file);
      }
    };
    walk(output);
    return files.map(file => [file.slice(output.length), createHash("sha256").update(readFileSync(file)).digest("hex")]);
  };
  const before = fingerprint();
  writeFileSync(join(output, "stale.html"), "old generated page");
  execFileSync(process.execPath, ["--experimental-strip-types", "scripts/build.ts"], { stdio: "pipe" });
  assert.equal(existsSync(join(output, "stale.html")), false);
  assert.deepEqual(fingerprint(), before);
});
