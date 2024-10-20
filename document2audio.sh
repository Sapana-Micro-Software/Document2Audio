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
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <PDF_FILE> [--verbose]"
    exit 1
fi

PDF_FILE="$1"
VERBOSE=false
MAX_CONCURRENT_JOBS=4

# Check for the verbose flag
if [ "$#" -eq 2 ] && [ "$2" == "--verbose" ]; then
    VERBOSE=true
fi

OUTPUT_DIR="${PDF_FILE%.*}_audio"
IMAGE_DIR="${PDF_FILE%.*}_images"
TEXT_DIR="${PDF_FILE%.*}_text"
PLAYLIST_FILE="${PDF_FILE%.*}.m3u"

# Create necessary directories
mkdir -p "$OUTPUT_DIR" "$IMAGE_DIR" "$TEXT_DIR"

echo "Starting conversion process for $PDF_FILE"
echo "Output directories created at $OUTPUT_DIR, $IMAGE_DIR, and $TEXT_DIR"

# Function to update the progress bar
update_progress_bar() {
    local current=$1
    local total=$2
    local title=$3
    local bar_length=50
    local progress=$((current * 100 / total))
    local filled_length=$((progress * bar_length / 100))
    local bar=$(printf "%-${bar_length}s" "#" | sed "s/ /#/g")
    local empty=$(printf "%-${bar_length}s" " " | sed "s/ / /g")
    tput civis  # Hide cursor
    printf "\r%s: [%-${bar_length}s] %d%%" "$title" "${bar:0:filled_length}${empty:filled_length}" "$progress"
    tput cnorm  # Show cursor
}

# Convert PDF to PNG images
echo "Converting PDF to PNG images..."
page_count=$(pdfinfo "$PDF_FILE" | grep Pages | awk '{print $2}')
for ((page=0; page<page_count; page++)); do
    output_file="$IMAGE_DIR/page_$(printf "%03d" $page).png"
    if [ "$VERBOSE" = true ]; then
        magick -density 300 "$PDF_FILE[$page]" "$output_file" &
    else
        magick -quiet -density 300 "$PDF_FILE[$page]" "$output_file" &
    fi
    pid=$!
    current_progress=0
    update_progress_bar $page $page_count "Converting Page $((page + 1))/$((page_count)) to PNG"
    while kill -0 $pid 2>/dev/null; do
        if [ -f "$output_file" ]; then
            break
        fi
        if [ $current_progress -ge 100 ]; then
            current_progress=0
        fi
    done
    update_progress_bar $page+1 $page_count "Converting Page $((page + 1))/$((page_count)) to PNG"
done
echo "\nPDF conversion to images completed. Images saved in $IMAGE_DIR\n"

# Perform OCR on each image
echo "Performing OCR on images..."
image_count=$(ls "$IMAGE_DIR"/*.png | wc -l)
current_image=0
for image_file in "$IMAGE_DIR"/*.png; do
    base_name=$(basename "$image_file" .png)
    text_file="$TEXT_DIR/${base_name}"
    tesseract "$image_file" "$text_file" --psm 1 &> /dev/null
    current_image=$((current_image + 1))
    update_progress_bar $current_image $image_count "PNG to Text OCR"
done
update_progress_bar $image_count $image_count "PNG to Text OCR"
echo "\nOCR completed. Text saved in $TEXT_DIR\n"

# Create a new playlist file
echo "Creating playlist file $PLAYLIST_FILE"
echo "#EXTM3U" > "$PLAYLIST_FILE"

# Convert each page's text to audio and add to playlist
current_page=0
active_jobs=0
pids=()

for text_file in "$TEXT_DIR"/page_*.txt; do
    page_number=$(basename "$text_file" .txt | sed 's/page_//')
    audio_file="$OUTPUT_DIR/page_${page_number}.aiff"

    # Run the say command in the background
    say -o "$audio_file" "$(<"$text_file")" &
    pids+=($!)
    active_jobs=$((active_jobs + 1))
    current_page=$((current_page + 1))

    # Wait for some jobs to finish if the limit is reached
    if [ "$active_jobs" -ge "$MAX_CONCURRENT_JOBS" ]; then
        while [ "$active_jobs" -ge "$MAX_CONCURRENT_JOBS" ]; do
            for pid in "${pids[@]}"; do
                if ! kill -0 $pid 2>/dev/null; then
                    active_jobs=$((active_jobs - 1))
                    pids=(${pids[@]/$pid})
                fi
            done
            sleep 0.1
            update_progress_bar $current_page $page_count "Text to Audio Conversion"
        done
    fi

    # Update progress bar based on completed files
    completed_files=$(ls "$OUTPUT_DIR"/*.opus 2>/dev/null | wc -l)
    #update_progress_bar $current_page $page_count "Text to Audio Conversion"

    # Add audio file to playlist
    echo "#EXTINF:-1,Page $page_number" >> "$PLAYLIST_FILE"
    echo "$audio_file" >> "$PLAYLIST_FILE"
done

# Wait for all background processes to complete
wait

update_progress_bar $page_count $page_count "Text to Audio Conversion"
echo -ne "\nConversion complete. Playlist created: $PLAYLIST_FILE\n"