import { strict as assert } from 'node:assert';
import { test } from 'node:test';
import { preview } from '../scripts/preview.ts';
import { baselinePath } from '../scripts/baseline.ts';

test('preview serves pages, assets, redirects, Markdown, and the site 404', async () => {
  const server = await preview(await baselinePath(), 0);
  try {
    const address = server.address();
    assert(address && typeof address === 'object');
    const origin = `http://127.0.0.1:${address.port}`;
    const home = await fetch(origin);
    assert.equal(home.status, 200);
    assert.match(await home.text(), /JSX in OCaml/);
    const redirect = await fetch(`${origin}/docs`, { redirect: 'manual' });
    assert.equal(redirect.status, 301);
    assert.equal(redirect.headers.get('location'), '/docs/');
    const markdown = await fetch(`${origin}/docs/installation.md`);
    assert.equal(markdown.status, 200);
    assert.match(markdown.headers.get('content-type') ?? '', /text\/markdown/);
    const favicon = await fetch(`${origin}/favicon.svg`);
    assert.equal(favicon.headers.get('content-type'), 'image/svg+xml');
    const missing = await fetch(`${origin}/missing`);
    assert.equal(missing.status, 404);
    assert.match(await missing.text(), /Page not found/);
  } finally {
    await new Promise<void>((done, reject) => server.close((error) => error ? reject(error) : done()));
  }
});
