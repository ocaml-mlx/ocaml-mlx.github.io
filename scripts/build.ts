import { spawn } from 'node:child_process';
import { cp, mkdir, mkdtemp, readFile, rename, rm, stat, writeFile } from 'node:fs/promises';
import { basename, join } from 'node:path';
import { build } from 'esbuild';
import * as pagefind from 'pagefind';
import { loadReleases } from './releases.ts';

const args = process.argv.slice(2);
if (args.length !== 0 && (args.length !== 2 || args[0] !== '--output')) {
  throw new Error('Usage: node scripts/build.ts [--output dist-name]');
}
const outputName = args[1] ?? 'dist';
if (!/^dist(?:-[a-z0-9-]+)?$/.test(outputName)) {
  throw new Error('Output must be dist or a dist- prefixed directory in the repository root');
}

const root = process.cwd();
const workspace = join(root, '.build');
const output = join(root, outputName);
const previous = join(workspace, `${outputName}.previous`);
const lock = join(workspace, 'build.lock');

function isErrorCode(error: unknown, code: string): boolean {
  return error instanceof Error && 'code' in error && error.code === code;
}

async function exists(path: string): Promise<boolean> {
  try {
    await stat(path);
    return true;
  } catch (error) {
    if (isErrorCode(error, 'ENOENT')) return false;
    throw error;
  }
}

async function acquireLock(): Promise<void> {
  await mkdir(workspace, { recursive: true });
  try {
    await writeFile(lock, String(process.pid), { flag: 'wx' });
  } catch (error) {
    if (!isErrorCode(error, 'EEXIST')) throw error;
    const pid = Number(await readFile(lock, 'utf8'));
    if (!Number.isSafeInteger(pid) || pid <= 0) throw new Error(`Invalid build lock: ${lock}`);
    try {
      process.kill(pid, 0);
    } catch (processError) {
      if (!isErrorCode(processError, 'ESRCH')) throw processError;
      await rm(lock);
      await writeFile(lock, String(process.pid), { flag: 'wx' });
      return;
    }
    throw new Error(`A site build is already running (process ${pid})`);
  }
}

async function command(binary: string, arguments_: string[]): Promise<void> {
  await new Promise<void>((done, reject) => {
    const child = spawn(binary, arguments_, { stdio: 'inherit' });
    child.once('error', reject);
    child.once('exit', (code, signal) => {
      if (code === 0) done();
      else reject(new Error(`${binary} failed (${signal ?? code})`));
    });
  });
}

function checkPagefind(errors: string[]): void {
  if (errors.length) throw new Error(`Pagefind: ${errors.join('\n')}`);
}

async function indexSite(directory: string): Promise<void> {
  try {
    const created = await pagefind.createIndex();
    checkPagefind(created.errors);
    if (!created.index) throw new Error('Pagefind did not create an index');
    const indexed = await created.index.addDirectory({ path: directory });
    checkPagefind(indexed.errors);
    if (!indexed.page_count) throw new Error('Pagefind found no HTML pages');
    const written = await created.index.writeFiles({ outputPath: join(directory, 'pagefind') });
    checkPagefind(written.errors);
    console.log(`Indexed ${indexed.page_count} HTML files`);
  } finally {
    await pagefind.close();
  }
}

await acquireLock();
let stage: string | undefined;
try {
  if (await exists(previous)) {
    if (await exists(output)) await rm(previous, { recursive: true });
    else await rename(previous, output);
  }
  stage = await mkdtemp(join(workspace, 'site-'));
  const releases = join(stage, 'releases.json');
  const site = join(stage, 'public');
  await writeFile(releases, JSON.stringify(await loadReleases()));
  await command('opam', ['exec', '--', 'dune', 'exec', '--root', '.', 'site/main.exe', '--', '--output', site, '--releases', releases]);
  await cp('public', site, { recursive: true });
  await cp('assets/public', site, { recursive: true });
  await build({
    entryPoints: { site: 'assets/js/site.ts', prefetch: 'assets/js/prefetch.ts' },
    outdir: join(site, 'assets'),
    bundle: true,
    platform: 'browser',
    format: 'esm',
    target: 'es2022',
    minify: true,
    legalComments: 'eof',
  });
  await build({
    entryPoints: {
      'authored-docs': 'src/styles/starlight.css',
      'authored-landing': 'src/styles/marketing.css',
    },
    outdir: join(site, 'css'),
    bundle: true,
    minify: true,
    loader: { '.woff': 'file', '.woff2': 'file' },
    assetNames: 'fonts/[name]-[hash]',
    legalComments: 'eof',
  });
  await indexSite(site);
  await stat(join(site, 'index.html'));
  if (await exists(output)) await rename(output, previous);
  try {
    await rename(site, output);
  } catch (error) {
    if (await exists(previous)) await rename(previous, output);
    throw error;
  }
  await rm(previous, { recursive: true, force: true });
  console.log(`Built ${basename(output)} with YOCaml and Ochre`);
} finally {
  if (stage) await rm(stage, { recursive: true, force: true });
  await rm(lock);
}
