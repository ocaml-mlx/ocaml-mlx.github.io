type element
type document
type attribute
type storage
type navigator
type clipboard
type window
type url
type style
type observer
type fonts
type transition

external listen : document -> string -> (transition -> unit) -> unit
  = "addEventListener"
[@@mel.send]

external transition_target : transition -> element Js.Nullable.t = "target"
[@@mel.get]

external transition_property : transition -> string = "propertyName" [@@mel.get]
external matches : element -> string -> bool = "matches" [@@mel.send]
external document : document = "document"
external navigator : navigator = "navigator"
external window : window = "window"
external location : url = "location"
external local_storage : storage = "localStorage"
external root : document -> element = "documentElement" [@@mel.get]
external head : document -> element = "head" [@@mel.get]
external body : document -> element = "body" [@@mel.get]
external title : document -> string = "title" [@@mel.get]
external lang : element -> string = "lang" [@@mel.get]
external tag : element -> string = "tagName" [@@mel.get]
external id : element -> string = "id" [@@mel.get]
external href : element -> string = "href" [@@mel.get]
external value : element -> string = "value" [@@mel.get]
external text : element -> string Js.Nullable.t = "textContent" [@@mel.get]

external attr : element -> string -> string Js.Nullable.t = "getAttribute"
[@@mel.send]

external attributes : element -> attribute array = "attributes" [@@mel.get]
external attr_name : attribute -> string = "name" [@@mel.get]
external attr_value : attribute -> string = "value" [@@mel.get]

external query : 'a -> string -> element Js.Nullable.t = "querySelector"
[@@mel.send]

external query_all : 'a -> string -> element array = "querySelectorAll"
[@@mel.send]

external get_element : document -> string -> element Js.Nullable.t
  = "getElementById"
[@@mel.send]

external array_from : 'a -> 'b array = "from" [@@mel.scope "Array"]
external set_item : storage -> string -> string -> unit = "setItem" [@@mel.send]

external get_item : storage -> string -> string Js.Nullable.t = "getItem"
[@@mel.send]

external clear : storage -> unit = "clear" [@@mel.send]
external dataset : element -> 'a = "dataset" [@@mel.get]
external theme : 'a -> string = "theme" [@@mel.get]
external scroll_width : element -> int = "scrollWidth" [@@mel.get]
external inner_width : int = "innerWidth"
external open_ : element -> bool = "open" [@@mel.get]
external has_attribute : element -> string -> bool = "hasAttribute" [@@mel.send]
external get_style : element -> style = "getComputedStyle"
external color_scheme : style -> string = "colorScheme" [@@mel.get]
external new_url : string -> url = "URL" [@@mel.new]
external origin : url -> string = "origin" [@@mel.get]
external pathname : url -> string = "pathname" [@@mel.get]
external hash : url -> string = "hash" [@@mel.get]
external decode_uri : string -> string = "decodeURIComponent"
external slice : string -> int -> string = "slice" [@@mel.send]
external regexp : string -> string -> 'a = "RegExp" [@@mel.new]
external replace : string -> 'a -> string -> string = "replace" [@@mel.send]
external trim : string -> string = "trim" [@@mel.send]
external set_global : window -> 'a -> unit = "__mlxParity" [@@mel.set]
external callback : window -> 'a = "__mlxParity" [@@mel.get]
external clipboard : navigator -> clipboard = "clipboard" [@@mel.get]
external read_text : clipboard -> string Js.Promise.t = "readText" [@@mel.send]

external define_property : 'a -> string -> 'b -> unit = "defineProperty"
[@@mel.scope "Object"]

