#!/usr/bin/env bash

print_usage()
{
    printf "Uploads a file.\n"
    printf "\n"
    printf "Usage:  %s options [TARGET_URI]\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the application\n"
    printf "\n"
    printf "  --title TITLE                        Title of the file\n"
    printf "  --description DESCRIPTION            Description of the file (optional)\n"
    printf "  --slug STRING                        String that will be used as URI path segment (optional)\n"
    printf "\n"
    printf "  --file ABS_PATH                      Absolute path to the file\n"
    printf "  --file-content-type MEDIA_TYPE       Media type of the file (optional)\n"
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
        -t|--content-type)
        content_type="$2"
        shift # past argument
        shift # past value
        ;;
        -b|--base)
        base="$2"
        shift # past argument
        shift # past value
        ;;
        --title)
        title="$2"
        shift # past argument
        shift # past value
        ;;
        --description)
        description="$2"
        shift # past argument
        shift # past value
        ;;
        --slug)
        slug="$2"
        shift # past argument
        shift # past value
        ;;
        --file)
        file="$2"
        shift # past argument
        shift # past value
        ;;
        --file-content-type)
        file_content_type="$2"
        shift # past argument
        shift # past value
        ;;
        --file-slug)
        file_slug="$2"
        shift # past argument
        shift # past value
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
if [ -z "$title" ] ; then
    print_usage
    exit 1
fi
if [ -z "$file" ] ; then
    print_usage
    exit 1
fi

file_container="${base}files/"

pushd "$SCRIPT_ROOT"

# upload the file and capture the document URI
file_doc=$(./imports/create-file.sh \
    -b "$base" \
    -f "$cert_pem_file" \
    -p "$cert_password" \
    --title "$title" \
    --file "${file}" \
    --file-content-type "${file_content_type}")

echo "file_doc: $file_doc"

# fetch the triples for the document
file_ntriples=$(./get-document.sh \
    -f "$cert_pem_file" \
    -p "$cert_password" \
    --accept 'application/n-triples' \
    "$file_doc")

echo "triples: $file_ntriples"

popd

# extract the file URI
file_uri=$(echo "$file_ntriples" | grep '<http://xmlns.com/foaf/0.1/primaryTopic>' | cut -d " " -f 3 | cut -d "<" -f 2 | cut -d ">" -f 1)

echo "file_uri: $file_uri"

# extract EXIF data from image file as RDF-XML
exif_rdf_xml=$(perl exif2rdf.pl "${file}")

esc_file_uri="${file_uri@Q}"
echo $esc_file_uri

# replace file path with file URI in RDF-XML
exif_rdf_xml=$(echo "$exif_rdf_xml" | sed -e 's/^<foaf:Image rdf:about.*/<foaf:Image rdf:about='"${file_uri//\//\\/}"'>/')

echo "RDF-XML: $exif_rdf_xml"
