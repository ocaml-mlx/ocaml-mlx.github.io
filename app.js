import {
  intro, snippets, ecosystem, editors, editorLinks, templates,
  projects, urls, escapeHtml, highlight
} from "./assets/content.js";
import { templateMetadata } from "./assets/templates/metadata.js";

const params = new URLSearchParams(location.search);
const page = ["landing", "docs", "blog"].includes(params.get("page")) ? params.get("page") : "landing";
const main = document.querySelector("#content");
const arrow = `<svg width="18" height="18" viewBox="0 0 18 18" fill="none" aria-hidden="true"><path d="M4 14 14 4M5 4h9v9" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/></svg>`;
const copyIcon = `<svg width="14" height="14" viewBox="0 0 16 16" fill="none" aria-hidden="true"><rect x="5" y="4.5" width="8" height="9" rx="1" stroke="currentColor" stroke-width="1.3"/><path d="M10.5 4V2.5a1 1 0 0 0-1-1h-7a1 1 0 0 0-1 1v8a1 1 0 0 0 1 1H5" stroke="currentColor" stroke-width="1.3"/></svg>`;
const external = (href, title) => `<a class="text-link" href="${escapeHtml(href)}" target="_blank" rel="noopener noreferrer">${title}</a>`;
const docsLink = (topic, title) => `<a class="text-link" href="?page=docs&topic=${topic}">${title}</a>`;
const copy = (value, label = "Copy") => `<button class="copy-button" type="button" data-copy="${escapeHtml(value)}" aria-label="Copy ${escapeHtml(label === "Copy" ? value : label)}">${copyIcon}<span>${label}</span></button>`;
const command = value => `<div class="command"><code><span class="prompt">$</span>${escapeHtml(value)}</code>${copy(value)}</div>`;
const codeBlock = (label, value) => `<div class="code-block"><div class="code-block-header"><span>${escapeHtml(label)}</span>${copy(value, "code")}</div><pre><code>${highlight(value)}</code></pre></div>`;
const mosaicUrl = "https://github.com/invariant-hq/mosaic/";
const mluiUrl = "https://github.com/lessp/mlui";
const playgroundUrl = "https://melange.re/v7.0.1/playground/?language=OCaml";
const setupPromptUrl = new URL("./assets/setup-mlx-prompt.txt", import.meta.url);
const mosaicView = `open Mosaic_mlx

let view count =
  <box flex_direction=Column border=true padding=(padding 1)>
    <text>("Count: " ^ string_of_int count)</text>
    <text>"Press q to quit"</text>
  </box>`;
const workshopSource = `let workshop ~title ~seats () =
  <article id="workshop" lang="en">
    <header>
      <a href="/workshops" title="Browse workshops">
        "All workshops"
      </a>
      <h1>title</h1>
      <time datetime="2026-12-05">"December 5"</time>
    </header>
    <form action="/register" method_="post">
      <label for_="email">"Email address"</label>
      <input
        id="email"
        name="email"
        type_="email"
        placeholder="you@example.com"
        required=true
      />
      <button type_="submit" disabled=(seats = 0)>
        "Reserve a seat"
      </button>
    </form>
  </article>`;
