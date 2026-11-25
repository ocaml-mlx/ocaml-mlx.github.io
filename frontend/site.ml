open Browser

type pagefind_options

external pagefind_options :
  element:string ->
  baseUrl:string ->
  bundlePath:string ->
  showImages:bool ->
  translations:Js.Json.t ->
  showSubResults:bool ->
  unit ->
  pagefind_options = ""
[@@mel.obj]

external pagefind_ui : pagefind_options -> unit = "PagefindUI"
[@@mel.module "@pagefind/default-ui"] [@@mel.new]

let shortcut () =
  match query_opt document "button[data-open-modal]" with
  | None -> ()
  | Some button -> (
      match query_opt button "kbd" with
      | None -> ()
      | Some hint ->
          (match query_opt hint "kbd" with
          | Some platform_key
            when let platform = String.lowercase_ascii (platform navigator) in
                 List.exists
                   (fun word -> Js.String.includes ~search:word platform)
                   [ "mac"; "iphone"; "ipod"; "ipad" ] ->
              set_text platform_key {js|⌘|js};
              set_attr button "aria-keyshortcuts" "Meta+K"
          | _ -> ());
          set_display (style hint) "")

let search () =
  each
    (fun search ->
      match
        ( query_opt search "button[data-open-modal]",
          query_opt search "button[data-close-modal]",
          query_opt search "dialog",
          query_opt search ".dialog-frame" )
      with
      | Some open_button, Some close_button, Some dialog, Some frame ->
          let close_modal () = close dialog in
          let click event =
            match event_node event with
            | None -> ()
            | Some target ->
                let is_link =
                  match event_element event with
                  | Some element -> option (closest element "a[href]") <> None
                  | None -> false
                in
                if
                  is_link
                  || contains (body document) target
                     && not (contains frame target)
                then close_modal ()
          in
          let open_modal event =
            show_modal dialog;
            toggle (body document) "data-search-modal-open" true;
            Option.iter focus (query_opt search "input");
            Option.iter stop_propagation event;
            add_listener window "click" click
          in
          add_listener open_button "click" (fun event ->
              open_modal (Some event));
          disabled open_button false;
          add_listener close_button "click" (fun _ -> close_modal ());
          add_listener dialog "close" (fun _ ->
              toggle (body document) "data-search-modal-open" false;
              remove_listener window "click" click);
          add_listener window "keydown" (fun event ->
              if (meta_key event || ctrl_key event) && key event = "k" then (
                if open_ dialog then close_modal () else open_modal None;
                prevent_default event));
          let translations =
            match get_attr search "data-translations" with
            | None -> Js.Json.object_ (Js.Dict.empty ())
            | Some raw -> (
                try Js.Json.parseExn raw
                with _ -> Js.Json.object_ (Js.Dict.empty ()))
          in
          add_listener window "DOMContentLoaded" (fun _ ->
              idle (fun () ->
                  pagefind_ui
                    (pagefind_options ~element:"#starlight__search" ~baseUrl:"/"
                       ~bundlePath:"/pagefind/" ~showImages:false ~translations
                       ~showSubResults:true ())))
      | _ -> ())
    (query_all document "site-search")

let menu () =
  each
    (fun menu ->
      match query_opt menu "button" with
      | None -> ()
      | Some button ->
          let set_expanded expanded =
            set_attr menu "aria-expanded" (string_of_bool expanded);
            toggle (body document) "data-mobile-menu-expanded" expanded
          in
          add_listener button "click" (fun _ ->
              set_expanded (get_attr menu "aria-expanded" <> Some "true"));
          Option.iter
            (fun nav ->
              add_listener nav "keyup" (fun event ->
                  if code event = "Escape" then (
                    set_expanded false;
                    focus button)))
            (option (closest menu "nav")))
    (query_all document "starlight-menu-button")

type sidebar_state = {
  hash : string;
  open_groups : bool option array;
  scroll : float;
}

let read_sidebar hash scroll =
  let empty = { hash; open_groups = [||]; scroll } in
  try
    match option (get_item session_storage "sl-sidebar-state") with
    | None -> empty
    | Some raw ->
        let json = Js.Json.parseExn raw in
        let dict = Option.get (Js.Json.decodeObject json) in
        let field key = Js.Dict.get dict key in
        let saved_hash = Option.bind (field "hash") Js.Json.decodeString in
        if saved_hash <> Some hash then empty
        else
          let open_groups =
            match Option.bind (field "open") Js.Json.decodeArray with
            | None -> [||]
            | Some values -> Array.map Js.Json.decodeBoolean values
          in
          let scroll =
            Option.value ~default:scroll
              (Option.bind (field "scroll") Js.Json.decodeNumber)
          in
          { hash; open_groups; scroll }
  with _ -> empty

