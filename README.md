# LDH Uploader

This project is a collection of shell scripts ussed to upload files or directory
of files to a [Linked Data Hub](https://github.com/AtomGraph/LinkedDataHub)
instance.

## Upload A Single File

To upload a single file, run `upload-file.sh` with a command like the following:

SCRIPT_ROOT=<path-to-ldh-scripts> ./upload-file.sh \
      --cert-pem-file <path-to-cert-pem> \
      --cert-password password \
      --base https://localhost:4443/ \
      --title "Some Title"
      --file <path-to-file>

## Upload a Directory of Files

To upload all files in a given directory, run `upload-dir.sh` with a command
like the following:

    $ SCRIPT_ROOT=<path-to-ldh-scripts> ./upload-dir.sh \
      --cert-pem-file <path-to-cert-pem> \
      --cert-password password \
      --base https://localhost:4443/ \
      --directory <path-to-directory>

## EXIF Metadata

EXIF metadata is extracted from `image/jpeg` files.  This is done using [the
`exif2rdf` Perl tool](https://github.com/mkanzaki/exif2rdf).

## Nix

If you're running Nix/NixOS you can easily obtain the necessary dependencies by
running the commands in a Nix shell provided by the included `shell.nix` file.
Enter this shell by running:

    $ nix-shell

in the project directory.
