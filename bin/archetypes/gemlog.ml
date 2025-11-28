open Yocaml

type t = Article.filled list

let make articles = List.sort Article.compare_by_date articles
let articles = Fun.id

let normalize articles =
  let open Data in
  [ ("articles", list_of Article.normalize_filled articles) ]
