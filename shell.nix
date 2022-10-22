{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = [
    pkgs.perl
    pkgs.curl
    pkgs.file
    pkgs.libuuid
    pkgs.saxon-he
    pkgs.apache-jena

    pkgs.perlPackages.ImageExifTool
    pkgs.perlPackages.JSON
  ];
}
