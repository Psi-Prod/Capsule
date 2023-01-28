open Yocaml
module Metaformat = Yocaml_yaml
module Template = Yocaml_jingoo

let target = "_build/"
let template file = add_extension file "gmi" |> into "templates"
let article_template = template "article"
let gemlog_template = template "gemlog"
let[@warning "-32"] tags_index_template = template "tags"
let[@warning "-32"] tags_index = "tags.gmi" |> into target
let article_target file = Model.article_path file |> into target
let binary_update = Build.watch Sys.argv.(0)
let gemlog = "gemlog.gmi" |> into target
let rss_feed = "feed.xml" |> into target
let tag_file tag = Model.tag_path tag |> into target
let tag_template = template "tag"

let process_pages =
  process_files [ "pages" ] File.is_gemtext (fun file ->
      let target = basename file |> into target in
      let open Build in
      create_file target
        (binary_update
        >>> Yocaml_yaml.read_file_with_metadata (module Metadata.Page) file
        >>^ Stdlib.snd))

let process_articles =
  process_files [ "articles" ] File.is_gemtext (fun article_file ->
      let open Build in
      create_file
        (article_target article_file)
        (binary_update
        >>> Metaformat.read_file_with_metadata
              (module Model.Article)
              article_file
        >>> Template.apply_as_template (module Model.Article) article_template
        >>^ Stdlib.snd))

let generate_feed =
  let open Build in
  let* articles_arrow =
    Collection.Articles.get_all (module Metaformat) "articles"
  in
  create_file rss_feed
    (binary_update >>> articles_arrow >>^ Feed.make >>^ Rss.Channel.to_rss)

let generate_tags =
  let* deps, tags = Collection.Tags.compute (module Metaformat) "articles" in
  let tags_string = List.map (fun (i, s) -> (i, List.length s)) tags in
  let mk_meta tag articles () = (Model.Tag.make tag articles tags_string, "") in
  List.fold_left
    (fun program (tag, articles) ->
      let open Build in
      program
      >> create_file (tag_file tag)
           (init deps >>> binary_update >>^ mk_meta tag articles
           >>> Template.apply_as_template (module Model.Tag) tag_template
           >>^ Stdlib.snd))
    (return ()) tags

(* let generate_index_tags =
   let open Build in
   let* deps, tags = Collection.Tags.compute (module Metaformat) "articles" in
   let tags_string = List.map (fun (i, s) -> (i, List.length s)) tags in
   let mk_meta tag articles () = (Model.Tag.make tag articles tags_string, "") in
   create_file tags_index
     (init deps >>> binary_update >>^ mk_meta tag []
     >>> Template.apply_as_template (module Model.Tag) tags_index
     >>^ Stdlib.snd) *)

let generate_articles_index =
  let open Build in
  let* articles_arrow =
    Collection.Articles.get_all (module Metaformat) "articles"
  in
  create_file gemlog
    (binary_update >>> articles_arrow
    >>^ (fun ((), articles) -> (Model.Articles.make articles, ""))
    >>> Template.apply_as_template (module Model.Articles) gemlog_template
    >>^ Stdlib.snd)