let save_sidebar state =
  try
    let dict = Js.Dict.empty () in
    Js.Dict.set dict "hash" (Js.Json.string state.hash);
    Js.Dict.set dict "scroll" (Js.Json.number state.scroll);
    Js.Dict.set dict "open"
      (Js.Json.array
         (Array.map
            (function
              | None -> Js.Json.null | Some value -> Js.Json.boolean value)
            state.open_groups));
    set_item session_storage "sl-sidebar-state"
      (Js.Json.stringifyAny (Js.Json.object_ dict) |> Option.get)
  with _ -> ()

let sidebar () =
  match option (by_id document "starlight__sidebar") with
  | None -> ()
  | Some scroller -> (
      match query_opt scroller "sl-sidebar-state-persist" with
      | None -> ()
      | Some sidebar ->
          let hash = Option.value ~default:"" (get_attr sidebar "data-hash") in
          let details () = query_all sidebar "details" in
          (try
             if media_matches (match_media window "(min-width: 50em)") then (
               let saved = read_sidebar hash (scroll_top scroller) in
               set_scroll_top scroller saved.scroll;
               Array.iteri
                 (fun index node ->
                   if index < Array.length saved.open_groups then
                     Option.iter (set_open node) saved.open_groups.(index))
                 (details ()))
           with _ -> ());
          add_listener sidebar "click" (fun event ->
              match event_element event with
              | None -> ()
              | Some target -> (
                  match option (closest target "summary") with
                  | None -> ()
                  | Some summary ->
                      Option.iter
                        (fun node ->
                          let all = details () in
                          Array.iteri
                            (fun index candidate ->
                              if candidate == node then (
                                let current =
                                  read_sidebar hash (scroll_top scroller)
                                in
                                let open_groups =
                                  Array.init (Array.length all) (fun i ->
                                      if i < Array.length current.open_groups
                                      then current.open_groups.(i)
                                      else None)
                                in
                                open_groups.(index) <- Some (not (open_ node));
                                save_sidebar { current with open_groups }))
                            all)
                        (option (closest summary "details"))));
          let save () =
            let state = read_sidebar hash (scroll_top scroller) in
            save_sidebar { state with scroll = scroll_top scroller }
          in
          add_listener window "visibilitychange" (fun _ ->
              if visibility document = "hidden" then save ());
          add_listener window "pageHide" (fun _ -> save ()))

let heading_for selector element =
  let rec find node =
    match node with
    | None -> None
    | Some node -> (
        if matches node ".sl-markdown-content, main > *" then
          option (by_id document "_top")
        else if matches node selector then Some node
        else
          match query_opt node selector with
          | Some heading -> Some heading
          | None -> (
              let rec last element =
                match option (last_child element) with
                | Some child -> last child
                | None -> element
              in
              match option (sibling node) with
              | Some previous -> (
                  match find (Some (last previous)) with
                  | Some heading -> Some heading
                  | None -> find (option (parent node)))
              | None -> find (option (parent node))))
  in
  find element

let toc mobile toc =
  let min_h =
    Option.value ~default:2
      (Option.bind (get_attr toc "data-min-h") int_of_string_opt)
  in
  let max_h =
    Option.value ~default:3
      (Option.bind (get_attr toc "data-max-h") int_of_string_opt)
  in
  let headings =
    List.init
      (max 0 (1 + max_h - min_h))
      (fun index -> "h" ^ string_of_int (min_h + index))
  in
  let selector = "h1#_top,:where(" ^ String.concat "," headings ^ ")[id]" in
  let targets =
    query_all document
      (String.concat ","
         [
           "main :where(" ^ selector ^ ")";
           "main :where(" ^ selector ^ ", .sl-heading-wrapper) ~ *:not(:has("
           ^ selector ^ "))";
           "main .sl-markdown-content > *:not(:has(" ^ selector ^ "))";
           "main > *:not(:has(" ^ selector ^ "))";
         ])
  in
  let links = query_all toc "a" in
  let current = ref (query_opt toc "a[aria-current=\"true\"]") in
  let set_current link =
    if
      not
        (Option.fold ~none:false
           ~some:(fun previous -> previous == link)
           !current)
    then (
      Option.iter (fun previous -> remove_attr previous "aria-current") !current;
      set_attr link "aria-current" "true";
      current := Some link;
      if mobile then
        Option.iter
          (fun display -> set_text display (get_text link))
          (query_opt toc ".display-current"))
  in
  idle (fun () ->
      let observer = ref None in
      let observe () =
        if !observer = None then (
          let selector_height selector =
            match query_opt document selector with
            | Some node -> height (bounding_rect node)
            | None -> 0.
          in
          let mobile_height =
            match query_opt toc "summary" with
            | Some node -> height (bounding_rect node)
            | None -> 0.
          in
          let top = selector_height "header" +. mobile_height +. 32. in
          let bottom =
            top +. 53. -. float_of_int (client_height (root document))
          in
          let margin = Printf.sprintf "-%gpx 0%% %gpx" top bottom in
          let instance =
            new_intersection
              (fun entries ->
                let rec inspect index =
                  if index < Array.length entries then
                    let entry = entries.(index) in
                    if intersecting entry then
                      match
                        heading_for selector (Some (entry_target entry))
                      with
                      | Some heading -> (
                          match
                            Array.find_opt
                              (fun link ->
                                hash link
                                = "#" ^ encode_uri_component (id heading))
                              links
                          with
                          | Some link -> set_current link
                          | None -> inspect (index + 1))
                      | None -> inspect (index + 1)
                    else inspect (index + 1)
                in
                inspect 0)
              (root_margin ~rootMargin:margin ())
          in
          observer := Some instance;
          each (observe instance) targets)
      in
      observe ();
      let timeout = ref None in
      add_listener window "resize" (fun _ ->
          Option.iter disconnect !observer;
          observer := None;
          Option.iter clear_timeout !timeout;
          timeout := Some (set_timeout (fun () -> idle observe) 200)));
  if mobile then
    Option.iter
      (fun details ->
        let close () = set_open details false in
        each
          (fun link -> add_listener link "click" (fun _ -> close ()))
          (query_all details "a");
        add_listener window "click" (fun event ->
            match event_node event with
            | Some target when not (contains details target) -> close ()
            | _ -> ());
        add_listener window "keydown" (fun event ->
            if key event = "Escape" && open_ details then (
              let focused =
                Option.fold ~none:false ~some:(contains details)
                  (option (active document))
              in
              close ();
              if focused then Option.iter focus (query_opt details "summary"))))
      (query_opt toc "details")

