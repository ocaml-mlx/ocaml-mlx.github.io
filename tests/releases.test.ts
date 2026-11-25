import { strict as assert } from 'node:assert';
import { test } from 'node:test';
import { renderReleases } from '../scripts/releases.ts';

test('release output preserves API order, fallback names, Markdown, and optional values', async () => {
  const item = {
    draft: false,
    prerelease: false,
    tag_name: 'v0.12',
    name: null,
    published_at: null,
    html_url: 'https://github.com/ocaml-mlx/mlx/releases/tag/v0.12',
    body: '**New** syntax',
  };
  const releases = await renderReleases([
    item,
    { ...item, draft: true },
    { ...item, name: 'vPreview / Test', tag_name: 'preview', body: null, prerelease: true },
  ]);
  assert.equal(releases.length, 2);
  assert.equal(releases[0].name, '0.12');
  assert.equal(releases[0].slug, '0-12');
  assert.equal(releases[0].bodyHtml, '<p><strong>New</strong> syntax</p>\n');
  assert.equal(releases[0].date, '');
  assert.equal(releases[1].name, 'Preview / Test');
  assert.equal(releases[1].slug, 'preview-test');
  assert.equal(releases[1].bodyHtml, '');
  assert.equal(releases[1].prerelease, true);
});

test('malformed release data is rejected at the adapter', async () => {
  await assert.rejects(renderReleases({ message: 'API failure' }), /must be an array/);
  await assert.rejects(renderReleases([{ draft: false }]), /draft and prerelease/);
  await assert.rejects(renderReleases([{
    draft: false, prerelease: false, name: null, tag_name: 'v1', body: null,
    published_at: null, html_url: 'javascript:alert(1)',
  }]), /HTTP URL/);
});
