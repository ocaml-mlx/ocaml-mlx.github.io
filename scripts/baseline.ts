import { execFile } from 'node:child_process';
import { createHash } from 'node:crypto';
import { access, mkdir, mkdtemp, readFile, rename, rm } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { promisify } from 'node:util';

export async function baselinePath(): Promise<string> {
  const archive = resolve('tests/fixtures/site-baseline.tar.gz');
  const hash = createHash('sha256').update(await readFile(archive)).digest('hex');
  const root = resolve('.build/parity-baselines');
  const output = join(root, hash);
  try {
    await access(join(output, 'index.html'));
    return output;
  } catch (error) {
    if (!(error instanceof Error) || !('code' in error) || error.code !== 'ENOENT') throw error;
  }
  await mkdir(root, { recursive: true });
  const stage = await mkdtemp(join(root, 'extract-'));
  try {
    await promisify(execFile)('tar', ['-xzf', archive, '-C', stage]);
    await access(join(stage, 'index.html'));
    try {
      await rename(stage, output);
    } catch (error) {
      if (!(error instanceof Error) || !('code' in error) || !['EEXIST', 'ENOTEMPTY'].includes(String(error.code))) throw error;
      await access(join(output, 'index.html'));
    }
    return output;
  } finally {
    await rm(stage, { recursive: true, force: true });
  }
}
