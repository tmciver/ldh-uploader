#!/usr/bin/env bash

if [ "$#" -ne 4 ] && [ "$#" -ne 5 ]; then
  echo "Usage:   $0" '$base $cert_pem_file $cert_password $abs_filename [$request_base]' >&2
  echo "Example: $0" 'https://linkeddatahub.com/my-context/my-dataspace/ ../../certs/martynas.stage.localhost.pem Password /folder/file.jpg' >&2
  echo "Note: special characters such as $ need to be escaped in passwords!" >&2
  exit 1
fi

base="$1"
cert_pem_file="$2"
cert_password="$3"
filename="$4"

if [ -n "$5" ]; then
    request_base="$5"
else
    request_base="$base"
fi

path=$(basename $filename) # strip the leading $pwd/
echo "path: $path"
#extension="${filename##*.}"

# case "$extension" in
#   png)
#     content_type="image/png"
#     ;;
#   jpg)
#     content_type="image/jpg"
#     ;;
#   svg)
#     content_type="image/svg+xml"
#     ;;
#   webm)
#     content_type="video/webm"
#     ;;
# esac

content_type=$(file -b --mime-type $filename)
echo "Content-Type: $content_type" 

[ -z "$content_type" ] && echo "Could not determine content type of ${filename}, skipping file" && exit 1

title="${filename##*/}" # strip folders

pushd . && cd "$SCRIPT_ROOT/imports"

./create-file.sh \
-b "$base" \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "${title}" \
--file "${filename}" \
--file-content-type "${content_type}" \
"${request_base}files/"

popd
