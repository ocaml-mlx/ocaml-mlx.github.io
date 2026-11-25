import { createServer, type Server } from 'node:http';
import { readFile, readdir, mkdir, writeFile } from 'node:fs/promises';
import { extname, join, relative, resolve, sep } from 'node:path';
import { pathToFileURL } from 'node:url';
import { chromium, type Browser, type BrowserContext, type Page } from 'playwright';
import sharp from 'sharp';
import { baselinePath } from './baseline.ts';

const routes = [
  '/',
  '/docs/',
  '/docs/installation/',
  '/docs/editors/',
  '/docs/formal-syntax/',
  '/docs/templates/',
  '/docs/projects-using-mlx/',
  '/docs/guides/melange-reason-react/',
  '/docs/guides/dream-html-of-jsx/',
  '/docs/guides/tyxml/',
  '/changelog/',
  '/404.html',
] as const;

const views = [
  { name: 'desktop-dark', width: 1440, height: 900, theme: 'dark' },
  { name: 'desktop-light', width: 1440, height: 900, theme: 'light' },
  { name: 'mobile-dark', width: 390, height: 844, theme: 'dark' },
  { name: 'mobile-light', width: 390, height: 844, theme: 'light' },
] as const;

type View = (typeof views)[number];
type VisualView = { name: string; width: number; height: number; theme: 'light' | 'dark' };
type ToleratedRasterDifference = {
  view: string;
  pixels: number;
  maximumChannelDifference: number;
  coordinates: [number, number][];
  reason: string;
};
const breakpointViews: VisualView[] = [
  { name: 'narrow-799-light', width: 799, height: 900, theme: 'light' },
  { name: 'wide-801-light', width: 801, height: 900, theme: 'light' },
  { name: 'sidebar-767-dark', width: 767, height: 900, theme: 'dark' },
  { name: 'sidebar-769-dark', width: 769, height: 900, theme: 'dark' },
  { name: 'marketing-1135-dark', width: 1135, height: 900, theme: 'dark' },
  { name: 'marketing-1137-dark', width: 1137, height: 900, theme: 'dark' },
];
type Options = {
  baseline: string;
  candidate: string;
  output: string;
  routes: string[];
  views: View[];
};

async function options(argv: string[]): Promise<Options> {
  const values = new Map<string, string[]>();
  for (let i = 0; i < argv.length; i++) {
    const key = argv[i];
    if (!key.startsWith('--') || !argv[i + 1] || argv[i + 1].startsWith('--')) {
      throw new Error(`Expected --name value, got ${key}`);
    }
    values.set(key, [...(values.get(key) ?? []), argv[++i]]);
  }
  for (const key of values.keys()) {
    if (!['--baseline', '--candidate', '--output', '--route', '--view'].includes(key)) {
      throw new Error(`Unknown option: ${key}`);
    }
  }
  const chosenRoutes = values.get('--route') ?? [...routes];
  const chosenViews = values.get('--view')?.map((name) => {
    const view = views.find((item) => item.name === name);
    if (!view) throw new Error(`Unknown view: ${name}`);
    return view;
  }) ?? [...views];
  for (const route of chosenRoutes) {
    if (!routes.includes(route as (typeof routes)[number])) throw new Error(`Unknown route: ${route}`);
  }
  return {
    baseline: resolve(values.get('--baseline')?.at(-1) ?? await baselinePath()),
    candidate: resolve(values.get('--candidate')?.at(-1) ?? 'dist'),
    output: resolve(values.get('--output')?.at(-1) ?? '.workplace/parity/latest'),
    routes: chosenRoutes,
    views: chosenViews,
  };
}

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

function equal(left: unknown, right: unknown, label: string): void {
  if (JSON.stringify(left) !== JSON.stringify(right)) {
    const difference = firstDifference(left, right, '$');
    throw new Error(`${label}\n${difference.path}\nBaseline: ${JSON.stringify(difference.left)}\nCandidate: ${JSON.stringify(difference.right)}`);
  }
}

