#!/usr/bin/env bash

#set -o xtrace

print_usage()
{
    printf "Watches directory and uploads new files to LDH.\nMoves uploaded files to the `uploaded` subdirectory of directory.\n"
    printf "\n"
    printf "Usage:  %s options [TARGET_URI]\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the application\n"
    printf "\n"
    printf "  -d, --directory ABS_PATH             Absolute path to the directory\n"
    printf "  -t, --move-to                        Directory to which uploaded files will be moved. Defaults to `uploaded`, created as a sub-directory to the watched directory.\n"
}

hash curl 2>/dev/null || { echo >&2 "curl not on \$PATH. Aborting."; exit 1; }

args=()
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        -f|--cert-pem-file)
        cert_pem_file="$2"
        shift # past argument
        shift # past value
        ;;
        -p|--cert-password)
        cert_password="$2"
        shift # past argument
        shift # past value
        ;;
        -b|--base)
        base="$2"
        shift # past argument
        shift # past value
        ;;
        -d|--directory)
        directory="$2"
        shift # past argument
        shift # past value
        ;;
        -t|--move-to)
        move_to="$2"
        shift # past argument
        ;;
        *)    # unknown arguments
        args+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done
set -- "${args[@]}" # restore args

if [ -z "$cert_pem_file" ] ; then
    print_usage
    exit 1
fi
if [ -z "$cert_password" ] ; then
    print_usage
    exit 1
fi
if [ -z "$base" ] ; then
    print_usage
    exit 1
fi
if [ -z "$directory" ] ; then
    print_usage
    exit 1
fi

if [ -z "$move_to" ] ; then
    move_to="$directory/uploaded"
    mkdir -p "$move_to"
fi

urlencode()
{
    # python -c 'from urllib.parse import urlencode; import sys; print(urlencode(sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()[0:-1]))' "$1"
    python2 -c 'import urllib, sys; print urllib.quote(sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()[0:-1])' "$1"
}

ns="${base}ns/domain/system#"
class="${ns}File"
forClass=$(urlencode "$class")
container="${base}files/"

# if target URL is not provided, it equals container
if [ -z "$1" ] ; then
    target="${container}?forClass=${forClass}"
else
    target="${1}?forClass=${forClass}"
fi

#find "$directory" $maxdepth -type f -exec bash -c "$upload_file" \;
inotifywait -m "$directory" -e create |
    while read directory action file; do
        # upload the file
        ./upload-file.sh \
            -f $cert_pem_file \
            -p $cert_password \
            -b $base \
            --title "$file" \
            --file "$directory/$file"

        # move it out of the directory
        mv "$directory/$file" "$move_to"
    done
