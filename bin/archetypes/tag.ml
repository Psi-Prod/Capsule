open Yocaml

type t = { name : string; articles : Article.filled list; tags : Tags_index.t }

let make ~name articles tags = { name; articles; tags }
let name t = t.name

let normalize { name; articles; tags } =
  let open Data in
  [
    ("tag", string name); ("articles", list_of Article.normalize_filled articles);
  ]
  @ Tags_index.normalize tags
