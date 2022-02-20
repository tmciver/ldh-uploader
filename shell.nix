{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
    buildInputs = [
        pkgs.jdk
        pkgs.apache-jena
        pkgs.python
        pkgs.openssl
	      pkgs.saxon-he
    ];
}