function firstDifference(left: unknown, right: unknown, path: string): { path: string; left: unknown; right: unknown } {
  if (Array.isArray(left) && Array.isArray(right)) {
    if (left.length !== right.length) return { path: `${path}.length`, left: left.length, right: right.length };
    for (let index = 0; index < left.length; index++) {
      if (JSON.stringify(left[index]) !== JSON.stringify(right[index])) {
        return firstDifference(left[index], right[index], `${path}[${index}]`);
      }
    }
  } else if (typeof left === 'object' && left !== null && typeof right === 'object' && right !== null) {
    const a = Object.entries(left);
    const b = Object.entries(right);
    if (JSON.stringify(a.map(([key]) => key)) !== JSON.stringify(b.map(([key]) => key))) {
      return { path: `${path}.keys`, left: a.map(([key]) => key), right: b.map(([key]) => key) };
    }
    for (let index = 0; index < a.length; index++) {
      if (JSON.stringify(a[index][1]) !== JSON.stringify(b[index][1])) {
        return firstDifference(a[index][1], b[index][1], `${path}.${a[index][0]}`);
      }
    }
  } else if (typeof left === 'string' && typeof right === 'string' && Math.max(left.length, right.length) > 240) {
    let offset = 0;
    while (left[offset] === right[offset] && offset < Math.min(left.length, right.length)) offset++;
    return { path: `${path} at character ${offset}`, left: left.slice(Math.max(0, offset - 60), offset + 180), right: right.slice(Math.max(0, offset - 60), offset + 180) };
  }
  return { path, left, right };
}

async function files(root: string): Promise<string[]> {
  const found: string[] = [];
  async function visit(directory: string): Promise<void> {
    for (const entry of await readdir(directory, { withFileTypes: true })) {
      if (entry.isDirectory()) await visit(join(directory, entry.name));
      else if (entry.isFile()) found.push(relative(root, join(directory, entry.name)));
    }
  }
  await visit(root);
  return found.sort();
}

async function compareExports(baseline: string, candidate: string): Promise<void> {
  const required = (await files(baseline)).filter((name) => name.endsWith('.md') || name.startsWith('sitemap-') && name.endsWith('.xml') || name === 'favicon.svg');
  assert(required.filter((name) => name.endsWith('.md')).length === 9, 'Baseline must contain nine Markdown exports');
  assert(required.filter((name) => name.startsWith('sitemap-')).length === 2, 'Baseline must contain two sitemaps');
  const output = await files(candidate);
  equal(output.filter((name) => name.endsWith('.md') || name.startsWith('sitemap-') && name.endsWith('.xml') || name === 'favicon.svg'), required, 'Export paths differ');
  for (const name of required) {
    const [left, right] = await Promise.all([readFile(join(baseline, name)), readFile(join(candidate, name))]);
    assert(left.equals(right), `${name}: exported bytes differ`);
  }
}

function serve(root: string): Promise<{ server: Server; origin: string }> {
  const server = createServer(async (request, response) => {
    try {
      const path = decodeURIComponent(new URL(request.url ?? '/', 'http://localhost').pathname);
      const file = resolve(root, `.${path}`, path.endsWith('/') ? 'index.html' : '.');
      if (!file.startsWith(root + sep)) throw new Error('Outside output directory');
      const contents = await readFile(file);
      const type: Record<string, string> = {
        '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8',
        '.css': 'text/css; charset=utf-8', '.json': 'application/json',
        '.svg': 'image/svg+xml', '.xml': 'application/xml',
        '.wasm': 'application/wasm', '.md': 'text/markdown',
        '.woff': 'font/woff', '.woff2': 'font/woff2',
      };
      response.setHeader('Content-Type', type[extname(file)] ?? 'application/octet-stream');
      response.end(contents);
    } catch {
      response.writeHead(404);
      response.end('Not found');
    }
  });
  return new Promise((done, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', () => {
      const address = server.address();
      assert(address && typeof address !== 'string', 'Missing server port');
      done({ server, origin: `http://127.0.0.1:${address.port}` });
    });
  });
}

