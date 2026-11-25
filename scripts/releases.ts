import { readFile } from 'node:fs/promises';
import { marked } from 'marked';

export type Release = {
  name: string;
  tagName: string;
  slug: string;
  publishedAt: string;
  date: string;
  htmlUrl: string;
  bodyHtml: string;
  prerelease: boolean;
};

export type ReleaseInput = {
  releases: Release[];
  error: string | null;
};

function record(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function text(value: unknown, field: string): string {
  if (typeof value !== 'string') throw new Error(`GitHub release ${field} must be a string`);
  return value;
}

function nullableText(value: unknown, field: string): string {
  return value === null ? '' : text(value, field);
}

export async function renderReleases(input: unknown): Promise<Release[]> {
  if (!Array.isArray(input)) throw new Error('GitHub releases must be an array');
  const formatter = new Intl.DateTimeFormat('en', { dateStyle: 'medium' });
  const releases: Release[] = [];
  for (const item of input) {
    if (!record(item) || typeof item.draft !== 'boolean' || typeof item.prerelease !== 'boolean') {
      throw new Error('GitHub release must contain draft and prerelease flags');
    }
    if (item.draft) continue;
    const tagName = text(item.tag_name, 'tag_name');
    const name = (nullableText(item.name, 'name') || tagName).replace(/^v/, '');
    const publishedAt = nullableText(item.published_at, 'published_at');
    const htmlUrl = text(item.html_url, 'html_url');
    const parsedUrl = new URL(htmlUrl);
    if (parsedUrl.protocol !== 'https:' && parsedUrl.protocol !== 'http:') {
      throw new Error('GitHub release html_url must be an HTTP URL');
    }
    releases.push({
      name,
      tagName,
      slug: name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, ''),
      publishedAt,
      date: publishedAt ? formatter.format(new Date(publishedAt)) : '',
      htmlUrl,
      bodyHtml: await marked.parse(nullableText(item.body, 'body')),
      prerelease: item.prerelease,
    });
  }
  return releases;
}

export async function loadReleases(): Promise<ReleaseInput> {
  try {
    let data: unknown;
    if (process.env.RELEASES_FILE) {
      data = JSON.parse(await readFile(process.env.RELEASES_FILE, 'utf8'));
    } else {
      const headers: Record<string, string> = {
        Accept: 'application/vnd.github+json',
        'User-Agent': 'ocaml-mlx-website',
      };
      if (process.env.GH_API_TOKEN) headers.Authorization = `Bearer ${process.env.GH_API_TOKEN}`;
      const response = await fetch('https://api.github.com/repos/ocaml-mlx/mlx/releases?per_page=20', {
        headers,
        signal: AbortSignal.timeout(30_000),
      });
      if (!response.ok) {
        throw new Error(`GitHub releases request failed: ${response.status} ${response.statusText}`);
      }
      data = await response.json();
    }
    return { releases: await renderReleases(data), error: null };
  } catch (error) {
    return { releases: [], error: error instanceof Error ? error.message : 'Unknown GitHub releases error' };
  }
}
