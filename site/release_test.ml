let () =
  if Array.length Sys.argv > 1 && Sys.argv.(1) = "--load" then
    print_endline (Yojson.Basic.to_string (Releases.load ()))
  else if Array.length Sys.argv > 1 then
    let raw = Yojson.Basic.from_string (Content.read Sys.argv.(1)) in
    print_endline (Yojson.Basic.to_string (Releases.render raw))
  else
    let item =
      `Assoc
        [
          ("draft", `Bool false);
          ("prerelease", `Bool false);
          ("tag_name", `String "v0.12");
          ("name", `Null);
          ("published_at", `Null);
          ( "html_url",
            `String "https://github.com/ocaml-mlx/mlx/releases/tag/v0.12" );
          ("body", `String "**New** syntax");
        ]
    in
    let result = Releases.render (`List [ item ]) in
    let field name =
      match result with
      | `List [ `Assoc fields ] -> List.assoc name fields
      | _ -> failwith "Expected one release"
    in
    assert (field "name" = `String "0.12");
    assert (field "slug" = `String "0-12");
    assert (field "bodyHtml" = `String "<p><strong>New</strong> syntax</p>\n");
    assert (field "date" = `String "");
    let rejected value =
      match Releases.render value with
      | _ -> failwith "Malformed release was accepted"
      | exception Failure _ -> ()
    in
    rejected (`Assoc [ ("message", `String "API failure") ]);
    rejected (`List [ `Assoc [ ("draft", `Bool false) ] ])
