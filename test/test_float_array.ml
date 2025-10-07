open! Base
open! Base_for_tests
open! Float_array
open! Expect_test_helpers_core

module%test [@tags "no-wasm"] Binary_searchable = Test_binary_searchable.Test (struct
    include Float_array

    type elt = float

    module For_test = struct
      let of_array = of_array
      let big = 420_000.
      let small = -420_000.
      let compare = Float.compare
    end
  end)

module%test Blit =
  Test_blit.Test
    (struct
      include Float

      let of_bool = function
        | true -> -42.0
        | false -> 42.0
      ;;
    end)
    (struct
      include Float_array

      let create ~len = create ~len 1.2345
      let get t pos = get t pos
      let set t pos value = set t pos value
    end)
    (Float_array)

module%test Sort = struct
  open Private.Sort

  module%test [@name "Intro_sort.five_element_sort"] _ = struct
    (* run [five_element_sort] on all permutations of an array of five elements *)

    let rec sprinkle x xs =
      (x :: xs)
      ::
      (match xs with
       | [] -> []
       | x' :: xs' -> List.map (sprinkle x xs') ~f:(fun sprinkled -> x' :: sprinkled))
    ;;

    let rec permutations = function
      | [] -> [ [] ]
      | x :: xs -> List.concat_map (permutations xs) ~f:(fun perms -> sprinkle x perms)
    ;;

    let all_perms = permutations [ 1.; 2.; 3.; 4.; 5. ]
    let%test _ = List.length all_perms = 120
    let%test _ = not (List.contains_dup ~compare:[%compare: float list] all_perms)

    let%test _ =
      List.for_all all_perms ~f:(fun l ->
        let arr = Float_array.of_list l in
        Intro_sort.five_element_sort arr ~compare:[%compare: float] 0 1 2 3 4;
        [%compare.equal: t] arr (of_list [ 1.; 2.; 3.; 4.; 5. ]))
    ;;
  end

  module Test (M : Private.Sort.Sort) = struct
    let random_data ~length ~range =
      let arr = Float_array.create ~len:length 0. in
      for i = 0 to length - 1 do
        set arr i (Float.of_int (Random.int range))
      done;
      arr
    ;;

    let assert_sorted arr =
      M.sort arr ~left:0 ~right:(Float_array.length arr - 1) ~compare:[%compare: float];
      let len = Float_array.length arr in
      let rec loop i prev =
        if i = len
        then true
        else if Float.( < ) (get arr i) prev
        then false
        else loop (i + 1) (get arr i)
      in
      loop 0 (-1.)
    ;;

    let%test _ = assert_sorted (random_data ~length:0 ~range:100)
    let%test _ = assert_sorted (random_data ~length:1 ~range:100)
    let%test _ = assert_sorted (random_data ~length:100 ~range:1_000)
    let%test _ = assert_sorted (random_data ~length:1_000 ~range:1)
    let%test _ = assert_sorted (random_data ~length:1_000 ~range:10)
    let%test _ = assert_sorted (random_data ~length:1_000 ~range:1_000_000)
  end

  module%test _ = Test (Insertion_sort)
  module%test _ = Test (Heap_sort)
  module%test _ = Test (Intro_sort)
end

let%test _ = is_sorted empty ~compare:[%compare: float]
let%test _ = is_sorted (of_list [ 0. ]) ~compare:[%compare: float]
let%test _ = is_sorted (of_list [ 0.; 1.; 2.; 2.; 4. ]) ~compare:[%compare: float]
let%test _ = not (is_sorted (of_list [ 0.; 1.; 2.; 3.; 2. ]) ~compare:[%compare: float])

let%test_unit _ =
  List.iter
    ~f:(fun (t, expect) ->
      assert (
        Bool.equal expect (is_sorted_strictly (of_list t) ~compare:[%compare: float])))
    [ [], true
    ; [ 1. ], true
    ; [ 1.; 2. ], true
    ; [ 1.; 1. ], false
    ; [ 2.; 1. ], false
    ; [ 1.; 2.; 3. ], true
    ; [ 1.; 1.; 3. ], false
    ; [ 1.; 2.; 2. ], false
    ]
