export function agentGuide({ docsLink, githubMark }) {
  return {
    title: "For your agent",
    intro: "Give your coding agent the mlx setup and syntax guides, then review its OCaml with your project's tools.",
    body: `<h2>Why JSX still matters</h2>
      <p>JSX keeps the tree of elements and components visible in the source. Nested tags show which children belong to which parent, and labeled attributes sit beside their values. This makes an agent's output easier for you to read and review than a long chain of construction calls. It does not guarantee that the output matches your intent.</p>
      <p>In mlx, JSX-shaped expressions become OCaml calls. You can use ordinary OCaml expressions inside them, and the compiler checks the resulting calls and labels against the functions in your project. The selected library supplies the behavior; mlx does not choose a runtime. Read the ${docsLink("syntax", "JSX syntax guide")} and ${docsLink("how-it-works", "how mlx works")} for the source forms and their translation.</p>
      <h2>Skills for your agent</h2>
      <p>Use the setup skill to configure a project and the syntax skill when writing or reviewing <code>.mlx</code> files. The skill files are hosted on GitHub; access to the repository is required.</p>
      <div class="template-grid">
        <a class="template-card" href="https://github.com/ocaml-mlx/skills/blob/main/skills/setup-mlx/SKILL.md" target="_blank" rel="noopener noreferrer" aria-label="Setup mlx skill on GitHub">
          <div class="template-card-header"><h3>Setup mlx</h3><span class="template-github">${githubMark}</span></div>
          <p>Install the toolchain, register the Dune dialect, check editor and formatter support, and verify the build.</p>
          <div class="template-meta"><span>Agent skill</span><span>GitHub</span></div>
        </a>
        <a class="template-card" href="https://github.com/ocaml-mlx/skills/blob/main/skills/mlx-syntax/SKILL.md" target="_blank" rel="noopener noreferrer" aria-label="JSX syntax skill on GitHub">
          <div class="template-card-header"><h3>JSX syntax</h3><span class="template-github">${githubMark}</span></div>
          <p>Check element calls, props, children, component signatures, and expressions that need parentheses.</p>
          <div class="template-meta"><span>Agent skill</span><span>GitHub</span></div>
        </a>
      </div>
      <h2>Working in an existing project</h2>
      <p>Tell your agent which runtime and UI library the project uses. Ask it to follow the project's component signatures and attribute names instead of assuming that JSX has the same meaning in every stack. Use the setup skill if the toolchain is missing, then the syntax skill for <code>.mlx</code> edits. Run the project's build, type checks, and formatter, and review the resulting view. Compiler feedback can catch invalid calls and labels, but it cannot confirm that the interface meets your requirements.</p>`
  };
}
