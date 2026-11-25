import { PagefindUI } from '@pagefind/default-ui';

const onIdle = (callback: IdleRequestCallback) =>
	(window.requestIdleCallback || ((callback: IdleRequestCallback) => setTimeout(callback, 1)))(callback);

const shortcut = document.querySelector<HTMLButtonElement>('button[data-open-modal]');
const hint = shortcut?.querySelector<HTMLElement>('kbd');
if (shortcut && hint) {
	const platformKey = hint.querySelector('kbd');
	if (platformKey && /(Mac|iPhone|iPod|iPad)/i.test(navigator.platform)) {
		platformKey.textContent = '⌘';
		shortcut.setAttribute('aria-keyshortcuts', 'Meta+K');
	}
	hint.style.display = '';
}

class SiteSearch extends HTMLElement {
	constructor() {
		super();
		const openBtn = this.querySelector<HTMLButtonElement>('button[data-open-modal]');
		const closeBtn = this.querySelector<HTMLButtonElement>('button[data-close-modal]');
		const dialog = this.querySelector<HTMLDialogElement>('dialog');
		const dialogFrame = this.querySelector<HTMLElement>('.dialog-frame');
		if (!openBtn || !closeBtn || !dialog || !dialogFrame) return;

		const closeModal = () => dialog.close();
		const onClick = (event: MouseEvent) => {
			const isLink = event.target instanceof Element && Boolean(event.target.closest('a[href]'));
			if (isLink || (event.target instanceof Node && document.body.contains(event.target) && !dialogFrame.contains(event.target))) {
				closeModal();
			}
		};
		const openModal = (event?: MouseEvent) => {
			dialog.showModal();
			document.body.toggleAttribute('data-search-modal-open', true);
			this.querySelector('input')?.focus();
			event?.stopPropagation();
			window.addEventListener('click', onClick);
		};
		openBtn.addEventListener('click', openModal);
		openBtn.disabled = false;
		closeBtn.addEventListener('click', closeModal);
		dialog.addEventListener('close', () => {
			document.body.toggleAttribute('data-search-modal-open', false);
			window.removeEventListener('click', onClick);
		});
		window.addEventListener('keydown', (event) => {
			if ((event.metaKey || event.ctrlKey) && event.key === 'k') {
				dialog.open ? closeModal() : openModal();
				event.preventDefault();
			}
		});

		let translations = {};
		try {
			translations = JSON.parse(this.dataset.translations || '{}');
		} catch {}
		window.addEventListener('DOMContentLoaded', () => {
			onIdle(() => {
				new PagefindUI({
					element: '#starlight__search',
					baseUrl: '/',
					bundlePath: '/pagefind/',
					showImages: false,
					translations,
					showSubResults: true,
				});
			});
		});
	}
}
customElements.define('site-search', SiteSearch);

class StarlightMenuButton extends HTMLElement {
	constructor() {
		super();
		const button = this.querySelector('button');
		if (!button) return;
		button.addEventListener('click', () => this.setExpanded(this.getAttribute('aria-expanded') !== 'true'));
		this.closest('nav')?.addEventListener('keyup', (event) => {
			if (event.code !== 'Escape') return;
			this.setExpanded(false);
			button.focus();
		});
	}
	private setExpanded(expanded: boolean) {
		this.setAttribute('aria-expanded', String(expanded));
		document.body.toggleAttribute('data-mobile-menu-expanded', expanded);
	}
}
customElements.define('starlight-menu-button', StarlightMenuButton);

