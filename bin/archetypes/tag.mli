open Yocaml

type t

val make : name:string -> Article.filled list -> Tags_index.t -> t
val name : t -> string

include Required.DATA_INJECTABLE with type t := t
