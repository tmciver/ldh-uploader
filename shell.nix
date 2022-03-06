{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = [
    pkgs.perl
    pkgs.curl
    pkgs.file
    pkgs.libuuid

    pkgs.perlPackages.ImageExifTool
    pkgs.perlPackages.JSON
  ];
}
