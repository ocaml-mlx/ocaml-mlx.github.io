type t = {
  grammar : Ochre.t;
  dark : Ochre.Theme.theme;
  light : Ochre.Theme.theme;
}

let unpack = function
  | Ok x -> x
  | Error e -> failwith (Ochre.Error.to_string e)

let load root =
  let input name = Filename.concat root (name ^ ".json") in
  let grammars =
    List.map
      (fun name -> (name, Content.read (input name)))
      [ "shellscript"; "lisp"; "ocaml"; "html" ]
  in
  let theme name =
    let value, warnings = Ochre.Theme.load_from_file (input name) |> unpack in
    List.iter
      (fun warning -> failwith (Ochre.Theme.warning_to_string warning))
      warnings;
    value
  in
  {
    grammar = Ochre.load grammars |> unpack;
    dark = theme "night-owl-dark";
    light = theme "night-owl-light";
  }

let escape value =
  let buffer = Buffer.create (String.length value) in
  String.iter
    (function
      | '&' -> Buffer.add_string buffer "&amp;"
      | '<' -> Buffer.add_string buffer "&#x3C;"
      | '>' -> Buffer.add_string buffer "&#x3E;"
      | '"' -> Buffer.add_string buffer "&#x22;"
      | '\'' -> Buffer.add_string buffer "&#x27;"
      | ch -> Buffer.add_char buffer ch)
    value;
  Buffer.contents buffer

let copy_text value =
  let buffer = Buffer.create (String.length value) in
  String.iter
    (function
      | '\n' -> Buffer.add_char buffer '\x7f'
      | '&' -> Buffer.add_string buffer "&amp;"
      | '"' -> Buffer.add_string buffer "&#x22;"
      | '\'' -> Buffer.add_string buffer "&#x27;"
      | ch -> Buffer.add_char buffer ch)
    value;
  Buffer.contents buffer

let code_lines code =
  let lines = String.split_on_char '\n' code in
  match List.rev lines with "" :: rest -> List.rev rest | _ -> lines

let render t ~lang ~title source =
  let grammar_name = if lang = "sh" then "shellscript" else lang in
  let grammar = Ochre.lang t.grammar grammar_name |> unpack in
  let dark = Ochre.highlight ~theme:t.dark ~lang:grammar source in
  let light = Ochre.highlight ~theme:t.light ~lang:grammar source in
  let has_font = ref false in
  let font_style (style : Ochre.Style.font_style) =
    let decorations =
      (if style.underline then [ "underline" ] else [])
      @ if style.strikethrough then [ "line-through" ] else []
    in
    let weight = if style.bold then "bold" else "normal" in
    let style_name = if style.italic then "italic" else "normal" in
    let decoration =
      if decorations = [] then "none" else String.concat " " decorations
    in
    (weight, style_name, decoration)
  in
  let span (text, (dark_style : Ochre.Style.t), (light_style : Ochre.Style.t)) =
    let text =
      if String.ends_with ~suffix:"\n" text then
        String.sub text 0 (String.length text - 1)
      else text
    in
    if text = "" then ""
    else
      let styled =
        dark_style.font_style <> Ochre.Style.plain
        || light_style.font_style <> Ochre.Style.plain
      in
      if styled then has_font := true;
      let font_vars =
        if not styled then ""
        else
          let d_weight, d_style, d_decoration =
            font_style dark_style.font_style
          in
          let l_weight, l_style, l_decoration =
            font_style light_style.font_style
          in
          Printf.sprintf
            ";--0-font-weight:%s;--1-font-weight:%s;--0-font-style:%s;--1-font-style:%s;--0-text-decoration:%s;--1-text-decoration:%s"
            d_weight l_weight d_style l_style d_decoration l_decoration
      in
      Printf.sprintf "<span%s style=\"--0:%s;--1:%s%s\">%s</span>"
        (if styled then " class=\"ochre-font\"" else "")
        (String.uppercase_ascii (Ochre.Color.to_hex dark_style.foreground))
        (String.uppercase_ascii (Ochre.Color.to_hex light_style.foreground))
        font_vars (escape text)
  in
  let segments dark_line light_line =
    List.map2
      (fun (dark : Ochre.Token.t) (light : Ochre.Token.t) ->
        if dark.text <> light.text then failwith "Ochre theme token mismatch";
        (dark.text, Ochre.Token.style dark, Ochre.Token.style light))
      dark_line light_line
    |> List.fold_left
         (fun segments (text, dark, light) ->
           match segments with
           | (previous, previous_dark, previous_light) :: rest
             when dark = previous_dark && light = previous_light ->
               (previous ^ text, dark, light) :: rest
           | _ -> (text, dark, light) :: segments)
         []
    |> List.rev
  in
  let lines =
    List.map2
      (fun dark_line light_line ->
        "<div class=\"ec-line\"><div class=\"code\">"
        ^ String.concat "" (List.map span (segments dark_line light_line))
        ^ "</div></div>")
      dark.Ochre.Themed.lines light.Ochre.Themed.lines
  in
  let empty_line = "<div class=\"ec-line\"><div class=\"code\"></div></div>" in
  let lines =
    if String.ends_with ~suffix:"\n" source then
      match List.rev lines with
      | line :: rest when line = empty_line -> List.rev rest
      | _ -> lines
    else lines
  in
  let lines =
    List.map
      (fun line ->
        if line = empty_line then
          "<div class=\"ec-line\"><div class=\"code\">\n</div></div>"
        else line)
      lines
  in
  let text = String.concat "\n" (code_lines source) in
  let terminal = lang = "sh" || lang = "shell" || lang = "bash" in
  let header =
    if terminal then
      "<figcaption class=\"header\"><span class=\"title\"></span><span \
       class=\"sr-only\">Terminal window</span></figcaption>"
    else
      match title with
      | Some title ->
          "<figcaption class=\"header\"><span class=\"title\">" ^ escape title
          ^ "</span></figcaption>"
      | None -> ""
  in
  let frame =
    if terminal then "is-terminal"
    else if Option.is_some title then "has-title"
    else ""
  in
  let font_css =
    if !has_font then
      {|<style>.expressive-code .ochre-font{font-weight:var(--0-font-weight);font-style:var(--0-font-style);text-decoration:var(--0-text-decoration)}:root[data-theme="light"] .expressive-code .ochre-font{font-weight:var(--1-font-weight);font-style:var(--1-font-style);text-decoration:var(--1-text-decoration)}</style>|}
    else ""
  in
  "<div class=\"expressive-code\">" ^ font_css ^ "<figure class=\"frame "
  ^ frame ^ " not-content\">" ^ header ^ "<pre data-language=\"" ^ escape lang
  ^ "\"><code>" ^ String.concat "" lines
  ^ "</code></pre><div class=\"copy\"><div aria-live=\"polite\"></div><button \
     title=\"Copy to clipboard\" data-copied=\"Copied!\" data-code=\""
  ^ copy_text text ^ "\"><div></div></button></div></figure></div>"
