open Cmdliner

let resolver =
  let open Yocaml.Path in
  let src =
    let pages = rel [ "pages" ] in
    let templates = rel [ "templates" ] in
    object
      method binary = rel [ Sys.argv.(0) ]
      method pages = pages
      method articles = rel [ "articles" ]
      method media = rel [ "media" ]
      method static = pages / "static"
      method layout_template = templates / "layout.gmi"
      method article_template = templates / "article.gmi"
      method gemlog_template = templates / "gemlog.gmi"
      method tag_template = templates / "tag.gmi"
      method tags_index_template = templates / "tags.gmi"
    end
  in
  let dst = Resolver.make_dest ~root:(rel [ "_build"; "site" ]) in
  Resolver.make ~src ~dst

let build level = Yocaml_unix.run ~level @@ fun () -> Actions.run resolver

let serve port =
  let private_of_pems ~cert ~priv_key =
    let pem = In_channel.(with_open_text cert input_all) in
    match X509.Certificate.decode_pem_multiple pem with
    | Ok certs -> (
        let pem = In_channel.(with_open_text priv_key input_all) in
        match X509.Private_key.decode_pem pem with
        | Ok key -> (certs, key)
        | Error (`Msg msg) ->
            Printf.sprintf "Private key (%s): failed to parse private key %s"
              priv_key msg
            |> invalid_arg)
    | Error (`Msg msg) ->
        Printf.sprintf
          "Private certificates (%s): failed to parse certificates %s" cert msg
        |> invalid_arg
  in
  let router =
    let open Mehari_miou_unix in
    let any = Mehari.Path.variable ~from_string:Option.some ~to_string:Fun.id in
    router
      [
        route Mehari.Path.(~/:any) (static "./_build/site/");
        route
          Mehari.Path.(~/:any /: any)
          (fun dir subdir ->
            static "./_build/site/" (String.concat "/" [ dir; subdir ]));
        route
          Mehari.Path.(~/:any /: any /: any)
          (fun dir subdir subsubdir ->
            static "./_build/site/"
              (String.concat "/" [ dir; subdir; subsubdir ]));
      ]
  in
  Miou_unix.run @@ fun () ->
  Mirage_crypto_rng_unix.use_default ();
  let cert = private_of_pems ~cert:"cert.pem" ~priv_key:"key.pem" in
  router |> Mehari_miou_unix.logger
  |> Mehari_miou_unix.run ~port ~certs:(Single cert)

let level =
  let parse = function
    | "debug" -> Ok `Debug
    | "info" -> Ok `Info
    | "warning" -> Ok `Warning
    | "error" -> Ok `Error
    | "app" -> Ok `App
    | s -> Error (`Msg s)
  in
  let pp ppf l =
    Format.pp_print_string ppf
    @@
    match l with
    | `Debug -> "debug"
    | `Info -> "info"
    | `Warning -> "warning"
    | `Error -> "error"
    | `App -> "app"
  in
  Arg.conv (parse, pp)

let level_arg =
  let arg = Arg.info ~doc:"Log level" [ "l"; "log" ] in
  Arg.(required & opt (some level) (Some `Info) & arg)

let build_cmd =
  let info = Cmd.info "build" ~doc:"Build site" in
  Cmd.v info Term.(const build $ level_arg)

let serve_cmd =
  let info = Cmd.info "serve" ~doc:"Serve site" in
  let port_arg =
    let doc = "Port to listen to" in
    Arg.(value & opt int 8000 & info ~doc [ "p"; "port" ])
  in
  Cmd.v info Term.(const serve $ port_arg)

let cmd =
  let default_info = Cmd.info Sys.argv.(0) in
  Cmd.group default_info [ build_cmd; serve_cmd ]

let () =
  Logs.set_level (Some Info);
  Logs.set_reporter (Logs_fmt.reporter ());
  exit (Cmdliner.Cmd.eval cmd)