let focusable_code () =
  let blocks = query_all document ".expressive-code pre > code" in
  if Array.length blocks > 0 then
    let observer =
      new_resize (fun entries ->
          each
            (fun entry ->
              let pre = entry_target entry in
              if scroll_width pre > client_width pre then (
                set_tab_index pre 0;
                set_attr pre "role" "region")
              else (
                remove_attr pre "tabindex";
                remove_attr pre "role"))
            entries)
    in
    each
      (fun block -> Option.iter (observe observer) (option (parent block)))
      blocks

let fallback_copy text =
  let element = create document "pre" in
  let css = style element in
  each
    (fun (property, value) -> set_css css property value)
    [|
      ("opacity", "0");
      ("pointer-events", "none");
      ("position", "absolute");
      ("overflow", "hidden");
      ("left", "0");
      ("top", "0");
      ("width", "20px");
      ("height", "20px");
      ("user-select", "all");
    |];
  set_attr element "aria-hidden" "true";
  set_text element text;
  ignore (append_child (body document) element);
  match option (get_selection ()) with
  | None ->
      remove element;
      false
  | Some selection ->
      let range = create_range document in
      select_node range element;
      remove_ranges selection;
      add_range selection range;
      let copied = try exec_command document "copy" with _ -> false in
      remove_ranges selection;
      remove element;
      copied

let copy_buttons () =
  each
    (fun button ->
      add_listener button "click" (fun _ ->
          let source = Option.value ~default:"" (get_attr button "data-code") in
          let text = String.concat "\n" (String.split_on_char '\x7f' source) in
          let feedback copied =
            if copied then
              Option.iter
                (fun parent ->
                  if query_opt parent ".feedback" = None then
                    Option.iter
                      (fun live ->
                        let feedback = create document "div" in
                        class_add (class_list feedback) "feedback";
                        append_text feedback
                          (Option.value ~default:"Copied!"
                             (get_attr button "data-copied"));
                        append live feedback;
                        ignore (bounding_rect feedback);
                        ignore
                          (request_animation_frame (fun _ ->
                               class_add (class_list feedback) "show"));
                        let hide () =
                          class_remove (class_list feedback) "show"
                        in
                        let remove_if_hidden () =
                          if
                            float_of_string_opt
                              (opacity (get_computed_style feedback))
                            = Some 0.
                          then remove feedback
                        in
                        ignore (set_timeout hide 1500);
                        ignore (set_timeout remove_if_hidden 2500);
                        add_listener button "blur" (fun _ -> hide ());
                        add_listener feedback "transitioncancel" (fun _ ->
                            remove_if_hidden ());
                        add_listener feedback "transitionend" (fun _ ->
                            remove_if_hidden ()))
                      (query_opt parent "[aria-live]"))
                (option (parent button))
          in
          try
            let promise = write_text (clipboard navigator) text in
            ignore
              (catch
                 (then_ promise (fun () -> feedback true))
                 (fun () -> feedback (fallback_copy text)))
          with _ -> feedback (fallback_copy text)))
    (query_all document ".expressive-code .copy button")

let () =
  shortcut ();
  search ();
  menu ();
  sidebar ();
  each (toc false) (query_all document "starlight-toc");
  each (toc true) (query_all document "mobile-starlight-toc");
  focusable_code ();
  copy_buttons ()
