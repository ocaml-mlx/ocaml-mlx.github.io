import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { extname, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('.', import.meta.url));
const port = Number(process.env.PORT ?? '4327');
const mime: Record<string, string> = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.webp': 'image/webp',
  '.png': 'image/png',
  '.ttf': 'font/ttf',
  '.woff2': 'font/woff2',
  '.txt': 'text/plain; charset=utf-8',
};

createServer(async (request, response) => {
  try {
    const url = new URL(request.url ?? '/', 'http://localhost');
    const pathname = decodeURIComponent(url.pathname);
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      response.writeHead(405, { Allow: 'GET, HEAD' }).end();
      return;
    }
    if (pathname.split('/').some((part) => part.startsWith('.'))) {
      response.writeHead(404).end('Not found');
      return;
    }
    let file = resolve(root, `.${pathname}`);
    if (!file.startsWith(`${resolve(root)}${sep}`) && file !== resolve(root)) {
      response.writeHead(404).end('Not found');
      return;
    }
    if ((await stat(file)).isDirectory()) file = resolve(file, 'index.html');
    const type = mime[extname(file)];
    if (!type) {
      response.writeHead(404).end('Not found');
      return;
    }
    const body = await readFile(file);
    const cache = extname(file) === '.woff2' ? 'public, max-age=86400' : 'no-store';
    response.writeHead(200, { 'Content-Type': type, 'Cache-Control': cache });
    response.end(request.method === 'HEAD' ? undefined : body);
  } catch (error) {
    const status = error instanceof URIError ? 400 : 404;
    response.writeHead(status).end(status === 400 ? 'Bad request' : 'Not found');
  }
}).listen(port, '127.0.0.1', () => {
  console.log(`mlx website: http://localhost:${port}`);
});
