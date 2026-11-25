let member key = function
  | `Assoc fields -> List.assoc_opt key fields
  | _ -> None

let string field value =
  match value with
  | Some (`String value) -> value
  | _ -> failwith ("GitHub release " ^ field ^ " must be a string")

let nullable field value =
  match value with Some `Null -> "" | value -> string field value

let slug name =
  let buffer = Buffer.create (String.length name) in
  let separator = ref false in
  String.iter
    (fun c ->
      match Char.lowercase_ascii c with
      | ('a' .. 'z' | '0' .. '9') as c ->
          if !separator && Buffer.length buffer > 0 then
            Buffer.add_char buffer '-';
          separator := false;
          Buffer.add_char buffer c
      | _ -> separator := true)
    name;
  Buffer.contents buffer

let date value =
  if value = "" then ""
  else
    match Ptime.of_rfc3339 value with
    | Error _ -> failwith ("Invalid release published_at: " ^ value)
    | Ok (time, _, _) ->
        let local = Unix.localtime (Ptime.to_float_s time) in
        let months =
          [|
            "Jan";
            "Feb";
            "Mar";
            "Apr";
            "May";
            "Jun";
            "Jul";
            "Aug";
            "Sep";
            "Oct";
            "Nov";
            "Dec";
          |]
        in
        Printf.sprintf "%s %d, %d" months.(local.Unix.tm_mon) local.Unix.tm_mday
          (local.Unix.tm_year + 1900)

let markdown body =
  if body = "" then ""
  else
    let html =
      Cmarkit.Doc.of_string ~strict:false body
      |> Cmarkit_renderer.doc_to_string (Cmarkit_html.renderer ~safe:false ())
    in
    if String.ends_with ~suffix:"\n" html then html else html ^ "\n"

let render data =
  let items =
    match data with
    | `List items -> items
    | _ -> failwith "GitHub releases must be an array"
  in
  let release item =
    let flags =
      match (member "draft" item, member "prerelease" item) with
      | Some (`Bool draft), Some (`Bool prerelease) -> (draft, prerelease)
      | _ -> failwith "GitHub release must contain draft and prerelease flags"
    in
    let draft, prerelease = flags in
    if draft then None
    else
      let tag = string "tag_name" (member "tag_name" item) in
      let name = nullable "name" (member "name" item) in
      let name = if name = "" then tag else name in
      let name =
        if String.starts_with ~prefix:"v" name then
          String.sub name 1 (String.length name - 1)
        else name
      in
      let published_at = nullable "published_at" (member "published_at" item) in
      let html_url = string "html_url" (member "html_url" item) in
      let prefix =
        if String.starts_with ~prefix:"https://" html_url then 8
        else if String.starts_with ~prefix:"http://" html_url then 7
        else failwith "GitHub release html_url must be an HTTP URL"
      in
      let tail = String.sub html_url prefix (String.length html_url - prefix) in
      let authority = List.hd (String.split_on_char '/' tail) in
      if
        authority = ""
        || String.exists
             (function
               | ' ' | '\t' | '\n' | '\r' | '?' | '#' -> true | _ -> false)
             authority
      then failwith "GitHub release html_url must be an HTTP URL";
      Some
        (`Assoc
           [
             ("name", `String name);
             ("tagName", `String tag);
             ("slug", `String (slug name));
             ("publishedAt", `String published_at);
             ("date", `String (date published_at));
             ("htmlUrl", `String html_url);
             ( "bodyHtml",
               `String (markdown (nullable "body" (member "body" item))) );
             ("prerelease", `Bool prerelease);
           ])
  in
  `List (List.filter_map release items)

let fetch () =
  match Sys.getenv_opt "RELEASES_FILE" with
  | Some file -> Yojson.Basic.from_string (Content.read file)
  | None ->
      let status_file = Filename.temp_file "mlx-release-status-" ".txt" in
      let body_file = Filename.temp_file "mlx-releases-" ".json" in
      Fun.protect
        ~finally:(fun () ->
          Sys.remove status_file;
          Sys.remove body_file)
        (fun () ->
          let config =
            "header = \"Accept: application/vnd.github+json\"\n"
            ^ "header = \"User-Agent: ocaml-mlx-website\"\n"
            ^
            match Sys.getenv_opt "GH_API_TOKEN" with
            | None -> ""
            | Some token ->
                if
                  String.exists
                    (function '\n' | '\r' | '"' | '\\' -> true | _ -> false)
                    token
                then failwith "Invalid GH_API_TOKEN";
                "header = \"Authorization: Bearer " ^ token ^ "\"\n"
          in
          let input_read, input_write = Unix.pipe ~cloexec:true () in
          let output_fd =
            Unix.openfile status_file
              [ Unix.O_WRONLY; Unix.O_TRUNC; Unix.O_CLOEXEC ]
              0o600
          in
          let pid =
            try
              Unix.create_process "curl"
                [|
                  "curl";
                  "--fail";
                  "--silent";
                  "--show-error";
                  "--max-time";
                  "30";
                  "--output";
                  body_file;
                  "--write-out";
                  "%{http_code}";
                  "--config";
                  "-";
                  "https://api.github.com/repos/ocaml-mlx/mlx/releases?per_page=20";
                |]
                input_read output_fd Unix.stderr
            with error ->
              Unix.close input_read;
              Unix.close input_write;
              Unix.close output_fd;
              raise error
          in
          Unix.close input_read;
          Unix.close output_fd;
          let channel = Unix.out_channel_of_descr input_write in
          output_string channel config;
          close_out channel;
          let result = snd (Unix.waitpid [] pid) in
          let status = String.trim (Content.read status_file) in
          let reason =
            match status with
            | "301" -> "Moved Permanently"
            | "302" -> "Found"
            | "403" -> "Forbidden"
            | "404" -> "Not Found"
            | "429" -> "Too Many Requests"
            | "500" -> "Internal Server Error"
            | "502" -> "Bad Gateway"
            | "503" -> "Service Unavailable"
            | _ -> ""
          in
          match result with
          | Unix.WEXITED 0 -> Yojson.Basic.from_string (Content.read body_file)
          | _ ->
              let detail =
                if status <> "" && status <> "000" then
                  status ^ if reason = "" then "" else " " ^ reason
                else
                  match result with
                  | Unix.WEXITED code -> "curl exit " ^ string_of_int code
                  | Unix.WSIGNALED signal | Unix.WSTOPPED signal ->
                      "curl signal " ^ string_of_int signal
              in
              failwith ("GitHub releases request failed: " ^ detail))

let load () =
  try
    let releases = render (fetch ()) in
    `Assoc [ ("releases", releases); ("error", `Null) ]
  with error ->
    let message =
      match error with
      | Failure message | Yojson.Json_error message -> message
      | _ -> Printexc.to_string error
    in
    `Assoc [ ("releases", `List []); ("error", `String message) ]