async function snapshot(page: Page): Promise<unknown> {
  return page.evaluate(() => {
    const text = (node: Element | null) => node?.textContent?.replace(/\s+/g, ' ').trim() ?? '';
    const attrs = (selector: string, attribute: string) =>
      [...document.querySelectorAll(selector)].map((element) => [element.getAttribute(attribute), text(element)]);
    return {
      title: document.title,
      lang: document.documentElement.lang,
      metadata: [...document.head.querySelectorAll('meta,link[rel="canonical"],link[rel="alternate"],link[rel="icon"],link[rel="manifest"]')]
        .filter((node) => node.getAttribute('name')?.toLowerCase() !== 'generator')
        .map((node) => [node.tagName, ...[...node.attributes].filter((attribute) => !['class', 'data-astro-cid'].includes(attribute.name)).map((attribute) => [attribute.name, attribute.value]).sort((a, b) => a[0].localeCompare(b[0]))]),
      headings: [...document.querySelectorAll('h1,h2,h3,h4,h5,h6')].map((node) => [node.tagName, node.id, text(node)]),
      links: attrs('a[href]', 'href'),
      main: text(document.querySelector('main')),
      code: [...document.querySelectorAll('pre')].map((node) => node.textContent),
      copy: [...document.querySelectorAll('.expressive-code button[data-code]')].map((node) => node.getAttribute('data-code')),
      ids: [...document.querySelectorAll('[id]')].map((node) => node.id),
    };
  });
}

async function open(context: BrowserContext, origin: string, route: string): Promise<Page> {
  const page = await context.newPage();
  const response = await page.goto(origin + route, { waitUntil: 'load' });
  assert(response?.ok(), `${route}: HTTP ${response?.status() ?? 'no response'}`);
  return page;
}

async function comparePages(contexts: [BrowserContext, BrowserContext], origins: [string, string], route: string): Promise<void> {
  const [baseline, candidate] = await Promise.all(contexts.map((context, index) => open(context, origins[index], route)));
  try {
    equal(await snapshot(baseline), await snapshot(candidate), `${route}: document structure differs`);
    const links = await candidate.evaluate(() => ({
      anchors: [...document.querySelectorAll('a[href^="#"]')]
        .filter((node) => !document.getElementById(decodeURIComponent(node.getAttribute('href')!.slice(1))))
        .map((node) => node.getAttribute('href')),
      internal: [...new Set([...document.querySelectorAll<HTMLAnchorElement>('a[href]')]
        .map((node) => new URL(node.href))
        .filter((url) => url.origin === location.origin)
        .map((url) => url.pathname))],
    }));
    assert(links.anchors.length === 0, `${route}: broken heading anchors: ${links.anchors.join(', ')}`);
    for (const path of links.internal) {
      const response = await candidate.request.get(origins[1] + path);
      assert(response.ok(), `${route}: internal link ${path} returned HTTP ${response.status()}`);
    }
  } finally {
    await Promise.all([baseline.close(), candidate.close()]);
  }
}

