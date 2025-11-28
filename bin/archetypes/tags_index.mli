open Yocaml

type t

val from_gemlog : Gemlog.t -> t
val assoc : t -> (string * Article.filled list) list

include Required.DATA_INJECTABLE with type t := t
