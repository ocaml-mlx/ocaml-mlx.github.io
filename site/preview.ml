let () =
  let port = Support.port (List.tl (Array.to_list Sys.argv)) "preview" in
  Printf.printf "Preview: http://127.0.0.1:%d\n%!" port;
  Server.run ~port ()
