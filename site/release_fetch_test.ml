let child status =
  ignore (Unix.setsid ());
  let result = Releases.load () in
  let expected =
    if status = "200" then `Null
    else `String "GitHub releases request failed: 403 Forbidden"
  in
  match result with
  | `Assoc fields when List.assoc "error" fields = expected -> ()
  | _ -> failwith "Unexpected release fetch result"

let check directory status =
  let completed, output = Unix.pipe ~cloexec:true () in
  let environment =
    Unix.environment () |> Array.to_list
    |> List.filter (fun entry ->
        not
          (List.exists
             (fun name -> String.starts_with ~prefix:(name ^ "=") entry)
             [ "RELEASES_FILE"; "GH_API_TOKEN"; "PATH"; "MOCK_HTTP_STATUS" ]))
    |> fun entries ->
    Array.of_list
      (("PATH=" ^ directory ^ ":" ^ Sys.getenv "PATH")
      :: "GH_API_TOKEN=test-token"
      :: ("MOCK_HTTP_STATUS=" ^ status)
      :: entries)
  in
  let executable = Unix.realpath Sys.executable_name in
  let pid =
    Unix.create_process_env executable
      [| executable; "--child"; status |]
      environment Unix.stdin output Unix.stderr
  in
  Unix.close output;
  Fun.protect
    ~finally:(fun () -> Unix.close completed)
    (fun () ->
      let ready, _, _ = Unix.select [ completed ] [] [] 2. in
      if ready = [] then (
        (try Unix.kill (-pid) Sys.sigkill
         with Unix.Unix_error (Unix.ESRCH, _, _) -> Unix.kill pid Sys.sigkill);
        ignore (Unix.waitpid [] pid);
        failwith "Release fetch did not finish after config stdin was closed");
      match snd (Unix.waitpid [] pid) with
      | Unix.WEXITED 0 -> ()
      | _ -> failwith "Release fetch subprocess failed")

let () =
  match Array.to_list Sys.argv with
  | [ _; "--child"; status ] -> child status
  | [ _; stub ] ->
      let directory = Filename.temp_file "mlx-fetch-test-" "" in
      Sys.remove directory;
      Unix.mkdir directory 0o700;
      Fun.protect
        ~finally:(fun () ->
          Unix.unlink (Filename.concat directory "curl");
          Unix.rmdir directory)
        (fun () ->
          Unix.symlink (Unix.realpath stub) (Filename.concat directory "curl");
          check directory "200";
          check directory "403");
      print_endline "PASS release fetch: config EOF and HTTP diagnostics"
  | _ -> failwith "Usage: release_fetch_test.exe CURL_STUB"
