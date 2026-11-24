export const sections = [
  ['jsx', 'What is JSX?'],
  ['installation', 'Installation'],
  ['ecosystem', 'Ecosystem support'],
  ['editors', 'Editors'],
  ['web', 'Designed for the web and more'],
  ['templates', 'Templates'],
  ['projects', 'Built with mlx'],
  ['community', 'What the community is saying'],
  ['join', 'Join us'],
];

export const intro = {
  title: 'OCaml + JSX',
  description: 'An extension of OCaml that brings JSX into the language. A small syntax layer, designed to fit the tools and libraries you already use.',
  install: 'opam install mlx',
  support: 'Editor and formatting support through ocamlmerlin-mlx and ocamlformat-mlx.',
};

export const snippets = {
  source: `let greeting ~name () =
  <div>
    <h1>("Hello, " ^ name ^ "!")</h1>
    <p>"Welcome to mlx."</p>
  </div>`,
  lowered: `([@JSX]
  div(
    ~children=[
      ([@JSX] h1(
        ~children=["Hello, " ^ name ^ "!"], ())),
      ([@JSX] p(
        ~children=["Welcome to mlx."], ()))
    ],
    ()))`,
  dune: `(dialect
 (name mlx)
 (implementation
  (extension mlx)
  (merlin_reader mlx)
  (format
   (run ocamlformat-mlx %{input-file}))
  (preprocess
   (run mlx-pp %{input-file}))))`,
  packages: 'opam install mlx ocamlformat-mlx ocamlmerlin-mlx',
  output: `<div class="greeting">
  <h1>Hello, World!</h1>
  <p>Welcome to mlx.</p>
</div>`,
};

export const ecosystem = [
  { name: 'OCaml LSP', text: 'Keep language-server features alongside the mlx dialect and reader.' },
  { name: 'Melange', text: 'Compile OCaml to JavaScript with your existing Melange stack.' },
  { name: 'js_of_ocaml', text: 'Use the syntax layer in an OCaml-to-JavaScript workflow.' },
  { name: 'ppxlib', text: 'Let the downstream PPX give the resulting calls their meaning.' },
  { name: 'odoc', text: 'Keep documentation in your existing OCaml toolchain.' },
  { name: 'opam', text: 'Install mlx and its companion packages with opam.' },
];

export const editors = ['VS Code', 'Cursor', 'Windsurf', 'Antigravity', 'Zed', 'Neovim'];
export const editorLinks = {
  platform: 'https://github.com/ocamllabs/vscode-ocaml-platform',
  neovim: 'https://github.com/ocaml-mlx/ocaml_mlx.nvim',
  treesitter: 'https://github.com/ocaml-mlx/tree-sitter-mlx',
  issues: 'https://github.com/ocaml-mlx/mlx/issues',
};

export const templates = [
  { name: 'andreypopp/melange-mlx-template', text: 'A starting point for Melange and mlx.', href: 'https://github.com/andreypopp/melange-mlx-template' },
  { name: 'KaranAhlawat/exuberant', text: 'Esy, Melange, mlx, and ReasonReact together.', href: 'https://github.com/KaranAhlawat/exuberant' },
  { name: 'camlworks/dream#330', text: 'An integration example for the Dream web framework.', href: 'https://github.com/camlworks/dream/pull/330' },
];

export const projects = [
  ['preview.dune.build', 'https://github.com/ocaml-dune/binary-distribution'],
  ['fun-ocaml.com', 'https://github.com/FUN-OCaml/fun-ocaml.com'],
  ['brisk-reconciler', 'https://github.com/briskml/brisk-reconciler'],
  ['feud.ml', 'https://github.com/terminaldotshop/feud.ml'],
  ['monocle', 'https://github.com/tjdevries/monocle'],
  ['topshelf.fm', 'https://github.com/tjdevries/topshelf.fm'],
  ['query-json.pages.dev', 'https://github.com/davesnx/query-json'],
  ['mesa', 'https://github.com/leostera/mesa'],
  ['andreypopp.com', 'https://github.com/andreypopp/andreypopp.com'],
  ['mailwoman', 'https://github.com/SoxPopuli/mailwoman'],
  ['html_of_jsx', 'https://github.com/davesnx/html_of_jsx'],
];

