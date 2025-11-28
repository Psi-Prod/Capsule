open Yocaml

let entity_name = "Article"

class t ~title ~date ~updated ~description ~authors ~tags =
  object
    method title : string = title
    method date : Datetime.t = date
    method updated : Datetime.t option = updated
    method description : string option = description
    method authors : string list = authors
    method tags : string list = tags
  end

class filled ~title ~date ~updated ~description ~authors ~tags ~link =
  object
    inherit t ~title ~date ~updated ~description ~authors ~tags
    method link : string = link
  end

let fill t ~link =
  new filled
    ~title:t#title ~date:t#date ~updated:t#updated ~description:t#description
    ~authors:t#authors ~tags:t#tags ~link

let neutral = Metadata.required entity_name

let validate =
  let open Data.Validation in
  record (fun fields ->
      let+ title = required fields "title" string
      and+ date = required fields "date" Datetime.validate
      and+ updated = optional fields "updated" Datetime.validate
      and+ description = optional fields "description" string
      and+ authors = required fields "authors" (list_of string)
      and+ tags = optional_or fields "tags" (list_of string) ~default:[] in
      new t ~title ~date ~updated ~description ~authors ~tags)

let normalize a =
  let open Data in
  let updated =
    Option.fold a#updated ~none:[] ~some:(fun date ->
        [ ("updated", Datetime.normalize date) ])
  in
  let description =
    Option.fold a#description ~none:[] ~some:(fun descr ->
        [ ("description", string descr) ])
  in
  [
    ("title", string a#title);
    ("date", Datetime.normalize a#date);
    ("authors", list_of string a#authors);
    ("tags", list_of string a#tags);
  ]
  @ updated @ description

let normalize_filled article =
  Data.record (("link", Data.string article#link) :: normalize article)

let compare_by_date a a' = -Datetime.compare a#date a'#date