const githubMark = `<svg viewBox="0 0 16 16" fill="currentColor" aria-hidden="true"><path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82A7.65 7.65 0 0 1 8 3.86c.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0 0 16 8c0-4.42-3.58-8-8-8Z"/></svg>`;
const starMark = `<svg viewBox="0 0 16 16" fill="none" aria-hidden="true"><path d="m8 1.5 2 4.05 4.47.65-3.24 3.16.77 4.46L8 11.71l-4 2.11.76-4.46L1.53 6.2 6 5.55 8 1.5Z" stroke="currentColor" stroke-width="1.35" stroke-linejoin="round"/></svg>`;
const featuredProjects = [
  { name: "fun-ocaml.com", site: "https://fun-ocaml.com", image: "fun-ocaml.webp" },
  { name: "query-json.pages.dev", site: "https://query-json.pages.dev", image: "query-json.webp" },
  { name: "html_of_jsx", site: "https://davesnx.github.io/html_of_jsx/", image: "html-of-jsx.webp" },
  { name: "topshelf.fm", site: "https://topshelf.fm/", image: "topshelf.webp" }
];
const footer = `<footer class="footer"><div class="footer-inner">
  <div class="footer-brand">mlx<p>JSX syntax for OCaml.</p></div>
  <div class="footer-column"><h2>Explore</h2><a href="?page=landing">Overview</a><a href="?page=landing#jsx">What is JSX?</a><a href="?page=landing#projects">Built with mlx</a></div>
  <div class="footer-column"><h2>Learn</h2><a href="?page=docs&topic=installation">Installation</a><a href="?page=docs&topic=syntax">Syntax</a><a href="?page=docs&topic=ecosystem">Ecosystem</a><a href="?page=docs&topic=libraries">Libraries</a></div>
  <div class="footer-column"><h2>Connect</h2><a href="${urls.github}" target="_blank" rel="noopener noreferrer">GitHub</a><a href="${urls.discord}" target="_blank" rel="noopener noreferrer">OCaml Discord</a><a href="${editorLinks.issues}" target="_blank" rel="noopener noreferrer">Issues</a></div>
  <div class="footer-column"><h2>More</h2><a href="?page=blog">Blog</a><a href="${urls.opam}" target="_blank" rel="noopener noreferrer">opam</a><a href="${urls.releases}" target="_blank" rel="noopener noreferrer">Releases</a></div>
</div></footer>`;

function templateCards() {
  return `<div class="template-grid">${templates.map(item => {
    const meta = templateMetadata[item.name];
    const stars = meta.stars.toLocaleString("en-US");
    return `<a class="template-card" href="${escapeHtml(item.href)}" target="_blank" rel="noopener noreferrer" aria-label="${escapeHtml(item.name)}${meta.kind ? `, ${meta.kind}` : ""} on GitHub">
      <div class="template-card-header"><img class="template-avatar" src="./assets/templates/${escapeHtml(meta.avatar)}" alt="" width="24" height="24" loading="lazy"><h3>${escapeHtml(item.name)}</h3><span class="template-github">${githubMark}</span></div>
      ${meta.kind ? `<span class="template-kind">${escapeHtml(meta.kind)}</span>` : ""}
      <p>${escapeHtml(item.text)}</p>
      <div class="template-meta"><span class="template-language"><span class="language-dot" aria-hidden="true"></span>${escapeHtml(meta.language)}</span><span class="template-stars" aria-label="${escapeHtml(meta.starContext ?? "Repository")} stars: ${stars}" title="${escapeHtml(meta.starContext ?? "Repository")} stars">${starMark}${stars}</span></div>
    </a>`;
  }).join("")}</div>`;
}

