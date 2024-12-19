#!/bin/bash

# Define the R2 bucket and endpoint URL
R2_BUCKET="here-you-go"
R2_ENDPOINT_URL="https://34b7b02be8bc4ebdb8c4b34f56c54526.r2.cloudflarestorage.com"

# Check if the correct number of arguments is passed
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <file-to-upload> <destination-key>"
    exit 1
fi

# Get the file and key from command-line arguments
FILE_TO_UPLOAD="$1"
DEST_KEY="$2"

# Upload the file to R2
put_file_to_r2() {
    aws s3api put-object \
        --endpoint-url "$R2_ENDPOINT_URL" \
        --bucket "$R2_BUCKET" \
        --key "$DEST_KEY" \
        --body "$FILE_TO_UPLOAD"
}

# Call the function to upload the file
put_file_to_r2

