open Yocaml

type t =
  < title : string
  ; date : Datetime.t
  ; updated : Datetime.t option
  ; description : string option
  ; authors : string list
  ; tags : string list >

type filled = < t ; link : string >

val fill : t -> link:string -> filled

include Required.DATA_READABLE with type t := t
include Required.DATA_INJECTABLE with type t := t

val normalize_filled : filled -> Data.t

val compare_by_date :
  < date : Datetime.t ; .. > -> < date : Datetime.t ; .. > -> int
