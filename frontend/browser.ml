type node
type element = node
type event
type document
type window
type node_list
type storage
type media
type style
type observer
type entry
type rect
type selection
type range
type clipboard
type navigator
type location
type url
type token_list
type promise
type event_options
type fetch_options
type intersection_options
type connection_info
type idle_function

external document : document = "document"
external window : window = "window"
external navigator : navigator = "navigator"
external location : location = "location"
external local_storage : storage = "localStorage"
external session_storage : storage = "sessionStorage"

external get_item : storage -> string -> string Js.Nullable.t = "getItem"
[@@mel.send]

external set_item : storage -> string -> string -> unit = "setItem" [@@mel.send]
external root : document -> element = "documentElement" [@@mel.get]
external body : document -> element = "body" [@@mel.get]
external head : document -> element = "head" [@@mel.get]

external active : document -> element Js.Nullable.t = "activeElement"
[@@mel.get]

external visibility : document -> string = "visibilityState" [@@mel.get]

external query : 'a -> string -> element Js.Nullable.t = "querySelector"
[@@mel.send]

external query_nodes : 'a -> string -> node_list = "querySelectorAll"
[@@mel.send]

external array_from : node_list -> element array = "from" [@@mel.scope "Array"]

let query_all node selector = array_from (query_nodes node selector)

external by_id : document -> string -> element Js.Nullable.t = "getElementById"
[@@mel.send]

external create : document -> string -> element = "createElement" [@@mel.send]
external create_range : document -> range = "createRange" [@@mel.send]
external exec_command : document -> string -> bool = "execCommand" [@@mel.send]

external add_listener : 'a -> string -> (event -> unit) -> unit
  = "addEventListener"
[@@mel.send]

external remove_listener : 'a -> string -> (event -> unit) -> unit
  = "removeEventListener"
[@@mel.send]

external add_passive : 'a -> string -> (event -> unit) -> event_options -> unit
  = "addEventListener"
[@@mel.send]

external passive : passive:bool -> unit -> event_options = "" [@@mel.obj]
external target : event -> node Js.Nullable.t = "target" [@@mel.get]
external node_type : node -> int Js.Nullable.t = "nodeType" [@@mel.get]
external key : event -> string = "key" [@@mel.get]
external code : event -> string = "code" [@@mel.get]
external meta_key : event -> bool = "metaKey" [@@mel.get]
external ctrl_key : event -> bool = "ctrlKey" [@@mel.get]
external prevent_default : event -> unit = "preventDefault" [@@mel.send]
external stop_propagation : event -> unit = "stopPropagation" [@@mel.send]
external storage_key : event -> string Js.Nullable.t = "key" [@@mel.get]
external new_value : event -> string Js.Nullable.t = "newValue" [@@mel.get]
external matches : element -> string -> bool = "matches" [@@mel.send]

external namespace_uri : element -> string Js.Nullable.t = "namespaceURI"
[@@mel.get]

external closest : element -> string -> element Js.Nullable.t = "closest"
[@@mel.send]

external contains : element -> element -> bool = "contains" [@@mel.send]

external attr : element -> string -> string Js.Nullable.t = "getAttribute"
[@@mel.send]

external set_attr : element -> string -> string -> unit = "setAttribute"
[@@mel.send]

external remove_attr : element -> string -> unit = "removeAttribute"
[@@mel.send]

external toggle_attr : element -> string -> bool -> bool = "toggleAttribute"
[@@mel.send]

external text : element -> string Js.Nullable.t = "textContent" [@@mel.get]
external set_text : element -> string -> unit = "textContent" [@@mel.set]
external value : element -> string = "value" [@@mel.get]
external set_value : element -> string -> unit = "value" [@@mel.set]
external disabled : element -> bool -> unit = "disabled" [@@mel.set]
external open_ : element -> bool = "open" [@@mel.get]
external set_open : element -> bool -> unit = "open" [@@mel.set]
external focus : element -> unit = "focus" [@@mel.send]
external show_modal : element -> unit = "showModal" [@@mel.send]
external close : element -> unit = "close" [@@mel.send]
external style : element -> style = "style" [@@mel.get]
external set_display : style -> string -> unit = "display" [@@mel.set]

external set_css : style -> string -> string -> unit = "setProperty"
[@@mel.send]

external class_list : element -> token_list = "classList" [@@mel.get]
external class_add : token_list -> string -> unit = "add" [@@mel.send]
external class_remove : token_list -> string -> unit = "remove" [@@mel.send]
external append : element -> element -> unit = "append" [@@mel.send]
external append_text : element -> string -> unit = "append" [@@mel.send]

external append_child : element -> element -> element = "appendChild"
[@@mel.send]

external remove : element -> unit = "remove" [@@mel.send]
external parent : element -> element Js.Nullable.t = "parentElement" [@@mel.get]

external sibling : element -> element Js.Nullable.t = "previousElementSibling"
[@@mel.get]

