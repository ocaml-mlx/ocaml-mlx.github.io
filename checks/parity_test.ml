open Node

external regexp : string -> string -> 'a = "RegExp" [@@mel.new]
external replace : string -> 'a -> string -> string = "replace" [@@mel.send]

external replace_once : string -> string -> string -> string = "replace"
[@@mel.send]

external includes : string -> string -> bool = "includes" [@@mel.send]

let runner = resolve "_build/default/checks/output/checks/parity.js"

let parity baseline candidate output view =
  let result =
    exec_file "node"
      [|
        runner;
        "--baseline";
        baseline;
        "--candidate";
        candidate;
        "--output";
        output;
        "--route";
        "/docs/installation/";
        "--view";
        view;
      |]
      [%mel.obj { encoding = "utf8"; timeout = 120000 }]
  in
  (option (child_status result), child_stdout result ^ child_stderr result)

let verify expected label (code, output) =
  assert_ (code = expected) (label ^ ": " ^ output)

let run () =
  let* baseline = Baseline.baseline_path () in
  let* () = mkdir (resolve ".build") recursive in
  let* scratch = mkdtemp (resolve ".build/mlx-parity-") in
  let candidate = join scratch "candidate" in
  let test () =
    verify (Some 0) "baseline self-comparison"
      (parity baseline baseline (join scratch "control") "desktop-dark");
    let* () = cp baseline candidate copy_options in
    let html_file = join candidate "docs/installation/index.html" in
    let* original = read_text html_file "utf8" in
    assert_
      (includes original "</body>")
      "Installation page has no closing body";
    let generator =
      replace original
        (regexp "(<meta name=\"generator\" content=\")[^\"]+" "g")
        "$1YOCaml"
    in
    assert_ (generator <> original) "Baseline has no generator metadata";
    let* () = write_file html_file generator in
    verify (Some 0) "permitted generator metadata"
      (parity baseline candidate (join scratch "generator") "desktop-dark");
    let description =
      replace original
        (regexp "(<meta name=\"description\" content=\")[^\"]+" "")
        "$1Changed description"
    in
    assert_ (description <> original) "Baseline has no SEO description";
    let* () = write_file html_file description in
    let code, output =
      parity baseline candidate (join scratch "seo") "desktop-dark"
    in
    assert_
      (code <> Some 0 && includes output "document structure differs")
      ("SEO description mutation passed: " ^ output);
    let* () =
      write_file html_file
        (replace_once original "</body>"
           "<style>body{opacity:.5!important}</style></body>")
    in
    let code, output =
      parity baseline candidate (join scratch "visual") "desktop-dark"
    in
    assert_
      (code <> Some 0 && includes output "screenshot pixels differ")
      ("Visual mutation passed: " ^ output);
    let* () =
      write_file html_file
        (replace_once original "</body>"
           "<style>body::after{content:\"\";position:fixed;top:20px;left:20px;width:1px;height:1px;background:red;z-index:99999}</style></body>")
    in
    let code, output =
      parity baseline candidate (join scratch "pixel") "mobile-light"
    in
    assert_
      (code <> Some 0 && includes output "screenshot pixels differ")
      ("One-pixel regression outside the mobile TOC passed: " ^ output);
    let copy_script =
      replace original
        (regexp "(<script type=\"module\" src=\"/)[^\"]*ec\\.[^\"]+" "")
        "$1missing-copy.js"
    in
    assert_ (copy_script <> original) "Baseline has no copy script";
    let* () = write_file html_file copy_script in
    let code, output =
      parity baseline candidate (join scratch "interaction") "desktop-dark"
    in
    assert_
      (code <> Some 0 && includes output "Code clipboard differs")
      ("Copy-button mutation passed: " ^ output);
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
    "PASS parity regression tests: control, generator, SEO, visual, one pixel, \
     copy";
  return ()

let () =
  ignore
    (Js.Promise.catch
       (fun failure ->
         error failure;
         exit_code 1;
         return ())
       (run ()))
