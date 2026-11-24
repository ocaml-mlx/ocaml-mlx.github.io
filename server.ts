import { createServer } from 'node:http';
import { readFile, realpath, stat } from 'node:fs/promises';
import { extname, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(fileURLToPath(new URL('.', import.meta.url)), 'dist');
const port = Number(process.env.PORT ?? '4327');
if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('PORT must be an integer from 1 to 65535');
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
  '.xml': 'application/xml; charset=utf-8',
  '.ico': 'image/x-icon',
};

async function notFound(method: string | undefined, response: import('node:http').ServerResponse): Promise<void> {
  const body = await readFile(resolve(root, '404.html'));
  response.writeHead(404, { 'Content-Type': mime['.html'], 'Cache-Control': 'no-store' });
  response.end(method === 'HEAD' ? undefined : body);
}

createServer(async (request, response) => {
  try {
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      response.writeHead(405, { Allow: 'GET, HEAD' }).end();
      return;
    }
    const url = new URL(request.url ?? '/', 'http://localhost');
    const pathname = decodeURIComponent(url.pathname);
    if (pathname.split('/').some((part) => part.startsWith('.'))) {
      await notFound(request.method, response);
      return;
    }
    let file = resolve(root, `.${pathname}`);
    if (!file.startsWith(`${root}${sep}`) && file !== root) {
      await notFound(request.method, response);
      return;
    }
    const info = await stat(file);
    const actual = await realpath(file);
    if (actual !== root && !actual.startsWith(`${root}${sep}`)) {
      await notFound(request.method, response);
      return;
    }
    if (info.isDirectory()) {
      if (!pathname.endsWith('/')) {
        response.writeHead(301, { Location: `${url.pathname}/${url.search}`, 'Cache-Control': 'no-store' }).end();
        return;
      }
      file = resolve(file, 'index.html');
    }
    const target = await realpath(file);
    if (target !== root && !target.startsWith(`${root}${sep}`)) {
      await notFound(request.method, response);
      return;
    }
    const type = mime[extname(file)];
    if (!type) {
      await notFound(request.method, response);
      return;
    }
    const body = await readFile(file);
    const cache = extname(file) === '.woff2' ? 'public, max-age=86400' : 'no-store';
    response.writeHead(200, { 'Content-Type': type, 'Cache-Control': cache });
    response.end(request.method === 'HEAD' ? undefined : body);
  } catch (error) {
    if (error instanceof URIError) {
      response.writeHead(400).end('Bad request');
      return;
    }
    if (error instanceof Error && 'code' in error && (error.code === 'ENOENT' || error.code === 'ENOTDIR')) {
      try {
        await notFound(request.method, response);
      } catch {
        response.writeHead(500).end('Missing 404.html; run npm run build');
      }
      return;
    }
    console.error(error);
    response.writeHead(500).end('Internal server error');
  }
}).listen(port, '127.0.0.1', () => {
  console.log(`mlx website: http://localhost:${port}`);
});
