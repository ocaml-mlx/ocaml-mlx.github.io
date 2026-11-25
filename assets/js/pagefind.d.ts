declare module '@pagefind/default-ui' {
	export class PagefindUI {
		constructor(options: {
			element: string;
			baseUrl: string;
			bundlePath: string;
			showImages: boolean;
			translations: Record<string, string>;
			showSubResults: boolean;
		});
	}
}
