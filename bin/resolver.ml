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

let make_dest ~root =
  let open Path.Infix in
  object
    method cache = Path.rel [ "_build"; "cache" ]
    method root = root
    method static = root / "static-pages"
    method gemlog = root / "gemlog.gmi"
    method tags_index = root / "browse-tag.gmi"
    method atom = root / "atom.xml"
    method as_page = Path.move ~into:root
    method as_article = Path.move ~into:(root / "articles")

    method as_tag tag =
      root / "tags" / tag
      |> Path.change_extension "gmi"
      |> Path.relocate ~into:root
  end

let make ~src ~dst = { src; dst }
let relative :> target = make_dest ~root:(Path.abs [])