function landing() {
  document.title = "mlx — JSX syntax for OCaml";
  const ecosystemItems = ecosystem.map(item => `<div class="ecosystem-item"><h3>${item.href ? external(item.href, escapeHtml(item.name)) : escapeHtml(item.name)}</h3><p>${escapeHtml(item.text)}</p></div>`).join("");
  const featuredItems = featuredProjects.map(({ name, site, image }) => {
    const repo = projects.find(([project]) => project === name)?.[1];
    return `<article class="featured-project"><a class="project-preview" href="${site}" target="_blank" rel="noopener noreferrer" aria-label="Visit ${escapeHtml(name)}"><img src="./assets/projects/${image}" alt="${escapeHtml(name)} website screenshot" width="1280" height="800" loading="lazy" /></a><div class="featured-project-info"><a class="project-site" href="${site}" target="_blank" rel="noopener noreferrer">${escapeHtml(name)} ${arrow}</a><a class="project-repo" href="${escapeHtml(repo)}" target="_blank" rel="noopener noreferrer" aria-label="${escapeHtml(name)} on GitHub" title="View source on GitHub">${githubMark}<span>GitHub</span></a></div></article>`;
  }).join("");
  const otherProjects = projects.filter(([name]) => name !== "mailwoman" && !featuredProjects.some(project => project.name === name)).map(([name, href]) => `<a class="project-row" href="${escapeHtml(href)}" target="_blank" rel="noopener noreferrer"><span>${escapeHtml(name)}</span>${githubMark}</a>`).join("");
  return `<div class="landing">
    <section class="hero" aria-labelledby="hero-title"><h1 id="hero-title">${escapeHtml(intro.title)}</h1><p class="lead">${escapeHtml(intro.description)}</p><div class="hero-command">${command(intro.install)}</div><div class="hero-actions"><a class="site-button site-button-secondary hero-setup" href="?page=docs&topic=installation">Read the installation guide</a><button class="site-button site-button-primary hero-prompt" type="button" data-copy-prompt>${copyIcon}<span aria-live="polite">Copy prompt</span></button></div></section>
    <section class="specimen-stage" aria-label="OCaml JSX example"><div class="specimen"><div class="specimen-body"><div class="specimen-gutter" aria-hidden="true">${workshopSource.split("\n").map((_, index) => index + 1).join("\n")}</div><pre tabindex="0" aria-label="Workshop JSX source, scroll horizontally to read"><code>${highlight(workshopSource)}</code></pre></div></div></section>
    <section class="landing-section" id="jsx"><div class="section-inner two-column"><div><h2 class="section-title">What is JSX?</h2><p class="section-intro">A way to write nested elements and components in OCaml source, without adopting a new UI runtime.</p><div class="section-actions">${docsLink("syntax", "Read the syntax guide →")}</div></div><div class="prose"><p>mlx translates JSX-shaped expressions into OCaml calls marked with <code>[@JSX]</code>. A downstream PPX or library defines what those calls produce.</p><p>Tags, attributes, and children stay close to the code around them. Your build, types, and choice of rendering stack remain part of the OCaml project.</p></div></div></section>
    <section class="landing-section installation-section" id="installation"><div class="section-inner two-column"><div><h2 class="section-title">Installation</h2><p class="section-intro">Install mlx, then tell Dune how to read and format <code>.mlx</code> files.</p><div class="section-actions">${docsLink("installation", "Complete setup →")}</div></div><div>${command(snippets.packages)}${codeBlock("dune-project", snippets.dune)}<p class="section-intro">${escapeHtml(intro.support)}</p></div></div></section>
    <section class="landing-section" id="ecosystem"><div class="section-inner"><h2 class="section-title">Ecosystem support</h2><p class="section-intro">A syntax layer that works alongside the tools you use in an OCaml project.</p><div class="ecosystem-grid">${ecosystemItems}</div><div class="section-actions">${docsLink("ecosystem", "Explore integrations →")}</div></div></section>
    <section class="landing-section editors-section" id="editors"><div class="section-inner"><h2 class="section-title">Editors</h2><div class="editor-list">${editors.map(name => `<span class="editor-logo"><img src="./assets/editors/${name.toLowerCase().replace(" ", "")}.svg" alt="${escapeHtml(name)}" title="${escapeHtml(name)}" width="40" height="40" loading="lazy" /></span>`).join("")}</div><div class="editor-copy"><p>${external(editorLinks.platform, "OCaml Platform extension")} provides editor features; ${external(editorLinks.neovim, "Neovim integration")} and ${external(editorLinks.treesitter, "Tree-sitter grammar")} provide additional paths.</p>${docsLink("editors", "Editor setup →")}</div></div></section>
    <section class="landing-section runtime-section" id="web"><div class="section-inner"><div class="two-column"><div><h2 class="section-title">Designed for the web and more</h2><p class="section-intro">Build for the browser, server, terminal, or desktop. Choose the application runtime first; use mlx where the stack supports its syntax.</p></div><div class="list-rows"><div class="list-row"><h3>In the browser</h3><p>Melange compiles OCaml to JavaScript. ${external("https://github.com/reasonml/reason-react", "reason-react")} supplies the component model and interprets JSX calls for a browser interface. ${external(playgroundUrl, "Try mlx in the Melange Playground →")} without installing anything.</p></div><div class="list-row"><h3>On the server</h3><p>Dream can serve HTML produced with ${external("https://github.com/davesnx/html_of_jsx", "html_of_jsx")}. The JSX-shaped source is rendered by that stack, not by mlx itself.</p></div><div class="list-row"><h3>Terminal interfaces</h3><p>${external(mosaicUrl, "Mosaic")} provides terminal widgets and layout with mlx-ready helpers. ${docsLink("libraries#libraries-5", "See a view excerpt →")}</p></div><div class="list-row"><h3>Desktop applications</h3><p>${external(mluiUrl, "mlui")} provides OCaml views for desktop windows, with flexbox layout and animations. ${docsLink("libraries#libraries-6", "Read desktop notes →")}</p></div><div class="list-row"><h3>Typed markup</h3><p>TyXML-oriented integrations can keep typed HTML construction. Check the PPX and attribute conventions used by your project.</p></div></div></div><div class="section-actions">${docsLink("libraries", "Compare runtime paths →")}</div></div></section>
    <section class="landing-section" id="templates"><div class="section-inner"><h2 class="section-title">Templates</h2><p class="section-intro">Start from a project that connects mlx to a working stack.</p>${templateCards()}</div></section>
    <section class="landing-section" id="projects"><div class="section-inner"><h2 class="section-title">Built with mlx</h2><p class="section-intro">Explore projects and examples using mlx.</p><div class="featured-projects">${featuredItems}</div><div class="project-grid">${otherProjects}</div></div></section>
    <section class="landing-section playground-section" id="playground"><div class="section-inner playground-panel"><h2 class="section-title">Try mlx in the browser</h2><p>Open the Melange Playground in OCaml (MLX) mode. Explore the syntax without installing the toolchain.</p><div class="section-actions"><a class="site-button site-button-primary" href="${playgroundUrl}" target="_blank" rel="noopener noreferrer">Open Melange Playground ${arrow}</a></div></div></section>
    <section class="landing-section closing-section" id="join"><div class="section-inner join-panel"><h2 class="section-title">Join us</h2><p>Follow the work, ask questions, or help improve the syntax and its tooling.</p><div class="section-actions"><a class="site-button site-button-primary" href="${urls.discord}" target="_blank" rel="noopener noreferrer"><img src="./assets/brands/discord.svg" alt="" width="20" height="20" loading="lazy" />Join the OCaml Discord</a><a class="site-button site-button-secondary" href="${urls.github}" target="_blank" rel="noopener noreferrer">${githubMark}Explore on GitHub</a></div></div></section>
  </div>${footer}`;
}

