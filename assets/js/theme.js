(() => {
	const storageKey = 'starlight-theme';
	const media = window.matchMedia?.('(prefers-color-scheme: light)');
	const parse = (value) => (value === 'light' || value === 'dark' ? value : 'auto');
	let preference = 'auto';

	try {
		preference = parse(localStorage.getItem(storageKey));
	} catch {}

	const sync = () => {
		const theme = preference === 'auto' ? (media?.matches ? 'light' : 'dark') : preference;
		document.documentElement.dataset.theme = theme;
		document.querySelectorAll('meta[name="theme-color"]').forEach((meta) => {
			meta.setAttribute('content', theme === 'light' ? '#f7f9ff' : '#07090f');
		});
		document.querySelectorAll('select[data-mlx-theme-select]').forEach((select) => {
			select.value = preference;
		});
	};

	sync();
	document.addEventListener('DOMContentLoaded', sync);
	window.addEventListener('pageshow', sync);
	document.addEventListener('change', (event) => {
		const select = event.target;
		if (!(select instanceof HTMLSelectElement) || !select.matches('[data-mlx-theme-select]')) return;
		preference = parse(select.value);
		sync();
		try {
			localStorage.setItem(storageKey, preference === 'auto' ? '' : preference);
		} catch {}
	});
	media?.addEventListener('change', () => {
		if (preference === 'auto') sync();
	});
	window.addEventListener('storage', (event) => {
		if (event.key !== storageKey && event.key !== null) return;
		preference = parse(event.key === null ? null : event.newValue);
		sync();
	});
})();
