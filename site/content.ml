type t = {
  source : string;
  slug : string;
  title : string;
  description : string;
  body : string;
  hero : Yaml.value;
  splash : bool;
}

let read path =
  let channel = open_in_bin path in
  Fun.protect
    ~finally:(fun () -> close_in channel)
    (fun () -> really_input_string channel (in_channel_length channel))

let field key = function
  | `O fields -> Option.value ~default:`Null (List.assoc_opt key fields)
  | _ -> `Null

let required key data =
  match field key data with
  | `String s when s <> "" -> s
  | _ -> failwith ("missing or invalid frontmatter " ^ key)

let valid_slug slug =
  let parts = String.split_on_char '/' slug in
  List.length parts >= 1
  && List.hd parts = "docs"
  && List.for_all
       (fun part ->
         part <> "" && part <> "." && part <> ".."
         && String.for_all
              (function 'a' .. 'z' | '0' .. '9' | '-' -> true | _ -> false)
              part)
       parts

let split_frontmatter source raw =
  let lines = String.split_on_char '\n' raw in
  match lines with
  | "---" :: rest ->
      let rec take acc = function
        | [] -> failwith (source ^ ": unterminated frontmatter")
        | "---" :: body ->
            (String.concat "\n" (List.rev acc), String.concat "\n" body)
        | line :: tail -> take (line :: acc) tail
      in
      take [] rest
  | _ -> failwith (source ^ ": missing frontmatter")

let validate_mdx source ~splash body =
  let lines = String.split_on_char '\n' body in
  let card = Str.regexp {|^<Card title="[^"]+" icon="[^"]+">$|} in
  let allowed trimmed =
    splash
    && (trimmed
        = "import { Card, CardGrid } from '@astrojs/starlight/components';"
       || List.mem trimmed [ "<CardGrid stagger>"; "</CardGrid>"; "</Card>" ]
       || Str.string_match card trimmed 0)
  in
  let rec check fenced = function
    | [] -> ()
    | line :: rest ->
        let trimmed = String.trim line in
        if String.length trimmed >= 3 && String.sub trimmed 0 3 = "```" then
          check (not fenced) rest
        else if
          (not fenced)
          && (String.starts_with ~prefix:"import " trimmed
              && not (allowed trimmed)
             || String.starts_with ~prefix:"export " trimmed
             || (String.starts_with ~prefix:"<" trimmed && not (allowed trimmed))
             )
        then failwith (source ^ ": unsupported MDX: " ^ trimmed)
        else check fenced rest
  in
  check false lines

let parse source raw =
  let yaml, body = split_frontmatter source raw in
  let data = Yaml.of_string_exn yaml in
  let slug = required "slug" data in
  if not (valid_slug slug) then failwith (source ^ ": unsafe route " ^ slug);
  let splash = field "template" data = `String "splash" in
  if Filename.check_suffix source ".mdx" then validate_mdx source ~splash body;
  {
    source;
    slug;
    title = required "title" data;
    description = required "description" data;
    body;
    hero = field "hero" data;
    splash;
  }

let mirror doc =
  let hero =
    if doc.splash then
      match doc.hero with
      | `O fields ->
          let actions =
            match List.assoc_opt "actions" fields with
            | Some (`A xs) ->
                `A
                  (List.map
                     (function
                       | `O action ->
                           let icon =
                             match List.assoc_opt "icon" action with
                             | Some (`String name) ->
                                 `O
                                   [
                                     ("type", `String "icon");
                                     ("name", `String name);
                                   ]
                             | _ -> `Null
                           in
                           let variant =
                             Option.value ~default:(`String "primary")
                               (List.assoc_opt "variant" action)
                           in
                           `O
                             (List.filter
                                (fun (_, v) -> v <> `Null)
                                (("text", field "text" (`O action))
                                :: ("link", field "link" (`O action))
                                :: ("variant", variant)
                                :: [ ("icon", icon) ]))
                       | _ -> failwith "invalid hero action")
                     xs)
            | _ -> `A []
          in
          [
            ( "hero",
              `O
                (List.map
                   (fun (k, v) ->
                     if k = "actions" then (k, actions) else (k, v))
                   fields) );
          ]
      | _ -> []
    else []
  in
  let scalar value =
    let plain =
      try
        Yaml.of_string_exn ("value: " ^ value ^ "\n")
        = `O [ ("value", `String value) ]
      with Invalid_argument _ -> false
    in
    if plain then value else Yojson.Basic.to_string (`String value)
  in
  let wrap prefix text =
    if scalar text <> text then prefix ^ scalar text
    else
      let words = String.split_on_char ' ' text in
      let rec loop line acc = function
        | [] -> String.concat "\n" (List.rev (line :: acc))
        | word :: rest ->
            if
              String.length line + 1 + String.length word > 80
              && String.length (String.concat " " (word :: rest)) >= 15
            then loop ("  " ^ word) (line :: acc) rest
            else loop (line ^ " " ^ word) acc rest
      in
      match words with
      | [] -> prefix
      | word :: rest -> loop (prefix ^ word) [] rest
  in
  let hero_text =
    match hero with
    | [ ("hero", `O fields) ] ->
        let title = required "title" (`O fields) in
        let tagline = required "tagline" (`O fields) in
        let actions =
          match field "actions" (`O fields) with
          | `A xs ->
              xs
              |> List.map (fun action ->
                  let name = required "name" (field "icon" action) in
                  "    - text: "
                  ^ scalar (required "text" action)
                  ^ "\n" ^ "      link: "
                  ^ scalar (required "link" action)
                  ^ "\n" ^ "      variant: "
                  ^ scalar (required "variant" action)
                  ^ "\n" ^ "      icon:\n" ^ "        type: icon\n"
                  ^ "        name: " ^ scalar name ^ "\n")
              |> String.concat ""
          | _ -> ""
        in
        "hero:\n  title: " ^ scalar title ^ "\n  tagline: " ^ scalar tagline
        ^ "\n  actions:\n" ^ actions
    | _ -> ""
  in
  let body =
    if String.ends_with ~suffix:"\n" doc.body then
      String.sub doc.body 0 (String.length doc.body - 1)
    else doc.body
  in
  "---\ntitle: " ^ scalar doc.title ^ "\n"
  ^ wrap "description: " doc.description
  ^ "\n" ^ "editUrl: true\nhead: []\ntemplate: "
  ^ (if doc.splash then "splash" else "doc")
  ^ "\n" ^ hero_text
  ^ "sidebar:\n\
    \  hidden: false\n\
    \  attrs: {}\n\
     pagefind: true\n\
     draft: false\n\
     ---\n" ^ body
