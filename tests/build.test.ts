import { strict as assert } from 'node:assert';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { cp, mkdir, mkdtemp, readFile, readdir, rename, rm, stat, symlink, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { test } from 'node:test';

async function manifest(root: string): Promise<Record<string, string>> {
  const entries: Record<string, string> = {};
  async function visit(path: string, prefix: string): Promise<void> {
    for (const entry of await readdir(path, { withFileTypes: true })) {
      const name = prefix + entry.name;
      const file = join(path, entry.name);
      if (entry.isDirectory()) await visit(file, `${name}/`);
      else entries[name] = createHash('sha256').update(await readFile(file)).digest('hex');
    }
  }
  await visit(root, '');
  return Object.fromEntries(Object.entries(entries).sort(([a], [b]) => a.localeCompare(b)));
}

test('builds regenerate content, remove stale routes, and recover without replacing good output on failure', { timeout: 240_000 }, async () => {
  await mkdir('.build', { recursive: true });
  const scratch = await mkdtemp(resolve('.build/build-test-'));
  const output = join(scratch, 'dist-test');
  const releases = resolve('tests/fixtures/releases.json');
  const run = () => {
    const result = spawnSync(process.execPath, [
      '--experimental-strip-types', 'scripts/build.ts', '--output', 'dist-test',
    ], {
      cwd: scratch,
      env: { ...process.env, RELEASES_FILE: releases },
      encoding: 'utf8',
      timeout: 90_000,
    });
    return { status: result.status, output: result.stdout + result.stderr };
  };
  const success = () => {
    const result = run();
    assert.equal(result.status, 0, result.output);
  };
  try {
    for (const path of ['site', 'assets', 'templates', 'src/content', 'src/styles', 'public', 'scripts', 'dune-project', 'ocaml_mlx_website.opam', 'package.json']) {
      await cp(path, join(scratch, path), { recursive: true });
    }
    await symlink(resolve('node_modules'), join(scratch, 'node_modules'), 'dir');
    success();
    const first = await manifest(output);
    assert.equal(Object.keys(first).filter((path) => path.endsWith('.html')).length, 12);
    assert(!Object.keys(first).some((path) => path.includes('yocaml-cache')), 'Build cache was published');
    success();
    assert.deepEqual(await manifest(output), first, 'Repeated build changed output');

    const source = join(scratch, 'src/content/docs/docs/temporary.md');
    await writeFile(source, '---\ntitle: Temporary guide\ndescription: A generated page.\nslug: docs/temporary\n---\n\n## New heading\n\nDistinct searchable content.\n');
    success();
    assert.match(await readFile(join(output, 'docs/temporary/index.html'), 'utf8'), /Distinct searchable content/);
    assert.match(await readFile(join(output, 'sitemap-0.xml'), 'utf8'), /docs\/temporary\//);
    await rm(source);
    success();
    await assert.rejects(stat(join(output, 'docs/temporary/index.html')), { code: 'ENOENT' });
    await assert.rejects(stat(join(output, 'docs/temporary.md')), { code: 'ENOENT' });
    assert.deepEqual(await manifest(output), first, 'Deleted source left stale output');

    const installation = join(scratch, 'src/content/docs/docs/installation.mdx');
    const original = await readFile(installation, 'utf8');
    await writeFile(installation, original.replace('slug: docs/installation', 'slug: docs/../escape'));
    const failed = run();
    assert.notEqual(failed.status, 0);
    assert.match(failed.output, /unsafe route/);
    assert.deepEqual(await manifest(output), first, 'Failed build replaced successful output');

    await rename(output, join(scratch, '.build/dist-test.previous'));
    const recovered = run();
    assert.notEqual(recovered.status, 0);
    assert.deepEqual(await manifest(output), first, 'Interrupted publication was not recovered');
    await writeFile(installation, original);
    await writeFile(join(scratch, '.build/build.lock'), '1073741824');
    success();
    assert.deepEqual(await manifest(output), first, 'Recovery changed output');
  } finally {
    await rm(scratch, { recursive: true, force: true });
  }
});