async function visual(contexts: [BrowserContext, BrowserContext], origins: [string, string], route: string, view: VisualView, output: string): Promise<ToleratedRasterDifference | null> {
  const pages = await Promise.all(contexts.map((context, index) => open(context, origins[index], route)));
  const [baseline, candidate] = pages;
  const id = (route === '/' ? 'landing' : route.replace(/^\/|\/$/g, '').replaceAll('/', '-')) + '-' + view.name;
  try {
    for (const page of pages) {
      await page.setViewportSize({ width: view.width, height: view.height });
      await page.evaluate((theme) => localStorage.setItem('starlight-theme', theme), view.theme);
      await page.reload();
      await page.evaluate(() => document.fonts.ready);
      await page.waitForFunction((theme) => document.documentElement.dataset.theme === theme, view.theme);
      await page.addStyleTag({ content: '*, *::before, *::after { animation-duration: 0s !important; transition-duration: 0s !important; caret-color: transparent !important; scroll-behavior: auto !important; }' });
      if (view.name.startsWith('print-')) await page.emulateMedia({ media: 'print' });
      await page.evaluate(() => new Promise<void>((done) => requestAnimationFrame(() => requestAnimationFrame(() => done()))));
      assert(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), `${id}: horizontal overflow`);
    }
    const left = await baseline.screenshot({ fullPage: true, animations: 'disabled' });
    const right = await candidate.screenshot({ fullPage: true, animations: 'disabled' });
    if (left.equals(right)) return null;
    const [first, second] = await Promise.all([sharp(left).ensureAlpha().raw().toBuffer({ resolveWithObject: true }), sharp(right).ensureAlpha().raw().toBuffer({ resolveWithObject: true })]);
    if (first.info.width === second.info.width && first.info.height === second.info.height && first.data.equals(second.data)) return null;
    await mkdir(output, { recursive: true });
    await Promise.all([writeFile(join(output, `${id}-baseline.png`), left), writeFile(join(output, `${id}-candidate.png`), right)]);
    if (first.info.width === second.info.width && first.info.height === second.info.height) {
      const coordinates: [number, number][] = [];
      let pixels = 0;
      let maximumChannelDifference = 0;
      for (let index = 0; index < first.data.length; index += 4) {
        let changed = false;
        for (let channel = 0; channel < 4; channel++) {
          const delta = Math.abs(first.data[index + channel] - second.data[index + channel]);
          if (delta) changed = true;
          maximumChannelDifference = Math.max(maximumChannelDifference, delta);
        }
        if (changed) {
          pixels++;
          if (coordinates.length < 3) coordinates.push([(index / 4) % first.info.width, Math.floor(index / 4 / first.info.width)]);
        }
      }
      if (view.width === 390 && view.height === 844 && pixels <= 2 && maximumChannelDifference <= 1
        && coordinates.every(([x, y]) => (x === 141 || x === 142) && y === 78)) {
        console.log(`RASTER ${id}: ${pixels} pixels, max channel delta ${maximumChannelDifference}, mobile TOC chevron`);
        return { view: id, pixels, maximumChannelDifference, coordinates, reason: 'Chromium mobile TOC chevron raster differs on baseline self-comparison' };
      }
    }
    throw new Error(`${id}: screenshot pixels differ (${first.info.width}x${first.info.height} vs ${second.info.width}x${second.info.height}); ${output}`);
  } finally {
    await Promise.all(pages.map((page) => page.close()));
  }
}

