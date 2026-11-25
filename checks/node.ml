type buffer
type hash
type stats
type dirent
type server
type request
type response
type address
type process
type child_result
type sharp
type raw_image
type image_info
type fetch_response
type headers

external argv : string array = "argv" [@@mel.scope "process"]
external cwd : unit -> string = "cwd" [@@mel.scope "process"]
external process : process = "process"
external set_exit_code : process -> int -> unit = "exitCode" [@@mel.set]
external env : 'a = "env" [@@mel.scope "process"]
external env_get : 'a -> string -> string Js.Nullable.t = "" [@@mel.get_index]
external log : string -> unit = "log" [@@mel.scope "console"]
external error : 'a -> unit = "error" [@@mel.scope "console"]
external message : 'a -> string = "message" [@@mel.get]

external read_file : string -> buffer Js.Promise.t = "readFile"
[@@mel.module "node:fs/promises"]

external read_text : string -> string -> string Js.Promise.t = "readFile"
[@@mel.module "node:fs/promises"]

external write_file : string -> 'a -> unit Js.Promise.t = "writeFile"
[@@mel.module "node:fs/promises"]

external readdir : string -> 'a -> dirent array Js.Promise.t = "readdir"
[@@mel.module "node:fs/promises"]

external mkdir : string -> 'a -> unit Js.Promise.t = "mkdir"
[@@mel.module "node:fs/promises"]

external mkdtemp : string -> string Js.Promise.t = "mkdtemp"
[@@mel.module "node:fs/promises"]

external access : string -> unit Js.Promise.t = "access"
[@@mel.module "node:fs/promises"]

external rename : string -> string -> unit Js.Promise.t = "rename"
[@@mel.module "node:fs/promises"]

external rm : string -> 'a -> unit Js.Promise.t = "rm"
[@@mel.module "node:fs/promises"]

external cp : string -> string -> 'a -> unit Js.Promise.t = "cp"
[@@mel.module "node:fs/promises"]

external stat : string -> stats Js.Promise.t = "stat"
[@@mel.module "node:fs/promises"]

external symlink : string -> string -> string -> unit Js.Promise.t = "symlink"
[@@mel.module "node:fs/promises"]

external is_dir : dirent -> bool = "isDirectory" [@@mel.send]
external is_file : dirent -> bool = "isFile" [@@mel.send]
external name : dirent -> string = "name" [@@mel.get]
external resolve : string -> string = "resolve" [@@mel.module "node:path"]
external join : string -> string -> string = "join" [@@mel.module "node:path"]

external relative : string -> string -> string = "relative"
[@@mel.module "node:path"]

external extname : string -> string = "extname" [@@mel.module "node:path"]
external separator : string = "sep" [@@mel.module "node:path"]
external tmpdir : unit -> string = "tmpdir" [@@mel.module "node:os"]

external hash_create : string -> hash = "createHash"
[@@mel.module "node:crypto"]

external hash_update : hash -> buffer -> hash = "update" [@@mel.send]
external hash_digest : hash -> string -> string = "digest" [@@mel.send]
external buffer_equals : buffer -> buffer -> bool = "equals" [@@mel.send]
external buffer_length : buffer -> int = "length" [@@mel.get]
external buffer_byte : buffer -> int -> int = "" [@@mel.get_index]

external exec_file : string -> string array -> 'a -> child_result = "spawnSync"
[@@mel.module "node:child_process"]

external child_status : child_result -> int Js.Nullable.t = "status" [@@mel.get]
external child_stdout : child_result -> string = "stdout" [@@mel.get]
external child_stderr : child_result -> string = "stderr" [@@mel.get]

external create_server : (request -> response -> unit) -> server
  = "createServer"
[@@mel.module "node:http"]

external listen : server -> int -> string -> (unit -> unit) -> unit = "listen"
[@@mel.send]

external close_server : server -> (unit -> unit) -> unit = "close" [@@mel.send]
external address : server -> address = "address" [@@mel.send]
external port : address -> int = "port" [@@mel.get]
external request_url : request -> string Js.Nullable.t = "url" [@@mel.get]

external set_header : response -> string -> string -> unit = "setHeader"
[@@mel.send]

external write_head : response -> int -> unit = "writeHead" [@@mel.send]
external end_response : response -> 'a -> unit = "end" [@@mel.send]
external sharp : buffer -> sharp = "default" [@@mel.module "sharp"]
external ensure_alpha : sharp -> sharp = "ensureAlpha" [@@mel.send]
external raw : sharp -> sharp = "raw" [@@mel.send]

