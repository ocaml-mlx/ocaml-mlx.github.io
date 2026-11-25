open Node

let baseline_path () =
  let archive = resolve "tests/fixtures/site-baseline.tar.gz" in
  let* bytes = read_file archive in
  let root = resolve ".build/parity-baselines" in
  let output = join root (sha256 bytes) in
  let* existing =
    Js.Promise.catch
      (fun _ -> return false)
      (let* () = access (join output "index.html") in
       return true)
  in
  if existing then return output
  else
    let* () = mkdir root recursive in
    let* stage = mkdtemp (join root "extract-") in
    let run () =
      let result =
        exec_file "tar"
          [| "-xzf"; archive; "-C"; stage |]
          [%mel.obj { encoding = "utf8" }]
      in
      assert_
        (option (child_status result) = Some 0)
        ("Failed to extract baseline: " ^ child_stderr result);
      let* () = access (join stage "index.html") in
      Js.Promise.catch
        (fun _ -> access (join output "index.html"))
        (rename stage output)
    in
    let* () =
      Js.Promise.catch
        (fun error ->
          let* () = rm stage recursive_force in
          reject_error error)
        (let* () = run () in
         rm stage recursive_force)
    in
    return output