external observer : ('a -> observer -> unit) -> observer = "MutationObserver"
[@@mel.new]

external observe : observer -> document -> 'a -> unit = "observe" [@@mel.send]
external disconnect : observer -> unit = "disconnect" [@@mel.send]
external set_first_paint : window -> string -> unit = "themeAtBody" [@@mel.set]

external first_paint : window -> string Js.Nullable.t = "themeAtBody"
[@@mel.get]

external set_clipboard : navigator -> 'a -> unit = "clipboard" [@@mel.set]
external fonts : document -> fonts = "fonts" [@@mel.get]
external fonts_ready : fonts -> unit Js.Promise.t = "ready" [@@mel.get]
external request_frame : (float -> unit) -> unit = "requestAnimationFrame"

external promise : ((unit -> unit) -> unit) -> unit Js.Promise.t = "Promise"
[@@mel.new]

let string = Js.Json.string

let nullable value =
  match Js.Nullable.toOption value with
  | Some value -> string value
  | None -> Js.Json.null

let obj entries = Js.Json.object_ (Js.Dict.fromList entries)
let list entries = Js.Json.array entries
let pair a b = list [| a; b |]

let normalized_text node =
  match Js.Nullable.toOption node with
  | None -> ""
  | Some node ->
      trim
        (replace
           (Option.value ~default:"" (Js.Nullable.toOption (text node)))
           (regexp "\\s+" "g") " ")

let selected node selector = array_from (query_all node selector)

let snapshot () =
  let root = root document in
  let metadata =
    selected (head document)
      "meta,link[rel=\"canonical\"],link[rel=\"alternate\"],link[rel=\"icon\"],link[rel=\"manifest\"]"
    |> Array.to_list
    |> List.filter (fun node ->
        match Js.Nullable.toOption (attr node "name") with
        | Some name -> String.lowercase_ascii name <> "generator"
        | None -> true)
    |> List.map (fun node ->
        let attributes =
          array_from (attributes node)
          |> Array.to_list
          |> List.filter (fun item ->
              let name = attr_name item in
              name <> "class" && name <> "data-astro-cid")
          |> List.sort (fun a b -> String.compare (attr_name a) (attr_name b))
          |> List.map (fun item ->
              pair (string (attr_name item)) (string (attr_value item)))
          |> Array.of_list
        in
        list [| string (tag node); list attributes |])
  in
  let metadata =
    List.map
      (fun item ->
        match Js.Json.decodeArray item with
        | Some pair ->
            let attrs = Option.get (Js.Json.decodeArray pair.(1)) in
            list (Array.append [| pair.(0) |] attrs)
        | None -> assert false)
      metadata
  in
  let attrs selector property =
    list
      (Array.map
         (fun node ->
           pair
             (nullable (attr node property))
             (string (normalized_text (Js.Nullable.return node))))
         (selected document selector))
  in
  obj
    [
      ("title", string (title document));
      ("lang", string (lang root));
      ("metadata", list (Array.of_list metadata));
      ( "headings",
        list
          (Array.map
             (fun node ->
               list
                 [|
                   string (tag node);
                   string (id node);
                   string (normalized_text (Js.Nullable.return node));
                 |])
             (selected document "h1,h2,h3,h4,h5,h6")) );
      ("links", attrs "a[href]" "href");
      ("main", string (normalized_text (query document "main")));
      ( "code",
        list
          (Array.map
             (fun node -> nullable (text node))
             (selected document "pre")) );
      ( "copy",
        list
          (Array.map
             (fun node -> nullable (attr node "data-code"))
             (selected document ".expressive-code button[data-code]")) );
      ("ids", Js.Json.stringArray (Array.map id (selected document "[id]")));
    ]
  |> Js.Json.stringify

let links () =
  let anchors =
    selected document "a[href^=\"#\"]"
    |> Array.to_list
    |> List.filter_map (fun node ->
        match Js.Nullable.toOption (attr node "href") with
        | None -> None
        | Some href ->
            if
              Js.Nullable.toOption
                (get_element document (decode_uri (slice href 1)))
              = None
            then Some href
            else None)
    |> Array.of_list
  in
  let internal =
    selected document "a[href]"
    |> Array.to_list
    |> List.filter_map (fun node ->
        let url = new_url (href node) in
        if origin url = origin location then Some (pathname url) else None)
    |> List.sort_uniq String.compare
    |> Array.of_list
  in
  [%mel.obj { anchors; internal }]

let theme_state () =
  let root = root document in
  [%mel.obj
    {
      theme = theme (dataset root);
      scheme = color_scheme (get_style root);
      meta =
        (match
           Js.Nullable.toOption (query document "meta[name=\"theme-color\"]")
         with
        | Some node ->
            Option.value ~default:""
              (Js.Nullable.toOption (attr node "content"))
        | None -> "");
      selected = Array.map value (selected document "[data-mlx-theme-select]");
    }]

let clipboard_value () = read_text (clipboard navigator)
let current_theme () = theme (dataset (root document))

let saved_theme () =
  Js.Nullable.toOption (get_item local_storage "starlight-theme")

let clear_storage () = clear local_storage
let store_theme value = set_item local_storage "starlight-theme" value

let open_dialog () =
  match
    Js.Nullable.toOption (query document "dialog[aria-label=\"Search\"]")
  with
  | Some node -> open_ node
  | None -> false

let open_node node = open_ node
let expanded_menu () = has_attribute (body document) "data-mobile-menu-expanded"
let overflow () = scroll_width (root document) > inner_width
let first_paint_theme () = Js.Nullable.toOption (first_paint window)

let settled () =
  Js.Promise.then_
    (fun _ ->
      promise (fun resolve ->
          request_frame (fun _ -> request_frame (fun _ -> resolve ()))))
    (fonts_ready (fonts document))

let () =
  let clipboard_contents = ref "" in
  let copy_transition = ref false in
  listen document "transitionrun" (fun event ->
      match Js.Nullable.toOption (transition_target event) with
      | Some target
        when matches target ".expressive-code .feedback"
             && transition_property event = "opacity" ->
          copy_transition := true
      | _ -> ());
  define_property navigator "clipboard"
    [%mel.obj
      {
        configurable = true;
        value =
          [%mel.obj
            {
              writeText =
                (fun text ->
                  clipboard_contents := text;
                  Js.Promise.resolve ());
              readText = (fun () -> Js.Promise.resolve !clipboard_contents);
            }];
      }];
  let watcher =
    observer (fun _ watcher ->
        if Js.Nullable.toOption (query document "body") <> None then (
          set_first_paint window (current_theme ());
          disconnect watcher))
  in
  observe watcher document [%mel.obj { childList = true; subtree = true }];
  set_global window
    [%mel.obj
      {
        snapshot;
        links;
        themeState = theme_state;
        clipboardValue = clipboard_value;
        copyTransition = (fun () -> !copy_transition);
        currentTheme = current_theme;
        savedTheme = saved_theme;
        clearStorage = clear_storage;
        storeTheme = store_theme;
        openDialog = open_dialog;
        expandedMenu = expanded_menu;
        overflow;
        firstPaintTheme = first_paint_theme;
        settled;
      }]
