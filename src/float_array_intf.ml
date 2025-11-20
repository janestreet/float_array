(** Mutable vector of [float]s with O(1) [get] and [set] operations. The individual
    [float]s within a value of type [t] are stored unboxed.

    There is no literal syntax in the language for these arrays. Use [empty], [of_list],
    [of_array], etc. to construct them. *)

open Core

module type S = sig @@ portable
  type float_elt
  type t [@@deriving bin_io ~localize, compare ~localize, globalize, sexp]

  val custom_sexp_of_t : (float_elt -> Sexp.t) -> t -> Sexp.t
  val custom_t_of_sexp : (Sexp.t -> float_elt) -> Sexp.t -> t

  include Binary_searchable.S with type t := t with type elt := float_elt
  include Container.S0 with type t := t with type elt := float_elt

  val length : local_ t -> int

  (** The empty array. *)
  val empty : t

  (** Create a floatarray from a normal array of boxed floats. *)
  val of_array : float_elt array -> t

  (** Maximum length of a normal array. The maximum length of a float array is
      [max_length/2] on 32-bit machines and [max_length] on 64-bit machines. *)
  val max_length : int

  (** [Float_array.get a n] returns the element number [n] of array [a]. The first element
      has number 0. The last element has number [Float_array.length a - 1].

      Raise [Invalid_argument "index out of bounds"] if [n] is outside the range 0 to
      [(Float_array.length a - 1)]. *)
  val get : local_ t -> int -> float_elt

  (** [Float_array.set a n x] modifies array [a] in place, replacing element number [n]
      with [x].

      Raise [Invalid_argument "index out of bounds"] if [n] is outside the range 0 to
      [Float_array.length a - 1]. *)
  external set : local_ t -> int -> local_ float_elt -> unit = "%floatarray_safe_set"

  (** Unsafe version of [get]. Can cause arbitrary behavior when used for an out-of-bounds
      array access. *)
  val unsafe_get : local_ t -> int -> float_elt

  (** Unsafe version of [set]. Can cause arbitrary behavior when used for an out-of-bounds
      array access. *)
  external unsafe_set
    :  local_ t
    -> int
    -> local_ float_elt
    -> unit
    = "%floatarray_unsafe_set"

  (** [create ~len x] creates an array of length [len] with the value [x] populated in
      each element. *)
  val create : len:int -> float_elt -> t

  (** [create_local ~len x] is like [create]. It allocates the array on the local stack.
      The array's elements are still global. *)
  val create_local : len:int -> float_elt -> local_ t

  (** [init n ~f] creates an array of length [n] where the [i]th element (starting at
      zero) is initialized with [f i]. *)
  val init : int -> f:(int -> float_elt) -> t

  (** [Float_array.make_matrix dimx dimy e] returns a two-dimensional array (an array of
      arrays) with first dimension [dimx] and second dimension [dimy]. All the elements of
      this new matrix are initially physically equal to [e].

      Raise [Invalid_argument] if [dimx] or [dimy] is negative or greater than
      [Float_array.max_length / 2]. *)
  val make_matrix : dimx:int -> dimy:int -> float_elt -> t Array.t

  (** [Float_array.append v1 v2] returns a fresh array containing the concatenation of the
      arrays [v1] and [v2]. *)
  val append : t -> t -> t

  (** Like [Float_array.append], but concatenates a list of arrays. *)
  val concat : t list -> t

  (** [Float_array.copy a] returns a copy of [a], that is, a fresh array containing the
      same elements as [a]. *)
  val copy : local_ t -> t

  (** [Float_array.fill a ofs len x] modifies the array [a] in place, storing [x] in
      elements number [ofs] to [ofs + len - 1].

      Raise [Invalid_argument "Float_array.fill"] if [ofs] and [len] do not designate a
      valid subarray of [a]. *)
  val fill : t -> pos:int -> len:int -> float_elt -> unit

  (** [Float_array.blit v1 o1 v2 o2 len] copies [len] elements from array [v1], starting
      at element number [o1], to array [v2], starting at element number [o2]. It works
      correctly even if [v1] and [v2] are the same array, and the source and destination
      chunks overlap.

      Raise [Invalid_argument "Float_array.blit"] if [o1] and [len] do not designate a
      valid subarray of [v1], or if [o2] and [len] do not designate a valid subarray of
      [v2].

      The unsafe versions do not bound-check the arguments. *)
  include Blit.S with type t := t

  (** [Float_array.of_list l] returns a fresh array containing the elements of [l]. *)
  val of_list : float_elt list -> t

  (** [Float_array.map t ~f] applies function [f] to all the elements of [t], and builds
      an array with the results returned by [f]:
      [[| f t.(0); f t.(1); ...; f t.(Float_array.length t - 1) |]]. *)
  val map : t -> f:(float_elt -> float_elt) -> t

  (** [folding_map] is a version of [map] that threads an accumulator through calls to
      [f]. *)
  val folding_map : t -> init:'a -> f:('a -> float_elt -> 'a * float_elt) -> t

  val folding_mapi : t -> init:'a -> f:(int -> 'a -> float_elt -> 'a * float_elt) -> t

  (** [Float_array.fold_map] is a combination of [Float_array.fold] and [Float_array.map]
      that threads an accumulator through calls to [f]. *)
  val fold_map : t -> init:'a -> f:('a -> float_elt -> 'a * float_elt) -> 'a * t

  val fold_mapi : t -> init:'a -> f:(int -> 'a -> float_elt -> 'a * float_elt) -> 'a * t

  (** Like {!Float_array.iter}, but the function is applied to the index of the element as
      first argument, and the element itself as second argument. *)
  val iteri : t -> f:(int -> float_elt -> unit) -> unit

  (** Like {!Float_array.map}, but the function is applied to the index of the element as
      first argument, and the element itself as second argument. *)
  val mapi : t -> f:(int -> float_elt -> float_elt) -> t

  val foldi : t -> init:'a -> f:(int -> 'a -> float_elt -> 'a) -> 'a

  (** [Float_array.fold_right f a ~init] computes
      [f a.(0) (f a.(1) ( ... (f a.(n-1) init) ...))], where [n] is the length of the
      array [a]. *)
  val fold_right : t -> f:(float_elt -> 'a -> 'a) -> init:'a -> 'a

  (** All sort functions in this module sort in increasing order by default. *)

  (** [sort] uses constant heap space. [stable_sort] uses linear heap space.

      To sort only part of the array, specify [pos] to be the index to start sorting from
      and [len] indicating how many elements to sort. *)
  val sort : ?pos:int -> ?len:int -> t -> compare:(float_elt -> float_elt -> int) -> unit

  val stable_sort : t -> compare:(float_elt -> float_elt -> int) -> unit
  val is_sorted : t -> compare:(float_elt -> float_elt -> int) -> bool

  (** [is_sorted_strictly xs ~compare] iff [is_sorted xs ~compare] and no two consecutive
      elements in [xs] are equal according to [compare]. *)
  val is_sorted_strictly : t -> compare:(float_elt -> float_elt -> int) -> bool

  (** Like [List.concat_map], [List.concat_mapi]. *)
  val concat_map : t -> f:(float_elt -> t) -> t

  val concat_mapi : t -> f:(int -> float_elt -> t) -> t
  val partition_tf : t -> f:(float_elt -> bool) -> t * t
  val partitioni_tf : t -> f:(int -> float_elt -> bool) -> t * t
  val cartesian_product : t -> t -> (float_elt * float_elt) Array.t

  (** [transpose] in the sense of a matrix transpose. It returns [None] if the arrays are
      not all the same length. *)
  val transpose : t Array.t -> t Array.t option

  val transpose_exn : t Array.t -> t Array.t

  (** [filter_opt array] returns a float array where [None] entries are omitted and
      [Some x] entries are replaced with [x]. Note that this changes the index at which
      elements will appear. *)
  val filter_opt : float_elt option Array.t -> t

  (** [filter_map ~f array] maps [f] over [array] and filters [None] out of the results. *)
  val filter_map : t -> f:(float_elt -> float_elt option) -> t

  (** Like [filter_map] but uses {!Float_array.mapi}. *)
  val filter_mapi : t -> f:(int -> float_elt -> float_elt option) -> t

  (** Like [for_all], but passes the index as an argument. *)
  val for_alli : t -> f:(int -> float_elt -> bool) -> bool

  (** Like [exists], but passes the index as an argument. *)
  val existsi : t -> f:(int -> float_elt -> bool) -> bool

  (** Like [count], but passes the index as an argument. *)
  val counti : t -> f:(int -> float_elt -> bool) -> int

  (** Functions with the 2 suffix raise an exception if the lengths of the two given
      arrays aren't the same. *)

  val iter2_exn : t -> t -> f:(float_elt -> float_elt -> unit) -> unit
  val map2_exn : t -> t -> f:(float_elt -> float_elt -> float_elt) -> t
  val fold2_exn : t -> t -> init:'c -> f:('c -> float_elt -> float_elt -> 'c) -> 'c

  (** [for_all2_exn t1 t2 ~f] fails if [length t1 <> length t2]. *)
  val for_all2_exn : t -> t -> f:(float_elt -> float_elt -> bool) -> bool

  (** [exists2_exn t1 t2 ~f] fails if [length t1 <> length t2]. *)
  val exists2_exn : t -> t -> f:(float_elt -> float_elt -> bool) -> bool

  (** [filter t ~f] removes the elements for which [f] returns false. *)
  val filter : t -> f:(float_elt -> bool) -> t

  (** Like [filter] except [f] also receives the index. *)
  val filteri : t -> f:(int -> float_elt -> bool) -> t

  (** [swap arr i j] swaps the value at index [i] with that at index [j]. *)
  val swap : t -> int -> int -> unit

  (** [rev_inplace t] reverses [t] in place. *)
  val rev_inplace : t -> unit

  (** [of_list_rev l] converts from list then reverses in place. *)
  val of_list_rev : float_elt list -> t

  (** [of_list_map l ~f] is the same as [of_list (List.map l ~f)]. *)
  val of_list_map : float_elt list -> f:(float_elt -> float_elt) -> t

  (** [of_list_mapi l ~f] is the same as [of_list (List.mapi l ~f)]. *)
  val of_list_mapi : float_elt list -> f:(int -> float_elt -> float_elt) -> t

  (** [of_list_rev_map l ~f] is the same as [of_list (List.rev_map l ~f)]. *)
  val of_list_rev_map : float_elt list -> f:(float_elt -> float_elt) -> t

  (** [of_list_rev_mapi l ~f] is the same as [of_list (List.rev_mapi l ~f)]. *)
  val of_list_rev_mapi : float_elt list -> f:(int -> float_elt -> float_elt) -> t

  (** Modifies an array in place, applying [f] to every element of the array *)
  val map_inplace : t -> f:(float_elt -> float_elt) -> unit

  (** [find_exn f t] returns the first [a] in [t] for which [f (get t i)] is true. It
      raises [Caml.Not_found] or [Not_found_s] if there is no such [a]. *)
  val find_exn : t -> f:(float_elt -> bool) -> float_elt

  (** Returns the first evaluation of [f] that returns [Some]. Raises [Caml.Not_found] or
      [Not_found_s] if [f] always returns [None]. *)
  val find_map_exn : t -> f:(float_elt -> 'a option) -> 'a

  (** [findi t f] returns the first index [i] of [t] for which [f i (get t i)] is true *)
  val findi : t -> f:(int -> float_elt -> bool) -> (int * float_elt) option

  (** [findi_exn t f] returns the first index [i] of [t] for which [f i (get t i)] is
      true. It raises [Caml.Not_found] or [Not_found_s] if there is no such element. *)
  val findi_exn : t -> f:(int -> float_elt -> bool) -> int * float_elt

  (** [find_mapi t f] is like [find_map] but passes the index as an argument. *)
  val find_mapi : t -> f:(int -> float_elt -> 'a option) -> 'a option

  (** [find_mapi_exn] is like [find_map_exn] but passes the index as an argument. *)
  val find_mapi_exn : t -> f:(int -> float_elt -> 'a option) -> 'a

  (** [find_consecutive_duplicate t ~equal] returns the first pair of consecutive elements
      [(a1, a2)] in [t] such that [equal a1 a2]. They are returned in the same order as
      they appear in [t]. *)
  val find_consecutive_duplicate
    :  t
    -> equal:(float_elt -> float_elt -> bool)
    -> (float_elt * float_elt) option

  (** [reduce f [a1; ...; an]] is [Some (f (... (f (f a1 a2) a3) ...) an)]. Returns [None]
      on the empty array. *)
  val reduce : t -> f:(float_elt -> float_elt -> float_elt) -> float_elt option

  val reduce_exn : t -> f:(float_elt -> float_elt -> float_elt) -> float_elt

  (** [permute ?random_state t] randomly permutes [t] in place.

      [permute] side-effects [random_state] by repeated calls to [Random.State.int]. If
      [random_state] is not supplied, [permute] uses [Random.State.default]. *)
  val permute : ?random_state:Random.State.t -> t -> unit

  (** [random_element ?random_state t] is [None] if [t] is empty, else it is [Some x] for
      some [x] chosen uniformly at random from [t].

      [random_element] side-effects [random_state] by calling [Random.State.int]. If
      [random_state] is not supplied, [random_element] uses [Random.State.default]. *)
  val random_element : ?random_state:Random.State.t -> t -> float_elt option

  val random_element_exn : ?random_state:Random.State.t -> t -> float_elt

  (** [zip] is like [List.zip], but for arrays. *)
  val zip : t -> t -> (float_elt * float_elt) Array.t option

  val zip_exn : t -> t -> (float_elt * float_elt) Array.t

  (** [unzip] is like [List.unzip], but for arrays. *)
  val unzip : (float_elt * float_elt) Array.t -> t * t

  (** [sorted_copy ar compare] returns a shallow copy of [ar] that is sorted. Similar to
      List.sort *)
  val sorted_copy : t -> compare:(float_elt -> float_elt -> int) -> t

  val last : t -> float_elt
  val equal : (float_elt -> float_elt -> bool) -> t -> t -> bool

  (** The input array is copied internally so that future modifications of it do not
      change the sequence. *)
  val to_sequence : t -> float_elt Sequence.t

  (** The input array is shared with the sequence and modifications of it will result in
      modification of the sequence. *)
  val to_sequence_mutable : t -> float_elt Sequence.t
end

module type Permissioned = sig
  type float_elt
  type permissionless
  type -'perms t [@@deriving bin_io ~localize, compare ~localize, globalize, sexp]

  val of_array_id : permissionless -> [< read_write ] t [@@zero_alloc]
  val to_array_id : [> read_write ] t -> permissionless [@@zero_alloc]

  (** [to_sequence_immutable t] converts [t] to a sequence. Unlike [to_sequence],
      [to_sequence_immutable] does not need to copy [t] since it is immutable. *)
  val to_sequence_immutable : [> immutable ] t -> float_elt Sequence.t

  include
    Container.S0_permissions with type 'perms t := 'perms t and type elt := float_elt

  include Blit.S_permissions with type 'perms t := 'perms t

  include
    Binary_searchable.S0_permissions
    with type 'perms t := 'perms t
     and type elt := float_elt

  (** These functions are in [Container.S1_permissions], but they are re-exposed here so
      that their types can be changed to make them more permissive (see comment above). *)

  val length : local_ _ t -> int
  val is_empty : _ t -> bool

  (** counterparts of regular array functions above *)

  val get : local_ [> read ] t -> int -> float_elt

  external set
    :  local_ [> write ] t
    -> int
    -> local_ float
    -> unit
    = "%floatarray_safe_set"

  val unsafe_get : local_ [> read ] t -> int -> float_elt

  external unsafe_set
    :  local_ [> write ] t
    -> int
    -> local_ float
    -> unit
    = "%floatarray_unsafe_set"

  val create : len:int -> float_elt -> [< _ perms ] t
  val init : int -> f:(int -> float_elt) -> [< _ perms ] t
  val make_matrix : dimx:int -> dimy:int -> float_elt -> [< _ perms ] t Array.t
  val append : [> read ] t -> [> read ] t -> [< _ perms ] t
  val concat : [> read ] t list -> [< _ perms ] t
  val copy : [> read ] t -> [< _ perms ] t
  val fill : [> write ] t -> pos:int -> len:int -> float_elt -> unit
  val of_list : float_elt list -> [< _ perms ] t
  val map : [> read ] t -> f:(float_elt -> float_elt) -> [< _ perms ] t
  val mapi : [> read ] t -> f:(int -> float_elt -> float_elt) -> [< _ perms ] t

  val folding_map
    :  [> read ] t
    -> init:'a
    -> f:('a -> float_elt -> 'a * float_elt)
    -> [< _ perms ] t

  val iteri : [> read ] t -> f:(int -> float_elt -> unit) -> unit
  val foldi : [> read ] t -> init:'a -> f:(int -> 'a -> float_elt -> 'a) -> 'a

  val folding_mapi
    :  [> read ] t
    -> init:'a
    -> f:(int -> 'a -> float_elt -> 'a * float_elt)
    -> [< _ perms ] t

  val fold_right : [> read ] t -> f:(float_elt -> 'a -> 'a) -> init:'a -> 'a

  val sort
    :  ?pos:int
    -> ?len:int
    -> [> read_write ] t
    -> compare:(float_elt -> float_elt -> int)
    -> unit

  val stable_sort : [> read_write ] t -> compare:(float_elt -> float_elt -> int) -> unit
  val is_sorted : [> read ] t -> compare:(float_elt -> float_elt -> int) -> bool
  val is_sorted_strictly : [> read ] t -> compare:(float_elt -> float_elt -> int) -> bool
  val concat_map : [> read ] t -> f:(float_elt -> [> read ] t) -> [< _ perms ] t
  val concat_mapi : [> read ] t -> f:(int -> float_elt -> [> read ] t) -> [< _ perms ] t

  val partition_tf
    :  [> read ] t
    -> f:(float_elt -> bool)
    -> [< _ perms ] t * [< _ perms ] t

  val partitioni_tf
    :  [> read ] t
    -> f:(int -> float_elt -> bool)
    -> [< _ perms ] t * [< _ perms ] t

  val cartesian_product : [> read ] t -> [> read ] t -> (float_elt * float_elt) Array.t
  val transpose : [> read ] t Array.t -> [< _ perms ] t Array.t option
  val transpose_exn : [> read ] t Array.t -> [< _ perms ] t Array.t
  val filter_opt : float_elt option Array.t -> [< _ perms ] t
  val filter_map : [> read ] t -> f:(float_elt -> float_elt option) -> [< _ perms ] t

  val filter_mapi
    :  [> read ] t
    -> f:(int -> float_elt -> float_elt option)
    -> [< _ perms ] t

  val for_alli : [> read ] t -> f:(int -> float_elt -> bool) -> bool
  val existsi : [> read ] t -> f:(int -> float_elt -> bool) -> bool
  val counti : [> read ] t -> f:(int -> float_elt -> bool) -> int
  val iter2_exn : [> read ] t -> [> read ] t -> f:(float_elt -> float_elt -> unit) -> unit

  val map2_exn
    :  [> read ] t
    -> [> read ] t
    -> f:(float_elt -> float_elt -> float_elt)
    -> [< _ perms ] t

  val fold2_exn
    :  [> read ] t
    -> [> read ] t
    -> init:'c
    -> f:('c -> float_elt -> float_elt -> 'c)
    -> 'c

  val for_all2_exn
    :  [> read ] t
    -> [> read ] t
    -> f:(float_elt -> float_elt -> bool)
    -> bool

  val exists2_exn
    :  [> read ] t
    -> [> read ] t
    -> f:(float_elt -> float_elt -> bool)
    -> bool

  val filter : [> read ] t -> f:(float_elt -> bool) -> [< _ perms ] t
  val filteri : [> read ] t -> f:(int -> float_elt -> bool) -> [< _ perms ] t
  val swap : [> read_write ] t -> int -> int -> unit
  val rev_inplace : [> read_write ] t -> unit
  val of_list_rev : float_elt list -> [< _ perms ] t
  val of_list_map : float_elt list -> f:(float_elt -> float_elt) -> [< _ perms ] t
  val of_list_mapi : float_elt list -> f:(int -> float_elt -> float_elt) -> [< _ perms ] t
  val of_list_rev_map : float_elt list -> f:(float_elt -> float_elt) -> [< _ perms ] t

  val of_list_rev_mapi
    :  float_elt list
    -> f:(int -> float_elt -> float_elt)
    -> [< _ perms ] t

  val map_inplace : [> read_write ] t -> f:(float_elt -> float_elt) -> unit
  val find_exn : [> read ] t -> f:(float_elt -> bool) -> float_elt
  val find_map_exn : [> read ] t -> f:(float_elt -> 'a option) -> 'a
  val findi : [> read ] t -> f:(int -> float_elt -> bool) -> (int * float_elt) option
  val findi_exn : [> read ] t -> f:(int -> float_elt -> bool) -> int * float_elt
  val find_mapi : [> read ] t -> f:(int -> float_elt -> 'a option) -> 'a option
  val find_mapi_exn : [> read ] t -> f:(int -> float_elt -> 'a option) -> 'a

  val find_consecutive_duplicate
    :  [> read ] t
    -> equal:(float_elt -> float_elt -> bool)
    -> (float_elt * float_elt) option

  val reduce : [> read ] t -> f:(float_elt -> float_elt -> float_elt) -> float_elt option
  val reduce_exn : [> read ] t -> f:(float_elt -> float_elt -> float_elt) -> float_elt
  val permute : ?random_state:Random.State.t -> [> read_write ] t -> unit
  val zip : [> read ] t -> [> read ] t -> (float_elt * float_elt) Array.t option
  val zip_exn : [> read ] t -> [> read ] t -> (float_elt * float_elt) Array.t
  val unzip : (float_elt * float_elt) Array.t -> [< _ perms ] t * [< _ perms ] t

  val sorted_copy
    :  [> read ] t
    -> compare:(float_elt -> float_elt -> int)
    -> [< _ perms ] t

  val last : [> read ] t -> float_elt
  val equal : (float_elt -> float_elt -> bool) -> [> read ] t -> [> read ] t -> bool
  val to_sequence : [> read ] t -> float_elt Sequence.t
  val to_sequence_mutable : [> read ] t -> float_elt Sequence.t
end

module type Float_array = sig @@ portable
  module type S = S
  module type Permissioned = Permissioned

  include S with type t = floatarray and type float_elt := float

  module Via_floatarray_optimization : sig
    (* We don't expose [of_array_id] and [to_array_id] in [Float_array.S] because [S.t] is
       abstract, and so the ["%identity"] version is not necessarily safe for all modules
       that otherwise implement this interface.

       Here, ["%identity"] is safe since [float array] and [floatarray] have the same
       representation in Flambda.

       These functions will also become incorrect when we delete the floatarray
       optimization (although they may be still be correct for converting to/from
       [float# array])
    *)
    [%%template:
    [@@@mode.default l = (global, local)]

    val of_array_id : float array @ l -> t @ l
    val to_array_id : t @ l -> float array @ l]
  end

  module Permissioned :
    Permissioned with type permissionless := t and type float_elt := float

  (**/**)

  (*_ See the Jane Street Style Guide for an explanation of [Private] submodules:

      https://opensource.janestreet.com/standards/#private-submodules *)
  module Private : sig
    module Sort : sig
      module type Sort = sig
        val sort : t -> compare:(float -> float -> int) -> left:int -> right:int -> unit
      end

      module Insertion_sort : Sort
      module Heap_sort : Sort

      module Intro_sort : sig
        include Sort

        val five_element_sort
          :  t
          -> compare:(float -> float -> int)
          -> int
          -> int
          -> int
          -> int
          -> int
          -> unit
      end
    end
  end
end