;;

let%test _ = Float.( = ) (foldi empty ~init:13. ~f:(fun _ _ _ -> failwith "bad")) 13.

let%test _ =
  Float.( = )
    (foldi (of_list [ 13. ]) ~init:17. ~f:(fun i ac x -> ac +. Float.of_int i +. x))
    30.
;;

let%test _ =
  Float.( = )
    (foldi (of_list [ 13.; 17. ]) ~init:19. ~f:(fun i ac x -> ac +. Float.of_int i +. x))
    50.
;;

let%test _ =
  counti
    (of_list [ 0.; 1.; 2.; 3.; 4. ])
    ~f:(fun idx x -> Float.( = ) (Float.of_int idx) x)
  = 5
;;

let%test _ =
  counti
    (of_list [ 0.; 1.; 2.; 3.; 4. ])
    ~f:(fun idx x -> Float.( = ) (Float.of_int idx) (4. -. x))
  = 1
;;

let%test_unit _ =
  for i = 0 to 5 do
    let l1 = List.init i ~f:Float.of_int in
    let l2 = List.rev (to_list (of_list_rev l1)) in
    assert ([%compare.equal: float list] l1 l2)
  done
;;

let%test_unit _ =
  [%test_result: t]
    (filter_opt [| Some 1.; None; Some 2.; None; Some 3. |])
    ~expect:(of_list [ 1.; 2.; 3. ])
;;

let%test_unit _ =
  [%test_result: t] (filter_opt [| Some 1.; None; Some 2. |]) ~expect:(of_list [ 1.; 2. ])
;;

let%test_unit _ = [%test_result: t] (filter_opt [| Some 1. |]) ~expect:(of_list [ 1. ])
let%test_unit _ = [%test_result: t] (filter_opt [| None |]) ~expect:empty
let%test_unit _ = [%test_result: t] (filter_opt [||]) ~expect:empty

let%test_unit _ =
  [%test_result: float]
    (fold2_exn empty empty ~init:13. ~f:(fun _ -> failwith "fail"))
    ~expect:13.
;;

let%test_unit _ =
  [%test_result: (float * float) list]
    (fold2_exn (of_list [ 1. ]) (of_list [ 2. ]) ~init:[] ~f:(fun ac a b -> (a, b) :: ac))
    ~expect:[ 1., 2. ]
;;

let%test_unit _ =
  [%test_result: t]
    (filter (of_list [ 0.; 1. ]) ~f:(fun n -> Float.( < ) n 2.))
    ~expect:(of_list [ 0.; 1. ])
;;

let%test_unit _ =
  [%test_result: t]
    (filter (of_list [ 0.; 1. ]) ~f:(fun n -> Float.( < ) n 1.))
    ~expect:(of_list [ 0. ])
;;

let%test_unit _ =
  [%test_result: t]
    (filter (of_list [ 0.; 1. ]) ~f:(fun n -> Float.( < ) n 0.))
    ~expect:empty
;;

let%test_unit _ = [%test_result: bool] (exists empty ~f:(fun _ -> true)) ~expect:false

let%test_unit _ =
  [%test_result: bool]
    (exists (of_list [ 0.; 1.; 2.; 3. ]) ~f:(fun x -> Float.( = ) 4. x))
    ~expect:false
;;

let%test_unit _ =
  [%test_result: bool]
    (exists (of_list [ 0.; 1.; 2.; 3. ]) ~f:(fun x -> Float.( = ) 2. x))
    ~expect:true
;;

let%test_unit _ = [%test_result: bool] (existsi empty ~f:(fun _ _ -> true)) ~expect:false

