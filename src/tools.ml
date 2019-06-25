(* -------------------------------------------------------------------- *)
exception No_value
exception Unsupported_yet

let debug_mode = ref false

(* -------------------------------------------------------------------- *)
let id = fun x -> x

let (|@) f g = fun x -> f (g x)

let proj3_1 (x, _, _) = x
let proj3_2 (_, x, _) = x
let proj3_3 (_, _, x) = x

let fst_map f (x, y) = (f x, y)
let snd_map f (x, y) = (x, f y)

let pair_map f g (x, y) = (f x, g y)

let swap = fun (x, y) -> (y, x)

(* -------------------------------------------------------------------- *)
module String : sig
  include module type of String

  val starts : pattern:string -> string -> bool
  val ends   : pattern:string -> string -> bool
end = struct
  include String

  let starts ~pattern s =
    let module E = struct exception No end in

    let plen = String.length pattern in
    let slen = String.length s in

    try
      if plen > slen then
        raise E.No;
      for i = 0 to plen-1 do
        if pattern.[i] <> s.[i] then
          raise E.No
      done;
      true

    with E.No -> false

  let ends ~pattern s =
    let module E = struct exception No end in

    let plen = String.length pattern in
    let slen = String.length s in

    try
      if plen > slen then
        raise E.No;
      for i = 0 to plen-1 do
        if pattern.[i] <> s.[slen-1-i] then
          raise E.No
      done;
      true

    with E.No -> false
end

