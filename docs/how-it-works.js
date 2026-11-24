export const howItWorksExamples = {
  source: `let tag ~class_ ~children () =
  "<" ^ class_ ^ ">" ^ String.concat "" children ^ "</" ^ class_ ^ ">"

let text ~children () = String.concat "" children

module Badge = struct
  let createElement ~label ~children () =
    "[" ^ label ^ ":" ^ String.concat "" children ^ "]"
end

let () =
  print_endline
    <tag class_="demo"><text>"Hello"</text><Badge label="mlx">"!"</Badge></tag>`,
  lowered: `print_endline
  ((tag ()
      ~children:[((text () ~children:["Hello"]) [@JSX ]);
                 ((Badge.createElement () ~children:["!"] ~label:"mlx")
                  [@JSX ])]
      ~class_:"demo")
   [@JSX ])`,
  inspect: `mlx-pp -print-ml example.mlx`,
  direct: `ocamlc -pp mlx-pp -impl example.mlx -o example
./example`,
  minimalProject: `(lang dune 3.16)
(name mlx_toolchain_example)

(dialect
 (name mlx)
 (implementation
  (extension mlx)
  (preprocess
   (run mlx-pp %{input-file}))))`,
  duneFile: `(executable
 (name example))`,
  duneRun: `dune exec ./example.exe`,
  fullProject: `(lang dune 3.16)
(name mlx_toolchain_example)

(dialect
 (name mlx)
 (implementation
  (extension mlx)
  (merlin_reader mlx)
  (format
   (run ocamlformat-mlx %{input-file}))
  (preprocess
   (run mlx-pp %{input-file}))))`,
  output: `<demo>Hello[mlx:!]</demo>`
};

const mlxSource = "https://github.com/ocaml-mlx/mlx/blob/e4580608d2d34904d27b766df8dc07f89b47edb9";
const formatterSource = "https://github.com/ocaml-mlx/ocamlformat-mlx/blob/2cc0d2774b64e796b221c43532242c543aa3561c";

