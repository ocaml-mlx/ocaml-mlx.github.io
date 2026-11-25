let () =
  (try
     while true do
       ignore (input_line stdin)
     done
   with End_of_file -> ());
  let rec output_file = function
    | "--output" :: path :: _ -> path
    | _ :: rest -> output_file rest
    | [] -> failwith "Missing curl output file"
  in
  let file = output_file (Array.to_list Sys.argv) in
  let channel = open_out_bin file in
  output_string channel "[]";
  close_out channel;
  let status = Sys.getenv "MOCK_HTTP_STATUS" in
  print_string status;
  flush stdout;
  if status <> "200" then exit 22
