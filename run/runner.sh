R2_BUCKET="come-here"
R2_ENDPOINT_URL="https://34b7b02be8bc4ebdb8c4b34f56c54526.r2.cloudflarestorage.com"

# Temporary files to store the previous and current file lists
PREVIOUS_LIST="/tmp/r2_files_list.txt"
CURRENT_LIST="/tmp/r2_files_list_current.txt"

# List the objects in the R2 bucket and store it in a file
list_files_in_r2() {
    aws s3api list-objects-v2 \
        --bucket "$R2_BUCKET" \
        --endpoint-url "$R2_ENDPOINT_URL" \
        --query "Contents[].{Key: Key, LastModified: LastModified}" \
        --output json > "$CURRENT_LIST"
}

# Compare the current and previous file lists
compare_lists() {
    # Use diff for a more detailed comparison
    if ! diff "$PREVIOUS_LIST" "$CURRENT_LIST" > /dev/null; then
        echo "R2 bucket has been updated!"
        echo "Changes detected on $(date):"

        # Extract keys from both the previous and current lists
        current_keys=$(jq -r '.[].Key' "$CURRENT_LIST")
        previous_keys=$(jq -r '.[].Key' "$PREVIOUS_LIST")

        # Debugging: Print the contents of both lists
        echo "Current keys:"
        echo "$current_keys"
        echo "Previous keys:"
        echo "$previous_keys"

        # Compare and print only the new files that aren't in the previous list
        new_files=$(echo "$current_keys" | grep -Fxv -f <(echo "$previous_keys"))
        
        # Debugging: Print the new files detected
        echo "New files: $new_files"

        if [[ -n "$new_files" ]]; then
            # Create an associative array to track files by prefix
            declare -A file_groups

            # Group files by their prefix before '___'
            for new_file in $new_files; do
                echo "Processing file: $new_file"  # Debugging line
                # Extract the prefix before the first '___' (using a regular expression to capture the part before '___')
                prefix=$(echo "$new_file" | sed -E 's/(^[^_]+___).*/\1/')  # Capture everything before '___'
                echo "Extracted prefix: $prefix"  # Debugging line
                file_groups["$prefix"]+="$new_file"$'\n'  # Add the file to the appropriate group
            done

            # Iterate over file groups and move files with the same prefix
            for prefix in "${!file_groups[@]}"; do
                files_in_group="${file_groups[$prefix]}"
                file_count=$(echo -n "$files_in_group" | wc -l)  # Ensure no extra newlines are counted

                # Debugging: Print the file count for the current group
                echo "File count for group $prefix: $file_count"

                if [[ $file_count -eq 2 ]]; then
                    echo "Found a group with exactly two files: $prefix"
                    echo "Files in the group:"

                    # List the files in this group
                    echo "$files_in_group"

                    # Ensure the destination folder exists
                    dest_folder="temp/images/$prefix"
                    mkdir -p "$dest_folder"
                    echo "Created directory: $dest_folder"  # Debugging line
		    
		    model_file="$dest_folder/${prefix}model.jpg"
		    garment_file="$dest_folder/${prefix}garment.jpg"
		    
                    # Mov each file to the destination foldect the file's base name (without path)
			
		base_name=$(basename "$file")
                  for file in $files_in_group; do
                        echo "Moving file: $file"
        		bash get-obj.sh $file
			mv "$file" "$dest_folder/$(basename "$file" | cut -d. -f1).jpg"
                        echo "Moved $file to $dest_folder"
                    done
		    
		    # model_file="$dest_folder/$(echo "$files_in_group" | head -n 1)"
		    # garment_file="$dest_folder/$(echo "$files_in_group" | tail -n 1)"
		    
		    # Run the Python script with the model and garment file
		    echo "Running Python script for $model_file and $garment_file"
		    python run_ootd.py --model_path "$model_file" --cloth_path "$garment_file" --category 0 --scale 0.5 --sample 1 
										
		    echo "Uploading completed file"
		    bash upload.sh images_output/out_hd_0.png $prefix.png

		    echo "Done with it"
                else
                    echo "Skipping group with prefix $prefix because it doesn't have exactly two files."
                fi
            done
        else
            echo "No new files detected."
        fi

        # Update the previous list with the current list
        cp "$CURRENT_LIST" "$PREVIOUS_LIST"
    else
        echo "No updates detected."
    fi
}

# Initialize the previous list file if it doesn't exist
if [[ ! -f "$PREVIOUS_LIST" ]]; then
    echo "Initializing previous file list..."
    list_files_in_r2
    jq -r '.[].Key' "$CURRENT_LIST" > "$PREVIOUS_LIST"
    echo "File list initialized."
fi

# Main loop to continually check for updates
while true; do
    list_files_in_r2
    compare_lists
    sleep 2  # Check every 60 seconds (adjust as needed)
done

