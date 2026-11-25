open Node

type child
type socket
type signal

external socket : unit -> socket = "Socket"
[@@mel.module "node:net"] [@@mel.new]

external connect : socket -> int -> string -> (unit -> unit) -> socket
  = "connect"
[@@mel.send]

external destroy : socket -> socket = "destroy" [@@mel.send]
external timeout_signal : int -> signal = "timeout" [@@mel.scope "AbortSignal"]

external spawn : string -> string array -> 'a -> child = "spawn"
[@@mel.module "node:child_process"]

external kill : child -> bool = "kill" [@@mel.send]
external includes : string -> string -> bool = "includes" [@@mel.send]

let check condition message = assert_ condition message
let wait ms = promise (fun resolve -> timer (fun () -> resolve ()) ms)

let rec wait_for_ready origin remaining =
  if remaining = 0 then failwith "Preview did not start"
  else
    Js.Promise.catch
      (fun _ ->
        let* () = wait 100 in
        wait_for_ready origin (remaining - 1))
      (let* response = fetch_default origin in
       if fetch_status response = 200 then return ()
       else
         let* () = wait 100 in
         wait_for_ready origin (remaining - 1))

let run () =
  let* baseline = Baseline.baseline_path () in
  let* scratch = mkdtemp (resolve ".build/preview-test-") in
  let* () = symlink baseline (join scratch "dist") "dir" in
  let* temporary, origin = create_static_server baseline in
  let* () = close_static_server temporary in
  let port =
    String.sub origin
      (String.rindex origin ':' + 1)
      (String.length origin - String.rindex origin ':' - 1)
  in
  let child =
    spawn
      (resolve "_build/default/site/preview.exe")
      [| "--port"; port |]
      [%mel.obj { cwd = scratch; stdio = "ignore" }]
  in
  let test () =
    let* () = wait_for_ready origin 50 in
    let idle = socket () in
    let* () =
      promise (fun resolve ->
          ignore (connect idle (int_of_string port) "127.0.0.1" resolve))
    in
    let* () =
      Js.Promise.catch
        (fun error ->
          ignore (destroy idle);
          reject_error error)
        (let* responses =
           Js.Promise.all
             (Array.map
                (fun path ->
                  let* response =
                    fetch (origin ^ path)
                      [%mel.obj { signal = timeout_signal 2000 }]
                  in
                  check
                    (fetch_status response = 200)
                    ("Concurrent preview request failed: " ^ path);
                  fetch_text response)
                [| "/"; "/docs/installation/"; "/favicon.svg" |])
         in
         check
           (includes responses.(0) "JSX in OCaml")
           "Idle connection blocked or truncated preview response";
         ignore (destroy idle);
         return ())
    in
    let* home = fetch_default origin in
    check (fetch_status home = 200) "Preview home returned non-200";
    let* body = fetch_text home in
    check (includes body "JSX in OCaml") "Preview home content differs";
    let* redirect =
      fetch (origin ^ "/docs") [%mel.obj { redirect = "manual" }]
    in
    check (fetch_status redirect = 301) "Preview docs redirect differs";
    check
      (option (header_get (fetch_headers redirect) "location") = Some "/docs/")
      "Preview redirect location differs";
    let* markdown = fetch_default (origin ^ "/docs/installation.md") in
    check (fetch_status markdown = 200) "Preview Markdown response differs";
    check
      (Option.fold ~none:false
         ~some:(fun type_ -> includes type_ "text/markdown")
         (option (header_get (fetch_headers markdown) "content-type")))
      "Preview Markdown content type differs";
    let* favicon = fetch_default (origin ^ "/favicon.svg") in
    check
      (option (header_get (fetch_headers favicon) "content-type")
      = Some "image/svg+xml")
      "Preview favicon content type differs";
    let* missing = fetch_default (origin ^ "/missing") in
    check (fetch_status missing = 404) "Preview missing page status differs";
    let* body = fetch_text missing in
    check (includes body "Page not found") "Preview 404 content differs";
    return ()
  in
  let* () =
    Js.Promise.catch
      (fun error ->
        ignore (kill child);
        let* () = rm scratch recursive_force in
        reject_error error)
      (let* () = test () in
       ignore (kill child);
       rm scratch recursive_force)
  in
  log
    "PASS preview: idle and concurrent connections, pages, assets, redirects, \
     Markdown, 404";
  return ()

let () =
  ignore
    (Js.Promise.catch
       (fun failure ->
         error failure;
         exit_code 1;
         return ())
       (run ()))
