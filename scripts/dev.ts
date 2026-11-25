import { spawn } from 'node:child_process';
import { watch } from 'node:fs';
import { preview } from './preview.ts';

const args = process.argv.slice(2);
if (args.length !== 0 && (args.length !== 2 || args[0] !== '--port')) {
  throw new Error('Usage: npm run dev -- [--port 4321]');
}
const port = Number(args[1] ?? 4321);
if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('Invalid port');

function rebuild(): Promise<void> {
  return new Promise((done, reject) => {
    const child = spawn(process.execPath, [
      '--experimental-strip-types', 'scripts/build.ts',
    ], { stdio: 'inherit' });
    child.once('error', reject);
    child.once('exit', (code) => code === 0 ? done() : reject(new Error(`Site build failed (${code})`)));
  });
}

await rebuild();
const server = await preview('dist', port);
let active = false;
let dirty = false;
async function changed(): Promise<void> {
  dirty = true;
  if (active) return;
  active = true;
  try {
    while (dirty) {
      dirty = false;
      try {
        await rebuild();
      } catch (error) {
        console.error(error);
      }
    }
  } finally {
    active = false;
  }
}

const watchers = ['src/content', 'src/styles', 'public', 'templates', 'assets', 'site', 'scripts'].map((directory) =>
  watch(directory, { recursive: true }, () => { void changed(); }),
);
for (const file of ['dune-project', 'package.json']) {
  watchers.push(watch(file, () => { void changed(); }));
}
for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.once(signal, () => {
    for (const watcher of watchers) watcher.close();
    server.close();
  });
}
console.log(`Development: http://127.0.0.1:${port} (rebuilds on source changes)`);
