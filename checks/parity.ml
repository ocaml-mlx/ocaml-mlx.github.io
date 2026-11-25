open Node

type browser
type context
type page
type locator
type playwright_response
type request_context
type keyboard
type chromium
type view = { name : string; width : int; height : int; theme : string }

type config = {
  baseline : string;
  candidate : string;
  output : string;
  routes : string list;
  views : view list;
}

external chromium : chromium = "chromium" [@@mel.module "playwright"]
external launch : chromium -> 'a -> browser Js.Promise.t = "launch" [@@mel.send]
external version : browser -> string = "version" [@@mel.send]

external new_context : browser -> 'a -> context Js.Promise.t = "newContext"
[@@mel.send]

external new_page : context -> page Js.Promise.t = "newPage" [@@mel.send]

external init_script : context -> 'a -> unit Js.Promise.t = "addInitScript"
[@@mel.send]

external goto :
  page -> string -> 'a -> playwright_response Js.Nullable.t Js.Promise.t
  = "goto"
[@@mel.send]

external reload : page -> unit Js.Promise.t = "reload" [@@mel.send]
external ok : playwright_response -> bool = "ok" [@@mel.send]
external status : playwright_response -> int = "status" [@@mel.send]
external close_page : page -> unit Js.Promise.t = "close" [@@mel.send]
external close_context : context -> unit Js.Promise.t = "close" [@@mel.send]
external close_browser : browser -> unit Js.Promise.t = "close" [@@mel.send]

