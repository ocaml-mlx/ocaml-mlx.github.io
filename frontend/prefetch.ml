open Browser

type urls

external urls : unit -> urls = "Set" [@@mel.new]
external has_url : urls -> string -> bool = "has" [@@mel.send]
external add_url : urls -> string -> urls = "add" [@@mel.send]

let prefetched = urls ()
let hover_timer = ref None

let slow_connection () =
  match option (connection navigator) with
  | None -> false
  | Some connection -> (
      option (save_data connection) = Some true
      ||
      match option (effective_type connection) with
      | Some connection -> Js.String.includes ~search:"2g" connection
      | None -> false)

let prefetch ?(ignore_slow = false) anchor =
  if on_line navigator && (ignore_slow || not (slow_connection ())) then (
    let url = new_url (href anchor) in
    url_hash url "";
    let address = url_href url in
    if
      url_origin url = location_origin location
      && (url_path url <> location_path location
         || url_search url <> location_search location)
      && not (has_url prefetched address)
    then (
      ignore (add_url prefetched address);
      let link = create document "link" in
      if supports (rel_list link) "prefetch" then (
        set_rel link "prefetch";
        set_href link address;
        append (head document) link)
      else
        ignore
          (catch
             (fetch_low url (low_priority ~priority:"low" ()))
             (fun () -> ()))))

let is_anchor node =
  matches node "a"
  && option (namespace_uri node) = Some "http://www.w3.org/1999/xhtml"

let hover_enabled anchor =
  is_anchor anchor
  &&
  match get_attr anchor "data-astro-prefetch" with
  | None | Some "" | Some "hover" -> true
  | _ -> false

let leave () =
  Option.iter clear_timeout !hover_timer;
  hover_timer := None

let enter event =
  match event_element event with
  | Some anchor when hover_enabled anchor ->
      leave ();
      hover_timer := Some (set_timeout (fun () -> prefetch anchor) 80)
  | _ -> ()

let () =
  let passive = passive ~passive:true () in
  add_passive (body document) "focusin" enter passive;
  add_passive (body document) "focusout" (fun _ -> leave ()) passive;
  each
    (fun anchor ->
      if hover_enabled anchor then (
        add_passive anchor "mouseenter" enter passive;
        add_passive anchor "mouseleave" (fun _ -> leave ()) passive))
    (query_all document "a");
  each
    (fun event_name ->
      add_passive document event_name
        (fun event ->
          match event_element event with
          | Some anchor
            when is_anchor anchor
                 && get_attr anchor "data-astro-prefetch" <> Some "false"
                 && (get_attr anchor "data-astro-prefetch" = Some "tap"
                    || slow_connection ()) ->
              prefetch ~ignore_slow:true anchor
          | _ -> ())
        passive)
    [| "touchstart"; "mousedown" |]
