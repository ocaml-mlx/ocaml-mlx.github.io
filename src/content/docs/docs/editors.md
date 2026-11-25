---
title: Editors
description: Configure editor support for mlx files in VS Code, Neovim, and tree-sitter based environments.
slug: docs/editors
---

## VS Code and forks

Install the [OCaml Platform extension](https://github.com/ocamllabs/vscode-ocaml-platform).

This is the path for VS Code itself plus compatible forks such as Cursor and Windsurf. Once your project has the `mlx` dialect configured, the usual navigation, diagnostics, and merlin-backed workflows remain available.

## Neovim

Use [`ocaml_mlx.nvim`](https://github.com/ocaml-mlx/ocaml_mlx.nvim) if you want dedicated Neovim support for `.mlx` files.

This path is a good fit if your editor setup already leans on `nvim-treesitter`, LSP integration, and a terminal-first OCaml workflow.

## tree-sitter

For editors and tools built around tree-sitter, use [`tree-sitter-mlx`](https://github.com/ocaml-mlx/tree-sitter-mlx).

This is especially useful for custom editor integrations, syntax highlighting, and tooling experiments outside the main editor plugins.

## Troubleshooting checklist

- Make sure the `dune-project` dialect block is present and committed.
- Install `ocamlmerlin-mlx` if your editor session cannot parse `.mlx` files yet.
- Install `ocamlformat-mlx` if formatting works for `.ml` but not for `.mlx`.
- Restart the editor after adding the dialect or switching opam switches.

## Missing your editor?

If your preferred editor is missing, [open an issue](https://github.com/ocaml-mlx/mlx/issues?q=sort%3Aupdated-desc+is%3Aissue+is%3Aopen) and include:

- the editor name and version
- how it currently parses OCaml
- whether it uses merlin, tree-sitter, or its own syntax engine
- any existing plugin or integration worth building on