external evaluate : page -> (unit -> 'a) -> 'a Js.Promise.t = "evaluate"
[@@mel.send]

external evaluate_promise : page -> (unit -> 'a Js.Promise.t) -> 'a Js.Promise.t
  = "evaluate"
[@@mel.send]

external evaluate_arg : page -> ('a -> 'b) -> 'a -> 'b Js.Promise.t = "evaluate"
[@@mel.send]

external locator : 'a -> string -> locator = "locator" [@@mel.send]
external first : locator -> locator = "first" [@@mel.send]
external locator_count : locator -> int Js.Promise.t = "count" [@@mel.send]
external locator_hover : locator -> unit Js.Promise.t = "hover" [@@mel.send]
external locator_click : locator -> unit Js.Promise.t = "click" [@@mel.send]

external locator_dispatch : locator -> string -> unit Js.Promise.t
  = "dispatchEvent"
[@@mel.send]

external locator_fill : locator -> string -> unit Js.Promise.t = "fill"
[@@mel.send]

external locator_wait : locator -> 'a -> unit Js.Promise.t = "waitFor"
[@@mel.send]

external locator_texts : locator -> string array Js.Promise.t
  = "allTextContents"
[@@mel.send]

external locator_attr : locator -> string -> string Js.Nullable.t Js.Promise.t
  = "getAttribute"
[@@mel.send]

external locator_select : locator -> string -> string array Js.Promise.t
  = "selectOption"
[@@mel.send]

external locator_evaluate : locator -> ('a -> 'b) -> 'b Js.Promise.t
  = "evaluate"
[@@mel.send]

external role : page -> string -> 'a -> locator = "getByRole" [@@mel.send]
external keyboard : page -> keyboard = "keyboard" [@@mel.get]
external press : keyboard -> string -> unit Js.Promise.t = "press" [@@mel.send]
external page_url : page -> string = "url" [@@mel.send]
external request : page -> request_context = "request" [@@mel.get]

external get : request_context -> string -> playwright_response Js.Promise.t
  = "get"
[@@mel.send]

external viewport : page -> 'a -> unit Js.Promise.t = "setViewportSize"
[@@mel.send]

external media : page -> 'a -> unit Js.Promise.t = "emulateMedia" [@@mel.send]

external add_style : page -> 'a -> unit Js.Promise.t = "addStyleTag"
[@@mel.send]

external screenshot : page -> 'a -> buffer Js.Promise.t = "screenshot"
[@@mel.send]

external wait_function : page -> ('a -> bool) -> 'a -> unit Js.Promise.t
  = "waitForFunction"
[@@mel.send]

external browser_snapshot : unit -> string = "snapshot"
[@@mel.scope "window.__mlxParity"]

external browser_links : unit -> 'a = "links" [@@mel.scope "window.__mlxParity"]
external browser_anchors : 'a -> string array = "anchors" [@@mel.get]
external browser_internal : 'a -> string array = "internal" [@@mel.get]

external browser_theme : unit -> string = "currentTheme"
[@@mel.scope "window.__mlxParity"]

external browser_theme_state : unit -> 'a = "themeState"
[@@mel.scope "window.__mlxParity"]

external state_theme : 'a -> string = "theme" [@@mel.get]
external state_scheme : 'a -> string = "scheme" [@@mel.get]
external state_meta : 'a -> string = "meta" [@@mel.get]
external state_selected : 'a -> string array = "selected" [@@mel.get]

external browser_store : string -> unit = "storeTheme"
[@@mel.scope "window.__mlxParity"]

external browser_clear : unit -> unit = "clearStorage"
[@@mel.scope "window.__mlxParity"]

external browser_saved : unit -> string Js.Nullable.t = "savedTheme"
[@@mel.scope "window.__mlxParity"]

external browser_dialog : unit -> bool = "openDialog"
[@@mel.scope "window.__mlxParity"]

external browser_clipboard : unit -> string Js.Promise.t = "clipboardValue"
[@@mel.scope "window.__mlxParity"]

external browser_copy_transition : unit -> bool = "copyTransition"
[@@mel.scope "window.__mlxParity"]

external wait_copy_transition :
  page -> (unit -> bool) -> unit -> 'a -> unit Js.Promise.t = "waitForFunction"
[@@mel.send]

external browser_menu : unit -> bool = "expandedMenu"
[@@mel.scope "window.__mlxParity"]

external browser_overflow : unit -> bool = "overflow"
[@@mel.scope "window.__mlxParity"]

external browser_first_paint : unit -> string Js.Nullable.t = "firstPaintTheme"
[@@mel.scope "window.__mlxParity"]

external browser_settled : unit -> unit Js.Promise.t = "settled"
[@@mel.scope "window.__mlxParity"]

external node_open : 'a -> bool = "open" [@@mel.get]
external url_hash : 'a -> string = "hash" [@@mel.get]

external page_errors : page -> string -> ('a -> unit) -> unit = "on"
[@@mel.send]

external split : string -> string -> string array = "split" [@@mel.send]
external includes : string -> string -> bool = "includes" [@@mel.send]

external replace_all : string -> string -> string -> string = "replaceAll"
[@@mel.send]

let routes =
  [
    "/";
    "/docs/";
    "/docs/installation/";
    "/docs/editors/";
    "/docs/formal-syntax/";
    "/docs/templates/";
    "/docs/projects-using-mlx/";
    "/docs/guides/melange-reason-react/";
    "/docs/guides/dream-html-of-jsx/";
    "/docs/guides/tyxml/";
    "/changelog/";
    "/404.html";
  ]

let views =
  [
    { name = "desktop-dark"; width = 1440; height = 900; theme = "dark" };
    { name = "desktop-light"; width = 1440; height = 900; theme = "light" };
    { name = "mobile-dark"; width = 390; height = 844; theme = "dark" };
    { name = "mobile-light"; width = 390; height = 844; theme = "light" };
  ]

let breakpoint_views =
  [
    { name = "narrow-799-light"; width = 799; height = 900; theme = "light" };
    { name = "wide-801-light"; width = 801; height = 900; theme = "light" };
    { name = "sidebar-767-dark"; width = 767; height = 900; theme = "dark" };
    { name = "sidebar-769-dark"; width = 769; height = 900; theme = "dark" };
    { name = "marketing-1135-dark"; width = 1135; height = 900; theme = "dark" };
    { name = "marketing-1137-dark"; width = 1137; height = 900; theme = "dark" };
  ]

let rec each f = function
  | [] -> return ()
  | head :: tail ->
      let* () = f head in
      each f tail

let options argv =
  let rec parse values = function
    | [] -> values
    | key :: value :: rest
      when String.starts_with ~prefix:"--" key
           && not (String.starts_with ~prefix:"--" value) ->
        if
          not
            (List.mem key
               [ "--baseline"; "--candidate"; "--output"; "--route"; "--view" ])
        then failwith ("Unknown option: " ^ key);
        parse ((key, value) :: values) rest
    | key :: _ -> failwith ("Expected --name value, got " ^ key)
  in
  let values = parse [] argv in
  let values_for key =
    List.filter_map
      (fun (option, value) -> if key = option then Some value else None)
      (List.rev values)
  in
  let last_or key default =
    match List.rev (values_for key) with value :: _ -> value | [] -> default
  in
  let chosen_routes =
    match values_for "--route" with [] -> routes | selected -> selected
  in
  let chosen_views =
    match values_for "--view" with
    | [] -> views
    | selected ->
        List.map
          (fun name ->
            match List.find_opt (fun view -> view.name = name) views with
            | Some view -> view
            | None -> failwith ("Unknown view: " ^ name))
          selected
  in
  List.iter
    (fun route -> assert_ (List.mem route routes) ("Unknown route: " ^ route))
    chosen_routes;
  let* baseline = Baseline.baseline_path () in
  return
    {
      baseline = resolve (last_or "--baseline" baseline);
      candidate = resolve (last_or "--candidate" "dist");
      output = resolve (last_or "--output" ".workplace/parity/latest");
      routes = chosen_routes;
      views = chosen_views;
    }

let export name =
  String.ends_with ~suffix:".md" name
  || String.starts_with ~prefix:"sitemap-" name
     && String.ends_with ~suffix:".xml" name
  || name = "favicon.svg"

let compare_exports baseline candidate =
  let* expected = files baseline baseline in
  let expected = List.filter export expected in
  assert_
    (List.length (List.filter (String.ends_with ~suffix:".md") expected) = 9)
    "Baseline must contain nine Markdown exports";
  assert_
    (List.length (List.filter (String.starts_with ~prefix:"sitemap-") expected)
    = 2)
    "Baseline must contain two sitemaps";
  let* actual = files candidate candidate in
  assert_ (List.filter export actual = expected) "Export paths differ";
  each
    (fun name ->
      let* left = read_file (join baseline name) in
      let* right = read_file (join candidate name) in
      assert_ (buffer_equals left right) (name ^ ": exported bytes differ");
      return ())
    expected

let open_page context origin route =
  let* page = new_page context in
  let* response =
    goto page (origin ^ route) [%mel.obj { waitUntil = "load" }]
  in
  let response = option response in
  assert_
    (Option.fold ~none:false ~some:ok response)
    (route ^ ": HTTP "
    ^ Option.fold ~none:"no response"
        ~some:(fun response -> string_of_int (status response))
        response);
  return page

let close_pages pages = each close_page pages

let compare_pages contexts origins route =
  let* left = open_page (fst contexts) (fst origins) route in
  let* right = open_page (snd contexts) (snd origins) route in
  let check () =
    let* before = evaluate left (fun () -> browser_snapshot ()) in
    let* after = evaluate right (fun () -> browser_snapshot ()) in
    assert_ (before = after)
      (route ^ ": document structure differs\nBaseline: " ^ before
     ^ "\nCandidate: " ^ after);
    let* links = evaluate right (fun () -> browser_links ()) in
    assert_
      (Array.length (browser_anchors links) = 0)
      (route ^ ": broken heading anchors: "
      ^ String.concat ", " (Array.to_list (browser_anchors links)));
    each
      (fun path ->
        let* response = get (request right) (snd origins ^ path) in
        assert_ (ok response)
          (route ^ ": internal link " ^ path ^ " returned HTTP "
          ^ string_of_int (status response));
        return ())
      (Array.to_list (browser_internal links))
  in
  let* result =
    Js.Promise.catch
      (fun error ->
        let* () = close_pages [ left; right ] in
        reject_error error)
      (let* () = check () in
       close_pages [ left; right ])
  in
  return result

let image_id route view =
  let route =
    if route = "/" then "landing"
    else
      split route "/" |> Array.to_list
      |> List.filter (( <> ) "")
      |> String.concat "-"
  in
  route ^ "-" ^ view.name

let stabilize page view =
  let* () =
    viewport page [%mel.obj { width = view.width; height = view.height }]
  in
  let* () = evaluate_arg page (fun value -> browser_store value) view.theme in
  let* () = reload page in
  let* () =
    wait_function page (fun value -> browser_theme () = value) view.theme
  in
  let* () =
    add_style page
      [%mel.obj
        {
          content =
            "*, *::before, *::after { animation-duration: 0s !important; \
             transition-duration: 0s !important; caret-color: transparent \
             !important; scroll-behavior: auto !important; }";
        }]
  in
  let* () =
    if String.starts_with ~prefix:"print-" view.name then
      media page [%mel.obj { media = "print" }]
    else return ()
  in
  let* () = evaluate_promise page (fun () -> browser_settled ()) in
  let* overflow = evaluate page (fun () -> browser_overflow ()) in
  assert_ (not overflow) (view.name ^ ": horizontal overflow");
  return ()

let compare_images output id view left right =
  if buffer_equals left right then return None
  else
    let* first = to_buffer (raw (ensure_alpha (sharp left))) raw_object in
    let* second = to_buffer (raw (ensure_alpha (sharp right))) raw_object in
    let first_data = image_data first and second_data = image_data second in
    let width = image_width (image_info first)
    and height = image_height (image_info first) in
    if
      width = image_width (image_info second)
      && height = image_height (image_info second)
      && buffer_equals first_data second_data
    then return None
    else
      let* () = mkdir output recursive in
      let* () = write_file (join output (id ^ "-baseline.png")) left in
      let* () = write_file (join output (id ^ "-candidate.png")) right in
      let pixels = ref 0 and maximum = ref 0 and coordinates = ref [] in
      if
        width = image_width (image_info second)
        && height = image_height (image_info second)
      then
        for index = 0 to (buffer_length first_data / 4) - 1 do
          let changed = ref false in
          for channel = 0 to 3 do
            let offset = (index * 4) + channel in
            let difference =
              abs
                (buffer_byte first_data offset - buffer_byte second_data offset)
            in
            if difference > 0 then changed := true;
            maximum := max !maximum difference
          done;
          if !changed then (
            incr pixels;
            if List.length !coordinates < 3 then
              coordinates := (index mod width, index / width) :: !coordinates)
        done;
      let coordinates = List.rev !coordinates in
      if
        view.width = 390 && view.height = 844 && !pixels <= 2 && !maximum <= 1
        && width = image_width (image_info second)
        && height = image_height (image_info second)
        && List.for_all
             (fun (x, y) -> (x = 141 || x = 142) && y = 78)
             coordinates
      then (
        log ("RASTER " ^ id ^ ": mobile TOC chevron");
        return
          (Some
             [%mel.obj
               {
                 view = id;
                 pixels = !pixels;
                 maximumChannelDifference = !maximum;
                 coordinates =
                   Array.of_list
                     (List.map (fun (x, y) -> [| x; y |]) coordinates);
                 reason =
                   "Chromium mobile TOC chevron raster differs on baseline \
                    self-comparison";
               }]))
      else
        failwith
          (id ^ ": screenshot pixels differ (" ^ string_of_int width ^ "x"
         ^ string_of_int height ^ " vs "
          ^ string_of_int (image_width (image_info second))
          ^ "x"
          ^ string_of_int (image_height (image_info second))
          ^ "); changed pixels " ^ string_of_int !pixels
          ^ ", max channel delta " ^ string_of_int !maximum
          ^ ", first coordinates "
          ^ String.concat ", "
              (List.map
                 (fun (x, y) ->
                   "(" ^ string_of_int x ^ "," ^ string_of_int y ^ ")")
                 coordinates)
          ^ "; " ^ output)

let visual contexts origins route view output =
  let* left = open_page (fst contexts) (fst origins) route in
  let* right = open_page (snd contexts) (snd origins) route in
  let check () =
    let* () = stabilize left view in
    let* () = stabilize right view in
    let* before =
      screenshot left [%mel.obj { fullPage = true; animations = "disabled" }]
    in
    let* after =
      screenshot right [%mel.obj { fullPage = true; animations = "disabled" }]
    in
    compare_images output (image_id route view) view before after
  in
  Js.Promise.catch
    (fun error ->
      let* () = close_pages [ left; right ] in
      reject_error error)
    (let* result = check () in
     let* () = close_pages [ left; right ] in
     return result)

let role_name page kind name = role page kind [%mel.obj { name }]
let check condition message = assert_ condition message

let count locator =
  let* value = locator_count locator in
  return (value > 0)

let hash_of_page page = url_hash (new_url (page_url page) "http://localhost")

let exercise context origin =
  let* page = open_page context origin "/docs/installation/" in
  let perform () =
    let* () =
      locator_hover
        (role page "link" [%mel.obj { name = "Editors"; exact = true }])
    in
    let* () =
      locator_wait
        (locator page
           ("link[rel=\"prefetch\"][href=\"" ^ origin ^ "/docs/editors/\"]"))
        [%mel.obj { state = "attached"; timeout = 5000 }]
    in
    let* () = locator_click (first (role_name page "button" "Search")) in
    let* opened = evaluate page (fun () -> browser_dialog ()) in
    check opened "Search dialog did not open";
    let* () =
      locator_fill (locator page ".pagefind-ui__search-input") "installation"
    in
    let* () =
      locator_wait
        (first (locator page ".pagefind-ui__result-link"))
        [%mel.obj { timeout = 10000 }]
    in
    let* search = locator_texts (locator page ".pagefind-ui__result-link") in
    check
      (Array.exists (fun text -> includes text "Installation") search)
      "Search returned no installation page";
    let* () = press (keyboard page) "Escape" in
    let* opened = evaluate page (fun () -> browser_dialog ()) in
    check (not opened) "Search dialog did not close";
    let* () = press (keyboard page) "ControlOrMeta+k" in
    let* opened = evaluate page (fun () -> browser_dialog ()) in
    check opened "Search keyboard shortcut failed";
    let* () = press (keyboard page) "Escape" in
    let copy = first (locator page ".expressive-code button[data-code]") in
    let* exists = count copy in
    check exists "Missing code copy control";
    let* expected = locator_attr copy "data-code" in
    let expected =
      replace_all (Option.value ~default:"" (option expected)) "\x7f" "\n"
    in
    let* () = media page [%mel.obj { reducedMotion = "no-preference" }] in
    let* () = locator_dispatch copy "click" in
    let* actual = evaluate_promise page (fun () -> browser_clipboard ()) in
    check (actual = expected)
      ("Code clipboard differs: " ^ actual ^ " vs " ^ expected);
    let* () =
      wait_copy_transition page
        (fun () -> browser_copy_transition ())
        () [%mel.obj { timeout = 750 }]
    in
    let* _ =
      locator_select (first (role_name page "combobox" "Color theme")) "light"
    in
    let* theme = evaluate page (fun () -> browser_theme ()) in
    let* saved = evaluate page (fun () -> browser_saved ()) in
    check
      (theme = "light" && option saved = Some "light")
      "Theme selection did not persist";
    let* () = reload page in
    let* theme = evaluate page (fun () -> browser_theme ()) in
    check (theme = "light") "Theme selection did not survive reload";
    let group = first (locator page "nav[aria-label=\"Main\"] details") in
    let* exists = count group in
    check exists "Missing sidebar group";
    let* () = locator_click (locator group "summary") in
    let* opened = locator_evaluate group (fun node -> node_open node) in
    check (not opened) "Sidebar group failed to close";
    let* () = reload page in
    let* opened = locator_evaluate group (fun node -> node_open node) in
    check (not opened) "Sidebar group did not keep its state after reload";
    let* () = locator_click (locator group "summary") in
    let* opened = locator_evaluate group (fun node -> node_open node) in
    check opened "Sidebar group failed to reopen";
    let toc =
      first (locator page "starlight-toc a[href=\"#install-the-packages\"]")
    in
    let* exists = count toc in
    check exists "Missing desktop table of contents";
    let* () = locator_click toc in
    check
      (hash_of_page page = "#install-the-packages")
      "Desktop TOC did not navigate";
    let* () = viewport page [%mel.obj { width = 390; height = 844 }] in
    let* () = locator_click (role_name page "button" "Menu") in
    let* expanded = evaluate page (fun () -> browser_menu ()) in
    check expanded "Mobile menu did not open";
    let* () = press (keyboard page) "Escape" in
    let* expanded = evaluate page (fun () -> browser_menu ()) in
    check (not expanded) "Mobile menu did not close on Escape";
    let mobile_toc = locator page "#starlight__mobile-toc" in
    let* () = locator_click (locator mobile_toc "summary") in
    let* opened = locator_evaluate mobile_toc (fun node -> node_open node) in
    check opened "Mobile TOC did not open";
    let* () = locator_click (locator mobile_toc "a[href=\"#sanity-check\"]") in
    check (hash_of_page page = "#sanity-check") "Mobile TOC did not navigate";
    return
      [%mel.obj
        {
          prefetch = "hover";
          search;
          copy = actual;
          theme = "light";
          sidebar = "toggle";
          toc = "#install-the-packages";
          menu = "open/escape";
          mobileToc = "#sanity-check";
        }]
  in
  Js.Promise.catch
    (fun error ->
      let* () = close_page page in
      reject_error error)
    (let* result = perform () in
     let* () = close_page page in
     return result)

let theme_state page expected preference =
  let* () =
    wait_function page (fun value -> browser_theme () = value) expected
  in
  let* state = evaluate page (fun () -> browser_theme_state ()) in
  check
    (state_theme state = expected
    && state_scheme state = expected
    && (state_meta state = if expected = "dark" then "#07090f" else "#f7f9ff")
    && Array.length (state_selected state) > 0
    && Array.for_all (( = ) preference) (state_selected state))
    ("Theme state differs: " ^ json_stringify state ^ ", expected " ^ expected
   ^ "/" ^ preference);
  return ()

let theme_behavior context origin =
  let* page = open_page context origin "/" in
  let perform () =
    let* () = media page [%mel.obj { colorScheme = "light" }] in
    let* () = evaluate page (fun () -> browser_clear ()) in
    let* () = reload page in
    let* () = theme_state page "light" "auto" in
    let* () = media page [%mel.obj { colorScheme = "dark" }] in
    let* () = theme_state page "dark" "auto" in
    let* _ = locator_select (role_name page "combobox" "Color theme") "light" in
    let* () = theme_state page "light" "light" in
    let* () = reload page in
    let* () = theme_state page "light" "light" in
    let* sibling = open_page context origin "/docs/installation/" in
    let* () =
      Js.Promise.catch
        (fun error ->
          let* () = close_page sibling in
          reject_error error)
        (let* () = theme_state sibling "light" "light" in
         let* _ =
           locator_select
             (first (role_name sibling "combobox" "Color theme"))
             "dark"
         in
         let* () = theme_state page "dark" "dark" in
         let* () = evaluate sibling (fun () -> browser_clear ()) in
         let* () = theme_state page "dark" "auto" in
         close_page sibling)
    in
    let* () = evaluate page (fun () -> browser_store "invalid") in
    let* () = reload page in
    let* () = theme_state page "dark" "auto" in
    let* first_paint = new_page context in
    Js.Promise.catch
      (fun error ->
        let* () = close_page first_paint in
        reject_error error)
      (let* _ =
         locator_select (role_name page "combobox" "Color theme") "light"
       in
       let* () =
         each
           (fun route ->
             let* _ =
               goto first_paint (origin ^ route)
                 [%mel.obj { waitUntil = "load" }]
             in
             let* theme =
               evaluate first_paint (fun () -> browser_first_paint ())
             in
             check
               (option theme = Some "light")
               (route ^ ": saved theme was not applied before body");
             return ())
           [ "/"; "/docs/installation/"; "/changelog/" ]
       in
       close_page first_paint)
  in
  Js.Promise.catch
    (fun error ->
      let* () = close_page page in
      reject_error error)
    (let* () = perform () in
     close_page page)

let helper_path = resolve "_build/default/checks/browser-helper.js"
let blocked_storage_path = resolve "_build/default/checks/blocked-storage.js"

let blocked_storage browser origin =
  let* context =
    new_context browser
      [%mel.obj { reducedMotion = "reduce"; colorScheme = "dark" }]
  in
  let perform () =
    let* () = init_script context [%mel.obj { path = blocked_storage_path }] in
    let* () = init_script context [%mel.obj { path = helper_path }] in
    let* page = open_page context origin "/" in
    let errors = ref [] in
    page_errors page "pageerror" (fun failure ->
        errors := message failure :: !errors);
    let check_page () =
      let* theme = evaluate page (fun () -> browser_theme ()) in
      check (theme = "dark") "Blocked storage prevented system theme";
      let* _ =
        locator_select (role_name page "combobox" "Color theme") "light"
      in
      let* () = media page [%mel.obj { colorScheme = "light" }] in
      let* () = media page [%mel.obj { colorScheme = "dark" }] in
      let* theme = evaluate page (fun () -> browser_theme ()) in
      check (theme = "light") "Blocked storage prevented explicit theme";
      check (!errors = [])
        ("Blocked storage caused page errors: " ^ String.concat "; " !errors);
      return ()
    in
    Js.Promise.catch
      (fun error ->
        let* () = close_page page in
        reject_error error)
      (let* () = check_page () in
       close_page page)
  in
  Js.Promise.catch
    (fun error ->
      let* () = close_context context in
      reject_error error)
    (let* () = perform () in
     close_context context)

let run argv =
  let* config = options argv in
  let* () = compare_exports config.baseline config.candidate in
  let* browser = launch chromium [%mel.obj { headless = true }] in
  let* base_server, base_origin = create_static_server config.baseline in
  let* candidate_server, candidate_origin =
    create_static_server config.candidate
  in
  let contexts () =
    let* baseline =
      new_context browser
        [%mel.obj { reducedMotion = "reduce"; colorScheme = "dark" }]
    in
    let* candidate =
      new_context browser
        [%mel.obj { reducedMotion = "reduce"; colorScheme = "dark" }]
    in
    let* () = init_script baseline [%mel.obj { path = helper_path }] in
    let* () = init_script candidate [%mel.obj { path = helper_path }] in
    let contexts = (baseline, candidate)
    and origins = (base_origin, candidate_origin) in
    let tolerance = ref [] in
    let record difference =
      match difference with
      | Some difference -> tolerance := difference :: !tolerance
      | None -> ()
    in
    let perform () =
      let* () =
        each
          (fun route ->
            let* () = compare_pages contexts origins route in
            let* () =
              each
                (fun view ->
                  let* difference =
                    visual contexts origins route view config.output
                  in
                  record difference;
                  return ())
                config.views
            in
            log
              ("PASS " ^ route ^ ": structure, "
              ^ string_of_int (List.length config.views)
              ^ " visual views");
            return ())
          config.routes
      in
      let* () =
        if List.length config.views <> List.length views then return ()
        else
          let breakpoints route names =
            if not (List.mem route config.routes) then return ()
            else
              let selected =
                List.filter
                  (fun view -> List.mem view.name names)
                  breakpoint_views
              in
              let* () =
                each
                  (fun view ->
                    let* difference =
                      visual contexts origins route view config.output
                    in
                    record difference;
                    return ())
                  selected
              in
              log
                ("PASS " ^ route ^ ": "
                ^ string_of_int (List.length selected)
                ^ " breakpoint views");
              return ()
          in
          let* () =
            breakpoints "/"
              [
                "marketing-1135-dark";
                "marketing-1137-dark";
                "narrow-799-light";
                "wide-801-light";
              ]
          in
          let* () =
            breakpoints "/docs/installation/"
              [ "sidebar-767-dark"; "sidebar-769-dark" ]
          in
          each
            (fun route ->
              if not (List.mem route config.routes) then return ()
              else
                let* difference =
                  visual contexts origins route
                    {
                      name = "print-light";
                      width = 1440;
                      height = 900;
                      theme = "light";
                    }
                    config.output
                in
                record difference;
                log ("PASS " ^ route ^ ": print view");
                return ())
            [ "/"; "/docs/installation/"; "/changelog/" ]
      in
      let* () =
        if not (List.mem "/docs/installation/" config.routes) then return ()
        else
          let* before = exercise baseline base_origin in
          let* after = exercise candidate candidate_origin in
          check
            (json_stringify before = json_stringify after)
            "Search/copy/theme/menu/sidebar/TOC interaction differs";
          log
            "PASS interactions: prefetch, search, shortcut, clipboard, theme, \
             menu, sidebar, TOC";
          return ()
      in
      let* () =
        if not (List.mem "/" config.routes) then return ()
        else
          let* () = theme_behavior baseline base_origin in
          let* () = theme_behavior candidate candidate_origin in
          let* () = blocked_storage browser base_origin in
          let* () = blocked_storage browser candidate_origin in
          log
            "PASS theme: system updates, persistence, cross-tab, invalid \
             preference, first paint, blocked storage";
          return ()
      in
      let* () = mkdir config.output recursive in
      let report =
        [%mel.obj
          {
            baseline = config.baseline;
            candidate = config.candidate;
            browser = version browser;
            routes = Array.of_list config.routes;
            views =
              Array.of_list (List.map (fun view -> view.name) config.views);
            exports = [%mel.obj { markdown = 9; sitemaps = 2 }];
            visualTolerance =
              [%mel.obj
                {
                  scope = "390x844 mobile TOC chevron at x=141..142, y=78";
                  maximumChangedPixels = 2;
                  maximumChannelDifference = 1;
                }];
            toleratedRasterDifferences = Array.of_list (List.rev !tolerance);
            interactions = List.mem "/docs/installation/" config.routes;
            theme = List.mem "/" config.routes;
            result = "pass";
          }]
      in
      let* () =
        write_file
          (join config.output "report.json")
          (json_pretty report Js.null 2 ^ "\n")
      in
      log
        ("PASS parity: "
        ^ string_of_int (List.length config.routes)
        ^ " pages, 9 Markdown exports, 2 sitemaps");
      return ()
    in
    Js.Promise.catch
      (fun error ->
        let* () = close_context baseline in
        let* () = close_context candidate in
        reject_error error)
      (let* () = perform () in
       let* () = close_context baseline in
       close_context candidate)
  in
  Js.Promise.catch
    (fun error ->
      let* () = close_browser browser in
      let* () = close_static_server base_server in
      let* () = close_static_server candidate_server in
      reject_error error)
    (let* () = contexts () in
     let* () = close_browser browser in
     let* () = close_static_server base_server in
     close_static_server candidate_server)

let () =
  let argv = Array.to_list Node.argv in
  let argv = match argv with _ :: _ :: args -> args | _ -> [] in
  ignore
    (Js.Promise.catch
       (fun failure ->
         Node.error failure;
         Node.exit_code 1;
         return ())
       (run argv))
