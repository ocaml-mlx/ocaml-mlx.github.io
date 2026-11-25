open Browser

type preference = Auto | Light | Dark

let parse = function Some "light" -> Light | Some "dark" -> Dark | _ -> Auto
let name = function Auto -> "auto" | Light -> "light" | Dark -> "dark"
let theme_key = "starlight-theme"

let media =
  try Some (match_media window "(prefers-color-scheme: light)") with _ -> None

let read () =
  try parse (option (get_item local_storage theme_key)) with _ -> Auto

let preference = ref (read ())

let sync () =
  let theme =
    match !preference with
    | Auto ->
        if Option.fold ~none:false ~some:media_matches media then "light"
        else "dark"
    | Light -> "light"
    | Dark -> "dark"
  in
  set_attr (root document) "data-theme" theme;
  each
    (fun meta ->
      set_attr meta "content" (if theme = "light" then "#f7f9ff" else "#07090f"))
    (query_all document "meta[name=\"theme-color\"]");
  each
    (fun select -> set_value select (name !preference))
    (query_all document "select[data-mlx-theme-select]")

let () =
  sync ();
  add_listener document "DOMContentLoaded" (fun _ -> sync ());
  add_listener window "pageshow" (fun _ -> sync ());
  add_listener document "change" (fun event ->
      match event_element event with
      | Some select when matches select "select[data-mlx-theme-select]" -> (
          preference := parse (Some (value select));
          sync ();
          try
            set_item local_storage theme_key
              (if !preference = Auto then "" else name !preference)
          with _ -> ())
      | _ -> ());
  Option.iter
    (fun m ->
      add_listener m "change" (fun _ -> if !preference = Auto then sync ()))
    media;
  add_listener window "storage" (fun event ->
      let key = option (storage_key event) in
      if key = None || key = Some theme_key then (
        preference :=
          parse (if key = None then None else option (new_value event));
        sync ()))
