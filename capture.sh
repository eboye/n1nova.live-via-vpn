#!/bin/bash

# Script to capture N1 or Nova streams to MP4 files
# This script is called from the main um.sh script
# Uses ffmpeg to capture streams to [channel][timestamp].mp4 format
#
# Usage: ./capture.sh <channel_name> <stream_url> [use_proxy] [proxy_cmd]
#   channel_name: N1 or Nova
#   stream_url: The stream URL to capture
#   use_proxy: "true" or "false" (optional)
#   proxy_cmd: The proxy command to use (optional)

# --- Debugging Configuration ---
DEBUG_MODE=false

# Function for debug messages
debug_echo() {
    if [ "$DEBUG_MODE" = true ]; then
        echo "DEBUG: $*" >&2
    fi
}

# --- Dependency Check ---
check_dependencies() {
    local missing_deps=()
    local required_deps=("curl" "grep" "sed" "bash")
    local capture_tools=("ffmpeg")
    local optional_tools=("streamlink" "yt-dlp")

    # Check required dependencies
    for cmd in "${required_deps[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    # Check for required capture tools
    local capture_found=false
    for tool in "${capture_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            capture_found=true
            break
        fi
    done

    if [ "$capture_found" = false ]; then
        echo "Error: No capture tools found. At least one of the following is required: ${capture_tools[*]}"
        echo "Please install ffmpeg:"
        echo "  Ubuntu/Debian: sudo apt install ffmpeg"
        echo "  Fedora: sudo dnf install ffmpeg"
        echo "  Arch: sudo pacman -S ffmpeg"
        exit 1
    fi

    # Check for optional tools and provide info
    echo "Checking for optional capture tools..."
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo "✓ $tool found"
        else
            echo "✗ $tool not found (will use ffmpeg fallback)"
        fi
    done

    debug_echo "Required dependencies found."
}

# --- Function to generate filename ---
generate_filename() {
    local channel_name="$1"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    echo "${channel_name}_${timestamp}.mp4"
}

# --- Function to extract real stream URL from simplified URL ---
extract_real_stream_url() {
    local simplified_url="$1"
    local real_url=""
    
    # Use yt-dlp to extract the real stream URL (since it's working in the tests)
    debug_echo "Extracting real stream URL from: $simplified_url"
    
    if command -v yt-dlp &> /dev/null; then
        # Use yt-dlp to simulate the same extraction it does internally
        # We'll use the same method that works in the capture attempts
        debug_echo "Using yt-dlp to extract URL like in capture attempts..."
        
        # Extract the redirect URL that yt-dlp finds
        real_url=$(yt-dlp --simulate --get-url "$simplified_url" 2>/dev/null | grep -v '^$' | head -1)
        
        if [ -z "$real_url" ]; then
            # Try alternative method - extract from verbose output
            real_url=$(yt-dlp --simulate --verbose "$simplified_url" 2>&1 | grep -oP 'https?://n1-bg-ku-r1-[0-9]+\.umn\.cdn\.united\.cloud/stream/\?[^[:space:]]+' | head -1)
        fi
        
        if [ -n "$real_url" ] && [ "$real_url" != "$simplified_url" ]; then
            debug_echo "Extracted real stream URL via yt-dlp simulation: $real_url"
            echo "$real_url"
            return
        else
            debug_echo "yt-dlp URL extraction failed"
        fi
    fi
    
    # Fallback: Use curl to follow redirects
    debug_echo "Trying curl redirect method..."
    real_url=$(curl -s -L -w "%{url_effective}" -o /dev/null "$simplified_url")
    
    if [ -n "$real_url" ] && [ "$real_url" != "$simplified_url" ]; then
        debug_echo "Extracted real stream URL via curl: $real_url"
        echo "$real_url"
        return
    fi
    
    # Fallback to simplified URL
    real_url="$simplified_url"
    debug_echo "Using simplified URL as fallback: $real_url"
    echo "$real_url"
}

