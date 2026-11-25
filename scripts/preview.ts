import { createServer, type Server } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { extname, join, resolve, sep } from 'node:path';
import { pathToFileURL } from 'node:url';

const contentTypes: Record<string, string> = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json',
  '.svg': 'image/svg+xml',
  '.xml': 'application/xml',
  '.md': 'text/markdown; charset=utf-8',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.wasm': 'application/wasm',
};

export async function preview(directory: string, port: number): Promise<Server> {
  const root = resolve(directory);
  await stat(join(root, 'index.html'));
  const server = createServer(async (request, response) => {
    try {
      const url = new URL(request.url ?? '/', 'http://localhost');
      const path = decodeURIComponent(url.pathname);
      let file = resolve(root, `.${path}`);
      if (file !== root && !file.startsWith(root + sep)) {
        response.writeHead(400).end();
        return;
      }
      if ((await stat(file)).isDirectory()) {
        if (!path.endsWith('/')) {
          response.writeHead(301, { Location: `${url.pathname}/${url.search}` }).end();
          return;
        }
        file = join(file, 'index.html');
      }
      response.setHeader('Content-Type', contentTypes[extname(file)] ?? 'application/octet-stream');
      response.end(await readFile(file));
    } catch {
      try {
        response.writeHead(404, { 'Content-Type': 'text/html; charset=utf-8' });
        response.end(await readFile(join(root, '404.html')));
      } catch {
        response.end('Not found');
      }
    }
  });
  await new Promise<void>((done, reject) => {
    server.once('error', reject);
    server.listen(port, '127.0.0.1', done);
  });
  return server;
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const args = process.argv.slice(2);
  if (args.length !== 0 && (args.length !== 2 || args[0] !== '--port')) {
    throw new Error('Usage: npm run preview -- [--port 4321]');
  }
  const port = Number(args[1] ?? 4321);
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('Invalid port');
  await preview('dist', port);
  console.log(`Preview: http://127.0.0.1:${port}`);
}