external last_child : element -> element Js.Nullable.t = "lastElementChild"
[@@mel.get]

external scroll_top : element -> float = "scrollTop" [@@mel.get]
external set_scroll_top : element -> float -> unit = "scrollTop" [@@mel.set]
external scroll_width : element -> int = "scrollWidth" [@@mel.get]
external client_width : element -> int = "clientWidth" [@@mel.get]
external client_height : element -> int = "clientHeight" [@@mel.get]
external set_tab_index : element -> int -> unit = "tabIndex" [@@mel.set]
external bounding_rect : element -> rect = "getBoundingClientRect" [@@mel.send]
external height : rect -> float = "height" [@@mel.get]
external hash : element -> string = "hash" [@@mel.get]
external id : element -> string = "id" [@@mel.get]
external href : element -> string = "href" [@@mel.get]
external set_href : element -> string -> unit = "href" [@@mel.set]
external set_rel : element -> string -> unit = "rel" [@@mel.set]
external rel_list : element -> token_list = "relList" [@@mel.get]
external supports : token_list -> string -> bool = "supports" [@@mel.send]
external match_media : window -> string -> media = "matchMedia" [@@mel.send]
external media_matches : media -> bool = "matches" [@@mel.get]
external set_timeout : (unit -> unit) -> int -> int = "setTimeout"
external clear_timeout : int -> unit = "clearTimeout"

external request_animation_frame : (float -> unit) -> int
  = "requestAnimationFrame"

external request_idle_callback : window -> (unit -> unit) -> int
  = "requestIdleCallback"
[@@mel.send]

external has_idle_callback : window -> idle_function Js.Nullable.t
  = "requestIdleCallback"
[@@mel.get]

external platform : navigator -> string = "platform" [@@mel.get]
external on_line : navigator -> bool = "onLine" [@@mel.get]
external clipboard : navigator -> clipboard = "clipboard" [@@mel.get]
external write_text : clipboard -> string -> promise = "writeText" [@@mel.send]
external then_ : promise -> (unit -> unit) -> promise = "then" [@@mel.send]
external catch : promise -> (unit -> unit) -> promise = "catch" [@@mel.send]

external connection : navigator -> connection_info Js.Nullable.t = "connection"
[@@mel.get]

external save_data : connection_info -> bool Js.Nullable.t = "saveData"
[@@mel.get]

external effective_type : connection_info -> string Js.Nullable.t
  = "effectiveType"
[@@mel.get]

external location_origin : location -> string = "origin" [@@mel.get]
external location_path : location -> string = "pathname" [@@mel.get]
external location_search : location -> string = "search" [@@mel.get]
external new_url : string -> url = "URL" [@@mel.new]
external url_hash : url -> string -> unit = "hash" [@@mel.set]
external url_origin : url -> string = "origin" [@@mel.get]
external url_path : url -> string = "pathname" [@@mel.get]
external url_search : url -> string = "search" [@@mel.get]
external url_href : url -> string = "href" [@@mel.get]
external fetch_low : url -> fetch_options -> promise = "fetch"

external low_priority : priority:string -> unit -> fetch_options = ""
[@@mel.obj]

external get_selection : unit -> selection Js.Nullable.t = "getSelection"
external select_node : range -> element -> unit = "selectNode" [@@mel.send]
external remove_ranges : selection -> unit = "removeAllRanges" [@@mel.send]
external add_range : selection -> range -> unit = "addRange" [@@mel.send]
external get_computed_style : element -> style = "getComputedStyle"
external opacity : style -> string = "opacity" [@@mel.get]
external encode_uri_component : string -> string = "encodeURIComponent"

external new_intersection :
  (entry array -> unit) -> intersection_options -> observer
  = "IntersectionObserver"
[@@mel.new]

external root_margin : rootMargin:string -> unit -> intersection_options = ""
[@@mel.obj]

external new_resize : (entry array -> unit) -> observer = "ResizeObserver"
[@@mel.new]

external observe : observer -> element -> unit = "observe" [@@mel.send]
external disconnect : observer -> unit = "disconnect" [@@mel.send]
external intersecting : entry -> bool = "isIntersecting" [@@mel.get]
external entry_target : entry -> element = "target" [@@mel.get]

let option = Js.Nullable.toOption
let each f items = Array.iter f items

let idle f =
  if option (has_idle_callback window) <> None then
    ignore (request_idle_callback window f)
  else ignore (set_timeout f 1)

let query_opt node selector = option (query node selector)
let get_attr node name = option (attr node name)
let get_text node = Option.value ~default:"" (option (text node))

let event_node e =
  match option (target e) with
  | Some node when option (node_type node) <> None -> Some node
  | _ -> None

let event_element e =
  match event_node e with
  | Some element when option (node_type element) = Some 1 -> Some element
  | _ -> None

let toggle node name value = ignore (toggle_attr node name value)