# --- Function to capture stream ---
capture_stream() {
    local channel_name="$1"
    local stream_url="$2"
    local use_proxy="$3"
    local proxy_cmd="$4"
    
    local filename=$(generate_filename "$channel_name")
    local capture_dir="./captures"
    
    # Create captures directory if it doesn't exist
    mkdir -p "$capture_dir"
    local full_path="$capture_dir/$filename"
    
    # Extract the real stream URL with session tokens
    echo "Extracting real stream URL for capture..."
    local real_stream_url=$(extract_real_stream_url "$stream_url")
    echo "DEBUG: Original URL: $stream_url"
    echo "DEBUG: Extracted URL: $real_stream_url"
    
    echo "Starting capture for $channel_name..."
    echo "Output file: $full_path"
    echo "Press Ctrl+C to stop recording"
    
    # Give a moment for any network initialization
    echo "Initializing stream connection..."
    sleep 3
    
    # Build ffmpeg command
    local ffmpeg_cmd="ffmpeg"
    
    # Add proxy if needed
    if [ "$use_proxy" = "true" ] && [ -n "$proxy_cmd" ]; then
        ffmpeg_cmd="$proxy_cmd $ffmpeg_cmd"
        debug_echo "Using proxy: $proxy_cmd"
    fi
    
    # Try different ffmpeg approaches for HLS streams
    local attempts=0
    local max_attempts=3
    
    while [ $attempts -lt $max_attempts ]; do
        attempts=$((attempts + 1))
        echo "Attempt $attempts of $max_attempts..."
        
        case $attempts in
            1)
                # First attempt: Use MPV for capture (since MPV can play the stream)
                echo "Trying MPV capture approach..."
                if command -v mpv &> /dev/null; then
                    # MPV can record streams it can play - include video but don't display it
                    if [ "$use_proxy" = "true" ] && [ -n "$proxy_cmd" ]; then
                        capture_cmd="$proxy_cmd mpv --stream-record=\"$full_path\" --vo=null --ao=null \"$real_stream_url\""
                    else
                        capture_cmd="mpv --stream-record=\"$full_path\" --vo=null --ao=null \"$real_stream_url\""
                    fi
                    ffmpeg_cmd="$capture_cmd"
                else
                    # Fallback to ffmpeg if MPV not available
                    ffmpeg_opts="-i \"$real_stream_url\" -c:v copy -c:a copy -movflags +faststart -timeout 6000000 -reconnect 1 -reconnect_streamed 1 -reconnect_delay_max 5 \"$full_path\""
                fi
                ;;
            2)
                # Second attempt: Use yt-dlp with proxychains for authentication
                echo "Trying yt-dlp approach with proxy..."
                if command -v yt-dlp &> /dev/null; then
                    if [ "$use_proxy" = "true" ] && [ -n "$proxy_cmd" ]; then
                        capture_cmd="$proxy_cmd yt-dlp -o \"$full_path\" \"$real_stream_url\""
                    else
                        capture_cmd="yt-dlp -o \"$full_path\" \"$real_stream_url\""
                    fi
                    ffmpeg_cmd="$capture_cmd"
                else
                    # Fallback to ffmpeg if yt-dlp not available
                    ffmpeg_opts="-fflags +genpts -i \"$real_stream_url\" -c:v copy -c:a copy -movflags +faststart -timeout 10000000 -reconnect 1 -reconnect_streamed 1 -reconnect_delay_max 10 \"$full_path\""
                fi
                ;;
            3)
                # Third attempt: Use streamlink with proxychains for authentication
                echo "Trying streamlink approach with proxy..."
                if command -v streamlink &> /dev/null; then
                    # Try to get the real URL first, then use streamlink
                    local real_url_for_streamlink=""
                    if command -v yt-dlp &> /dev/null; then
                        real_url_for_streamlink=$(yt-dlp --simulate --get-url "$real_stream_url" 2>/dev/null | grep -v '^$' | head -1)
                        if [ -n "$real_url_for_streamlink" ] && [ "$real_url_for_streamlink" != "$real_stream_url" ]; then
                            debug_echo "Using yt-dlp extracted URL for streamlink: $real_url_for_streamlink"
                        fi
                    fi
                    
                    # Use the extracted URL or fallback to original
                    local url_to_use="${real_url_for_streamlink:-$real_stream_url}"
                    if [ "$use_proxy" = "true" ] && [ -n "$proxy_cmd" ]; then
                        capture_cmd="$proxy_cmd streamlink --stdout \"$url_to_use\" best -o \"$full_path\""
                    else
                        capture_cmd="streamlink --stdout \"$url_to_use\" best -o \"$full_path\""
                    fi
                    ffmpeg_cmd="$capture_cmd"
                else
                    # Last resort: Try basic ffmpeg with no stream mapping
                    ffmpeg_opts="-i \"$real_stream_url\" -c copy -timeout 15000000 -reconnect 1 -reconnect_streamed 1 -reconnect_delay_max 15 \"$full_path\""
                fi
                ;;
        esac
        
        # Execute capture command
        if [ -n "$capture_cmd" ]; then
            # Using alternative capture tool (streamlink/yt-dlp)
            full_cmd="$capture_cmd"
        else
            # Using ffmpeg
            full_cmd="$ffmpeg_cmd $ffmpeg_opts"
        fi
        debug_echo "Capture command (attempt $attempts): $full_cmd"
        
        if eval "$full_cmd"; then
            echo "Capture completed successfully: $full_path"
            echo "File size: $(du -h "$full_path" | cut -f1)"
            return 0
        else
            echo "Attempt $attempts failed."
            if [ $attempts -lt $max_attempts ]; then
                echo "Retrying with different options..."
                sleep 2
            fi
        fi
    done
    
    echo "Error during capture after $max_attempts attempts. Check ffmpeg output for details."
    # Remove incomplete file if capture failed
    if [ -f "$full_path" ]; then
        rm -f "$full_path"
        echo "Removed incomplete file: $full_path"
    fi
    return 1
}

# --- Main Script Logic ---
debug_echo "Capture script starting..."

# Check dependencies
check_dependencies

# Parse arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <channel_name> <stream_url> [use_proxy] [proxy_cmd]"
    echo "Example: $0 N1 \"http://example.com/stream.m3u8\""
    exit 1
fi

CHANNEL_NAME="$1"
STREAM_URL="$2"
USE_PROXY="${3:-false}"
PROXY_CMD="${4:-}"

debug_echo "Channel: $CHANNEL_NAME"
debug_echo "Stream URL: $STREAM_URL"
debug_echo "Use proxy: $USE_PROXY"
debug_echo "Proxy command: $PROXY_CMD"

# Validate channel name
if [[ ! "$CHANNEL_NAME" =~ ^(N1|Nova)$ ]]; then
    echo "Error: Invalid channel name '$CHANNEL_NAME'. Must be 'N1' or 'Nova'."
    exit 1
fi

# Start capture
capture_stream "$CHANNEL_NAME" "$STREAM_URL" "$USE_PROXY" "$PROXY_CMD"

exit 0