let%test_unit _ =
  [%test_result: bool]
    (existsi (of_list [ 0.; 1.; 2.; 3. ]) ~f:(fun i x -> Float.( <> ) (Float.of_int i) x))
    ~expect:false
;;

let%test_unit _ =
  [%test_result: bool]
    (existsi (of_list [ 0.; 1.; 3.; 3. ]) ~f:(fun i x -> Float.( <> ) (Float.of_int i) x))
    ~expect:true
;;

let%test_unit _ = [%test_result: bool] (for_all empty ~f:(fun _ -> false)) ~expect:true

let%test_unit _ =
  [%test_result: bool]
    (for_all (of_list [ 1.; 2.; 3. ]) ~f:Float.is_positive)
    ~expect:true
;;

let%test_unit _ =
  [%test_result: bool]
    (for_all (of_list [ 0.; 1.; 3.; 3. ]) ~f:Float.is_positive)
    ~expect:false
;;

let%test_unit _ = [%test_result: bool] (for_alli empty ~f:(fun _ _ -> false)) ~expect:true

let%test_unit _ =
  [%test_result: bool]
    (for_alli (of_list [ 0.; 1.; 2.; 3. ]) ~f:(fun i x -> Float.( = ) (Float.of_int i) x))
    ~expect:true
;;

let%test_unit _ =
  [%test_result: bool]
    (for_alli (of_list [ 0.; 1.; 3.; 3. ]) ~f:(fun i x -> Float.( = ) (Float.of_int i) x))
    ~expect:false
;;

let%test_unit _ =
  [%test_result: bool] (exists2_exn empty empty ~f:(fun _ _ -> true)) ~expect:false
;;

let%test_unit _ =
  [%test_result: bool]
    (exists2_exn
       (of_list [ 0.; 2.; 4.; 6. ])
       (of_list [ 0.; 2.; 4.; 6. ])
       ~f:(fun x y -> Float.( <> ) x y))
    ~expect:false
;;

let%test_unit _ =
  [%test_result: bool]
    (exists2_exn
       (of_list [ 0.; 2.; 4.; 8. ])
       (of_list [ 0.; 2.; 4.; 6. ])
       ~f:(fun x y -> Float.( <> ) x y))
    ~expect:true
;;

let%test_unit _ =
  [%test_result: bool]
    (exists2_exn
       (of_list [ 2.; 2.; 4.; 6. ])
       (of_list [ 0.; 2.; 4.; 6. ])
       ~f:(fun x y -> Float.( <> ) x y))
    ~expect:true
;;

let%test_unit _ =
  [%test_result: bool] (for_all2_exn empty empty ~f:(fun _ _ -> false)) ~expect:true
;;

let%test_unit _ =
  [%test_result: bool]
    (for_all2_exn
       (of_list [ 0.; 2.; 4.; 6. ])
       (of_list [ 0.; 2.; 4.; 6. ])
       ~f:(fun x y -> Float.( = ) x y))
    ~expect:true
;;

let%test_unit _ =
  [%test_result: bool]
    (for_all2_exn
       (of_list [ 0.; 2.; 4.; 8. ])
       (of_list [ 0.; 2.; 4.; 6. ])
       ~f:(fun x y -> Float.( = ) x y))
    ~expect:false
;;

let%test_unit _ =
  [%test_result: bool]
    (for_all2_exn
       (of_list [ 2.; 2.; 4.; 6. ])
       (of_list [ 0.; 2.; 4.; 6. ])
       ~f:(fun x y -> Float.( = ) x y))
    ~expect:false
;;

let%test_unit _ = [%test_result: bool] (equal Float.( = ) empty empty) ~expect:true

let%test_unit _ =
  [%test_result: bool] (equal Float.( = ) (of_list [ 1. ]) (of_list [ 1. ])) ~expect:true
;;

let%test_unit _ =
  [%test_result: bool]
    (equal Float.( = ) (of_list [ 1.; 2. ]) (of_list [ 1.; 2. ]))
    ~expect:true