async function exercise(context: BrowserContext, origin: string): Promise<Record<string, unknown>> {
  const page = await open(context, origin, '/docs/installation/');
  try {
    const result: Record<string, unknown> = {};
    await page.getByRole('link', { name: 'Editors', exact: true }).hover();
    await page.locator(`link[rel="prefetch"][href="${origin}/docs/editors/"]`).waitFor({ state: 'attached', timeout: 5000 });
    result.prefetch = 'hover';
    await page.getByRole('button', { name: 'Search' }).first().click();
    assert(await page.locator('dialog[aria-label="Search"]').evaluate((node) => (node as HTMLDialogElement).open), 'Search dialog did not open');
    await page.locator('.pagefind-ui__search-input').fill('installation');
    await page.locator('.pagefind-ui__result-link').first().waitFor({ timeout: 10000 });
    result.search = await page.locator('.pagefind-ui__result-link').allTextContents();
    assert((result.search as string[]).some((value) => value.includes('Installation')), 'Search returned no installation page');
    await page.keyboard.press('Escape');
    assert(!(await page.locator('dialog[aria-label="Search"]').evaluate((node) => (node as HTMLDialogElement).open)), 'Search dialog did not close');
    await page.keyboard.press('ControlOrMeta+k');
    assert(await page.locator('dialog[aria-label="Search"]').evaluate((node) => (node as HTMLDialogElement).open), 'Search keyboard shortcut failed');
    await page.keyboard.press('Escape');
    const copy = page.locator('.expressive-code button[data-code]').first();
    assert(await copy.count(), 'Missing code copy control');
    const expected = (await copy.getAttribute('data-code'))!.replaceAll('\x7f', '\n');
    await copy.click();
    const actual = await page.evaluate(() => navigator.clipboard.readText());
    assert(actual === expected, `Code clipboard differs: ${JSON.stringify(actual)} vs ${JSON.stringify(expected)}`);
    result.copy = actual;
    const select = page.getByRole('combobox', { name: 'Color theme' }).first();
    await select.selectOption('light');
    assert(await page.evaluate(() => document.documentElement.dataset.theme === 'light' && localStorage.getItem('starlight-theme') === 'light'), 'Theme selection did not persist');
    await page.reload();
    assert(await page.evaluate(() => document.documentElement.dataset.theme === 'light'), 'Theme selection did not survive reload');
    result.theme = 'light';
    const group = page.locator('nav[aria-label="Main"] details').first();
    assert(await group.count(), 'Missing sidebar group');
    await group.locator('summary').click();
    assert(!(await group.evaluate((node) => (node as HTMLDetailsElement).open)), 'Sidebar group failed to close');
    await page.reload();
    assert(!(await group.evaluate((node) => (node as HTMLDetailsElement).open)), 'Sidebar group did not keep its state after reload');
    await group.locator('summary').click();
    assert(await group.evaluate((node) => (node as HTMLDetailsElement).open), 'Sidebar group failed to reopen');
    result.sidebar = 'toggle';
    const toc = page.locator('starlight-toc a[href="#install-the-packages"]').first();
    assert(await toc.count(), 'Missing desktop table of contents');
    await toc.click();
    assert(new URL(page.url()).hash === '#install-the-packages', 'Desktop TOC did not navigate');
    result.toc = new URL(page.url()).hash;
    await page.setViewportSize({ width: 390, height: 844 });
    const menu = page.getByRole('button', { name: 'Menu' });
    await menu.click();
    assert(await page.evaluate(() => document.body.hasAttribute('data-mobile-menu-expanded')), 'Mobile menu did not open');
    await page.keyboard.press('Escape');
    assert(!(await page.evaluate(() => document.body.hasAttribute('data-mobile-menu-expanded'))), 'Mobile menu did not close on Escape');
    result.menu = 'open/escape';
    const mobileToc = page.locator('#starlight__mobile-toc');
    await mobileToc.locator('summary').click();
    assert(await mobileToc.evaluate((node) => (node as HTMLDetailsElement).open), 'Mobile TOC did not open');
    await mobileToc.locator('a[href="#sanity-check"]').click();
    assert(new URL(page.url()).hash === '#sanity-check', 'Mobile TOC did not navigate');
    result.mobileToc = new URL(page.url()).hash;
    return result;
  } finally {
    await page.close();
  }
}

