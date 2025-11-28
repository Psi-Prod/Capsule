(lang dune 3.19)

(version 1.0)

(name capsule)

(license "GPL-3.0-or-later")

(authors "Psi-prod's members")

(maintainers "tim.arnouts@protonmail.com" "lelolartichaut@laposte.net")

(source
 (github Psi-Prod/Capsule))

(homepage "https://github.com/Psi-Prod/Capsule")

(generate_opam_files true)

(package
 (name capsule)
 (synopsis "Psi-prod's gemini capsule")
 (description "Psi-prod's gemini capsule.")
 (depends
  (ocaml
   (>= 5.3))
  (cmdliner
   (>= 1.3.0))
  (mehari-eio
   (>= dev))
  (mirage-crypto-rng
   (>= 2.0.2))
  (uri
   (>= 4.4.0))
  (yocaml
   (>= 2.6.0))
  (yocaml_unix
   (>= 2.6.0))
  (yocaml_yaml
   (>= 2.6.0))
  (yocaml_jingoo
   (>= 2.6.0))
  (yocaml_syndication
   (>= 2.6.0))))
