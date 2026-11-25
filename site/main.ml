module D = Yocaml.Data
module P = Yocaml.Path
module T = Yocaml.Task

let str = D.string
let obj = D.record
let list = D.list
let path = P.from_string
let string key value = (key, str value)

let rec json_data : Yojson.Basic.t -> D.t = function
  | `Null -> D.null
  | `Bool value -> D.bool value
  | `Int value -> D.int value
  | `Float value -> D.float value
  | `String value -> str value
  | `List values -> list (List.map json_data values)
  | `Assoc fields ->
      obj (List.map (fun (key, value) -> (key, json_data value)) fields)

let rec yaml_data : Yaml.value -> D.t = function
  | `Null -> D.null
  | `String s -> str s
  | `Bool b -> D.bool b
  | `Float f -> D.float f
  | `A xs -> list (List.map yaml_data xs)
  | `O fields -> obj (List.map (fun (key, v) -> (key, yaml_data v)) fields)

let rec files dir =
  Sys.readdir dir |> Array.to_list |> List.sort String.compare
  |> List.concat_map (fun name ->
      let file = Filename.concat dir name in
      if Sys.is_directory file then files file
      else if
        Filename.check_suffix name ".md" || Filename.check_suffix name ".mdx"
      then [ file ]
      else [])

let all_docs source =
  let docs =
    files source
    |> List.map (fun file -> Content.parse file (Content.read file))
  in
  let seen = Hashtbl.create 16 in
  List.iter
    (fun doc ->
      if Hashtbl.mem seen doc.Content.slug then
        failwith ("duplicate route: " ^ doc.Content.slug);
      Hashtbl.add seen doc.slug ())
    docs;
  docs

let nav_order =
  [
    ( "Documentation",
      [
        ("docs/installation", "Installation");
        ("docs/editors", "Editors");
        ("docs/formal-syntax", "Formal syntax");
        ("changelog", "Version history");
      ] );
    ( "Guides",
      [
        ("docs/guides/melange-reason-react", "mlx with Melange and ReasonReact");
        ("docs/guides/dream-html-of-jsx", "mlx with Dream and html_of_jsx");
        ("docs/guides/tyxml", "mlx with TyXML");
      ] );
    ( "Ecosystem",
      [
        ("docs/templates", "Templates");
        ("docs/projects-using-mlx", "Projects using mlx");
      ] );
  ]

let route slug = if slug = "changelog" then "/changelog/" else "/" ^ slug ^ "/"

let page_path slug =
  if slug = "docs" then "docs/index.html" else slug ^ "/index.html"

let mirror_path slug = slug ^ ".md"

let item slug label current =
  obj
    [
      string "label" label;
      string "url" (route slug);
      ("current", D.bool (slug = current));
    ]

let navigation docs current =
  let lookup slug fallback =
    match List.find_opt (fun doc -> doc.Content.slug = slug) docs with
    | Some doc -> doc.Content.title
    | None -> fallback
  in
  let known =
    nav_order
    |> List.map (fun (label, items) ->
        ( label,
          List.filter_map
            (fun (slug, fallback) ->
              if
                slug = "changelog"
                || List.exists (fun doc -> doc.Content.slug = slug) docs
              then Some (slug, lookup slug fallback)
              else None)
            items ))
  in
  let named = List.concat_map (fun (_, items) -> List.map fst items) known in
  let remaining =
    docs
    |> List.filter (fun doc ->
        doc.Content.slug <> "docs" && not (List.mem doc.Content.slug named))
    |> List.map (fun doc -> (doc.Content.slug, doc.Content.title))
  in
  let groups =
    if remaining = [] then known else known @ [ ("More", remaining) ]
  in
  let nav =
    groups
    |> List.map (fun (label, items) ->
        obj
          [
            string "label" label;
            ( "items",
              list
                (List.map (fun (slug, title) -> item slug title current) items)
            );
          ])
    |> list
  in
  let flat = List.concat_map snd groups in
  let rec adjacent = function
    | (slug, _) :: (next_slug, next_title) :: _ when slug = current ->
        (D.null, item next_slug next_title current)
    | (slug, title) :: ((next_slug, _) :: _ as tail) when next_slug = current ->
        let after =
          match tail with
          | _ :: (after_slug, after_title) :: _ ->
              item after_slug after_title current
          | _ -> D.null
        in
        (item slug title current, after)
    | _ :: rest -> adjacent rest
    | [] -> (D.null, D.null)
  in
  let previous, next = adjacent flat in
  (nav, previous, next)

let headings_value headings =
  list
    (List.map
       (fun (heading : Markdown.heading) ->
         obj
           [
             string "id" heading.id;
             string "text" heading.text;
             ("depth", D.int heading.depth);
           ])
       headings)

type release = {
  name : string;
  tag_name : string;
  slug : string;
  published_at : string;
  date : string;
  html_url : string;
  body_html : string;
  prerelease : bool;
}

type release_input = { releases : release list; error : string option }

let parse_releases raw =
  let json =
    try Yojson.Basic.from_string raw
    with Yojson.Json_error message ->
      failwith ("invalid release input: " ^ message)
  in
  let member location key = function
    | `Assoc fields -> (
        match List.assoc_opt key fields with
        | Some value -> value
        | None ->
            failwith
              ("invalid release input: " ^ location ^ "." ^ key ^ " is missing")
        )
    | _ -> failwith ("invalid release input: " ^ location ^ " must be an object")
  in
  let text location key json =
    match member location key json with
    | `String value -> value
    | _ ->
        failwith
          ("invalid release input: " ^ location ^ "." ^ key
         ^ " must be a string")
  in
  let release index json =
    let location = Printf.sprintf "releases[%d]" index in
    let name = text location "name" json in
    let tag_name = text location "tagName" json in
    let slug = text location "slug" json in
    let published_at = text location "publishedAt" json in
    let date = text location "date" json in
    let html_url = text location "htmlUrl" json in
    let body_html = text location "bodyHtml" json in
    let prerelease =
      match member location "prerelease" json with
      | `Bool value -> value
      | _ ->
          failwith
            ("invalid release input: " ^ location
           ^ ".prerelease must be a boolean")
    in
    {
      name;
      tag_name;
      slug;
      published_at;
      date;
      html_url;
      body_html;
      prerelease;
    }
  in
  let error =
    match member "root" "error" json with
    | `Null -> None
    | `String value -> Some value
    | _ -> failwith "invalid release input: root.error must be null or string"
  in
  let releases =
    match member "root" "releases" json with
    | `List items -> List.mapi release items
    | _ -> failwith "invalid release input: root.releases must be an array"
  in
  { releases; error }

let release_value release =
  obj
    [
      string "name" release.name;
      string "tagName" release.tag_name;
      string "slug" release.slug;
      string "publishedAt" release.published_at;
      string "date" release.date;
      string "htmlUrl" release.html_url;
      string "bodyHtml" release.body_html;
      ("prerelease", D.bool release.prerelease);
    ]

let render_releases input =
  let escape = Highlight.escape in
  let header =
    {|<div class="sl-markdown-content release-intro"><p>This page is generated directly from <a href="https://github.com/ocaml-mlx/mlx/releases">GitHub Releases</a> so the public release history stays close to the repository.</p></div> |}
  in
  let failure =
    match input.error with
    | None -> ""
    | Some error ->
        {|<div class="release-error"><p>Could not load GitHub releases during the build.</p><pre><code>|}
        ^ escape error ^ "</code></pre></div> "
  in
  let card item =
    let name = escape item.name in
    let tag = escape item.tag_name in
    let badge =
      if item.prerelease then {|<span class="release-badge">Prerelease</span>|}
      else ""
    in
    let date =
      if item.published_at = "" then ""
      else
        "<time datetime=\"" ^ escape item.published_at ^ "\">"
        ^ escape item.date ^ "</time> "
    in
    let body =
      if item.body_html = "" then
        {|<p class="release-empty">No release notes were published for this version.</p>|}
      else {|<div class="sl-markdown-content">|} ^ item.body_html ^ "</div>"
    in
    "<section class=\"release-card\" id=\"" ^ escape item.slug
    ^ "\"> <div class=\"release-card__header\"> <div> <h2>" ^ name
    ^ "</h2> <p> <code>" ^ tag ^ "</code> " ^ badge
    ^ " </p> </div> <div class=\"release-meta\"> " ^ date ^ "<a href=\""
    ^ escape item.html_url ^ "\">View on GitHub</a> </div> </div> " ^ body
    ^ " </section> "
  in
  header ^ failure ^ "<div class=\"release-list\"> "
  ^ String.concat "" (List.map card input.releases)
  ^ "</div>"

let common ~docs ~kind ~route:route_ ~title ~description ~body ~headings ~hero
    ~edit_url ~releases ~error ~theme_script =
  let nav, previous, next = navigation docs (String.trim route_) in
  [
    string "page_kind" kind;
    string "kind" kind;
    string "route"
      (if kind = "landing" then "/"
       else if kind = "not_found" then "/404.html"
       else route route_);
    string "title" title;
    string "description" description;
    string "body" body;
    ("headings", headings_value headings);
    ("navigation", nav);
    ("previous", previous);
    ("next", next);
    ("edit_url", D.option str edit_url);
    ("hero", yaml_data hero);
    ("releases", releases);
    string "error" error;
    string "theme_script" theme_script;
  ]

let source_task filename = Yocaml.Pipeline.read_file (path filename)

let dependency_files =
  [ "site/content.ml"; "site/highlight.ml"; "site/markdown.ml"; "site/main.ml" ]

let highlight_files =
  List.map
    (fun name -> "assets/highlight/" ^ name ^ ".json")
    [
      "html";
      "lisp";
      "ocaml";
      "shellscript";
      "night-owl-dark";
      "night-owl-light";
    ]

let tracked paths = Yocaml.Pipeline.track_files (List.map path paths)

let render_template context template =
  let models =
    match Yocaml_jingoo.from (obj context) with
    | Jingoo.Jg_types.Tobj models -> models
    | _ -> failwith "invalid template context"
  in
  let env = Jingoo.Jg_types.{ std_env with template_dirs = [ "templates" ] } in
  Jingoo.Jg_template.from_string ~env ~models template

let all_sources filenames =
  List.fold_left
    (fun task file ->
      T.map2
        (fun docs body -> Content.parse file body :: docs)
        task (source_task file))
    (T.pure []) filenames
  |> T.map List.rev

let run ~output ~releases:releases_file ~theme:theme_file =
  let source = "src/content/docs/docs" in
  let docs = all_docs source in
  let source_files = List.map (fun doc -> doc.Content.source) docs in
  let highlight = Highlight.load "assets/highlight" in
  if not (Sys.file_exists theme_file) then
    failwith ("required asset missing: " ^ theme_file);
  let theme_task = source_task theme_file in
  let docs_task = all_sources source_files in
  let templates =
    if Sys.file_exists "templates" then
      Sys.readdir "templates" |> Array.to_list
      |> List.map (Filename.concat "templates")
      |> List.filter (fun file -> not (Sys.is_directory file))
    else []
  in
  let inputs = dependency_files @ highlight_files @ templates in
  let page_task doc =
    T.map5
      (fun docs theme_script body card_template heading_template ->
        let doc = Content.parse doc.Content.source body in
        let body =
          if doc.Content.splash then
            Markdown.render_cards highlight ~card_template ~heading_template
              doc.body
          else doc.body
        in
        let rendered = Markdown.render highlight ~heading_template body in
        let context =
          common ~docs
            ~kind:(if doc.splash then "splash" else "doc")
            ~route:doc.slug ~title:doc.title ~description:doc.description
            ~body:rendered.html ~headings:rendered.headings ~hero:doc.hero
            ~edit_url:
              (Some
                 ("https://github.com/ocaml-mlx/website/edit/main/" ^ doc.source))
            ~releases:(list []) ~error:"" ~theme_script
        in
        context)
      docs_task theme_task (source_task doc.source)
      (source_task "templates/card.html")
      (source_task "templates/heading.html")
  in
  let output_path file = path (Filename.concat output file) in
  let write_file file task =
    Yocaml.Action.write_static_file (output_path file) task
  in
  let doc_action doc =
    let html_task =
      T.map2 render_template (page_task doc) (source_task "templates/page.html")
    in
    let html_task = T.rcompose (tracked inputs) html_task in
    let mirror_task =
      T.map
        (fun raw -> Content.mirror (Content.parse doc.source raw))
        (source_task doc.source)
      |> T.rcompose (tracked [ "site/content.ml" ])
    in
    fun cache ->
      let open Yocaml.Eff.Syntax in
      let* cache = write_file (page_path doc.slug) html_task cache in
      write_file (mirror_path doc.slug) mirror_task cache
  in
  let release_task =
    T.map3
      (fun docs theme_script raw ->
        let input = parse_releases raw in
        let headings =
          List.map
            (fun release ->
              { Markdown.id = release.slug; text = release.name; depth = 2 })
            input.releases
        in
        common ~docs ~kind:"changelog" ~route:"changelog"
          ~title:"Version history"
          ~description:"Release notes for mlx fetched from GitHub Releases."
          ~body:(render_releases input) ~headings ~hero:`Null ~edit_url:None
          ~releases:(list (List.map release_value input.releases))
          ~error:(Option.value ~default:"" input.error)
          ~theme_script)
      docs_task theme_task
      (source_task releases_file)
  in
  let simple_context kind docs theme_script =
    common ~docs ~kind ~route:kind
      ~title:
        (if kind = "landing" then "mlx — JSX for OCaml" else "Page not found")
      ~description:
        "JSX syntax for OCaml with minimal parser and tooling changes."
      ~body:"" ~headings:[] ~hero:`Null ~edit_url:None ~releases:(list [])
      ~error:"" ~theme_script
  in
  let plain kind file template_file =
    let landing_task =
      if kind = "landing" then source_task "assets/landing.json"
      else T.pure "{}"
    in
    let context =
      T.map3
        (fun docs theme_script landing ->
          simple_context kind docs theme_script
          @ [ ("landing", json_data (Yojson.Basic.from_string landing)) ])
        docs_task theme_task landing_task
    in
    let task =
      T.map2 render_template context (source_task template_file)
      |> T.rcompose (tracked inputs)
    in
    write_file file task
  in
  let changelog =
    let task =
      T.map2 render_template release_task (source_task "templates/page.html")
      |> T.rcompose (tracked inputs)
    in
    write_file "changelog/index.html" task
  in
  let site = "https://ocaml-mlx.pages.dev/" in
  let locations =
    [ ""; "changelog/" ]
    @ List.sort String.compare
        (List.map (fun doc -> doc.Content.slug ^ "/") docs)
  in
  let sitemap =
    let begin_ =
      {|<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:news="http://www.google.com/schemas/sitemap-news/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:image="http://www.google.com/schemas/sitemap-image/1.1" xmlns:video="http://www.google.com/schemas/sitemap-video/1.1">|}
    in
    begin_
    ^ String.concat ""
        (List.map
           (fun location -> "<url><loc>" ^ site ^ location ^ "</loc></url>")
           locations)
    ^ "</urlset>"
  in
  let index =
    {|<?xml version="1.0" encoding="UTF-8"?><sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"><sitemap><loc>https://ocaml-mlx.pages.dev/sitemap-0.xml</loc></sitemap></sitemapindex>|}
  in
  let actions =
    List.map doc_action docs
    @ [
        changelog;
        plain "landing" "index.html" "templates/landing.html";
        plain "not_found" "404.html" "templates/page.html";
        write_file "sitemap-0.xml"
          (T.map (fun _ -> sitemap) docs_task
          |> T.rcompose (tracked [ "site/main.ml" ]));
        write_file "sitemap-index.xml"
          (T.rcompose (tracked [ "site/main.ml" ]) (T.pure index));
      ]
  in
  Yocaml_unix.run (fun () ->
      Yocaml.Action.with_cache
        (path (output ^ ".yocaml-cache"))
        (Yocaml.Action.batch_list actions (fun action -> action)))

let () =
  let output = ref "" in
  let releases = ref "" in
  let theme = ref "" in
  let options =
    [
      ("--output", Arg.Set_string output, "Output directory");
      ("--releases", Arg.Set_string releases, "Validated release JSON");
      ("--theme", Arg.Set_string theme, "Compiled synchronous theme script");
    ]
  in
  Arg.parse options
    (fun value -> raise (Arg.Bad ("unexpected argument " ^ value)))
    "site/main.exe --output DIR --releases FILE --theme FILE";
  if !output = "" || !releases = "" || !theme = "" then
    failwith "usage: site/main.exe --output DIR --releases FILE --theme FILE";
  run ~output:!output ~releases:!releases ~theme:!theme
