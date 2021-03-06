(* nat: fonctions auxiliaires et d'impression pour le type nat.
   Derive de nats.ml de Caml V3.1, Vale'rie Me'nissier.
   Adapte a Caml Light par Xavier Leroy. *)

#open "eq";;
#open "exc";;
#open "int";;
#open "bool";;
#open "ref";;
#open "fstring";;
#open "fvect";;
#open "fchar";;
#open "int_misc";;

let length_of_digit = 32;;

let make_nat len =
  if len < 0 then invalid_arg "make_nat" else
    let res = create_nat len in set_to_zero_nat res 0 len; res
;;

let copy_nat nat off_set length =
 let res = create_nat (length) in
  blit_nat res 0 nat off_set length; 
  res
;;

let is_zero_nat n off len =
  compare_nat (make_nat 1) 0 1 n off (num_digits_nat n off len) == 0 
;;

let is_nat_int nat off len =
  num_digits_nat nat off len == 1 & is_digit_int nat off
;;

let sys_int_of_nat nat off len =
  if is_nat_int nat off len
  then nth_digit_nat nat off
  else failwith "int_of_nat"
;;

let int_of_nat nat =
  sys_int_of_nat nat 0 (length_nat nat)
;;

let nat_of_int i =
  if i < 0 then invalid_arg "nat_of_int" else
    let res = make_nat 1 in
    if i == 0 then res else begin set_digit_nat res 0 i; res end
;;

let eq_nat nat1 off1 len1 nat2 off2 len2 =
  compare_nat nat1 off1 (num_digits_nat nat1 off1 len1)
              nat2 off2 (num_digits_nat nat2 off2 len2) == 0
and le_nat nat1 off1 len1 nat2 off2 len2 =
  compare_nat nat1 off1 (num_digits_nat nat1 off1 len1)
              nat2 off2 (num_digits_nat nat2 off2 len2) <= 0
and lt_nat nat1 off1 len1 nat2 off2 len2 =
  compare_nat nat1 off1 (num_digits_nat nat1 off1 len1)
              nat2 off2 (num_digits_nat nat2 off2 len2) < 0
and ge_nat nat1 off1 len1 nat2 off2 len2 =
  compare_nat nat1 off1 (num_digits_nat nat1 off1 len1)
              nat2 off2 (num_digits_nat nat2 off2 len2) >= 0
and gt_nat nat1 off1 len1 nat2 off2 len2 =
  compare_nat nat1 off1 (num_digits_nat nat1 off1 len1)
              nat2 off2 (num_digits_nat nat2 off2 len2) > 0
;;

let square_nat nat1 off1 len1 nat2 off2 len2 =
  let c = ref 0 
  and trash = make_nat 1 in
    (* Double product *)
    for i = 0 to len2 - 2 do
        c := !c + mult_digit_nat 
                         nat1
                         (succ (off1 + 2 * i))
                         (2 * (pred (len2 - i)))
                         nat2 
                         (succ (off2 + i))
                         (pred (len2 - i))
                         nat2
                         (off2 + i)
    done;
    shift_left_nat nat1 0 len1 trash 0 1;
    (* Square of digit *)
    for i = 0 to len2 - 1 do
        c := !c + mult_digit_nat 
                         nat1 
                         (off1 + 2 * i)
                         (len1 - 2 * i)
                         nat2
                         (off2 + i)
                         1
                         nat2
                         (off2 + i)
    done;
  !c
;;

let gcd_int_nat i nat off len = 
  if i == 0 then 1 else
  if is_nat_int nat off len then begin
    set_digit_nat nat off (gcd_int (nth_digit_nat nat off) i); 0
  end else begin
    let len_copy = succ len in
    let copy = create_nat len_copy 
    and quotient = create_nat 1 
    and remainder = create_nat 1 in
    blit_nat copy 0 nat off len;
    set_digit_nat copy len 0;
    div_digit_nat quotient 0 remainder 0 copy 0 len_copy (nat_of_int i) 0;
    set_digit_nat nat off (gcd_int (nth_digit_nat remainder 0) i);
    0
  end
;;

let exchange r1 r2 =
  let old1 = !r1 in r1 := !r2; r2 := old1
;;