export function howItWorksGuide({ codeBlock, docsLink, external }) {
  const examples = howItWorksExamples;
  return {
    title: "How it works",
    intro: "Follow a .mlx expression from the parser to an ordinary OCaml program, then connect the same path to Dune and editor tools.",
    body: `<h2>The compilation path</h2>
      <p>A <code>.mlx</code> file starts as OCaml with JSX-shaped expressions. <code>mlx-pp</code> parses it into an OCaml syntax tree, then the installed OCaml compiler checks and compiles that tree. Your component functions or a later PPX define what the resulting calls do. mlx does not provide an HTML renderer or replace <code>ocamlc</code>.</p>
      <h2>A modified OCaml parser</h2>
      <p>The mlx source includes adapted OCaml lexer and parser code. Its lexer recognizes opening and closing tags; its parser accepts elements as expressions alongside ordinary OCaml expressions. This is a fork of the parsing layer, not a fork you must use as your application compiler. The <code>mlx</code> package installs the <code>mlx-pp</code> preprocessor.</p>
      <p>By default, <code>mlx-pp</code> writes a binary OCaml syntax tree for the compiler, not a text <code>.ml</code> file. To inspect readable OCaml, use its real <code>-print-ml</code> option:</p>
      <p>The parser produces a tree for its vendored OCaml version. <code>mlx-pp</code> uses <code>ppxlib</code> to migrate that tree to the compiler AST version it was built with, then writes the compiler's binary AST header and tree. This is why the modified parser can work with a supported, ordinary OCaml compiler. The parser and your application's compiler do not have to be the same fork.</p>
      ${codeBlock("Inspect the generated OCaml · shell", examples.inspect)}
      <h2>Elements become calls</h2>
      <p>Consider this complete program. Its helpers use plain strings so you can run it without a UI framework or PPX:</p>
      ${codeBlock("example.mlx", examples.source)}
      <p>The lowercase <code>&lt;tag&gt;</code> and <code>&lt;text&gt;</code> call functions in scope. The capitalized <code>&lt;Badge&gt;</code> calls <code>Badge.createElement</code>. Attributes become labeled arguments such as <code>~class_:"demo"</code> and <code>~label:"mlx"</code>. Nested expressions become one <code>~children</code> list. Every element call also receives an unlabeled <code>()</code> argument first. The relevant part of <code>mlx-pp -print-ml example.mlx</code> looks like this; only the helper declarations and whitespace are omitted:</p>
      ${codeBlock("Generated OCaml · excerpt", examples.lowered)}
      <h2>Why the JSX attribute remains</h2>
      <p>The <code>[@JSX]</code> attribute marks each generated element application. It lets a downstream PPX recognize JSX calls instead of guessing from ordinary function calls. A fragment has no tag to call: its list of children, or its spread expression, carries the marker instead. A PPX may use these markers to implement a framework's behavior, but a PPX is not required. In the program above, the OCaml compiler accepts the marked calls and the plain functions build the result.</p>
      <h2>Compile directly with ocamlc</h2>
      <p>Install <code>mlx</code> and make sure <code>mlx-pp</code> and <code>ocamlc</code> are on your <code>PATH</code>. Save the program above as <code>example.mlx</code>, then run:</p>
      ${codeBlock("Compile and run · shell", examples.direct)}
      <p>The <code>-pp</code> option runs <code>mlx-pp</code> before parsing by the compiler; <code>-impl</code> identifies <code>example.mlx</code> as an implementation. The program prints:</p>
      ${codeBlock("Output", examples.output)}
      <h2>Build the same program with Dune</h2>
      <p>For a new project, save the following <code>dune-project</code> beside <code>example.mlx</code>. You need Dune 3.16 or newer for this dialect. A build needs only the mlx preprocessor, OCaml, and Dune.</p>
      ${codeBlock("dune-project · minimal", examples.minimalProject)}
      <p><code>(name mlx)</code> registers the dialect. <code>(extension mlx)</code> selects <code>.mlx</code> implementation files. <code>(preprocess (run mlx-pp %{input-file}))</code> gives Dune the source file and writes the binary syntax tree to stdout for the compiler. The dialect does not change <code>.mli</code> files here.</p>
      <p>Save this in a file named <code>dune</code> in the same directory:</p>
      ${codeBlock("dune", examples.duneFile)}
      ${codeBlock("Build and run · shell", examples.duneRun)}
      <p>It prints the same output shown above. If your application uses a downstream PPX, configure it in the usual Dune library or executable stanza after this syntax preprocessing step. The mlx dialect does not choose that PPX.</p>
      <h2>Add editor and formatter support when needed</h2>
      <p>The following version adds two independent tools. Install <code>ocamlmerlin-mlx</code> and <code>ocamlformat-mlx</code> before you copy these optional fields:</p>
      ${codeBlock("dune-project · editor and formatter", examples.fullProject)}
      <p><code>(merlin_reader mlx)</code> selects the <code>ocamlmerlin-mlx</code> reader extension for Merlin's editor parsing. Its adapted Merlin parser reports source errors and converts the result for Merlin. It is not a replacement OCaml compiler or a full replacement for Merlin or OCaml LSP. <code>(format (run ocamlformat-mlx %{input-file}))</code> runs the separate OCamlFormat fork when formatting a <code>.mlx</code> source file; it is not part of compilation. Leave either clause out if you do not use that tool. The <code>preprocess</code> clause is the one the compiler build needs.</p>
      <h2>Where a downstream PPX fits</h2>
      <p>The order is <code>.mlx</code> source → mlx parsing → marked OCaml calls → optional downstream PPX → normal type checking and compilation. Do not substitute <code>ocamlc -ppx mlx-pp</code> for <code>-pp mlx-pp</code>. A PPX runs after the compiler parses its input, so it cannot teach the ordinary compiler parser to read JSX tags. Use ${docsLink("libraries", "the libraries guide")} to choose the functions or PPX that give your tags their behavior.</p>
      <h2>Sources and version scope</h2>
      <p>This explanation follows mlx source at revision <code>e458060</code>, just after release 0.12. That release added fragment and children-spread syntax; the later revision also rejects an explicit <code>children</code> prop combined with nested children. The standalone program and Dune example were run with OCaml 5.5.0 and Dune 3.24.2. They do not test the companion editor or formatter binaries.</p>
      <ul>
        <li>${external(`${mlxSource}/mlx/pp.ml`, "mlx-pp: output format and -print-ml")}</li>
        <li>${external(`${mlxSource}/mlx/jsx_helper.ml`, "Element lowering and the JSX marker")}</li>
        <li>${external(`${mlxSource}/ocamlmerlin_mlx/ocamlmerlin_mlx.ml`, "Merlin reader extension")}</li>
        <li>${external(`${formatterSource}/vendor/parser-extended/jsx_helper.ml`, "Separate formatter's JSX support")}</li>
        <li>${external("https://dune.readthedocs.io/en/stable/reference/dune-project/dialect.html", "Dune dialect reference")}</li>
      </ul>`
  };
}