(* -------------------------------------------------------------------- *)
module Option : sig
  val is_none : 'a option -> bool
  val is_some : 'a option -> bool

  val none        : 'a option
  val some        : 'a -> 'a option

  val get         : 'a option -> 'a
  val get_all     : ('a option) list -> 'a list option
  val get_exn     : exn -> 'a option -> 'a
  val get_dfl     : 'a -> 'a option -> 'a
  val get_fdfl    : (unit -> 'a) -> 'a option -> 'a
  val iter        : ('a -> unit) -> 'a option -> unit
  val map         : ('a -> 'b) -> 'a option -> 'b option
  val bind        : ('a -> 'b option) -> 'a option -> 'b option
  val fold        : ('a -> 'b -> 'a) -> 'a -> 'b option -> 'a
  val foldmap     : ('a -> 'b -> 'a * 'c) -> 'a -> 'b option -> 'a * 'c option
  val map_dfl     : ('a -> 'b) -> 'b -> 'a option -> 'b
  val get_as_list : 'a option -> 'a list
  val flatten     : 'a option option -> 'a option

  val fst : ('a * 'b) option -> 'a option
  val snd : ('a * 'b) option -> 'b option
end = struct
  let is_none = function None -> true  | Some _ -> false
  let is_some = function None -> false | Some _ -> true

  let none =
    None

  let some =
    fun x -> Some x

  let get =
    function None -> raise No_value | Some e -> e

  let get_dfl dfl =
    function None -> dfl | Some e -> e

  let get_fdfl dfl =
    function None -> dfl () | Some e -> e

  let get_all xs =
    let module E = struct exception Aaarg end in

    try
      Some (List.map (function Some x -> x | None -> raise E.Aaarg) xs)
    with E.Aaarg -> None

  let get_exn e = function Some v -> v | None -> raise e

  let iter f = function None -> () | Some x -> f x

  let map f = function None -> None | Some x -> Some (f x)

  let bind f = function None -> None | Some x -> f x

  let fold f state = function None -> state | Some v -> f state v

  let foldmap f state = function
    | None   -> state, None
    | Some v -> let state, aout = f state v in state, Some aout

  let map_dfl f n = function None -> n | Some x -> f x

  let get_as_list = function None -> [] | Some x -> [x]

  let flatten = function Some (Some v) -> Some v | _ -> None

  let fst = fun x -> map fst x
  let snd = fun x -> map snd x
end

let (|?>) x f = Option.map f x
let (|? ) x f = ignore (Option.map f x)

(* -------------------------------------------------------------------- *)
module List : sig
  include module type of List

  val is_empty      : 'a list -> bool
  val as_seq1       : 'a list -> 'a option
  val as_seq2       : 'a list -> ('a * 'a) option
  val make          : (int -> 'a) -> int -> 'a list
  val int_fold      : ('a -> int -> 'a) -> 'a -> int -> 'a
  val pmap          : ('a -> 'b option) -> 'a list -> 'b list
  val mappdt        : ('a -> 'b -> 'c) -> 'a list -> 'b list -> 'c list
  val find_dup      : ('a -> 'b) -> 'a list -> ('a * 'a) option
  val undup         : ('a -> 'b) -> 'a list -> 'a list
  val xfilter       : ('a -> [`Left of 'b | `Right of 'c]) -> 'a list -> 'b list * 'c list
  val fold_left_map : ('a -> 'b -> 'a * 'c) -> 'a -> 'b list -> 'a * 'c list
  val assoc_all     : 'a -> ('a * 'b) list -> 'b list

  module Exn : sig
    val assoc : 'a -> ('a * 'b) list -> 'b option
  end
end = struct
  include List

  let is_empty = function [] -> true | _ -> false

  let as_seq1 = function [x] -> Some x | _ -> None
  let as_seq2 = function [x; y] -> Some (x, y) | _ -> None

  let make f =
    let rec doit acc n =
      if n <= 0 then List.rev acc else doit (f n :: acc) (n-1)
    in fun n -> doit [] n

  let int_fold f acc n =
    let rec int_fold_rec acc i =
      if (i = n)
      then acc
      else int_fold_rec (f acc i) (i + 1) in
    int_fold_rec acc 0

  let pmap f =
    let rec doit xs =
      match xs with
      | [] ->
        []
      | x :: xs -> begin
          match f x with
          | None -> doit xs
          | Some y -> y :: doit xs
        end
    in fun xs -> doit xs

  let mappdt f xs ys =
    List.flatten (List.map (fun x -> List.map (fun y -> f x y) ys) xs)

  let find_dup (type a b) (key : a -> b) (xs : a list) : (a * a) option =
    let module M = Map.Make(struct
        type t = b
        let compare (x : b) (y : b) = (Pervasives.compare x y)
      end) in

    let module E = struct exception Found of a * a end in

    try
      let _ : a M.t =
        let doit map v =
          let udp =
            function None -> Some v | Some v' -> raise (E.Found (v', v))
          in M.update (key v) udp map
        in List.fold_left doit M.empty xs
      in
      None

    with E.Found (x, y) -> Some (x, y)

  let undup (type a b) (key : a -> b) (xs : a list) =
    let module M = Set.Make(struct
        type t = b
        let compare = (Pervasives.compare : t -> t -> int)
      end) in

    List.rev (snd (List.fold_left (fun (seen, acc) x ->
        let k = key x in
        (M.add k seen, (if M.mem k seen then acc else x :: acc))
      ) (M.empty, []) xs))

  let xfilter f =
    let rec doit (accl, accr) = function
      | [] ->
        (List.rev accl, List.rev accr)
      | x :: xs -> begin
          match f x with
          | `Left  y -> doit (y :: accl, accr) xs
          | `Right y -> doit (accl, y :: accr) xs
        end

    in fun xs -> doit ([], []) xs

  let fold_left_map f state xs =
    let state, xs =
      List.fold_left (fun (state, acc) x ->
          let state, x = f state x in (state, x :: acc)
        ) (state, []) xs in

    (state, List.rev xs)

  let assoc_all (v : 'a) (xs : ('a * 'b) list) =
    pmap (fun (x, y) -> if x = v then Some y else None) xs

  module Exn = struct
    let assoc x xs =
      try Some (List.assoc x xs) with Not_found -> None
  end
end

(* -------------------------------------------------------------------- *)
module Map : sig
  module type OrderedType = Map.OrderedType

  module Make(S : OrderedType) : sig
    include module type of Map.Make(S)

    val of_list : ?last:bool -> (key * 'a) list -> 'a t
    val collect : ('a -> key) -> ('a * 'b list) list -> ('a * 'b list) list
  end
end = struct
  module type OrderedType = Map.OrderedType

  module Make(S : OrderedType) = struct
    include Map.Make(S)

    let of_list ?(last = false) xs =
      let upd v old =
        if last || Option.is_none old then Some v else old in
      List.fold_left (fun map (k, v) -> update k (upd v) map) empty xs

    let collect (type a b) (key : a -> key) (xs : (a * b list) list) =
      let map =
        List.fold_left (fun map (k, v) ->
            update (key k) (fun v'-> Some (Option.get_dfl [] v' @ v)) map
          ) empty xs in

      List.map
        (fun k -> (k, find (key k) map))
        (List.undup key (List.map fst xs))
  end
end

(* -------------------------------------------------------------------- *)
module Set = Set

(* -------------------------------------------------------------------- *)
let norm_hex_string (s : string) =
  if String.starts ~pattern:"0x" s then s else "0x" ^ s

let int_of_hex (s : string) =
  int_of_string (norm_hex_string s)

let sha s : int =
  let s = Digestif.SHA1.to_hex (Digestif.SHA1.digest_string s) in
  int_of_hex (String.sub s 0 5)