let gcd_nat nat1 off1 len1 nat2 off2 len2 =
  if is_zero_nat nat1 off1 len1 then begin
    blit_nat nat1 off1 nat2 off2 len2; len2
  end else begin
    let copy1 = ref (create_nat (succ len1))
    and copy2 = ref (create_nat (succ len2)) in
      blit_nat !copy1 0 nat1 off1 len1;
      blit_nat !copy2 0 nat2 off2 len2;
      set_digit_nat !copy1 len1 0;
      set_digit_nat !copy2 len2 0;
      if lt_nat !copy1 0 len1 !copy2 0 len2
         then exchange copy1 copy2;
      let real_len1 = 
            ref (num_digits_nat !copy1 0 (length_nat !copy1))
      and real_len2 = 
            ref (num_digits_nat !copy2 0 (length_nat !copy2)) in
      while not (is_zero_nat !copy2 0 !real_len2) do
        set_digit_nat !copy1 !real_len1 0;
        div_nat !copy1 0 (succ !real_len1) !copy2 0 !real_len2;
        exchange copy1 copy2;
        real_len1 := !real_len2;
        real_len2 := num_digits_nat !copy2 0 !real_len2
      done;                
      blit_nat nat1 off1 !copy1 0 !real_len1;
      !real_len1
  end
;;

let sqrt_nat nat off len = 
 let size_copy = succ len in
 let size_sqrt = len / 2 + len mod 2 in
 let candidate = make_nat (size_sqrt) 
 and beginning = make_nat (size_sqrt) in
  set_digit_nat candidate (size_sqrt - 1) 1;
  shift_left_nat candidate (size_sqrt - 1) 1 beginning 0
    (((if eq_int (len mod 2) 0 then 31 else 15) -
      num_leading_zero_bits_in_digit nat (off + len - 1)) / 2);
 let size_aux = size_copy - size_sqrt in
 let copy = create_nat size_copy in
 let aux = make_nat size_aux in
  set_digit_nat copy len 0;
  blit_nat copy 0 nat off len;
  div_nat copy 0 size_copy candidate 0 size_sqrt;
  blit_nat aux 0 copy size_sqrt size_aux;
  add_nat aux 0 size_aux candidate 0 (num_digits_nat candidate 0 size_sqrt) 0;
  shift_right_nat aux 0 size_aux beginning 0 1;
  while not
    (eq_nat aux 0 (num_digits_nat aux 0 size_aux)
            candidate 0 (num_digits_nat candidate 0 size_sqrt))
  do
   blit_nat candidate 0 aux 0 size_aux;
   set_digit_nat copy len 0;
   blit_nat copy 0 nat off len;
   div_nat copy 0 size_copy candidate 0 size_sqrt;
   blit_nat aux 0 copy size_sqrt size_aux;
   add_nat aux 0 size_aux candidate 0 (num_digits_nat candidate 0 size_sqrt) 0;
   shift_right_nat aux 0 size_aux beginning 0 1
   done;
 candidate
;;

let power_base_max = make_nat 2;;

set_digit_nat power_base_max 0 10000; 
mult_digit_nat power_base_max 0 2 
               power_base_max 0 1 (nat_of_int 9999) 0;
mult_digit_nat power_base_max 0 2 
               power_base_max 0 1 (nat_of_int 9) 0;;

let pmax = 9;;