const scroller = document.getElementById('starlight__sidebar');
const sidebar = scroller?.querySelector<HTMLElement>('sl-sidebar-state-persist');
type SidebarState = { hash: string; open: Array<boolean | null>; scroll: number };
const getSidebarState = (): SidebarState => {
	let open: SidebarState['open'] = [];
	const hash = sidebar?.dataset.hash || '';
	try {
		const saved = JSON.parse(sessionStorage.getItem('sl-sidebar-state') || '{}') as SidebarState;
		if (Array.isArray(saved.open) && saved.hash === hash) open = saved.open;
	} catch {}
	return { hash, open, scroll: scroller?.scrollTop || 0 };
};
const storeSidebarState = (state: SidebarState) => {
	try {
		sessionStorage.setItem('sl-sidebar-state', JSON.stringify(state));
	} catch {}
};
if (sidebar && scroller) {
	try {
		if (matchMedia('(min-width: 50em)').matches) {
			const saved = JSON.parse(sessionStorage.getItem('sl-sidebar-state') || '{}') as SidebarState;
			if (saved.hash === sidebar.dataset.hash) {
				if (typeof saved.scroll === 'number') scroller.scrollTop = saved.scroll;
				sidebar.querySelectorAll<HTMLDetailsElement>('details').forEach((details, index) => {
					if (typeof saved.open?.[index] === 'boolean') details.open = saved.open[index]!;
				});
			}
		}
	} catch {}
	sidebar.addEventListener('click', (event) => {
		if (!(event.target instanceof Element)) return;
		const details = event.target.closest('summary')?.closest('details');
		if (!details) return;
		const index = Array.from(sidebar.querySelectorAll('details')).indexOf(details);
		if (index === -1) return;
		const state = getSidebarState();
		state.open[index] = !details.open;
		storeSidebarState(state);
	});
	const save = () => storeSidebarState(getSidebarState());
	window.addEventListener('visibilitychange', () => {
		if (document.visibilityState === 'hidden') save();
	});
	window.addEventListener('pageHide', save);
}

class StarlightTOC extends HTMLElement {
	private currentLink = this.querySelector<HTMLAnchorElement>('a[aria-current="true"]');
	private minH = Number(this.dataset.minH || 2);
	private maxH = Number(this.dataset.maxH || 3);
	private headingSelector = `h1#_top,:where(${Array.from({ length: 1 + this.maxH - this.minH }, (_, index) => `h${this.minH + index}`).join()})[id]`;

	protected set current(link: HTMLAnchorElement) {
		if (link === this.currentLink) return;
		this.currentLink?.removeAttribute('aria-current');
		link.setAttribute('aria-current', 'true');
		this.currentLink = link;
	}

	constructor() {
		super();
		onIdle(() => this.init());
	}

	private init() {
		const links = Array.from(this.querySelectorAll<HTMLAnchorElement>('a'));
		const isHeading = (element: Element): element is HTMLHeadingElement => element.matches(this.headingSelector);
		const getHeading = (element: Element | null): HTMLHeadingElement | null => {
			if (!element) return null;
			const origin = element;
			while (element) {
				if (element.matches('.sl-markdown-content, main > *')) return document.getElementById('_top') as HTMLHeadingElement;
				if (isHeading(element)) return element;
				const child = element.querySelector<HTMLHeadingElement>(this.headingSelector);
				if (child) return child;
				element = element.previousElementSibling;
				while (element?.lastElementChild) element = element.lastElementChild;
				const heading = getHeading(element);
				if (heading) return heading;
			}
			return getHeading(origin.parentElement);
		};
		const targetSelector = [
			`main :where(${this.headingSelector})`,
			`main :where(${this.headingSelector}, .sl-heading-wrapper) ~ *:not(:has(${this.headingSelector}))`,
			`main .sl-markdown-content > *:not(:has(${this.headingSelector}))`,
			`main > *:not(:has(${this.headingSelector}))`,
		].join();
		const targets = document.querySelectorAll(targetSelector);
		let observer: IntersectionObserver | undefined;
		const observe = () => {
			if (observer) return;
			const navbar = document.querySelector('header')?.getBoundingClientRect().height || 0;
			const mobileToc = this.querySelector('summary')?.getBoundingClientRect().height || 0;
			const top = navbar + mobileToc + 32;
			const bottom = top + 53 - document.documentElement.clientHeight;
			observer = new IntersectionObserver((entries) => {
				for (const { isIntersecting, target } of entries) {
					if (!isIntersecting) continue;
					const heading = getHeading(target);
					const link = heading && links.find((item) => item.hash === '#' + encodeURIComponent(heading.id));
					if (link) {
						this.current = link;
						break;
					}
				}
			}, { rootMargin: `-${top}px 0% ${bottom}px` });
			targets.forEach((target) => observer?.observe(target));
		};
		observe();
		let resizeTimeout: ReturnType<typeof setTimeout>;
		window.addEventListener('resize', () => {
			observer?.disconnect();
			observer = undefined;
			clearTimeout(resizeTimeout);
			resizeTimeout = setTimeout(() => onIdle(observe), 200);
		});
	}
}
customElements.define('starlight-toc', StarlightTOC);

