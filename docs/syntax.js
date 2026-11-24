const component = {
  label: "A component in a .mlx file",
  code: `module Card = struct
  let createElement () ~title ~children =
    (title, children)
end

let example = <Card title="News">"Hello"</Card>`
};

const tagPaths = {
  label: "Names and module paths",
  code: `let page =
  <Ui.Layout>
    <Ui.button disabled=false>"Save"</Ui.button>
    <Ui.Icon />
  </Ui.Layout>`
};

const attributes = {
  label: "Attributes and optional arguments",
  code: `let field ~label ?placeholder ~readonly () =
  <Ui.input
    label
    ?placeholder
    readonly
    required=true
    width=(max 1 (String.length label))
  />`
};

const optionalValues = {
  label: "Optional value and a parenthesized expression",
  code: `let search ~hint ~count () =
  <Ui.search
    ?placeholder=(Some hint)
    count=(count + 1)
    onChange=(fun value -> print_endline value)
  />`
};

const expressions = {
  label: "OCaml expressions as attribute values",
  code: `let view ~count ~items () =
  <Ui.panel
    state=\`Ready
    fallback=(<Ui.empty />)
    options=[1; 2; 3]
    positions=[|0; count|]
    config={ width = count; items }
    value=(if count > 0 then count else 1)
  />`
};

const children = {
  label: "Quoted text, variables, and expressions",
  code: `let greeting ~name ~count () =
  <div>
    ("Hello, " ^ name)
    <span>(string_of_int count)</span>
    (if count = 1 then "item" else "items")
  </div>`
};

const nested = {
  label: "Elements in ordinary OCaml values",
  code: `let entries = [<Ui.row>"First"</Ui.row>; <Ui.row>"Second"</Ui.row>]
let columns = [|<Ui.column />; <Ui.column />|]
let page = { view = <Ui.row>"Ready"</Ui.row>; count = 1 }
let result = render <Ui.row>"Done"</Ui.row>`
};

const comments = {
  label: "OCaml comments between attributes and children",
  code: `let note =
  <Ui.note
    title="Notice"
    (* This comment is not an attribute. *)
    level=2
  >
    "Read this"
    (* This comment is not a child. *)
    <Ui.link>"More"</Ui.link>
  </Ui.note>`
};

const explicitChildren = {
  label: "Forward children as an attribute",
  code: `let forward children =
  <Card children />

let empty_body children =
  <Card children></Card>`
};

const fragments = {
  label: "Empty, nested, and parenthesized fragments",
  code: `let empty = <></>
let pair = <><Header /><Footer /></>
let inside = <Ui.panel><>"Left" "Right"</></Ui.panel>
let nested = <><> "one" </><> "two" </></>
let argument = consume (<> "before" "after" </>)`
};

const spread = {
  label: "Forward an existing children value",
  code: `let forward children = <Card>...children</Card>
let mapped items = <Card>...(List.map render_item items)</Card>
let grouped children = <>...children</>`
};

const comparisons = {
  label: "Operators and parentheses near JSX",
  code: `let less_than = a < b
let unequal = a <> b
let child = <Ui.row>(a < b)</Ui.row>
let fragment = <>(a <> b)</>
let custom_operator = <>(a </> b)</>`
};

export const syntaxExamples = [
  component,
  tagPaths,
  attributes,
  optionalValues,
  expressions,
  children,
  nested,
  comments,
  explicitChildren,
  fragments,
  spread,
  comparisons
];