export const community = [
  { text: 'The JSX syntax feels natural alongside the OCaml I already write.', context: 'Authoring experience' },
  { text: 'A familiar way to write components, with OCaml types close at hand.', context: 'Typed interfaces' },
  { text: 'The formatter and editor integrations are part of the everyday workflow.', context: 'Tooling' },
  { text: 'It adds JSX syntax on top of OCaml instead of replacing the language.', context: 'Small syntax layer' },
  { text: 'The examples make it easier to see how the pieces fit together.', context: 'Learning' },
  { text: 'The runtime stays a choice for the application, not the syntax.', context: 'Runtime choice' },
];
export const communityNotice = 'Sample community quotes for this prototype. These are illustrative, not verified endorsements.';
export const urls = {
  github: 'https://github.com/ocaml-mlx/mlx',
  discord: 'https://discord.gg/ocaml',
  opam: 'https://opam.ocaml.org/packages/mlx/',
  releases: 'https://github.com/ocaml-mlx/mlx/releases',
};

export const articles = [
  { id: 'syntax', category: 'Language', title: 'A small syntax change. A familiar language.', description: 'Where JSX stops and ordinary OCaml begins.', paragraphs: [
    'mlx brings a JSX-shaped surface to OCaml. Tags, attributes, and children become expressions in the language rather than a separate template system.',
    'A capitalized tag is a component-level call. A lowercase tag is an element helper call. Attributes become labeled arguments, and children remain values.',
    'The resulting calls carry a JSX marker. A downstream PPX or library gives them their final meaning. The syntax is shared; runtime behavior is specific to the stack you choose.',
  ] },
  { id: 'tooling', category: 'Tooling', title: 'A place for .mlx in your Dune project.', description: 'Connect a new file extension to an existing build.', paragraphs: [
    'The integration point for mlx is a dialect in dune-project. It tells Dune which file extension to read, which reader Merlin should use, and how to preprocess and format the source.',
    'Install mlx along with ocamlformat-mlx and ocamlmerlin-mlx when you need formatter and editor support. Add the dialect, then create a small file and run your normal build.',
    'The application still uses its usual libraries and downstream preprocessing. Start with one module, check the entire path from source to output, and expand from there.',
  ] },
  { id: 'runtime', category: 'Ecosystem', title: 'One surface. More than one destination.', description: 'Browser components and server HTML, with an explicit boundary.', paragraphs: [
    'mlx does not decide whether your application runs in a browser or renders on a server. It supplies the authoring syntax and leaves the rendering model to your libraries.',
    'Melange and ReasonReact can interpret that source as browser components. Dream and html_of_jsx can render HTML on the server. Typed HTML integrations keep their own rules for attributes and children.',
    'Choose the runtime for the application you want to build. Then use mlx where the source becomes clearer. A common notation does not mean every stack has the same semantics.',
  ] },
];

export function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, (character) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[character]);
}

export function highlight(source) {
  return source.split(/("(?:[^"\\]|\\.)*"|\b(?:let|if|then|else|fun|match|with)\b|~[a-zA-Z_]+|<\/?[a-zA-Z][a-zA-Z0-9.]*)/g).map((part) => {
    const value = escapeHtml(part);
    if (/^"/.test(part)) return `<span class="token-string">${value}</span>`;
    if (/^(let|if|then|else|fun|match|with)$/.test(part)) return `<span class="token-keyword">${value}</span>`;
    if (/^~/.test(part)) return `<span class="token-attribute">${value}</span>`;
    if (/^</.test(part)) return `<span class="token-tag">${value}</span>`;
    return value;
  }).join('');
}
