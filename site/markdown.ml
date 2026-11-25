type heading = { id : string; text : string; depth : int }
type rendered = { html : string; headings : heading list }

let smart_text text =
  let buffer = Buffer.create (String.length text) in
  let len = String.length text in
  let is_word = function
    | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' -> true
    | _ -> false
  in
  let is_opening = function
    | ' ' | '\t' | '\n' | '(' | '[' | '{' -> true
    | _ -> false
  in
  let rec scan index =
    if index < len then
      let current = text.[index] in
      let previous = if index = 0 then ' ' else text.[index - 1] in
      let next = if index + 1 = len then ' ' else text.[index + 1] in
      if index + 2 < len && String.sub text index 3 = "..." then (
        Buffer.add_string buffer "…";
        scan (index + 3))
      else if index + 1 < len && String.sub text index 2 = "--" then (
        Buffer.add_string buffer "—";
        scan (index + 2))
      else (
        (match current with
        | '\'' ->
            Buffer.add_string buffer
              (if is_word previous then "’"
               else if is_word next then "‘"
               else "’")
        | '"' ->
            Buffer.add_string buffer
              (if is_opening previous && is_word next then "“" else "”")
        | _ -> Buffer.add_char buffer current);
        scan (index + 1))
  in
  scan 0;
  Buffer.contents buffer

let smart_inline context = function
  | Cmarkit.Inline.Text (text, _) ->
      Cmarkit_html.html_escaped_string context (smart_text text);
      true
  | _ -> false

let plain inline =
  Cmarkit.Inline.to_plain_text ~break_on_soft:false inline
  |> List.map (String.concat "")
  |> String.concat "\n"

let fenced_sources body =
  let rec collect current codes = function
    | [] -> List.rev codes
    | line :: rest when String.starts_with ~prefix:"```" (String.trim line) -> (
        match current with
        | None -> collect (Some []) codes rest
        | Some content ->
            collect None (String.concat "\n" (List.rev content) :: codes) rest)
    | line :: rest -> (
        match current with
        | None -> collect None codes rest
        | Some content -> collect (Some (line :: content)) codes rest)
  in
  collect None [] (String.split_on_char '\n' body)

let render highlighter ~heading_template body =
  let headings = ref [] in
  let ids = Hashtbl.create 32 in
  let source_codes = ref (fenced_sources body) in
  let custom = function
    | Cmarkit.Block.Code_block (block, _) ->
        let lang, title =
          match Cmarkit.Block.Code_block.info_string block with
          | None -> ("text", None)
          | Some (info, _) ->
              let lang, rest =
                match Cmarkit.Block.Code_block.language_of_info_string info with
                | Some pair -> pair
                | None -> ("text", "")
              in
              let title_pattern = Str.regexp {|title="\([^"]+\)"|} in
              let title =
                try
                  ignore (Str.search_forward title_pattern rest 0);
                  Some (Str.matched_group 1 rest)
                with Not_found -> None
              in
              (lang, title)
        in
        let code =
          match !source_codes with
          | code :: rest ->
              source_codes := rest;
              code
          | [] ->
              Cmarkit.Block.Code_block.code block
              |> List.map Cmarkit.Block_line.to_string
              |> String.concat "\n"
        in
        let html = Highlight.render highlighter ~lang ~title code ^ "\n" in
        Some html
    | Cmarkit.Block.Heading (heading, _) ->
        let text = plain (Cmarkit.Block.Heading.inline heading) in
        let base = Cmarkit.Inline.id (Cmarkit.Block.Heading.inline heading) in
        let count = Option.value ~default:0 (Hashtbl.find_opt ids base) in
        Hashtbl.replace ids base (count + 1);
        let id = if count = 0 then base else base ^ "-" ^ string_of_int count in
        let depth = Cmarkit.Block.Heading.level heading in
        headings := { id; text; depth } :: !headings;
        let buffer = Buffer.create 128 in
        let inline_renderer =
          Cmarkit_renderer.make ~inline:smart_inline ()
          |> Cmarkit_renderer.compose (Cmarkit_html.renderer ~safe:false ())
        in
        let context = Cmarkit_renderer.Context.make inline_renderer buffer in
        Cmarkit_renderer.Context.inline context
          (Cmarkit.Block.Heading.inline heading);
        let env =
          Jingoo.Jg_types.{ std_env with template_dirs = [ "templates" ] }
        in
        Some
          (Jingoo.Jg_template.from_string ~env
             ~models:
               [
                 ("depth", Jingoo.Jg_types.Tint depth);
                 ("id", Jingoo.Jg_types.Tstr id);
                 ("plain_text", Jingoo.Jg_types.Tstr (smart_text text));
                 ("text", Jingoo.Jg_types.Tstr (Buffer.contents buffer));
               ]
             heading_template)
    | _ -> None
  in
  let renderer =
    Cmarkit_renderer.make ~inline:smart_inline
      ~block:(fun context block ->
        match custom block with
        | None -> false
        | Some html ->
            Cmarkit_renderer.Context.string context html;
            true)
      ()
    |> Cmarkit_renderer.compose (Cmarkit_html.renderer ~safe:false ())
  in
  let doc = Cmarkit.Doc.of_string ~strict:false body in
  let html = Cmarkit_renderer.doc_to_string renderer doc in
  { html; headings = List.rev !headings }

let render_cards highlighter ~card_template ~heading_template body =
  let body =
    String.concat "\n"
      (List.filter
         (fun line ->
           String.trim line
           <> "import { Card, CardGrid } from '@astrojs/starlight/components';")
         (String.split_on_char '\n' body))
  in
  let card_pattern = Str.regexp {|<Card title="\([^"]+\)" icon="\([^"]+\)">|} in
  let rec replace_cards start body =
    try
      let begin_ = Str.search_forward card_pattern body start in
      let content_start = Str.match_end () in
      let title = Str.matched_group 1 body in
      let icon = Str.matched_group 2 body in
      let line_start =
        try String.rindex_from body (begin_ - 1) '\n' + 1 with Not_found -> 0
      in
      let indent = String.sub body line_start (begin_ - line_start) in
      let begin_ =
        if String.for_all (function ' ' | '\t' -> true | _ -> false) indent
        then line_start
        else begin_
      in
      let end_ =
        Str.search_forward (Str.regexp_string "</Card>") body content_start
      in
      let content = String.sub body content_start (end_ - content_start) in
      let end_ = end_ + String.length "</Card>" in
      let html =
        (render highlighter ~heading_template (String.trim content)).html
      in
      let replacement =
        let env =
          Jingoo.Jg_types.{ std_env with template_dirs = [ "templates" ] }
        in
        Jingoo.Jg_template.from_string ~env
          ~models:
            [
              ("title", Jingoo.Jg_types.Tstr title);
              ("icon", Jingoo.Jg_types.Tstr icon);
              ("body", Jingoo.Jg_types.Tstr html);
            ]
          card_template
      in
      let body =
        String.sub body 0 begin_ ^ replacement
        ^ String.sub body end_ (String.length body - end_)
      in
      replace_cards (begin_ + String.length replacement) body
    with Not_found -> body
  in
  let body = replace_cards 0 body in
  body
  |> Str.global_replace
       (Str.regexp_string "<CardGrid stagger>")
       "<div class=\"card-grid stagger astro-vgpqfw56\">"
  |> Str.global_replace (Str.regexp_string "</CardGrid>") "</div>"