(* XL: j'ai specialise le code ci-dessous au cas length_of_digit = 32 *)

(****
let pmax =
  if eq_int length_of_digit 16 then begin
          set_digit_nat power_base_max 0 10000; 4
  end else if lt_int length_of_digit 20 then begin
          set_digit_nat power_base_max 0 3125;           
          shift_left_nat power_base_max 0 1 (nat_of_int 0) 0 5; 5
  end else if lt_int length_of_digit 24 then begin 
          set_digit_nat power_base_max 0 15625;           
          shift_left_nat power_base_max 0 1 (nat_of_int 0) 0 6; 6
  end else if lt_int length_of_digit 27 then begin 
          set_digit_nat power_base_max 0 10000; 
          mult_digit_nat power_base_max 0 2 
                         power_base_max 0 1 (nat_of_int 999) 0; 7
  end else if lt_int length_of_digit 30 then begin 
          set_digit_nat power_base_max 0 10000; 
          mult_digit_nat power_base_max 0 2 
                          power_base_max 0 1 (nat_of_int 9999) 0; 8
  end else begin
          set_digit_nat power_base_max 0 10000; 
          mult_digit_nat power_base_max 0 2 
                          power_base_max 0 1 (nat_of_int 9999) 0;
          mult_digit_nat power_base_max 0 2 
                          power_base_max 0 1 (nat_of_int 9) 0; 9
  end
;;
*****)         

(* Nat temporaries *)
let A_2 = make_nat 2
and A_1 = make_nat 1 
and B_1 = make_nat 1 
and C_1 = make_nat 1 
and B_2 = make_nat 2 
;;

(* Nat constants *)
let nat_10_4 = nat_of_int 10000;;
(* Creation of 10^8 *)
let nat_10_8 = make_nat 2;;
set_digit_nat nat_10_8 0 10000;;
mult_digit_nat nat_10_8 0 2 nat_10_8 0 1 (nat_of_int 9999) 0;;

(* Print a digit into a temporary string *)
let raw_string_of_digit_vect =
    [| "00000"; "000000"; "0000000"; "00000000"; "000000000"; "0000000000" |];;

let raw_string_of_digit nat off =
  if is_nat_int nat off 1 then begin
           string_of_int (nth_digit_nat nat off)
  end else if lt_int (compare_digits_nat nat off nat_10_8 0) 0 then begin
         blit_nat B_2 0 nat off 1;
         div_digit_nat A_2 0 A_1 0 B_2 0 2 nat_10_4 0;
         begin
           let s1 = string_of_int (nth_digit_nat A_2 0) in
           let result =
             raw_string_of_digit_vect.(pred (string_length s1)) in
           fill_string result (string_length s1) 4 `0`;
           blit_string s1 0 result 0 4(*(string_length s1)*);
           let s2 = string_of_int (nth_digit_nat A_1 0) in
           blit_string s2 0 result
                       (sub_int (string_length result) (string_length s2))
                       4(*(string_length s2)*);
           result
         end
  end else begin
         blit_nat B_2 0 nat off 1;
         div_digit_nat A_2 0 A_1 0 B_2 0 2 nat_10_4 0;
         div_digit_nat B_1 0 C_1 0 A_2 0 2 nat_10_4 0;
         let leading_digits = nth_digit_nat B_1 0
         and s1 = string_of_int (nth_digit_nat C_1 0) in
         if lt_int leading_digits 10 then begin
              let result = raw_string_of_digit_vect.(4) in
              fill_string result 1 8 `0`;
              set_nth_char result 0 (char_of_int (add_int 48 leading_digits));
              blit_string s1 0
                          result (sub_int (sub_int 9 (string_length s1)) 4) 4;
              let s2 = string_of_int (nth_digit_nat A_1 0) in
              blit_string s2 0 result (sub_int 9 (string_length s2)) 4;
              result
         end else begin
              let result = raw_string_of_digit_vect.(5) in
              fill_string result 2 8 `0`;
              blit_string (string_of_int leading_digits) 0 result 0 2;
              blit_string s1 0 
                          result (sub_int (sub_int 10 (string_length s1)) 4) 4;
              let s2 = string_of_int (nth_digit_nat A_1 0) in
              blit_string s2 0 result (sub_int 10 (string_length s2)) 4;
              result
        end
  end
;;

(* XL: suppression de string_of_digit *)


let sys_string_of_digit nat off =
    let s = raw_string_of_digit nat off in
    let result = create_string (string_length s) in
    blit_string s 0 result 0 (string_length s);
    s
;;

(******

let string_of_digit nat =
    sys_string_of_digit nat 0
;;

*******)

let digits = "0123456789ABCDEF";;

(*
   make_power_base affecte power_base des puissances successives de base a` 
   partir de la puissance 1-ie`me.
   A la fin de la boucle i-1 est la plus grande puissance de la base qui tient 
   sur un seul digit et j est la plus grande puissance de la base qui tient 
   sur un int.
*)
let make_power_base base power_base = 
  let i = ref 0 
  and j = ref 0 in
   set_digit_nat power_base 0 base;
   while incr i; is_digit_zero power_base !i do
   mult_digit_nat power_base !i 2 
                  power_base (pred !i) 1 
                  power_base 0
   done;
   while !j <= !i & is_digit_int power_base !j do incr j done;
  (!i - 2, !j);;

(* 
   int_to_string place la repre'sentation de l'entier int en base base 
   dans la chaine s en le rangeant de la fin indique'e par pos vers le 
   debut, sur times places et affecte a` pos sa nouvelle valeur. 
*)
let int_to_string int s pos_ref base times = 
  let i = ref int 
  and j = ref times in
     while ((!i != 0) or (!j != 0)) & (!pos_ref != -1) do
        set_nth_char s !pos_ref (nth_char digits (!i mod base));
        decr pos_ref;
        decr j;
        i := !i / base
     done
;;

(* XL: suppression de adjust_string *)

let power_base_int base i = 
  if i == 0 then
    nat_of_int 1 
  else if i < 0 then
    invalid_arg "power_base_int"
  else begin
         let power_base = make_nat (succ length_of_digit) in
         let (pmax, pint) = make_power_base base power_base in
         let n = i / (succ pmax) 
         and rem = i mod (succ pmax) in
           if n > 0 then begin
               let newn =
                 if i == biggest_int then n else (succ n) in
               let res = make_nat newn
               and res2 = make_nat newn
               and l = num_bits_int n - 2 in
               let p = ref (1 lsl l) in
                 blit_nat res 0 power_base pmax 1;
                 for i = l downto 0 do
                   let len = num_digits_nat res 0 newn in
                   let len2 = min n (2 * len) in
                   let succ_len2 = succ len2 in
                     square_nat res2 0 len2 res 0 len;
                     if n land !p > 0 then begin
                       set_to_zero_nat res 0 len;
                       mult_digit_nat res 0 succ_len2 
                                      res2 0 len2 
                                      power_base pmax;
                       ()
                     end else
                       blit_nat res 0 res2 0 len2;
                     set_to_zero_nat res2 0 len2;
                     p := !p lsr 1
                 done;
               if rem > 0 then begin
                 mult_digit_nat res2 0 newn 
                                res 0 n power_base (pred rem);
                 res2
               end else res
            end else 
              copy_nat power_base (pred rem) 1
  end
;;

(* the ith element (i >= 2) of num_digits_max_vector is :
    |                                 |
    | biggest_string_length * log (i) |
    | ------------------------------- | + 1
    |      length_of_digit * log (2)  |
    --                               --
*)

(* XL: j'ai specialise le code d'origine a length_of_digit = 32. *)
(* Puis je l'ai supprime (inutile?) *)

(******
let num_digits_max_vector = 
  [|0; 0; 1024; 1623; 2048; 2378; 2647; 2875; 3072; 3246; 3402; 
              3543; 3671; 3789; 3899; 4001; 4096|];;

let num_digits_max_vector = 
   match length_of_digit with
     16 -> [|0; 0; 2048; 3246; 4096; 4755; 5294; 5749; 6144; 6492; 6803; 
              7085; 7342; 7578; 7797; 8001; 8192|]
(* If really exotic machines !!!!
   | 17 -> [|0; 0; 1928; 3055; 3855; 4476; 4983; 5411; 5783; 6110; 6403; 
              6668; 6910; 7133; 7339; 7530; 7710|]
   | 18 -> [|0; 0; 1821; 2886; 3641; 4227; 4706; 5111; 5461; 5771; 6047; 
              6298; 6526; 6736; 6931; 7112; 7282|]
   | 19 -> [|0; 0; 1725; 2734; 3449; 4005; 4458; 4842; 5174; 5467; 5729; 
              5966; 6183; 6382; 6566; 6738; 6898|]
   | 20 -> [|0; 0; 1639; 2597; 3277; 3804; 4235; 4600; 4915; 5194; 5443; 
              5668; 5874; 6063; 6238; 6401; 6553|] 
   | 21 -> [|0; 0; 1561; 2473; 3121; 3623; 4034; 4381; 4681; 4946; 5183; 
              5398; 5594; 5774; 5941; 6096; 6241|]
   | 22 -> [|0; 0; 1490; 2361; 2979; 3459; 3850; 4182; 4468; 4722; 4948; 
              5153; 5340; 5512; 5671; 5819; 5958|]
   | 23 -> [|0; 0; 1425; 2258; 2850; 3308; 3683; 4000; 4274; 4516; 4733; 
              4929; 5108; 5272; 5424; 5566; 5699|]
   | 24 -> [|0; 0; 1366; 2164; 2731; 3170; 3530; 3833; 4096; 4328; 4536; 
              4723; 4895; 5052; 5198; 5334; 5461|]
   | 25 -> [|0; 0; 1311; 2078; 2622; 3044; 3388; 3680; 3932; 4155; 4354; 
              4534; 4699; 4850; 4990; 5121; 5243|]
   | 26 -> [|0; 0; 1261; 1998; 2521; 2927; 3258; 3538; 3781; 3995; 4187; 
              4360; 4518; 4664; 4798; 4924; 5041|]
   | 27 -> [|0; 0; 1214; 1924; 2428; 2818; 3137; 3407; 3641; 3847; 4032; 
              4199; 4351; 4491; 4621; 4742; 4855|]
   | 28 -> [|0; 0; 1171; 1855; 2341; 2718; 3025; 3286; 3511; 3710; 3888; 
              4049; 4196; 4331; 4456; 4572; 4681|]
   | 29 -> [|0; 0; 1130; 1791; 2260; 2624; 2921; 3172; 3390; 3582; 3754; 
              3909; 4051; 4181; 4302; 4415; 4520|]
   | 30 -> [|0; 0; 1093; 1732; 2185; 2536; 2824; 3067; 3277; 3463; 3629; 
              3779; 3916; 4042; 4159; 4267; 4369|]
   | 31 -> [|0; 0; 1057; 1676; 2114; 2455; 2733; 2968; 3171; 3351; 3512; 
              3657; 3790; 3912; 4025; 4130; 4228|]
*)
   | 32 -> [|0; 0; 1024; 1623; 2048; 2378; 2647; 2875; 3072; 3246; 3402; 
              3543; 3671; 3789; 3899; 4001; 4096|]
   | n -> failwith "num_digits_max_vector"
;;
******)

(* XL: suppression de string_list_of_nat *)

let unadjusted_string_of_nat nat off len_nat =
  let len = num_digits_nat nat off len_nat in
  if len == 1 then
       sys_string_of_digit nat off
  else
       let len_copy = ref (succ len) in
       let copy1 = create_nat !len_copy
       and copy2 = make_nat !len_copy
       and rest_digit = make_nat 2 in
         if len > biggest_int / (succ pmax)
            then failwith "number too long" 
            else let len_s = (succ pmax) * len in
                 let s = make_string len_s `0`
                 and pos_ref = ref len_s in
                   len_copy := pred !len_copy; 
                   blit_nat copy1 0 nat off len;
                   set_digit_nat copy1 len 0;
                   while not (is_zero_nat copy1 0 !len_copy) do  
                      div_digit_nat copy2 0 
                                     rest_digit 0 
                                     copy1 0 (succ !len_copy) 
                                     power_base_max 0;
                      let str = raw_string_of_digit rest_digit 0 in
                      blit_string str 0 
                                  s (!pos_ref - string_length str)
                                  (string_length str);
                      (* XL: il y avait pmax a la place de string_length str
                         mais ca ne marche pas avec le blit de Caml Light,
                         qui ne verifie pas les debordements *)
                      pos_ref := !pos_ref - pmax;
                      len_copy := num_digits_nat copy2 0 !len_copy; 
                      blit_nat copy1 0 copy2 0 !len_copy;
                      set_digit_nat copy1 !len_copy 0 
                   done;
                   s
;;

let string_of_nat nat = 
  let s = unadjusted_string_of_nat nat 0 (length_nat nat) 
  and index = ref 0 in
    begin try
      for i = 0 to sub_int (string_length s) 2 do
       if nth_char s i != `0` then (index:= i; raise Exit)
      done
    with Exit -> ()
    end;
    sub_string s !index (sub_int (string_length s) !index)
;;

(* XL: suppression de sys_string_of_nat *)

(* XL: suppression de debug_string_nat *)

let base_digit_of_char c base =
  let n = int_of_char c in
    if n >= 48 & n <= 47 + min base 10 then n - 48
    else if n >= 65 & n <= 65 + base - 11 then n - 55
    else failwith "invalid digit"
;;

(* 
   La sous-chaine (s, off, len) repre'sente un nat en base base que 
   l'on de'termine ici 
*)
let sys_nat_of_string base s off len = 
  let power_base = make_nat (succ length_of_digit) in
  let (pmax, pint) = make_power_base base power_base in
  let new_len = ref (1 + len / (pmax + 1))
  and current_len = ref 1 in
  let possible_len = ref (min 2 !new_len) in

  let nat1 = make_nat !new_len
  and nat2 = make_nat !new_len 

  and digits_read = ref 0 
  and bound = off + len - 1
  and int = ref 0 in

  for i = off to bound do
    (* 
       on lit pint (au maximum) chiffres, on en fait un int 
       et on l'inte`gre au nombre
     *)
      let c = nth_char s i  in
        begin match c with 
          ` ` | `\t` | `\n` | `\r` | `\\` -> ()
        | _ -> int := !int * base + base_digit_of_char c base;
               incr digits_read
        end;
        if (!digits_read == pint or i == bound) & not (!digits_read == 0) then 
          begin
           set_digit_nat nat1 0 !int;
           for j = 1 to !current_len do 
             set_digit_nat nat1 j 0
           done;
           mult_digit_nat nat1 0 !possible_len 
                          nat2 0 !current_len 
                          power_base (pred !digits_read);
           blit_nat nat2 0 nat1 0 !possible_len;
           current_len := num_digits_nat nat1 0 !possible_len;
           possible_len := min !new_len (succ !current_len);
           int := 0;
           digits_read := 0
           end
  done;
  (* 
     On recadre le nat 
  *)
  let nat = create_nat !current_len in
    blit_nat nat 0 nat1 0 !current_len;
    nat
;;

let nat_of_string s = sys_nat_of_string 10 s 0 (string_length s);;

let float_of_nat nat = float__float_of_string(string_of_nat nat);;