export function syntaxGuide({ codeBlock, docsLink, external }) {
  const upstream = "https://github.com/ocaml-mlx/mlx/blob/e4580608d2d34904d27b766df8dc07f89b47edb9";

  return {
    title: "JSX syntax",
    intro: "Write JSX expressions inside OCaml. This guide covers tags, attributes, children, fragments, and the syntax limits that matter when you write .mlx files.",
    body: `
      <h2>Start with an OCaml expression</h2>
      <p>A <code>.mlx</code> file is OCaml with JSX expressions. You can bind an element with <code>let</code>, return one from a function, or put one inside another OCaml value. mlx does not supply HTML elements or a renderer: the functions and modules in your project decide what each tag means.</p>
      <p>This small component needs no UI library. Its <code>createElement</code> function accepts a unit argument, a labeled <code>title</code>, and labeled <code>children</code>. Real libraries define their own element types and component signatures.</p>
      ${codeBlock(component.label, component.code)}
      <p>The examples below use placeholder modules such as <code>Ui</code>. Use the names and types from your chosen library. For compiler and PPX details, see ${docsLink("how-it-works", "How it works")}.</p>

      <h2>Name a tag</h2>
      <p>A lowercase tag, such as <code>&lt;div /&gt;</code>, calls a function named <code>div</code>. An uppercase tag, such as <code>&lt;Card /&gt;</code>, calls the module&rsquo;s <code>createElement</code> function. For a qualified name, the <em>last</em> segment decides: <code>&lt;Ui.button /&gt;</code> names the function <code>Ui.button</code>; <code>&lt;Ui.Icon /&gt;</code> names the module <code>Ui.Icon</code> and its <code>createElement</code> function. A runtime PPX can interpret these calls differently.</p>
      ${codeBlock(tagPaths.label, tagPaths.code)}
      <p>Use OCaml identifiers and module paths for tag names, not arbitrary HTML names such as <code>&lt;my-widget /&gt;</code>. Match the whole opening and closing name: <code>&lt;Ui.Layout&gt;...&lt;/Ui.Layout&gt;</code>. A self-closing tag has an empty body; <code>&lt;Card&gt;&lt;/Card&gt;</code> has one too.</p>

      <h2>Pass attributes</h2>
      <p>Attributes are labeled OCaml arguments. <code>required=true</code> passes a Boolean value; a bare <code>readonly</code> passes the variable <code>readonly</code>, <strong>not</strong> <code>true</code>. Write <code>label</code> instead of <code>label=label</code> when a variable has the same name. The called function sets the accepted labels and their types.</p>
      ${codeBlock(attributes.label, attributes.code)}
      <p>Use <code>?placeholder</code> to pass an existing optional argument. Use <code>?placeholder=(Some hint)</code> to pass a chosen optional value. These forms use OCaml optional arguments; they do not make an HTML attribute optional by themselves.</p>
      ${codeBlock(optionalValues.label, optionalValues.code)}

      <h2>Use OCaml names for attributes</h2>
      <p>Attribute names must be lowercase OCaml identifiers. OCaml keywords such as <code>class</code>, <code>type</code>, <code>method</code>, and <code>open</code> cannot be attribute names. Use the actual label defined by your library, often <code>class_</code> or <code>type_</code>. mlx does not remove the underscore or rename the label. A hyphenated HTML name such as <code>aria-label</code> is not an OCaml attribute name; follow your library&rsquo;s convention instead.</p>

      <h2>Use expressions as attribute values</h2>
      <p>You can use OCaml literals, identifiers, constructors, variants, field access, lists, arrays, records, and even another JSX element as values. Dereferences such as <code>!value</code> and object method calls such as <code>object_#method_</code> are also expressions. Parenthesize a compound expression: a function call, negative number, operator expression, <code>if</code>, <code>match</code>, <code>fun</code>, <code>let</code>, or type annotation. The compiler checks each value against the receiving function's type.</p>
      ${codeBlock(expressions.label, expressions.code)}
      <p>For example, write <code>size=(to_size count)</code>. Without parentheses, <code>size=to_size count</code> is a <code>size</code> attribute plus a separate punned <code>count</code> attribute. For a JSX-valued attribute, parentheses also keep <code>=</code> separate from the tag's <code>&lt;</code>: write <code>fallback=(&lt;Ui.empty /&gt;)</code>. A braced value such as <code>config={ width = count }</code> is an OCaml record, not JSX interpolation. There is no props spread such as <code>&lt;Ui.panel ...props /&gt;</code>.</p>

      <h2>Write children as OCaml values</h2>
      <p>Put expressions between an opening and closing tag. Separate children with whitespace or newlines. Quote literal text: <code>"hello world"</code> is a string, while <code>hello world</code> is <em>two variables</em>. Whitespace between children does not produce a text node. mlx does not convert other values to strings; your runtime decides what children it accepts.</p>
      ${codeBlock(children.label, children.code)}
      <p>Use parentheses for one compound child. <code>&lt;div&gt;string_of_int count&lt;/div&gt;</code> has two children, the function and its argument. Write <code>&lt;div&gt;(string_of_int count)&lt;/div&gt;</code> instead. You can write <code>(match x with ...)</code>, <code>(let x = ... in ...)</code>, or <code>(value : type_name)</code> the same way. Combine text and a variable into one child with <code>("Hello, " ^ name)</code>.</p>

      <h2>Place elements inside other OCaml code</h2>
      <p>An element is an expression, not a separate template file. It can be a list or array item, a record field, or a function argument without parentheses. Ordinary OCaml syntax around the element remains available.</p>
      ${codeBlock(nested.label, nested.code)}

      <h2>Use OCaml comments</h2>
      <p>Write <code>(* ... *)</code> between attributes or children. Comments do not create attributes or children. They follow the usual OCaml comment rules.</p>
      ${codeBlock(comments.label, comments.code)}

      <h2>Pass children in one place</h2>
      <p>An element always passes a <code>children</code> argument, even when its body is empty. You can supply an existing value with a punned <code>children</code> attribute or with <code>children=value</code>. An optional <code>?children</code> follows the same rule. Pass children <strong>either</strong> as an attribute <strong>or</strong> between tags, not both. The latest upstream parser rejects an explicit <code>children</code> or <code>?children</code> combined with nested content; an empty body is allowed.</p>
      ${codeBlock(explicitChildren.label, explicitChildren.code)}

      <h2>Group with fragments (mlx 0.12+)</h2>
      <p>A fragment uses <code>&lt;&gt;</code> and <code>&lt;/&gt;</code> without a named tag. It can be empty, contain multiple children, or nest inside an element or another fragment. A nested fragment stays one child in its parent; mlx does not flatten it automatically. The chosen runtime decides how fragments render.</p>
      ${codeBlock(fragments.label, fragments.code)}
      <p>Unlike an element, a fragment passed directly as a function argument needs parentheses: <code>consume (&lt;&gt;"one"&lt;/&gt;)</code>. Fragments arrived in mlx 0.12; do not use them with an older version.</p>

      <h2>Spread one children value (mlx 0.12+)</h2>
      <p>When you already have a children value, prefix it with <code>...</code> <em>inside</em> an element or fragment. The spread must be its only child. It passes the existing value directly rather than adding it as one item of a new children list. Parenthesize a function call after the dots. Spaces around the dots are optional.</p>
      ${codeBlock(spread.label, spread.code)}
      <p><code>&lt;Card&gt;"first" ...rest&lt;/Card&gt;</code>, <code>&lt;Card&gt;...rest "last"&lt;/Card&gt;</code>, and the equivalent mixed fragments are syntax errors. <code>&lt;&gt;...children&lt;/&gt;</code> marks the existing value as a fragment. The dots do not spread attributes.</p>

      <h2>Keep delimiters and operators distinct</h2>
      <p>Closing names must match: <code>&lt;Ui.Card&gt;...&lt;/Ui.Card&gt;</code> cannot close as <code>&lt;/Card&gt;</code> or <code>&lt;/&gt;</code>. A fragment must close with <code>&lt;/&gt;</code>. OCaml&rsquo;s <code>&lt;&gt;</code> inequality operator and the <code>&lt;/&gt;</code> operator remain available. Inside a fragment, parenthesize an operator expression so it cannot be mistaken for the fragment delimiter.</p>
      ${codeBlock(comparisons.label, comparisons.code)}
      <p>Put spaces around a less-than comparison, <code>a &lt; b</code>: without a space, <code>a&lt;b</code> can be read as the start of a JSX tag. Parenthesize comparisons inside children and attribute values. The sequence <code>&gt;...</code> is reserved for children spread, so an operator beginning with it is unavailable in mlx 0.12. Some operator prefixes adjacent to fragment delimiters also changed in 0.12; check the ${external("https://github.com/ocaml-mlx/mlx/blob/e4580608d2d34904d27b766df8dc07f89b47edb9/CHANGES", "0.12 release notes")} if you use custom symbolic operators.</p>

      <h2>Check the source</h2>
      <p>These rules follow the upstream ${external(`${upstream}/test/mlx.t`, "JSX and fragment tests")} and ${external(`${upstream}/test/overrides.t`, "OCaml delimiter tests")} at commit <code>e4580608</code>. Tests confirm parser behavior, not the types or output of any particular UI library. Use your library&rsquo;s documentation to check prop names, child types, and rendering.</p>
    `
  };
}