async function themeBehavior(context: BrowserContext, origin: string): Promise<void> {
  const page = await open(context, origin, '/');
  try {
    await page.emulateMedia({ colorScheme: 'light' });
    await page.evaluate(() => localStorage.clear());
    await page.reload();
    const state = async (target: Page) => target.evaluate(() => ({
      theme: document.documentElement.dataset.theme,
      scheme: getComputedStyle(document.documentElement).colorScheme,
      meta: document.querySelector('meta[name="theme-color"]')?.getAttribute('content'),
      selected: [...document.querySelectorAll<HTMLSelectElement>('[data-mlx-theme-select]')].map((select) => select.value),
    }));
    const expect = async (target: Page, theme: 'light' | 'dark', preference: 'auto' | 'light' | 'dark') => {
      await target.waitForFunction((value) => document.documentElement.dataset.theme === value, theme);
      const actual = await state(target);
      assert(actual.theme === theme && actual.scheme === theme && actual.meta === (theme === 'dark' ? '#07090f' : '#f7f9ff')
        && actual.selected.length > 0 && actual.selected.every((value) => value === preference),
      `Theme state differs: ${JSON.stringify(actual)}, expected ${theme}/${preference}`);
    };
    await expect(page, 'light', 'auto');
    await page.emulateMedia({ colorScheme: 'dark' });
    await expect(page, 'dark', 'auto');
    await page.getByRole('combobox', { name: 'Color theme' }).selectOption('light');
    await expect(page, 'light', 'light');
    await page.reload();
    await expect(page, 'light', 'light');
    const sibling = await open(context, origin, '/docs/installation/');
    try {
      await expect(sibling, 'light', 'light');
      await sibling.getByRole('combobox', { name: 'Color theme' }).first().selectOption('dark');
      await expect(page, 'dark', 'dark');
      await sibling.evaluate(() => localStorage.clear());
      await expect(page, 'dark', 'auto');
    } finally {
      await sibling.close();
    }
    await page.evaluate(() => localStorage.setItem('starlight-theme', 'invalid'));
    await page.reload();
    await expect(page, 'dark', 'auto');
    const firstPaint = await context.newPage();
    try {
      await firstPaint.addInitScript(() => {
        new MutationObserver((_, observer) => {
          if (document.body) {
            (window as Window & { themeAtBody?: string }).themeAtBody = document.documentElement.dataset.theme;
            observer.disconnect();
          }
        }).observe(document, { childList: true, subtree: true });
      });
      await page.getByRole('combobox', { name: 'Color theme' }).selectOption('light');
      for (const route of ['/', '/docs/installation/', '/changelog/']) {
        await firstPaint.goto(origin + route);
        assert(await firstPaint.evaluate(() => (window as Window & { themeAtBody?: string }).themeAtBody === 'light'),
          `${route}: saved theme was not applied before body`);
      }
    } finally {
      await firstPaint.close();
    }
  } finally {
    await page.close();
  }
}

async function blockedStorage(browser: Browser, origin: string): Promise<void> {
  const context = await browser.newContext({ reducedMotion: 'reduce', colorScheme: 'dark' });
  try {
    await context.addInitScript(() => {
      Object.defineProperty(window, 'localStorage', {
        get() { throw new DOMException('Blocked', 'SecurityError'); },
      });
    });
    const page = await open(context, origin, '/');
    const errors: string[] = [];
    page.on('pageerror', (error) => errors.push(error.message));
    try {
      assert(await page.evaluate(() => document.documentElement.dataset.theme === 'dark'), 'Blocked storage prevented system theme');
      await page.getByRole('combobox', { name: 'Color theme' }).selectOption('light');
      await page.emulateMedia({ colorScheme: 'light' });
      await page.emulateMedia({ colorScheme: 'dark' });
      assert(await page.evaluate(() => document.documentElement.dataset.theme === 'light'), 'Blocked storage prevented explicit theme');
      assert(errors.length === 0, `Blocked storage caused page errors: ${errors.join('; ')}`);
    } finally {
      await page.close();
    }
  } finally {
    await context.close();
  }
}

