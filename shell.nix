{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  permittedInsecurePackages = [
    "python-2.7.18.6"
  ];
  buildInputs = [
    pkgs.perl
    pkgs.curl
    pkgs.file
    pkgs.libuuid
    pkgs.saxon-he
    pkgs.apache-jena
    pkgs.python2
    pkgs.inotify-tools

    pkgs.perlPackages.ImageExifTool
    pkgs.perlPackages.JSON
  ];
}