const topics = {
  installation: {
    title: "Installation",
    intro: "Install the syntax package, register the .mlx dialect with Dune, and keep your editor and formatter in step.",
    body: `<h2>Install mlx</h2><p>Start with the syntax package. Add its companion packages for formatting and editor support.</p>${command(snippets.packages)}<p>You can also install only <code>mlx</code> first with <code>opam install mlx</code>.</p><h2>Add the Dune dialect</h2><p>Place this dialect in <code>dune-project</code>. It connects the file extension, Merlin reader, formatter, and preprocessing step.</p>${codeBlock("dune-project", snippets.dune)}<h2>Check a module</h2><p>Create a small <code>.mlx</code> file and build it with your project's normal command. Check that Dune reads it and that editor features and formatting work in that file.</p>${codeBlock("Greeting.mlx", snippets.source)}<p>mlx supplies syntax, not rendering. Choose the libraries and downstream PPX for your ${docsLink("libraries", "runtime path")}.</p>`
  },
  syntax: {
    title: "JSX syntax",
    intro: "JSX-shaped source becomes OCaml expressions. The downstream library decides the meaning of the calls.",
    body: `<h2>Source and lowering</h2><p>Here is a component with an attribute and nested elements. The lowering below is a conceptual call shape; a downstream PPX gives it meaning.</p>${codeBlock("Greeting.mlx", snippets.source)}${codeBlock("Conceptual lowering", snippets.lowered)}<h2>Tags and attributes</h2><p>Capitalized tags refer to components. Lowercase tags refer to element helpers. Attributes become labeled arguments. Each stack defines the interpretation of those calls.</p><h2>Children are OCaml values</h2><p>Use parentheses to place an OCaml expression among children. Literal text can appear directly. You remain in OCaml, not a separate template language.</p><p>For a working project, first ${docsLink("installation", "register the dialect")} and then select a ${docsLink("libraries", "UI library")}.</p>`
  },
  editors: {
    title: "Editor support",
    intro: "Use the mlx reader, formatter, and grammar support where your editor needs them.",
    body: `<h2>Companion packages</h2><p>Install <code>ocamlmerlin-mlx</code> and <code>ocamlformat-mlx</code> alongside mlx, then add the ${docsLink("installation", "Dune dialect")}. The dialect declares the reader and format command.</p>${command(snippets.packages)}<h2>Available editors</h2><p>${editors.map(escapeHtml).join(", ")} are the editors listed for this prototype's support paths. The exact setup depends on the editor and installed OCaml tooling.</p><ul><li>${external(editorLinks.platform, "OCaml Platform extension")} for VS Code-compatible editors.</li><li>${external(editorLinks.neovim, "Neovim integration")} for Neovim.</li><li>${external(editorLinks.treesitter, "Tree-sitter grammar")} for syntax highlighting.</li></ul><h2>Another editor?</h2><p>Missing your editor? ${external(editorLinks.issues, "Open an issue")} to help track support.</p>`
  },
  ecosystem: {
    title: "Ecosystem",
    intro: "Use mlx alongside the existing OCaml build, editor, formatting, and documentation tools.",
    body: `<h2>Existing OCaml tools</h2><p>The syntax layer fits into these toolchain paths:</p><ul>${ecosystem.map(item => `<li><strong>${escapeHtml(item.name)}.</strong> ${escapeHtml(item.text)}</li>`).join("")}</ul><h2>mlx tool forks</h2><h3>${external("https://github.com/ocaml-mlx/ocamlformat-mlx", "ocamlformat-mlx")}</h3><p>A fork of ocamlformat that formats <code>.mlx</code> files. Install it alongside mlx when you use the Dune dialect's format command.</p><h3>${external("https://github.com/ocaml-mlx/mlx", "ocamlmerlin-mlx")}</h3><p>A Merlin tooling fork adapted to read <code>.mlx</code> files. The Dune dialect selects its reader for editor support. It does not replace OCaml LSP.</p>`
  },
  libraries: {
    title: "Libraries",
    intro: "Choose a UI library for the browser, server, terminal, or desktop. mlx supplies syntax, not a renderer.",
    body: `<h2>React components</h2><p>Use Melange to compile OCaml to JavaScript and ${external("https://github.com/reasonml/reason-react", "reason-react")} for browser components. mlx provides the JSX-shaped source; the component library defines the resulting behavior. ${external(templates[0].href, "Melange template ↗")}</p><h2>Reativa</h2><p>${external("https://github.com/brnrdog/reativa", "Reativa")} builds web interfaces in OCaml or Reason with signals. Views update real DOM nodes without a virtual DOM. It supports Melange and js_of_ocaml, with a <code>Reativa.View.Mlx</code> adapter and <code>reativa.mlx_ppx</code> for mlx source.</p><h2>Server HTML</h2><p>With ${external("https://github.com/camlworks/dream", "Dream")} and ${external("https://github.com/davesnx/html_of_jsx", "html_of_jsx")}, a server route can return HTML from JSX-shaped OCaml source. The rendering path belongs to those libraries. ${external(templates[2].href, "Dream integration example ↗")}</p><h2>Yuka</h2><p>${external("https://github.com/davesnx/yuka", "Yuka")} is an experimental OCaml web framework. It renders JSX pages on the server and streams slow sections as they become ready. Melange compiles interactive islands to JavaScript; pages without islands load no JavaScript.</p><h2>Typed HTML</h2><p>A ${external("https://github.com/ocsigen/tyxml", "TyXML")}-facing integration keeps typed HTML construction. Check the PPX chain, attributes, and children in your own project before adopting the syntax.</p><h2>Terminal interfaces with Mosaic</h2><p>${external(mosaicUrl, "Mosaic")} offers terminal widgets, layout, and an Elm-style model/update/view loop. Its <code>Mosaic_mlx</code> module exposes element helpers that accept mlx children. This is a view excerpt; a complete application also supplies a model, update function, and run loop.</p>${codeBlock("Mosaic view excerpt · .mlx", mosaicView)}<h2>Desktop applications with mlui</h2><p>${external(mluiUrl, "mlui")} is a declarative OCaml desktop framework with flexbox layout, animations, and Elm-style state updates. Its ${external(`${mluiUrl}#using-the-library`, "counter example")} creates a window with <code>Mlui.Window.make</code> and runs the view through its SDL backend. The current examples use the OCaml API; mlx authoring would need adapter functions that accept mlx children.</p><h2>Templates</h2><p>Start from a project that connects mlx to an existing stack.</p>${templateCards()}`
  }
};

