import { strict as assert } from 'node:assert';
import { spawnSync } from 'node:child_process';
import { cp, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { resolve, join } from 'node:path';
import { test } from 'node:test';
import { baselinePath } from '../scripts/baseline.ts';

const baseline = await baselinePath();
const runner = resolve('scripts/parity.ts');

function parity(candidate: string, output: string, view = 'desktop-dark'): { status: number | null; output: string } {
  const result = spawnSync(process.execPath, [
    '--experimental-strip-types', runner,
    '--baseline', baseline, '--candidate', candidate, '--output', output,
    '--route', '/docs/installation/', '--view', view,
  ], { encoding: 'utf8', timeout: 120_000 });
  return { status: result.status, output: result.stdout + result.stderr };
}

test('baseline agrees with itself and rejects visual and interaction regressions', async () => {
  const scratch = await mkdtemp(join(tmpdir(), 'mlx-parity-'));
  const candidate = join(scratch, 'candidate');
  try {
    const control = parity(baseline, join(scratch, 'control'));
    assert.equal(control.status, 0, control.output);
    await cp(baseline, candidate, { recursive: true });
    const htmlFile = join(candidate, 'docs/installation/index.html');
    const original = await readFile(htmlFile, 'utf8');
    assert(original.includes('</body>'), 'Installation page has no closing body');
    const generator = original.replace(/(<meta name="generator" content=")[^"]+/g, '$1YOCaml');
    assert.notEqual(generator, original, 'Baseline has no generator metadata');
    await writeFile(htmlFile, generator);
    const generated = parity(candidate, join(scratch, 'generator'));
    assert.equal(generated.status, 0, generated.output);
    const description = original.replace(/(<meta name="description" content=")[^"]+/, '$1Changed description');
    assert.notEqual(description, original, 'Baseline has no SEO description');
    await writeFile(htmlFile, description);
    const seo = parity(candidate, join(scratch, 'seo'));
    assert.notEqual(seo.status, 0, 'SEO description mutation passed');
    assert.match(seo.output, /document structure differs/);
    await writeFile(htmlFile, original.replace('</body>', '<style>body{opacity:.5!important}</style></body>'));
    const visual = parity(candidate, join(scratch, 'visual'));
    assert.notEqual(visual.status, 0, 'Visual mutation passed');
    assert.match(visual.output, /screenshot pixels differ/);
    await writeFile(htmlFile, original.replace('</body>', '<style>body::after{content:"";position:fixed;top:20px;left:20px;width:1px;height:1px;background:red;z-index:99999}</style></body>'));
    const pixel = parity(candidate, join(scratch, 'pixel'), 'mobile-light');
    assert.notEqual(pixel.status, 0, 'One-pixel regression outside the mobile TOC passed');
    assert.match(pixel.output, /screenshot pixels differ/);
    await writeFile(htmlFile, original.replace('</body>', '<script>Object.defineProperty(navigator.clipboard,"writeText",{value:async()=>undefined})</script></body>'));
    const interaction = parity(candidate, join(scratch, 'interaction'));
    assert.notEqual(interaction.status, 0, 'Copy-button mutation passed');
    assert.match(interaction.output, /Code clipboard differs/);
  } finally {
    await rm(scratch, { recursive: true, force: true });
  }
});
