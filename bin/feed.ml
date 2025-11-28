open Yocaml
open Yocaml_syndication

let domain = Uri.of_string "https://heyplzlookat.me" |> Uri.canonicalize
let icon_url = Uri.with_path domain "images/icon.png"

let tim =
  Person.make "Tim" ~uri:"https://site.condor-du-plateau.fr/"
    ~email:"tim.arnouts@protonmail.com"

let leo = Person.make "Léo" ~email:"lelolartichaut@laposte.net"
let date = Datetime.make ~tz:(Tz.Plus 200)

let entry_of_article article =
  let open Atom in
  let id = Uri.with_path domain article#link |> Uri.to_string in
  let updated = Option.value ~default:article#date article#updated |> date in
  let summary = Option.map text article#description in
  let categories =
    List.map
      (fun tag ->
        let scheme =
          Resolver.relative#as_tag tag
          |> Path.to_string |> Uri.with_path domain |> Uri.to_string
        in
        Category.make tag ~label:tag ~scheme)
      article#tags
  in
  let authors = List.map Person.make article#authors in
  entry ~id ~title:(text article#title) ~published:(date article#date) ~updated
    ?summary ~categories
    ~links:[ alternate id ]
    ~authors ()

let feed articles =
  let self_uri =
    Path.to_string Resolver.relative#atom
    |> Uri.with_path domain |> Uri.to_string
  in
  let open Atom in
  feed ~id:self_uri
    ~title:(text "Fil Heyplzlookatme")
    ~subtitle:
      (text
         "Nous postons ici des avis et commentaires politiques désastreux, des \
          devlog OCaml et d'autres trucs qui nous intéressent de près ou de \
          loin")
    ~updated:(updated_from_entries ()) ~icon:(Uri.to_string icon_url)
    ~authors:Nel.(append (singleton tim) (singleton leo))
    ~links:
      [
        self ~title:"Lien vers le feed" ~hreflang:"fr" self_uri;
        alternate ~title:"Lien vers le proxy" ~hreflang:"fr"
          ~media_type:Text_html (Uri.to_string domain);
        alternate ~title:"Lien vers le site" ~hreflang:"fr"
          (Uri.with_scheme domain (Some "gemini") |> Uri.to_string);
      ]
    entry_of_article articles

let make gemlog = Archetypes.Gemlog.articles gemlog |> feed |> Xml.to_string
