let exists path = Sys.file_exists path

let rec mkdir path =
  if path <> "" && path <> "." && not (exists path) then (
    mkdir (Filename.dirname path);
    Unix.mkdir path 0o755)

let rec remove path =
  if exists path then
    match (Unix.lstat path).Unix.st_kind with
    | Unix.S_DIR ->
        Sys.readdir path
        |> Array.iter (fun name -> remove (Filename.concat path name));
        Unix.rmdir path
    | _ -> Unix.unlink path

let rec copy source destination =
  match (Unix.lstat source).Unix.st_kind with
  | Unix.S_DIR ->
      mkdir destination;
      Sys.readdir source
      |> Array.iter (fun name ->
          copy (Filename.concat source name) (Filename.concat destination name))
  | Unix.S_REG ->
      mkdir (Filename.dirname destination);
      let source_channel = open_in_bin source in
      Fun.protect
        ~finally:(fun () -> close_in source_channel)
        (fun () ->
          let destination_channel = open_out_bin destination in
          Fun.protect
            ~finally:(fun () -> close_out destination_channel)
            (fun () ->
              let buffer = Bytes.create 65536 in
              let rec loop () =
                let count =
                  input source_channel buffer 0 (Bytes.length buffer)
                in
                if count > 0 then (
                  output destination_channel buffer 0 count;
                  loop ())
              in
              loop ()))
  | _ -> failwith ("unsupported asset: " ^ source)

let write path contents =
  mkdir (Filename.dirname path);
  let channel = open_out_bin path in
  Fun.protect
    ~finally:(fun () -> close_out channel)
    (fun () -> output_string channel contents)

let command binary args =
  let arguments = Array.of_list (binary :: args) in
  let pid =
    Unix.create_process binary arguments Unix.stdin Unix.stdout Unix.stderr
  in
  match snd (Unix.waitpid [] pid) with
  | Unix.WEXITED 0 -> ()
  | Unix.WEXITED code ->
      failwith (Printf.sprintf "%s failed (exit %d)" binary code)
  | Unix.WSIGNALED signal | Unix.WSTOPPED signal ->
      failwith (Printf.sprintf "%s failed (signal %d)" binary signal)

let port args command =
  match args with
  | [] -> 4321
  | [ "--port"; value ] -> (
      match int_of_string_opt value with
      | Some port when port >= 1 && port <= 65535 -> port
      | _ -> failwith "Invalid port")
  | _ -> failwith ("Usage: site/" ^ command ^ ".exe [--port N]")

let binary ~variable ~package ~name =
  match Sys.getenv_opt variable with
  | Some binary when binary <> "" -> binary
  | _ ->
      let uname option =
        let channel = Unix.open_process_in ("uname " ^ option) in
        let value = input_line channel in
        match Unix.close_process_in channel with
        | Unix.WEXITED 0 -> value
        | _ -> failwith "uname failed"
      in
      let platform =
        match Sys.os_type with
        | "Unix" -> (
            match (uname "-s", uname "-m") with
            | "Darwin", machine ->
                "darwin-" ^ if machine = "arm64" then "arm64" else "x64"
            | "Linux", machine ->
                "linux-" ^ if machine = "aarch64" then "arm64" else "x64"
            | _ -> failwith ("unsupported platform for " ^ name))
        | _ -> failwith ("unsupported platform for " ^ name)
      in
      let local =
        Filename.concat "node_modules"
          (Filename.concat ("@" ^ package)
             (Filename.concat platform (Filename.concat "bin" name)))
      in
      if exists local then local else name