topics.ecosystem.body += `<h2>Try mlx in a browser</h2><p>The ${external(playgroundUrl, "Melange Playground")} has an OCaml (MLX) mode. Use it to try the syntax without installing the toolchain.</p>`;

function docsPage() {
  const key = Object.hasOwn(topics, params.get("topic")) ? params.get("topic") : "installation";
  const topic = topics[key];
  document.title = `${topic.title} — mlx guide`;
  const nav = (keys, title) => `<div class="docs-nav-group"><h2>${title}</h2>${keys.map(name => `<a href="?page=docs&topic=${name}" ${name === key ? 'aria-current="page"' : ""}>${topics[name].title}</a>`).join("")}</div>`;
  const headings = [...topic.body.matchAll(/<h2>(.*?)<\/h2>/g)].map((match, index) => ({ title: match[1].replace(/<[^>]*>/g, ""), id: `${key}-${index}` }));
  let headingIndex = 0;
  const body = topic.body.replace(/<h2>/g, () => `<h2 id="${headings[headingIndex++].id}">`);
  const order = Object.keys(topics);
  const next = order[(order.indexOf(key) + 1) % order.length];
  return `<div class="docs-shell"><aside class="docs-sidebar"><nav class="docs-sidebar-inner" aria-label="Documentation topics">${nav(["installation", "syntax"], "Getting started")}${nav(["editors", "ecosystem", "libraries"], "Guides")}</nav></aside><article class="docs-article"><h1>${topic.title}</h1><p class="lead">${topic.intro}</p>${body}<a class="docs-next" href="?page=docs&topic=${next}"><span>Continue reading</span>${topics[next].title} →</a></article><aside class="docs-toc" aria-label="On this page"><div class="docs-toc-inner"><h2>On this page</h2>${headings.map(item => `<a href="#${item.id}">${item.title}</a>`).join("")}</div></aside></div>${footer}`;
}

