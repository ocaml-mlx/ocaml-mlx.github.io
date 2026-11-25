const prefetched = new Set<string>();
let hoverTimer: ReturnType<typeof setTimeout> | undefined;

function slowConnection(): boolean {
  if (!('connection' in navigator)) return false;
  const connection = navigator.connection;
  if (typeof connection !== 'object' || connection === null) return false;
  return ('saveData' in connection && connection.saveData === true)
    || ('effectiveType' in connection && typeof connection.effectiveType === 'string' && /2g/.test(connection.effectiveType));
}

function prefetch(anchor: HTMLAnchorElement, ignoreSlowConnection = false): void {
  if (!navigator.onLine || (!ignoreSlowConnection && slowConnection())) return;
  const url = new URL(anchor.href);
  url.hash = '';
  if (url.origin !== location.origin || (url.pathname === location.pathname && url.search === location.search) || prefetched.has(url.href)) return;
  prefetched.add(url.href);
  const link = document.createElement('link');
  if (link.relList.supports('prefetch')) {
    link.rel = 'prefetch';
    link.href = url.href;
    document.head.append(link);
  } else {
    void fetch(url, { priority: 'low' }).catch(() => {});
  }
}

function hoverEnabled(target: EventTarget | null): target is HTMLAnchorElement {
  return target instanceof HTMLAnchorElement
    && (target.dataset.astroPrefetch === undefined || target.dataset.astroPrefetch === '' || target.dataset.astroPrefetch === 'hover');
}

function leave(): void {
  clearTimeout(hoverTimer);
  hoverTimer = undefined;
}

function enter(event: Event): void {
  const anchor = event.target;
  if (!hoverEnabled(anchor)) return;
  leave();
  hoverTimer = setTimeout(() => prefetch(anchor), 80);
}

document.body.addEventListener('focusin', enter, { passive: true });
document.body.addEventListener('focusout', leave, { passive: true });
for (const anchor of document.querySelectorAll('a')) {
  if (!hoverEnabled(anchor)) continue;
  anchor.addEventListener('mouseenter', enter, { passive: true });
  anchor.addEventListener('mouseleave', leave, { passive: true });
}
for (const event of ['touchstart', 'mousedown']) {
  document.addEventListener(event, (event) => {
    const anchor = event.target;
    if (anchor instanceof HTMLAnchorElement && anchor.dataset.astroPrefetch !== 'false'
      && (anchor.dataset.astroPrefetch === 'tap' || slowConnection())) prefetch(anchor, true);
  }, { passive: true });
}
