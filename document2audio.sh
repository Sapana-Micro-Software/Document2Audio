# Script Name: Document2Audio.sh
# This script converts a PDF document to audio and streams it to a VLC server.
# Prompt for Cursor 0.42.3: 
# Create a robust and modular shell script to convert either a flattened or 
# unflattened PDF into a enumeration of speech synthesized files cut by the section 
# of the PDF with that being the title and saved in the OPUS file format and delivered 
# to a VLC via the IP Address of the server as the command line argument along with 
# using "say" commnad in MacOS for the speech synthesis and remove all extroneous 
# characters, charts, and pictures inside the PDF.   Please convert the PDF into text, 
# then into cut by section of the PDF by the header title as the filename title for the 
# opus audio file, and then convert the text into audio using say.
# Engine used: gpt-4o

# Second Prompt for Cursor 0.42.3:
# Instead of streaming, could you instead add the files to a playlist that is the same as 
# the filename of the PDF inside the VLC on the computer?
# Engine used: gpt-4o

#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <PDF_FILE>"
    exit 1
fi

PDF_FILE="$1"
OUTPUT_DIR="${PDF_FILE%.*}_audio"
IMAGE_DIR="${PDF_FILE%.*}_images"
TEXT_DIR="${PDF_FILE%.*}_text"
PLAYLIST_FILE="${PDF_FILE%.*}.m3u"

# Create necessary directories
mkdir -p "$OUTPUT_DIR" "$IMAGE_DIR" "$TEXT_DIR"

echo "Starting conversion process for $PDF_FILE"
echo "Output directories created at $OUTPUT_DIR, $IMAGE_DIR, and $TEXT_DIR"

# Convert PDF to PNG images
echo "Converting PDF to PNG images..."
magick -density 300 "$PDF_FILE" "$IMAGE_DIR/page_%03d.png"
echo "PDF conversion to images completed. Images saved in $IMAGE_DIR"

# Perform OCR on each image
echo "Performing OCR on images..."
for image_file in "$IMAGE_DIR"/*.png; do
    base_name=$(basename "$image_file" .png)
    text_file="$TEXT_DIR/${base_name}.txt"
    tesseract "$image_file" "$text_file" --psm 1
    echo "OCR completed for $image_file. Text saved to $text_file"
done

# Function to clean and split text by sections
process_text() {
    local input_dir="$1"
    local output_dir="$2"
    local section_number=1

    echo "Processing text to identify sections..."
    for text_file in "$input_dir"/*.txt; do
        while IFS= read -r line; do
            # Check for section headers (customize this regex as needed)
            if [[ "$line" =~ ^[A-Z][A-Za-z0-9\ ]+$ ]]; then
                section_title=$(echo "$line" | tr ' ' '_')
                section_file="$output_dir/section_$(printf "%010d" $section_number)_${section_title}.txt"
                echo "Processing section: $section_title"
                section_number=$((section_number + 1))
            fi
            # Append line to the current section file
            echo "$line" >> "$section_file"
        done < "$text_file"
    done
    echo "Text processing completed. Sections saved in $output_dir"
}

# Process the text files
process_text "$TEXT_DIR" "$OUTPUT_DIR"

# Create a new playlist file
echo "Creating playlist file $PLAYLIST_FILE"
echo "#EXTM3U" > "$PLAYLIST_FILE"

# Convert each section to audio and add to playlist
section_count=$(ls "$OUTPUT_DIR"/section_*.txt | wc -l)
current_section=0

for section_file in "$OUTPUT_DIR"/section_*.txt; do
    section_title=$(basename "$section_file" .txt)
    audio_file="$OUTPUT_DIR/${section_title}.aiff"

    echo "Converting section $section_title to audio..."
    # Convert text to audio
    say -o "$audio_file" "$(<"$section_file")"
    echo "Audio file created: $audio_file"

    # Add audio file to playlist
    echo "Adding $audio_file to playlist"
    echo "#EXTINF:-1,$section_title" >> "$PLAYLIST_FILE"
    echo "$audio_file" >> "$PLAYLIST_FILE"

    # Update progress bar
    current_section=$((current_section + 1))
    progress=$((current_section * 100 / section_count))
    echo -ne "Progress: ["
    for ((i = 0; i < 50; i++)); do
        if [ $((i * 2)) -lt $progress ]; then
            echo -ne "#"
        else
            echo -ne " "
        fi
    done
    echo -ne "] $progress% \r"
done

echo -ne "\nConversion complete. Playlist created: $PLAYLIST_FILE\n"