const articles = [
  {
    id: "hello-world",
    title: "<Hello /> <World />",
    description: "A starting point for mlx installation, syntax, and library choices.",
    date: "2026-11-24",
    dateLabel: "Nov 24, 2026",
    paragraphs: [
      "Welcome to the mlx website. mlx adds JSX syntax to OCaml. This site explains how to install it, what the syntax means, and how it fits with libraries that render the resulting calls.",
      "Start with the installation guide to add a .mlx file to a Dune project. The syntax reference and library notes are there when you need to understand a specific expression or choose a runtime."
    ],
    action: () => docsLink("installation", "Read the installation guide →")
  },
  {
    id: "melange-playground",
    title: "Melange Playground supports mlx",
    description: "Try OCaml (MLX) in the browser without installing the toolchain.",
    date: "2026-11-24",
    dateLabel: "Nov 24, 2026",
    paragraphs: [
      "The Melange Playground has an OCaml (MLX) mode. Select that tab to write JSX-shaped OCaml in the browser and inspect the result without setting up a local project.",
      "It is a useful first stop if you want to check the syntax before installing mlx. When you are ready to use it in a project, follow the installation guide for the Dune dialect and editor setup."
    ],
    action: () => external(playgroundUrl, "Open the Melange Playground →")
  },
  {
    id: "fragments-0-12",
    title: "mlx 0.12 supports fragments",
    description: "Group children with fragment syntax in mlx 0.12.",
    date: "2026-11-02",
    dateLabel: "Nov 2, 2026",
    paragraphs: [
      "mlx 0.12 adds fragment syntax. You can group children between empty tags without introducing a named wrapper element. The release supports both ordinary fragment children and a spread form for an existing list of children.",
      "This is a syntax change, so check the expectations of the library that consumes your JSX calls. Read the 0.12 release notes for the fragment forms and the other changes in that release."
    ],
    action: () => external("https://github.com/ocaml-mlx/mlx/releases/tag/0.12", "Read the 0.12 release notes →")
  },
  {
    id: "ocaml-5-4",
    title: "mlx supports OCaml 5.4",
    description: "OCaml 5.4 support arrived with mlx 0.11.",
    date: "2025-12-25",
    dateLabel: "Dec 25, 2025",
    paragraphs: [
      "mlx 0.11 adds support for OCaml 5.4. If you are moving a project to OCaml 5.4, use an mlx release that includes this change before checking your .mlx files with the new compiler.",
      "The 0.11 release notes record the compatibility update. You can then build your project with its normal Dune setup to check the syntax and the rest of your dependencies together."
    ],
    action: () => external("https://github.com/ocaml-mlx/mlx/releases/tag/0.11", "Read the 0.11 release notes →")
  }
];
const draftAuthor = "David Sancho";
const draftAuthorUrl = "https://sancho.dev/about";
const articleSummary = article => `<div class="article-summary"><div class="article-description-group"><p class="article-description">${escapeHtml(article.description)}</p><time datetime="${article.date}">${article.dateLabel}</time></div><a class="article-author" href="${draftAuthorUrl}">${draftAuthor}</a></div>`;

