import { cp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { pages } from '../site.js';

type Page = {
  path: string;
  title: string;
  description: string;
  section: 'landing' | 'docs' | 'blog';
  html: string;
  type: 'website' | 'article';
  date?: string;
};

const root = fileURLToPath(new URL('../', import.meta.url));
const dist = resolve(root, 'dist');
const origin = 'https://ocaml-mlx.github.io';

function escapeHtml(value: string): string {
  return value.replaceAll('&', '&amp;').replaceAll('"', '&quot;').replaceAll("'", '&#39;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}

function validatePages(value: unknown): asserts value is Page[] {
  if (!Array.isArray(value) || value.length === 0) throw new Error('Expected a non-empty list of canonical pages');
  const paths = new Set<string>();
  for (const page of value) {
    if (typeof page !== 'object' || page === null) throw new Error('Invalid page entry');
    const { path, title, description, section, html, type, date } = page as Record<string, unknown>;
    if (typeof path !== 'string' || !/^\/(?:[a-z0-9-]+\/)*$/.test(path) || paths.has(path)) {
      throw new Error(`Invalid or duplicate canonical path: ${String(path)}`);
    }
    paths.add(path);
    if (typeof title !== 'string' || !title.trim() || typeof description !== 'string' || !description.trim() || typeof html !== 'string' || !html.trim()) {
      throw new Error(`Missing title, description, or body for ${path}`);
    }
    if (!['landing', 'docs', 'blog'].includes(String(section)) || !['website', 'article'].includes(String(type))) {
      throw new Error(`Invalid section or Open Graph type for ${path}`);
    }
    if ((path === '/') !== (section === 'landing') || (path.startsWith('/docs/')) !== (section === 'docs') || (path.startsWith('/blog/')) !== (section === 'blog')) {
      throw new Error(`Invalid section for ${path}`);
    }
    if (date !== undefined && (type !== 'article' || typeof date !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(date) || Number.isNaN(Date.parse(`${date}T00:00:00Z`)) || new Date(`${date}T00:00:00Z`).toISOString().slice(0, 10) !== date)) {
      throw new Error(`Invalid published date for ${path}`);
    }
  }
  if (!paths.has('/') || !paths.has('/docs/') || !paths.has('/blog/')) throw new Error('Missing a required section root');
}

function render(template: string, page: Page, is404 = false): string {
  const canonical = `${origin}${page.path}`;
  const openGraph = is404 ? '' : [
    `<meta property="og:title" content="${escapeHtml(page.title)}" />`,
    `<meta property="og:description" content="${escapeHtml(page.description)}" />`,
    `<meta property="og:url" content="${escapeHtml(canonical)}" />`,
    `<meta property="og:type" content="${page.type}" />`,
    ...(page.date ? [`<meta property="article:published_time" content="${escapeHtml(page.date)}" />`] : []),
  ].join('\n    ');
  const fields: Record<string, string> = {
    title: escapeHtml(page.title),
    description: escapeHtml(page.description),
    canonical: is404 ? '' : `<link rel="canonical" href="${escapeHtml(canonical)}" />`,
    openGraph,
    robots: is404 ? '<meta name="robots" content="noindex" />' : '',
    docsActive: page.section === 'docs' ? ' aria-current="page"' : '',
    blogActive: page.section === 'blog' ? ' aria-current="page"' : '',
    content: page.html,
  };
  return template.replace(/\{\{(title|description|canonical|openGraph|robots|docsActive|blogActive|content)\}\}/g, (_, field: string) => fields[field] ?? '');
}

async function build(): Promise<void> {
  validatePages(pages);
  const template = await readFile(resolve(root, 'index.html'), 'utf8');
  await rm(dist, { recursive: true, force: true });
  await mkdir(dist, { recursive: true });
  await cp(resolve(root, 'assets'), resolve(dist, 'assets'), { recursive: true });
  await cp(resolve(root, 'app.js'), resolve(dist, 'app.js'));
  await cp(resolve(root, 'routes.js'), resolve(dist, 'routes.js'));
  await cp(resolve(root, 'style.css'), resolve(dist, 'style.css'));
  for (const page of pages) {
    const directory = resolve(dist, `.${page.path}`);
    await mkdir(directory, { recursive: true });
    await writeFile(resolve(directory, 'index.html'), render(template, page));
  }
  const missing: Page = {
    path: '/',
    title: 'Page not found — mlx',
    description: 'This page does not exist. Return to the mlx website or read the documentation.',
    section: 'landing',
    html: '<div class="landing"><section class="hero" aria-labelledby="not-found-title"><h1 id="not-found-title">Page not found</h1><p class="lead">This page does not exist.</p><div class="hero-actions"><a class="site-button site-button-primary" href="/">Back to mlx</a><a class="site-button site-button-secondary" href="/docs/">Read the documentation</a></div></section></div>',
    type: 'website',
  };
  await writeFile(resolve(dist, '404.html'), render(template, missing, true));
  const sitemap = pages.map(page => `  <url><loc>${escapeHtml(`${origin}${page.path}`)}</loc></url>`).join('\n');
  await writeFile(resolve(dist, 'sitemap.xml'), `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${sitemap}\n</urlset>\n`);
  await writeFile(resolve(dist, 'robots.txt'), `User-agent: *\nAllow: /\nSitemap: ${origin}/sitemap.xml\n`);
  await writeFile(resolve(dist, '.nojekyll'), '');
}

await build();