class MobileStarlightTOC extends StarlightTOC {
	protected override set current(link: HTMLAnchorElement) {
		super.current = link;
		const display = this.querySelector('.display-current');
		if (display) display.textContent = link.textContent;
	}
	constructor() {
		super();
		const details = this.querySelector('details');
		if (!details) return;
		const close = () => { details.open = false; };
		details.querySelectorAll('a').forEach((link) => link.addEventListener('click', close));
		window.addEventListener('click', (event) => {
			if (event.target instanceof Node && !details.contains(event.target)) close();
		});
		window.addEventListener('keydown', (event) => {
			if (event.key !== 'Escape' || !details.open) return;
			const hasFocus = details.contains(document.activeElement);
			close();
			if (hasFocus) details.querySelector('summary')?.focus();
		});
	}
}
customElements.define('mobile-starlight-toc', MobileStarlightTOC);

const codeBlocks = document.querySelectorAll<HTMLElement>('.expressive-code pre > code');
const setFocusableCode = (pre: HTMLElement) => {
	if (pre.scrollWidth > pre.clientWidth) {
		pre.tabIndex = 0;
		pre.setAttribute('role', 'region');
	} else {
		pre.removeAttribute('tabindex');
		pre.removeAttribute('role');
	}
};
if (codeBlocks.length) {
	const observer = new ResizeObserver((entries) => entries.forEach((entry) => setFocusableCode(entry.target as HTMLElement)));
	codeBlocks.forEach((block) => {
		const pre = block.parentElement;
		if (pre) observer.observe(pre);
	});
}

const fallbackCopy = (text: string) => {
	const element = document.createElement('pre');
	Object.assign(element.style, {
		opacity: '0', pointerEvents: 'none', position: 'absolute', overflow: 'hidden',
		left: '0', top: '0', width: '20px', height: '20px', userSelect: 'all',
	});
	element.ariaHidden = 'true';
	element.textContent = text;
	document.body.appendChild(element);
	const selection = getSelection();
	if (!selection) {
		element.remove();
		return false;
	}
	const range = document.createRange();
	range.selectNode(element);
	selection.removeAllRanges();
	selection.addRange(range);
	let copied = false;
	try {
		copied = document.execCommand('copy');
	} finally {
		selection.removeAllRanges();
		element.remove();
	}
	return copied;
};

document.querySelectorAll<HTMLButtonElement>('.expressive-code .copy button').forEach((button) => {
	button.addEventListener('click', async () => {
		const text = (button.dataset.code || '').replace(/\u007f/g, '\n');
		let copied = false;
		try {
			await navigator.clipboard.writeText(text);
			copied = true;
		} catch {
			copied = fallbackCopy(text);
		}
		if (!copied || button.parentNode?.querySelector('.feedback')) return;
		const live = button.parentNode?.querySelector('[aria-live]');
		if (!live) return;
		const feedback = document.createElement('div');
		feedback.classList.add('feedback');
		feedback.append(button.dataset.copied || 'Copied!');
		live.append(feedback);
		void feedback.offsetWidth;
		requestAnimationFrame(() => feedback.classList.add('show'));
		const hide = () => feedback.classList.remove('show');
		const remove = () => {
			if (parseFloat(getComputedStyle(feedback).opacity) === 0) feedback.remove();
		};
		setTimeout(hide, 1500);
		setTimeout(remove, 2500);
		button.addEventListener('blur', hide);
		feedback.addEventListener('transitioncancel', remove);
		feedback.addEventListener('transitionend', remove);
	});
});