external to_buffer : sharp -> 'a -> raw_image Js.Promise.t = "toBuffer"
[@@mel.send]

external image_data : raw_image -> buffer = "data" [@@mel.get]
external image_info : raw_image -> image_info = "info" [@@mel.get]
external image_width : image_info -> int = "width" [@@mel.get]
external image_height : image_info -> int = "height" [@@mel.get]
external fetch : string -> 'a -> fetch_response Js.Promise.t = "fetch"
external fetch_default : string -> fetch_response Js.Promise.t = "fetch"
external fetch_status : fetch_response -> int = "status" [@@mel.get]

external fetch_text : fetch_response -> string Js.Promise.t = "text"
[@@mel.send]

external fetch_headers : fetch_response -> headers = "headers" [@@mel.get]

external header_get : headers -> string -> string Js.Nullable.t = "get"
[@@mel.send]

external json_stringify : 'a -> string = "stringify" [@@mel.scope "JSON"]

external json_pretty : 'a -> 'b -> int -> string = "stringify"
[@@mel.scope "JSON"]

external new_url : string -> string -> 'a = "URL" [@@mel.new]
external pathname : 'a -> string = "pathname" [@@mel.get]
external decode_uri : string -> string = "decodeURIComponent"
external timer : (unit -> unit) -> int -> unit = "setTimeout"

external promise : ((unit -> unit) -> unit) -> unit Js.Promise.t = "Promise"
[@@mel.new]

external reject_error : 'a -> 'b Js.Promise.t = "reject" [@@mel.scope "Promise"]

let ( let* ) p f = Js.Promise.then_ f p
let return = Js.Promise.resolve
let assert_ condition message = if not condition then failwith message
let recursive = [%mel.obj { recursive = true }]
let recursive_force = [%mel.obj { recursive = true; force = true }]
let with_file_types = [%mel.obj { withFileTypes = true }]
let raw_object = [%mel.obj { resolveWithObject = true }]
let copy_options = [%mel.obj { recursive = true }]
let resolve2 a b = resolve (join a b)

let sha256 contents =
  hash_digest (hash_update (hash_create "sha256") contents) "hex"

let option value = Js.Nullable.toOption value
let exit_code value = set_exit_code process value

let rec files root directory =
  let* entries = readdir directory with_file_types in
  let* nested =
    Js.Promise.all
      (Array.map
         (fun entry ->
           let path = join directory (name entry) in
           if is_dir entry then files root path
           else if is_file entry then return [ relative root path ]
           else return [])
         entries)
  in
  return (List.sort String.compare (List.concat (Array.to_list nested)))

let create_static_server root =
  let root = resolve root in
  let server =
    create_server (fun request response ->
        let path =
          decode_uri
            (pathname
               (new_url
                  (Option.value ~default:"/" (option (request_url request)))
                  "http://localhost"))
        in
        let file =
          resolve2 root
            ("." ^ path
            ^ if String.ends_with ~suffix:"/" path then "index.html" else "")
        in
        let send =
          if not (String.starts_with ~prefix:(root ^ separator) file) then
            Js.Promise.reject (Failure "Outside output directory")
          else read_file file
        in
        ignore
          (Js.Promise.catch
             (fun _ ->
               write_head response 404;
               end_response response "Not found";
               return ())
             (let* content = send in
              let type_ =
                match extname file with
                | ".html" -> "text/html; charset=utf-8"
                | ".js" | ".mjs" -> "text/javascript; charset=utf-8"
                | ".css" -> "text/css; charset=utf-8"
                | ".json" -> "application/json"
                | ".svg" -> "image/svg+xml"
                | ".xml" -> "application/xml"
                | ".wasm" -> "application/wasm"
                | ".md" -> "text/markdown"
                | ".woff" -> "font/woff"
                | ".woff2" -> "font/woff2"
                | _ -> "application/octet-stream"
              in
              set_header response "Content-Type" type_;
              end_response response content;
              return ())))
  in
  let* () =
    promise (fun resolve -> listen server 0 "127.0.0.1" (fun () -> resolve ()))
  in
  return (server, "http://127.0.0.1:" ^ string_of_int (port (address server)))

let close_static_server server =
  promise (fun resolve -> close_server server (fun () -> resolve ()))