;;

let%test_unit _ =
  [%test_result: bool] (equal Float.( = ) empty (of_list [ 1. ])) ~expect:false
;;

let%test_unit _ =
  [%test_result: bool] (equal Float.( = ) (of_list [ 1. ]) empty) ~expect:false
;;

let%test_unit _ =
  [%test_result: bool]
    (equal Float.( = ) (of_list [ 1. ]) (of_list [ 1.; 2. ]))
    ~expect:false
;;

let%test_unit _ =
  [%test_result: bool]
    (equal Float.( = ) (of_list [ 1.; 2. ]) (of_list [ 1.; 3. ]))
    ~expect:false
;;

let%test_unit _ =
  [%test_result: (int * float) option]
    (findi
       (of_list [ 1.; 2.; 3.; 4. ])
       ~f:(fun i x -> Float.( = ) (Float.of_int i) (2. *. x)))
    ~expect:None
;;

let%test_unit _ =
  [%test_result: (int * float) option]
    (findi
       (of_list [ 1.; 2.; 1.; 4. ])
       ~f:(fun i x -> Float.( = ) (Float.of_int i) (2. *. x)))
    ~expect:(Some (2, 1.))
;;

let%test_unit _ =
  [%test_result: float option]
    (find_mapi
       (of_list [ 0.; 5.; 2.; 1.; 4. ])
       ~f:(fun i x ->
         let i = Float.of_int i in
         if Float.( = ) i x then Some (i +. x) else None))
    ~expect:(Some 0.)
;;

let%test_unit _ =
  [%test_result: float option]
    (find_mapi
       (of_list [ 3.; 5.; 2.; 1.; 4. ])
       ~f:(fun i x ->
         let i = Float.of_int i in
         if Float.( = ) i x then Some (i +. x) else None))
    ~expect:(Some 4.)
;;

let%test_unit _ =
  [%test_result: float option]
    (find_mapi
       (of_list [ 3.; 5.; 1.; 1.; 4. ])
       ~f:(fun i x ->
         let i = Float.of_int i in
         if Float.( = ) i x then Some (i +. x) else None))
    ~expect:(Some 8.)
;;

let%test_unit _ =
  [%test_result: float option]
    (find_mapi
       (of_list [ 3.; 5.; 1.; 1.; 2. ])
       ~f:(fun i x ->
         let i = Float.of_int i in
         if Float.( = ) i x then Some (i +. x) else None))
    ~expect:None
;;

let%test_unit _ =
  List.iter
    ~f:(fun (l, expect) ->
      let t = of_list l in
      assert (Poly.equal expect (find_consecutive_duplicate t ~equal:Poly.equal)))
    [ [], None
    ; [ 1. ], None
    ; [ 1.; 1. ], Some (1., 1.)
    ; [ 1.; 2. ], None
    ; [ 1.; 2.; 1. ], None
    ; [ 1.; 2.; 2. ], Some (2., 2.)
    ; [ 1.; 1.; 2.; 2. ], Some (1., 1.)
    ]
;;

let%test_unit _ = [%test_result: float option] (random_element empty) ~expect:None

let%test_unit _ =
  [%test_result: float option] (random_element (of_list [ 0. ])) ~expect:(Some 0.)
;;

let%test_unit _ =
  List.iter
    [ empty; of_list [ 1. ]; of_list [ 1.; 2.; 3.; 4.; 5. ] ]
    ~f:(fun t ->
      [%test_result: float array] (Sequence.to_array (to_sequence t)) ~expect:(to_array t))
;;

let test_fold_map array ~init ~f ~expect =
  [%test_result: t] (folding_map array ~init ~f) ~expect:(snd expect);
  [%test_result: float * t] (fold_map array ~init ~f) ~expect
;;

