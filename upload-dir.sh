#!/usr/bin/env bash

#set -o xtrace

print_usage()
{
    printf "Uploads all files in a directory.\n"
    printf "\n"
    printf "Usage:  %s options [TARGET_URI]\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the application\n"
    printf "\n"
    printf "  -d, --directory ABS_PATH             Absolute path to the directory\n"
    printf "  -r, --recurse                        Recurse into sub-directories\n"
}

hash curl 2>/dev/null || { echo >&2 "curl not on \$PATH. Aborting."; exit 1; }

recurse=false

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
        -r|--recurse)
        recurse=true
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

urlencode()
{
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

if [ "$recurse" = true ] ; then
    maxdepth=""
else
    maxdepth="-maxdepth 1"
fi

pushd . && cd "$SCRIPT_ROOT/imports"

create_file="./create-file.sh \
             -f $cert_pem_file \
             -p $cert_password \
             -b $base \
             --file-content-type 'image/png' \
             --title \`basename {}\` \
             --file {}"

find "$directory" $maxdepth -type f -exec bash -c "$create_file" \;
