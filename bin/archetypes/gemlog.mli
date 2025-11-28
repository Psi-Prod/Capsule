open Yocaml

type t

val make : Article.filled list -> t
val articles : t -> Article.filled list

include Required.DATA_INJECTABLE with type t := t