let test_fold_mapi array ~init ~f ~expect =
  [%test_result: t] (folding_mapi array ~init ~f) ~expect:(snd expect);
  [%test_result: float * t] (fold_mapi array ~init ~f) ~expect
;;

let%test_unit _ =
  test_fold_map
    (of_list [ 1.; 2.; 3.; 4. ])
    ~init:0.
    ~f:(fun acc x ->
      let y = acc +. x in
      y, y)
    ~expect:(10., of_list [ 1.; 3.; 6.; 10. ])
;;

let%test_unit _ =
  test_fold_map
    empty
    ~init:0.
    ~f:(fun acc x ->
      let y = acc +. x in
      y, y)
    ~expect:(0., empty)
;;

let%test_unit _ =
  test_fold_mapi
    (of_list [ 1.; 2.; 3.; 4. ])
    ~init:0.
    ~f:(fun i acc x ->
      let y = acc +. (Float.of_int i *. x) in
      y, y)
    ~expect:(20., of_list [ 0.; 2.; 8.; 20. ])
;;

let%test_unit _ =
  test_fold_mapi
    empty
    ~init:0.
    ~f:(fun i acc x ->
      let y = acc +. (Float.of_int i *. x) in
      y, y)
    ~expect:(0., empty)
;;

module%test [@name "create_local length check"] _ = struct
  (* wasm/javascript/native have different exception messages *)

  let run () = require_does_raise (fun () -> ignore (create_local ~len:(-1) 0.0 : t))

  let%expect_test (_ [@tags "no-js"]) =
    run ();
    [%expect {| (Invalid_argument "Float_array.create_local ~len:-1: invalid length") |}]
  ;;

  let%expect_test ("create_local length check (javascript)" [@tags "js-only", "no-wasm"]) =
    run ();
    [%expect {| (Invalid_argument "index out of bounds") |}]
  ;;

  let%expect_test ("create_local length check (wasm)" [@tags "wasm-only"]) =
    run ();
    [%expect {| (Invalid_argument Array.make) |}]
  ;;
end

let%test_unit "create_local (safe accesses)" =
  let rec test ~len =
    if len = 1_000
    then ()
    else (
      let arr = create_local ~len 1. in
      for i = 0 to len - 1 do
        set arr i (Float.of_int i)
      done;
      test ~len:(len + 1);
      for i = 0 to len - 1 do
        [%test_result: float] (get arr i) ~expect:(Float.of_int i)
      done)
  in
  test ~len:0
;;

let%test_unit "create_local (unsafe accesses)" =
  let rec test ~len =
    if len = 1_000
    then ()
    else (
      let arr = create_local ~len 1. in
      for i = 0 to len - 1 do
        unsafe_set arr i (Float.of_int i)
      done;
      test ~len:(len + 1);
      for i = 0 to len - 1 do
        [%test_result: float] (unsafe_get arr i) ~expect:(Float.of_int i)
      done)
  in
  test ~len:0
;;

let%test "{to_of}_array_id" =
  let arr' = [| 1.; 2.; 3.; 4. |] in
  let t = Via_floatarray_optimization.of_array_id arr' in
  let r1 = for_alli t ~f:(fun i x -> [%compare.equal: float] x (Array.get arr' i)) in
  let arr = Via_floatarray_optimization.to_array_id t in
  let r2 = for_alli t ~f:(fun i x -> [%compare.equal: float] x (Array.get arr i)) in
  r1 && r2
;;

let%test_unit "custom sexp round trips" =
  let sexp_of_elt x = Sexp.List [ Float.sexp_of_t x ] in
  let elt_of_sexp = function
    | Sexp.List [ x ] -> Float.t_of_sexp x
    | _ -> failwith "bad sexp"
  in
  let arr = of_list [ 0.; 2.; 4.; 6. ] in
  let roundtripped = custom_sexp_of_t sexp_of_elt arr |> custom_t_of_sexp elt_of_sexp in
  [%test_result: t] roundtripped ~expect:arr
;;
