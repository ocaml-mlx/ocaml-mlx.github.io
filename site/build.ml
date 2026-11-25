let valid_output name =
  name = "dist"
  || String.starts_with ~prefix:"dist-" name
     && String.length name > 5
     && String.for_all
          (function 'a' .. 'z' | '0' .. '9' | '-' -> true | _ -> false)
          name

let output args =
  let name =
    match args with
    | [] -> "dist"
    | [ "--output"; name ] -> name
    | _ -> failwith "Usage: site/build.exe [--output dist-name]"
  in
  if not (valid_output name) then
    failwith
      "Output must be dist or a dist- prefixed directory in the repository root";
  name

let with_lock action =
  Support.mkdir ".build";
  let fd =
    Unix.openfile ".build/build.lock"
      [ Unix.O_RDWR; Unix.O_CREAT; Unix.O_CLOEXEC ]
      0o600
  in
  Fun.protect
    ~finally:(fun () -> Unix.close fd)
    (fun () ->
      try
        Unix.lockf fd Unix.F_TLOCK 0;
        action ()
      with Unix.Unix_error ((Unix.EACCES | Unix.EAGAIN), _, _) ->
        failwith "A site build is already running")

let stage () =
  let rec create attempts =
    if attempts = 0 then failwith "Unable to create build staging directory";
    let suffix =
      Printf.sprintf "site-%d-%06x" (Unix.getpid ()) (Random.bits ())
    in
    let dir = Filename.concat ".build" suffix in
    try
      Unix.mkdir dir 0o700;
      dir
    with Unix.Unix_error (Unix.EEXIST, _, _) -> create (attempts - 1)
  in
  create 10

let build output =
  with_lock (fun () ->
      let previous = Filename.concat ".build" (output ^ ".previous") in
      if Support.exists previous then
        if Support.exists output then Support.remove previous
        else Unix.rename previous output;
      let scratch = stage () in
      Fun.protect
        ~finally:(fun () -> Support.remove scratch)
        (fun () ->
          let site = Filename.concat scratch "public" in
          let releases = Filename.concat scratch "releases.json" in
          let theme = Filename.concat scratch "theme.js" in
          Support.command "dune"
            [ "build"; "--root"; "."; "site/main.exe"; "@browser" ];
          let esbuild =
            Support.binary ~variable:"ESBUILD_BINARY" ~package:"esbuild"
              ~name:"esbuild"
          in
          let frontend file =
            "_build/default/frontend/output/frontend/" ^ file ^ ".js"
          in
          let standard =
            [
              "--bundle";
              "--platform=browser";
              "--target=es2022";
              "--minify";
              "--legal-comments=eof";
              "--log-level=warning";
            ]
          in
          Support.command esbuild
            ((frontend "theme" :: standard)
            @ [ "--format=iife"; "--outfile=" ^ theme ]);
          Support.write releases (Yojson.Basic.to_string (Releases.load ()));
          Support.command "_build/default/site/main.exe"
            [ "--output"; site; "--releases"; releases; "--theme"; theme ];
          Support.copy "public" site;
          Support.copy "assets/public" site;
          Support.command esbuild
            ([ frontend "site"; frontend "prefetch" ]
            @ standard
            @ [ "--format=esm"; "--outdir=" ^ Filename.concat site "assets" ]);
          Support.command esbuild
            ([ "src/styles/starlight.css"; "src/styles/marketing.css" ]
            @ [
                "--bundle";
                "--minify";
                "--loader:.woff=file";
                "--loader:.woff2=file";
                "--asset-names=fonts/[name]-[hash]";
                "--legal-comments=eof";
                "--log-level=warning";
                "--outdir=" ^ Filename.concat site "css";
                "--outbase=src/styles";
              ]);
          let css = Filename.concat site "css" in
          Unix.rename
            (Filename.concat css "starlight.css")
            (Filename.concat css "authored-docs.css");
          Unix.rename
            (Filename.concat css "marketing.css")
            (Filename.concat css "authored-landing.css");
          let pagefind =
            Support.binary ~variable:"PAGEFIND_BINARY" ~package:"pagefind"
              ~name:"pagefind_extended"
          in
          Support.command pagefind [ "--site"; site ];
          if not (Support.exists (Filename.concat site "index.html")) then
            failwith "Site build produced no index.html";
          if Support.exists output then Unix.rename output previous;
          (try Unix.rename site output
           with error ->
             if Support.exists previous && not (Support.exists output) then
               Unix.rename previous output;
             raise error);
          Support.remove previous;
          Printf.printf "Built %s with YOCaml and Ochre\n%!" output))

let () = build (output (List.tl (Array.to_list Sys.argv)))
