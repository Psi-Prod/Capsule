open Yocaml

type t = (string * Article.filled list) list

let from_gemlog gemlog =
  let module String_map = Map.Make (String) in
  Gemlog.articles gemlog
  |> List.fold_left
       (fun acc article ->
         List.fold_left
           (fun map tag ->
             match String_map.find_opt tag map with
             | Some articles -> String_map.add tag (article :: articles) map
             | None -> String_map.add tag [ article ] map)
           acc article#tags)
       String_map.empty
  |> String_map.map (List.sort Article.compare_by_date)
  |> String_map.bindings

let assoc = Fun.id

let count index =
  let by_quantity (_, n) (_, n') = -Int.compare n n' in
  List.map (fun (tag, articles) -> (tag, List.length articles)) index
  |> List.sort by_quantity

let normalize tags =
  let open Data in
  [
    ( "tags",
      list_of
        (fun (tag, n) ->
          record
            [
              ("name", string tag);
              ("link", path (Resolver.relative#as_tag tag));
              ("number", int n);
            ])
        (count tags) );
  ]