function articleRow(article) {
  return `<article class="article-row"><h2><a href="?page=blog&article=${encodeURIComponent(article.id)}">${escapeHtml(article.title)}</a></h2>${articleSummary(article)}</article>`;
}

function blogPage() {
  const article = articles.find(item => item.id === params.get("article"));
  if (article) {
    document.title = `${article.title} — mlx blog`;
    return `<div class="blog-shell"><div class="blog-inner article"><a class="back-link" href="?page=blog">← Back to all articles</a><h1>${escapeHtml(article.title)}</h1>${articleSummary(article)}<div class="article-body">${article.paragraphs.map(text => `<p>${escapeHtml(text)}</p>`).join("")}</div><div class="article-bottom"><a href="?page=blog">← All articles</a>${article.action()}</div></div></div>${footer}`;
  }
  document.title = "Blog — mlx";
  return `<div class="blog-shell"><div class="blog-inner"><h1>Blog</h1><p class="blog-intro">Updates on mlx syntax, compatibility, and places to try it.</p><div>${articles.map(articleRow).join("")}</div></div></div>${footer}`;
}

main.innerHTML = page === "docs" ? docsPage() : page === "blog" ? blogPage() : landing();
document.querySelectorAll("[data-page-link]").forEach(link => {
  if (link.dataset.pageLink === page) link.setAttribute("aria-current", "page");
});

let setupPromptPromise;
let promptFeedbackTimer;
function loadSetupPrompt() {
  setupPromptPromise ??= fetch(setupPromptUrl).then(response => {
    if (!response.ok) throw new Error(`Setup prompt unavailable (${response.status})`);
    return response.text();
  }).catch(error => {
    setupPromptPromise = null;
    throw error;
  });
  return setupPromptPromise;
}

document.addEventListener("click", async event => {
  const promptButton = event.target.closest("[data-copy-prompt]");
  if (promptButton) {
    clearTimeout(promptFeedbackTimer);
    const label = promptButton.querySelector("span");
    promptButton.disabled = true;
    label.textContent = "Loading prompt…";
    let promptLoaded = false;
    try {
      const prompt = await loadSetupPrompt();
      promptLoaded = true;
      label.textContent = "Copying prompt…";
      await navigator.clipboard.writeText(prompt);
      label.textContent = "Copied prompt";
    } catch {
      label.textContent = promptLoaded ? "Clipboard blocked — retry" : "Prompt unavailable — retry";
    } finally {
      promptButton.disabled = false;
      promptFeedbackTimer = setTimeout(() => {
        if (promptButton.isConnected) label.textContent = "Copy prompt";
      }, 3000);
    }
    return;
  }
  const button = event.target.closest("[data-copy]");
  if (button) {
    try {
      await navigator.clipboard.writeText(button.dataset.copy);
      button.querySelector("span").textContent = "Copied";
      setTimeout(() => { if (button.isConnected) button.querySelector("span").textContent = "Copy"; }, 1800);
    } catch {
      button.querySelector("span").textContent = "Select to copy";
    }
  }
});
