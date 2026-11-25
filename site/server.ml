let mime file =
  match Filename.extension file with
  | ".html" -> "text/html; charset=utf-8"
  | ".css" -> "text/css; charset=utf-8"
  | ".js" -> "text/javascript; charset=utf-8"
  | ".json" -> "application/json"
  | ".svg" -> "image/svg+xml"
  | ".xml" -> "application/xml"
  | ".md" -> "text/markdown; charset=utf-8"
  | ".woff" -> "font/woff"
  | ".woff2" -> "font/woff2"
  | ".wasm" -> "application/wasm"
  | _ -> "application/octet-stream"

let decode path =
  let buffer = Buffer.create (String.length path) in
  let rec loop index =
    if index < String.length path then
      if path.[index] = '%' && index + 2 < String.length path then
        let code = String.sub path (index + 1) 2 in
        match int_of_string_opt ("0x" ^ code) with
        | Some n ->
            Buffer.add_char buffer (Char.chr n);
            loop (index + 3)
        | None -> failwith "Invalid URL encoding"
      else (
        Buffer.add_char buffer path.[index];
        loop (index + 1))
  in
  loop 0;
  Buffer.contents buffer

let response channel ~head status headers body =
  Printf.fprintf channel "HTTP/1.1 %s\r\n" status;
  List.iter
    (fun (key, value) -> Printf.fprintf channel "%s: %s\r\n" key value)
    headers;
  Printf.fprintf channel "Content-Length: %d\r\nConnection: close\r\n\r\n"
    (String.length body);
  if not head then output_string channel body;
  flush channel

let serve_file channel ~head path =
  let body = Content.read path in
  response channel ~head "200 OK" [ ("Content-Type", mime path) ] body

let request_line socket =
  let buffer = Buffer.create 1024 in
  let chunk = Bytes.create 4096 in
  let deadline = Unix.gettimeofday () +. 5. in
  let rec read () =
    let current = Buffer.contents buffer in
    if String.length current > 16384 then failwith "Request headers too large";
    let complete =
      String.contains current '\n'
      && ((String.contains current '\r'
          &&
            try
              ignore
                (Str.search_forward (Str.regexp_string "\r\n\r\n") current 0);
              true
            with Not_found -> false)
         ||
           try
             ignore (Str.search_forward (Str.regexp_string "\n\n") current 0);
             true
           with Not_found -> false)
    in
    if complete then
      match String.split_on_char '\n' current with
      | first :: _ -> String.trim first
      | _ -> failwith "Invalid request"
    else
      let remaining = deadline -. Unix.gettimeofday () in
      if remaining <= 0. then failwith "Request timed out";
      let ready, _, _ = Unix.select [ socket ] [] [] remaining in
      if ready = [] then failwith "Request timed out";
      let count = Unix.read socket chunk 0 (Bytes.length chunk) in
      if count = 0 then failwith "Incomplete request";
      Buffer.add_subbytes buffer chunk 0 count;
      read ()
  in
  read ()

let handle root socket =
  let channel = Unix.in_channel_of_descr socket in
  let output = Unix.out_channel_of_descr (Unix.dup ~cloexec:true socket) in
  Fun.protect
    ~finally:(fun () ->
      close_in_noerr channel;
      close_out_noerr output)
    (fun () ->
      let head = ref false in
      try
        let request = request_line socket in
        let method_, url =
          match String.split_on_char ' ' request with
          | method_ :: url :: _ -> (method_, url)
          | _ -> failwith "Invalid request"
        in
        head := method_ = "HEAD";
        if method_ <> "GET" && not !head then
          response output ~head:!head "405 Method Not Allowed" [] ""
        else
          let pathname =
            match String.index_opt url '?' with
            | None -> url
            | Some index -> String.sub url 0 index
          in
          let path = decode pathname in
          if
            (not (String.starts_with ~prefix:"/" path))
            || String.contains path '\000'
            || List.mem ".." (String.split_on_char '/' path)
          then response output ~head:!head "400 Bad Request" [] ""
          else
            let relative = String.sub path 1 (String.length path - 1) in
            let candidate = Filename.concat root relative in
            let resolved = Unix.realpath candidate in
            if
              resolved <> root
              && not (String.starts_with ~prefix:(root ^ "/") resolved)
            then response output ~head:!head "400 Bad Request" [] ""
            else
              let file =
                if Sys.is_directory resolved then
                  if not (String.ends_with ~suffix:"/" pathname) then (
                    let query =
                      String.sub url (String.length pathname)
                        (String.length url - String.length pathname)
                    in
                    response output ~head:!head "301 Moved Permanently"
                      [ ("Location", pathname ^ "/" ^ query) ]
                      "";
                    "")
                  else Filename.concat resolved "index.html"
                else resolved
              in
              if file <> "" then serve_file output ~head:!head file
      with
      | Failure _ -> response output ~head:!head "400 Bad Request" [] ""
      | _ ->
          let not_found = Filename.concat root "404.html" in
          let body = try Content.read not_found with _ -> "Not found" in
          response output ~head:!head "404 Not Found"
            [ ("Content-Type", "text/html; charset=utf-8") ]
            body)

let run ?(tick = fun () -> ()) ~port () =
  let root = Unix.realpath "dist" in
  ignore (Unix.stat (Filename.concat root "index.html"));
  let socket = Unix.socket ~cloexec:true Unix.PF_INET Unix.SOCK_STREAM 0 in
  Fun.protect
    ~finally:(fun () -> Unix.close socket)
    (fun () ->
      Unix.setsockopt socket Unix.SO_REUSEADDR true;
      Unix.bind socket (Unix.ADDR_INET (Unix.inet_addr_loopback, port));
      Unix.listen socket 64;
      let children = ref 0 in
      let rec reap () =
        match Unix.waitpid [ Unix.WNOHANG ] (-1) with
        | 0, _ -> ()
        | _, _ ->
            decr children;
            reap ()
        | exception Unix.Unix_error (Unix.ECHILD, _, _) -> children := 0
      in
      while true do
        reap ();
        tick ();
        let ready, _, _ = Unix.select [ socket ] [] [] 0.4 in
        if ready <> [] then
          let client, _ = Unix.accept ~cloexec:true socket in
          if !children >= 64 then Unix.close client
          else
            match Unix.fork () with
            | 0 ->
                Unix.close socket;
                handle root client;
                Unix._exit 0
            | _ ->
                incr children;
                Unix.close client
      done)