export async function run(argv: string[]): Promise<void> {
  const config = await options(argv);
  await compareExports(config.baseline, config.candidate);
  const browser: Browser = await chromium.launch({ headless: true });
  const servers = await Promise.all([serve(config.baseline), serve(config.candidate)]);
  const origins: [string, string] = [servers[0].origin, servers[1].origin];
  const contexts: [BrowserContext, BrowserContext] = [
    await browser.newContext({ reducedMotion: 'reduce', colorScheme: 'dark' }),
    await browser.newContext({ reducedMotion: 'reduce', colorScheme: 'dark' }),
  ];
  const toleratedRasterDifferences: ToleratedRasterDifference[] = [];
  try {
    for (const context of contexts) {
      await context.addInitScript(() => {
        let value = '';
        Object.defineProperty(navigator, 'clipboard', {
          configurable: true,
          value: {
            writeText: async (text: string) => { value = text; },
            readText: async () => value,
          },
        });
      });
    }
    for (const route of config.routes) {
      await comparePages(contexts, origins, route);
      for (const view of config.views) {
        const difference = await visual(contexts, origins, route, view, config.output);
        if (difference) toleratedRasterDifferences.push(difference);
      }
      console.log(`PASS ${route}: structure, ${config.views.length} visual views`);
    }
    if (config.views.length === views.length) {
      for (const [route, names] of [
        ['/', ['marketing-1135-dark', 'marketing-1137-dark', 'narrow-799-light', 'wide-801-light']],
        ['/docs/installation/', ['sidebar-767-dark', 'sidebar-769-dark']],
      ] as const) {
        if (!config.routes.includes(route)) continue;
        for (const view of breakpointViews.filter((item) => names.some((name) => name === item.name))) {
          const difference = await visual(contexts, origins, route, view, config.output);
          if (difference) toleratedRasterDifferences.push(difference);
        }
        console.log(`PASS ${route}: ${names.length} breakpoint views`);
      }
      for (const route of ['/', '/docs/installation/', '/changelog/']) {
        if (!config.routes.includes(route)) continue;
        const difference = await visual(contexts, origins, route, { name: 'print-light', width: 1440, height: 900, theme: 'light' }, config.output);
        if (difference) toleratedRasterDifferences.push(difference);
        console.log(`PASS ${route}: print view`);
      }
    }
    if (config.routes.includes('/docs/installation/')) {
      const baseline = await exercise(contexts[0], origins[0]);
      const candidate = await exercise(contexts[1], origins[1]);
      equal(baseline, candidate, 'Search/copy/theme/menu/sidebar/TOC interaction differs');
      console.log('PASS interactions: prefetch, search, shortcut, clipboard, theme, menu, sidebar, TOC');
    }
    if (config.routes.includes('/')) {
      await themeBehavior(contexts[0], origins[0]);
      await themeBehavior(contexts[1], origins[1]);
      await blockedStorage(browser, origins[0]);
      await blockedStorage(browser, origins[1]);
      console.log('PASS theme: system updates, persistence, cross-tab, invalid preference, first paint, blocked storage');
    }
    await mkdir(config.output, { recursive: true });
    await writeFile(join(config.output, 'report.json'), JSON.stringify({
      baseline: config.baseline,
      candidate: config.candidate,
      browser: browser.version(),
      routes: config.routes,
      views: config.views.map((view) => view.name),
      exports: { markdown: 9, sitemaps: 2 },
      visualTolerance: { scope: '390x844 mobile TOC chevron at x=141..142, y=78', maximumChangedPixels: 2, maximumChannelDifference: 1 },
      toleratedRasterDifferences,
      interactions: config.routes.includes('/docs/installation/'),
      theme: config.routes.includes('/'),
      result: 'pass',
    }, null, 2) + '\n');
    console.log(`PASS parity: ${config.routes.length} pages, 9 Markdown exports, 2 sitemaps`);
  } finally {
    await Promise.all(contexts.map((context) => context.close()));
    await browser.close();
    await Promise.all(servers.map(({ server }) => new Promise<void>((done) => server.close(() => done()))));
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  run(process.argv.slice(2)).catch((error: unknown) => {
    console.error(error);
    process.exitCode = 1;
  });
}
