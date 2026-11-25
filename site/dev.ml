let directories =
  [
    "src/content";
    "src/styles";
    "public";
    "templates";
    "assets";
    "site";
    "frontend";
  ]

let rec collect path =
  if not (Support.exists path) then []
  else
    let stat = Unix.lstat path in
    match stat.Unix.st_kind with
    | Unix.S_DIR ->
        Sys.readdir path |> Array.to_list |> List.sort String.compare
        |> List.concat_map (fun name -> collect (Filename.concat path name))
    | Unix.S_REG -> [ (path, stat.Unix.st_mtime, stat.Unix.st_size) ]
    | _ -> []

let snapshot () =
  List.concat_map collect (directories @ [ "dune-project"; "package.json" ])

let () =
  let port = Support.port (List.tl (Array.to_list Sys.argv)) "dev" in
  Support.command "dune" [ "exec"; "--root"; "."; "site/build.exe" ];
  let previous = ref (snapshot ()) in
  let last = ref 0. in
  let tick () =
    if Unix.gettimeofday () -. !last >= 0.4 then (
      last := Unix.gettimeofday ();
      let current = snapshot () in
      if current <> !previous then (
        previous := current;
        try Support.command "dune" [ "exec"; "--root"; "."; "site/build.exe" ]
        with error -> prerr_endline (Printexc.to_string error)))
  in
  Printf.printf
    "Development: http://127.0.0.1:%d (rebuilds on source changes)\n%!" port;
  Server.run ~tick ~port ()
