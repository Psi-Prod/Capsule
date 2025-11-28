open Yocaml
open Archetypes

module File = struct
  let is_gemtext = Path.has_extension "gmi"

  let is_index p =
    match Path.basename p with
    | None -> false
    | Some basename -> String.starts_with ~prefix:"index" basename
end

let process_media { Resolver.src; dst } =
  Action.batch src#media ~only:`Directories
    (Action.copy_directory ~into:dst#root)

let process_index { Resolver.src; dst } =
  Action.batch src#pages ~only:`Files ~where:File.is_index
    (Action.copy_file ~into:dst#root)

let process_static { Resolver.src; dst } =
  Action.batch src#static ~only:`Files (Action.copy_file ~into:dst#static)

let process_page { Resolver.src; dst } path =
  let pipeline =
    let open Task in
    let+ () = Pipeline.track_file src#binary
    and+ apply_templates = Yocaml_jingoo.read_template src#layout_template
    and+ metadata, content =
      Yocaml_yaml.Pipeline.read_file_with_metadata (module Page) path
    in
    apply_templates (module Page) ~metadata content
  in
  Action.write_static_file (dst#as_page path) pipeline

let process_pages ({ Resolver.src; _ } as resolver) =
  Action.batch src#pages ~only:`Files
    ~where:(fun path -> File.is_gemtext path && not (File.is_index path))
    (process_page resolver)

let process_article { Resolver.src; dst } path =
  let pipeline =
    let open Task in
    let+ () = Pipeline.track_file src#binary
    and+ apply_templates =
      Yocaml_jingoo.read_templates [ src#article_template; src#layout_template ]
    and+ metadata, content =
      Yocaml_yaml.Pipeline.read_file_with_metadata (module Article) path
    in
    apply_templates (module Article) ~metadata content
  in
  Action.write_static_file (dst#as_article path) pipeline

let process_articles ({ Resolver.src; _ } as resolver) =
  Action.batch src#articles ~only:`Files ~where:File.is_gemtext
    (process_article resolver)

let fetch_gemlog { Resolver.src; _ } =
  let open Eff in
  let+ articles =
    read_directory ~on:`Source ~only:`Files src#articles
    >>= List.traverse (fun path ->
            let+ article, _ =
              Yocaml_yaml.Eff.read_file_with_metadata
                (module Article)
                ~on:`Source path
            in
            let link = Resolver.relative#as_article path |> Path.to_string in
            Article.fill article ~link)
  in
  Gemlog.make articles

let fetch_gemlog_task ({ Resolver.src; _ } as resolver) =
  let open Task in
  make (Deps.singleton src#articles) (fun () -> fetch_gemlog resolver)

let process_gemlog ({ Resolver.src; dst } as resolver) =
  let pipeline =
    let open Task in
    let+ () = Pipeline.track_file src#binary
    and+ apply_templates =
      Yocaml_jingoo.read_templates [ src#gemlog_template; src#layout_template ]
    and+ gemlog = fetch_gemlog_task resolver in
    apply_templates (module Gemlog) ~metadata:gemlog ""
  in
  Action.write_static_file dst#gemlog pipeline

let process_feed ({ Resolver.src; dst } as resolver) =
  let pipeline =
    let open Task in
    let+ () = Pipeline.track_file src#binary
    and+ gemlog = fetch_gemlog_task resolver in
    Feed.make gemlog
  in
  Action.write_static_file dst#atom pipeline

let process_tag { Resolver.src; dst } tag =
  let pipeline =
    let open Task in
    let+ () = Pipeline.track_files [ src#binary; src#articles ]
    and+ apply_templates =
      Yocaml_jingoo.read_templates [ src#tag_template; src#layout_template ]
    in
    apply_templates (module Tag) ~metadata:tag ""
  in
  Action.write_static_file (dst#as_tag (Tag.name tag)) pipeline

let process_tags resolver cache =
  let open Eff in
  let* tags = fetch_gemlog resolver >|= Tags_index.from_gemlog in
  Action.batch_list (Tags_index.assoc tags)
    (fun (name, articles) ->
      let tag = Tag.make ~name articles tags in
      process_tag resolver tag)
    cache

let process_tags_index ({ Resolver.src; dst } as resolver) =
  let pipeline =
    let open Task in
    let+ () = Pipeline.track_files [ src#binary; src#articles ]
    and+ apply_templates =
      Yocaml_jingoo.read_templates
        [ src#tags_index_template; src#layout_template ]
    and+ tags = fetch_gemlog_task resolver >>| Tags_index.from_gemlog in
    apply_templates (module Tags_index) ~metadata:tags ""
  in
  Action.write_static_file dst#tags_index pipeline

let run resolver =
  let open Eff in
  Action.restore_cache ~on:`Source resolver.Resolver.dst#cache
  >>= process_media resolver >>= process_static resolver
  >>= process_index resolver >>= process_pages resolver
  >>= process_articles resolver >>= process_gemlog resolver
  >>= process_feed resolver >>= process_tags resolver
  >>= process_tags_index resolver
  >>= Action.store_cache ~on:`Source resolver.dst#cache
