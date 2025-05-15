
#!/bin/bash

# Color codes for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for required tools
check_dependencies() {
    if ! command -v yt-dlp &> /dev/null; then
        echo -e "${RED}Error: yt-dlp not found.${NC}"
        echo -e "Please install it using: ${BLUE}pip install yt-dlp${NC}"
        exit 1
    fi

    if ! command -v ffmpeg &> /dev/null; then
        echo -e "${RED}Error: ffmpeg not found.${NC}"
        echo -e "Install it with: ${BLUE}sudo apt-get install ffmpeg${NC} (on Ubuntu/Debian)"
        exit 1
    fi
}

# Initialize variables and directories
setup_environment() {
    INPUT_FILE="links.txt"
    OUTPUT_DIR="mp3_downloads"
    mkdir -p "$OUTPUT_DIR"

    if [ ! -f "$INPUT_FILE" ]; then
        echo -e "${RED}Error: Input file $INPUT_FILE not found.${NC}"
        echo -e "Please create it with one YouTube URL per line."
        exit 1
    fi

    # Count total URLs (ignoring empty lines and comments)
    total_files=$(grep -v '^$\|^#' "$INPUT_FILE" | wc -l)
    current_file=0
    successful_downloads=0
    failed_downloads=0
}

# Download and convert a single URL
process_url() {
    local url="$1"
    ((current_file++))

    echo -e "\n${YELLOW}📁 Processing file ${current_file}/${total_files}:${NC} ${url}"

    # Extract video ID for logging
    video_id=$(echo "$url" | grep -oP '(?<=v=)[^&]+' || basename "$url")

    # Download with progress and metadata
    yt-dlp --extract-audio \
           --audio-format mp3 \
           --audio-quality 0 \
           --output "$OUTPUT_DIR/%(title).50s.%(ext)s" \
           --progress \
           --embed-thumbnail \
           --add-metadata \
           "$url"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Successfully downloaded: ${video_id}${NC}"
        ((successful_downloads++))
    else
        echo -e "${RED}❌ Failed to download: ${video_id}${NC}"
        ((failed_downloads++))
    fi

    # Show progress
    remaining=$((total_files - current_file))
    echo -e "${BLUE}📊 Progress: ${current_file}/${total_files} (${remaining} remaining)${NC}"
}

# Main execution
main() {
    check_dependencies
    setup_environment

    echo -e "\n${GREEN}🚀 Starting YouTube to MP3 downloader${NC}"
    echo -e "📋 Total URLs found: ${total_files}"
    echo -e "📂 Output directory: ${OUTPUT_DIR}\n"

    # Process each URL
    while IFS= read -r url; do
        if [ -n "$url" ] && [[ ! "$url" =~ ^# ]]; then
            process_url "$url"
        fi
    done < "$INPUT_FILE"

    # Final summary
    echo -e "\n${GREEN}🎉 Download process completed!${NC}"
    echo -e "✔ Successfully downloaded: ${successful_downloads}"
    echo -e "✖ Failed downloads: ${failed_downloads}"
    echo -e "\n${YELLOW}📁 Your MP3 files are stored in:${NC}"
    echo -e "   ${BLUE}$(pwd)/${OUTPUT_DIR}${NC}"
    echo -e "\n${YELLOW}🔍 To access your files, run:${NC}"
    echo -e "   ${BLUE}cd \"$(pwd)/${OUTPUT_DIR}\" && ls -lh${NC}"
}

main
