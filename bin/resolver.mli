open Yocaml

type target =
  < root : Path.t
  ; static : Path.t
  ; gemlog : Path.t
  ; tags_index : Path.t
  ; atom : Path.t
  ; as_page : Path.t -> Path.t
  ; as_article : Path.t -> Path.t
  ; as_tag : string -> Path.t >

type t = { src : src; dst : dst }

and src =
  < binary : Path.t
  ; pages : Path.t
  ; articles : Path.t
  ; media : Path.t
  ; static : Path.t
  ; layout_template : Path.t
  ; article_template : Path.t
  ; gemlog_template : Path.t
  ; tag_template : Path.t
  ; tags_index_template : Path.t >

and dst = < target ; cache : Path.t >

val make_dest : root:Yocaml.Path.t -> dst
val make : src:src -> dst:dst -> t
val relative : target
