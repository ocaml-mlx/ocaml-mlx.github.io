type window
type storage

external window : window = "window"
external dom_exception : string -> string -> exn = "DOMException" [@@mel.new]

external define_property : window -> string -> 'a -> unit = "defineProperty"
[@@mel.scope "Object"]

let () =
  define_property window "localStorage"
    [%mel.obj
      { get = (fun () -> raise (dom_exception "Blocked" "SecurityError")) }]
