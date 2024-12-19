#!/bin/bash

R2_BUCKET="come-here"
R2_ENDPOINT_URL="https://34b7b02be8bc4ebdb8c4b34f56c54526.r2.cloudflarestorage.com"

# Check if the correct number of arguments is passed
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <file-to-upload>"
    exit 1
fi

# Get the file and key from command-line arguments
FILE_TO_UPLOAD="$1"

# Upload the file to R2
put_file_to_r2() {
    aws s3api get-object $FILE_TO_UPLOAD \
        --endpoint-url "$R2_ENDPOINT_URL" \
        --bucket "$R2_BUCKET" \
        --key "$FILE_TO_UPLOAD" 
}

# Call the function to upload the file
put_file_to_r2

