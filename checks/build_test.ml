open Node

external includes : string -> string -> bool = "includes" [@@mel.send]

external replace_once : string -> string -> string -> string = "replace"
[@@mel.send]

external set_env : 'a -> string -> string -> unit = "" [@@mel.set_index]

let run_builder scratch =
  let result =
    exec_file
      (resolve "_build/default/site/build.exe")
      [| "--output"; "dist-test" |]
      [%mel.obj { cwd = scratch; encoding = "utf8"; timeout = 90000 }]
  in
  (option (child_status result), child_stdout result ^ child_stderr result)

let success scratch =
  let status, output = run_builder scratch in
  assert_ (status = Some 0) ("Build failed: " ^ output)

let manifest root =
  let* paths = files root root in
  let* entries =
    Js.Promise.all
      (Array.of_list
         (List.map
            (fun path ->
              let* contents = read_file (join root path) in
              return (path, sha256 contents))
            paths))
  in
  return (Array.to_list entries)

let run () =
  let* () = mkdir ".build" recursive in
  let* scratch = mkdtemp (resolve ".build/build-test-") in
  let output = join scratch "dist-test" in
  let source = join scratch "src/content/docs/docs/temporary.md" in
  let installation = join scratch "src/content/docs/docs/installation.mdx" in
  let test () =
    let* _ =
      Js.Promise.all
        (Array.of_list
           (List.map
              (fun path -> cp path (join scratch path) copy_options)
              [
                "site";
                "assets";
                "templates";
                "src/content";
                "src/styles";
                "public";
                "frontend";
                "dune-project";
                "ocaml_mlx_website.opam";
                "package.json";
              ]))
    in
    let* () =
      symlink (resolve "node_modules") (join scratch "node_modules") "dir"
    in
    set_env env "RELEASES_FILE" (resolve "tests/fixtures/releases.json");
    success scratch;
    let* first = manifest output in
    assert_
      (List.length
         (List.filter
            (fun (path, _) -> String.ends_with ~suffix:".html" path)
            first)
      = 12)
      "Build produced other than twelve HTML pages";
    assert_
      (not (List.exists (fun (path, _) -> includes path "yocaml-cache") first))
      "Build cache was published";
    success scratch;
    let* repeated = manifest output in
    assert_ (repeated = first) "Repeated build changed output";
    let* () =
      write_file source
        "---\n\
         title: Temporary guide\n\
         description: A generated page.\n\
         slug: docs/temporary\n\
         ---\n\n\
         ## New heading\n\n\
         Distinct searchable content.\n"
    in
    success scratch;
    let* generated =
      read_text (join output "docs/temporary/index.html") "utf8"
    in
    assert_
      (includes generated "Distinct searchable content")
      "New page did not appear";
    let* sitemap = read_text (join output "sitemap-0.xml") "utf8" in
    assert_ (includes sitemap "docs/temporary/") "New page missing in sitemap";
    let* () = rm source recursive_force in
    success scratch;
    let* missing =
      Js.Promise.catch
        (fun _ -> return true)
        (let* _ = stat (join output "docs/temporary/index.html") in
         return false)
    in
    assert_ missing "Deleted source page still exists";
    let* missing =
      Js.Promise.catch
        (fun _ -> return true)
        (let* _ = stat (join output "docs/temporary.md") in
         return false)
    in
    assert_ missing "Deleted Markdown export still exists";
    let* restored = manifest output in
    assert_ (restored = first) "Deleted source left stale output";
    let* original = read_text installation "utf8" in
    let* () =
      write_file installation
        (replace_once original "slug: docs/installation" "slug: docs/../escape")
    in
    let status, failure = run_builder scratch in
    assert_
      (status <> Some 0 && includes failure "unsafe route")
      ("Unsafe route was accepted: " ^ failure);
    let* after_failure = manifest output in
    assert_ (after_failure = first) "Failed build replaced successful output";
    let* () = rename output (join scratch ".build/dist-test.previous") in
    let status, _ = run_builder scratch in
    assert_ (status <> Some 0)
      "Invalid source built after interrupted publication";
    let* recovered = manifest output in
    assert_ (recovered = first) "Interrupted publication was not recovered";
    let* () = write_file installation original in
    let* () = write_file (join scratch ".build/build.lock") "1073741824" in
    success scratch;
    let* final = manifest output in
    assert_ (final = first) "Recovery changed output";
    return ()
  in
  let* () =
    Js.Promise.catch
      (fun error ->
        let* () = rm scratch recursive_force in
        reject_error error)
      (let* () = test () in
       rm scratch recursive_force)
  in
  log
    "PASS build lifecycle: deterministic, additions, deletions, failure, \
     recovery";
  return ()

let () =
  ignore
    (Js.Promise.catch
       (fun failure ->
         error failure;
         exit_code 1;
         return ())
       (run ()))
