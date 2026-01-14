#!/bin/bash

# Script to stream, capture, or stream & capture N1 or Nova channels using MPV, VLC, or ffmpeg
# It prioritizes MPV, then native VLC, then Flatpak VLC for streaming.
# Uses ffmpeg for capturing streams to MP4 files.
# Can stream and capture simultaneously.
# Defaults to streaming N1 if no options are chosen interactively.
# Uses NordVPN proxy if configured for both streaming and capturing.
#
# Usage:
#   Run interactively: ./um.sh
#   Specify action and channel: ./um.sh 1 1 (1=Stream, 2=Capture, 3=Stream & Capture; 1=N1, 2=Nova)
#
# Dependencies: curl, grep, sed, bash, mpv (native), vlc (native or flatpak), nordvpn CLI, gum, ffmpeg (for capture)
# NordVPN credentials in nordvpn_credentials.conf (optional, prompts if missing)
#
# NordVPN SOCKS Proxy Format: <country_code>.socks.nordvpn.com:1080

# --- Debugging Configuration ---
DEBUG_MODE=false # Set to true to enable verbose debugging output

# Function for debug messages
debug_echo() {
    if [ "$DEBUG_MODE" = true ]; then
        echo "DEBUG: $*" >&2
    fi
}

# --- Configuration ---
declare -A PAGE_URLS
PAGE_URLS=(
    ["N1"]="https://n1nova.live/n1-uzivo.html"
    ["Nova"]="https://n1nova.live/novas-uzivo.html"
)

# --- Function to extract stream URL from a given page ---
extract_stream_url() {
    local page_url="$1"
    local stream_url=""
    local html_content=""

    html_content=$(curl -s -L "$page_url")
    debug_echo "Fetched HTML content length: ${#html_content}"

    stream_url=$(echo "$html_content" | grep -oP 'https?://best-str\.umn\.cdn\.united\.cloud/stream\?stream=sp1400&sp=n1info&channel=n1srp&u=n1info&p=n1Sh4redSecre7iNf0&player=m3u8[^"]*')
    if [ -z "$stream_url" ]; then
        stream_url=$(echo "$html_content" | grep -oP 'https?://best-str\.umn\.cdn\.united\.cloud/stream\?stream=hp7000&sp=novas&channel=novashd&u=novas&p=n0v43!23t001&player=m3u8[^"]*')
    fi

    if [ -z "$stream_url" ]; then
        stream_url=$(echo "$html_content" | grep -oP 'https?://[^"]+\.m3u8[^"]*')
    fi

    stream_url=$(echo "$stream_url" | sed 's/"$//' | sed "s/'$//")
    echo "$stream_url"
}

# --- Function to detect distribution and provide install commands ---
detect_distribution() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif command -v lsb_release &> /dev/null; then
        lsb_release -si | tr '[:upper:]' '[:lower:]'
    elif [ -f /etc/redhat-release ]; then
        echo "fedora"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# --- Function to provide installation commands ---
provide_install_commands() {
    local distro=$(detect_distribution)
    local missing_deps=("$@")

    echo ""
    echo "=== Installation Commands ==="
    echo "Detected distribution: $distro"
    echo ""

    case "$distro" in
        fedora|rhel|centos)
            echo "Install missing dependencies with:"
            echo "sudo dnf install ${missing_deps[*]}"
            echo ""
            echo "For MPV (if not in repos):"
            echo "sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
            echo "sudo dnf install mpv"
            echo ""
            echo "For ffmpeg (required for capture):"
            echo "sudo dnf install ffmpeg"
            ;;
        debian|ubuntu|linuxmint|pop)
            echo "Install missing dependencies with:"
            echo "sudo apt update"
            echo "sudo apt install ${missing_deps[*]}"
            echo ""
            echo "For gum (if not in repos):"
            echo "sudo mkdir -p /etc/apt/keyrings"
            echo "curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg"
            echo "echo \"deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *\" | sudo tee /etc/apt/sources.list.d/charm.list"
            echo "sudo apt update && sudo apt install gum"
            echo ""
            echo "For ffmpeg (required for capture):"
            echo "sudo apt install ffmpeg"
            ;;
        arch|manjaro|endeavouros)
            echo "Install missing dependencies with:"
            echo "sudo pacman -S ${missing_deps[*]}"
            echo ""
            echo "For gum (AUR):"
            echo "yay -S gum"
            echo "or"
            echo "paru -S gum"
            echo ""
            echo "For ffmpeg (required for capture):"
            echo "sudo pacman -S ffmpeg"
            ;;
        nixos)
            echo "Add to your configuration.nix:"
            echo "environment.systemPackages = with pkgs; ["
            for dep in "${missing_deps[@]}"; do
                echo "  $dep"
            done
            echo "  ffmpeg"
            echo "];"
            echo ""
            echo "Then run: sudo nixos-rebuild switch"
            ;;
        alpine)
            echo "Install missing dependencies with:"
            echo "sudo apk add ${missing_deps[*]}"
            echo ""
            echo "For ffmpeg (required for capture):"
            echo "sudo apk add ffmpeg"
            ;;
        freebsd)
            echo "Install missing dependencies with:"
            echo "sudo pkg install ${missing_deps[*]}"
            echo ""
            echo "For ffmpeg (required for capture):"
            echo "sudo pkg install ffmpeg"
            ;;
        opensuse|suse)
            echo "Install missing dependencies with:"
            echo "sudo zypper install ${missing_deps[*]}"
            echo ""
            echo "For ffmpeg (required for capture):"
            echo "sudo zypper install ffmpeg"
            ;;
        *)
            echo "Unknown distribution. Please install the following packages manually:"
            echo "${missing_deps[*]}"
            echo ""
            echo "Common package names:"
            echo "- curl, grep, sed, bash: Usually pre-installed"
            echo "- vlc: vlc"
            echo "- mpv: mpv"
            echo "- nordvpn: nordvpn"
            echo "- gum: gum (may need manual installation from GitHub)"
            echo "- ffmpeg: ffmpeg (required for capture functionality)"
            ;;
    esac
    echo ""
}

# --- Dependency Checks ---
check_dependencies() {
    local missing_deps=()
    local required_deps=("curl" "grep" "sed" "bash" "nordvpn" "gum")
    local media_players=("vlc" "mpv")
    local capture_tools=("ffmpeg")

    # Check required dependencies
    for cmd in "${required_deps[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    # Check for at least one media player
    local player_found=false
    for player in "${media_players[@]}"; do
        if command -v "$player" &> /dev/null; then
            player_found=true
            break
        fi
    done

    if [ "$player_found" = false ]; then
        missing_deps+=("vlc-or-mpv")
    fi

    # Check for ffmpeg (required for capture functionality)
    local ffmpeg_found=false
    if command -v ffmpeg &> /dev/null; then
        ffmpeg_found=true
    fi

    if [ "$ffmpeg_found" = false ]; then
        echo "Warning: ffmpeg not found. Capture functionality will not be available."
        echo "Install ffmpeg with: sudo apt install ffmpeg (Ubuntu/Debian) or sudo dnf install ffmpeg (Fedora)"
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "Error: Missing required command(s): ${missing_deps[*]}"
        provide_install_commands "${missing_deps[@]}"
        exit 1
    fi
    debug_echo "Dependencies (curl, grep, sed, bash, vlc/mpv, nordvpn, gum) found."
}

# --- NordVPN Credential Handling ---
get_nordvpn_credentials() {
    local cred_file="./nordvpn_credentials.conf"
    local user=""
    local pass=""

    debug_echo "Checking for NordVPN credentials..."

    if [ -f "$cred_file" ] && [ -r "$cred_file" ]; then
        user=$(grep NORDVPN_USER "$cred_file" | sed 's/.*="\(.*\)".*/\1/')
        pass=$(grep NORDVPN_PASS "$cred_file" | sed 's/.*="\(.*\)".*/\1/')
        debug_echo "Parsed user: '$user', pass: '$pass'"
    else
        debug_echo "Credentials file '$cred_file' not found or not readable."
    fi

    if [ -z "$user" ] || [ -z "$pass" ]; then
        echo "NordVPN credentials not found or incomplete in '$cred_file'."
        debug_echo "Prompting for NordVPN credentials..."

        user=$(gum input --prompt "NordVPN Username: ")
        pass=$(gum input --prompt "NordVPN Password: " --password)

        if [ -z "$user" ] || [ -z "$pass" ]; then
            echo "NordVPN username and password are required."
            return 1
        fi

        echo "NORDVPN_USER=\"$user\"" > "$cred_file"
        echo "NORDVPN_PASS=\"$pass\"" >> "$cred_file"
        chmod 600 "$cred_file"
        debug_echo "NordVPN credentials saved to $cred_file"
    else
        debug_echo "NordVPN credentials loaded from file."
    fi

    echo "$user"
    echo "$pass"
    return 0
}

# --- Function to select player ---
select_player() {
    local available_players=()
    local player_commands=()

    if command -v mpv &> /dev/null; then
        available_players+=("MPV (Recommended)")
        player_commands+=("mpv")
    fi

    if command -v vlc &> /dev/null; then
        available_players+=("VLC")
        player_commands+=("vlc")
    fi

    if [ ${#available_players[@]} -eq 0 ]; then
        echo "Error: No media players found. Please install VLC or MPV."
        exit 1
    fi

    if [ ${#available_players[@]} -eq 1 ]; then
        echo "Using ${available_players[0]} (only player available)"
        echo "${player_commands[0]}"
        return 0
    fi

    local selected_player=$(gum choose "${available_players[@]}" --header "Select media player:")

    for i in "${!available_players[@]}"; do
        if [ "${available_players[$i]}" = "$selected_player" ]; then
            echo "${player_commands[$i]}"
            return 0
        fi
    done

    echo "vlc"  # Default fallback
    return 0
}

# --- Main Script Logic ---
debug_echo "Script starting..."

# --- Dependency Checks ---
check_dependencies

# --- Select Player ---
echo "Select media player for streaming:"
PLAYER_EXEC_CMD=$(select_player)
exit_code=$?

if [ $exit_code -ne 0 ]; then
    exit 1
fi
debug_echo "Player command determined: '$PLAYER_EXEC_CMD'"

# --- VPN Configuration ---
USE_VPN_CHOICE="" # This will store 'true' or 'false' from gum confirm
VPN_COUNTRY_CODE=""
NORDVPN_USER=""
NORDVPN_PASS=""
SOCKS_PROXY_CMD=""

# Ask if VPN is needed using gum confirm and capture its exit code
if gum confirm "Use VPN for streaming?"; then
    USE_VPN_CHOICE="true"
else
    USE_VPN_CHOICE="false"
fi

# Check if the output of gum confirm is exactly the string "true"
if [ "$USE_VPN_CHOICE" = "true" ]; then
    debug_echo "User wants to use VPN."

    VPN_COUNTRY=$(gum choose "Netherlands (nl)" "Sweden (se)" "United States (us)" "Amsterdam (nl)" "Atlanta (us)" "Chicago (us)" "Dallas (us)" "Los Angeles (us)" "New York (us)" "Phoenix (us)" "San Francisco (us)" "Stockholm (se)")
    VPN_COUNTRY_CODE=$(echo "$VPN_COUNTRY" | grep -oP '\([^)]+\)' | sed 's/[()]//g')

    if [ -z "$VPN_COUNTRY_CODE" ]; then
        echo "Error: Could not determine VPN country code. Please check input."
        exit 1
    fi
    debug_echo "Selected VPN Country Code: $VPN_COUNTRY_CODE"

    output="$(get_nordvpn_credentials)"
    NORDVPN_USER=$(echo "$output" | head -1 | tr -d '\n')
    NORDVPN_PASS=$(echo "$output" | sed -n '2p' | tr -d '\n')
    debug_echo "After extraction: user='$NORDVPN_USER', pass='$NORDVPN_PASS'"
    if [ $? -ne 0 ] || [ -z "$NORDVPN_USER" ] || [ -z "$NORDVPN_PASS" ]; then
        echo "Failed to get NordVPN credentials. Exiting."
        exit 1
    fi
    debug_echo "NordVPN credentials obtained."

    # Test NordVPN SOCKS proxy connectivity first
    debug_echo "Testing SOCKS proxy connectivity..."

    # Map country codes to the new nordhold.net servers
    case "$VPN_COUNTRY_CODE" in
        "nl") SOCKS_SERVER="nl.socks.nordhold.net" ;;
        "se") SOCKS_SERVER="se.socks.nordhold.net" ;;
        "us") SOCKS_SERVER="us.socks.nordhold.net" ;;
        "amsterdam") SOCKS_SERVER="amsterdam.nl.socks.nordhold.net" ;;
        "atlanta") SOCKS_SERVER="atlanta.us.socks.nordhold.net" ;;
        "chicago") SOCKS_SERVER="chicago.us.socks.nordhold.net" ;;
        "dallas") SOCKS_SERVER="dallas.us.socks.nordhold.net" ;;
        "los-angeles") SOCKS_SERVER="los-angeles.us.socks.nordhold.net" ;;
        "new-york") SOCKS_SERVER="new-york.us.socks.nordhold.net" ;;
        "phoenix") SOCKS_SERVER="phoenix.us.socks.nordhold.net" ;;
        "san-francisco") SOCKS_SERVER="san-francisco.us.socks.nordhold.net" ;;
        "stockholm") SOCKS_SERVER="stockholm.se.socks.nordhold.net" ;;
        *) SOCKS_SERVER="nl.socks.nordhold.net" ;;  # Default to Netherlands
    esac

    debug_echo "Using SOCKS server: $SOCKS_SERVER"

    if curl --socks5 "${NORDVPN_USER}:${NORDVPN_PASS}@${SOCKS_SERVER}:1080" -s --max-time 10 https://httpbin.org/ip >/dev/null 2>&1; then
        debug_echo "SOCKS proxy is reachable."

        # Resolve SOCKS server to IP for proxychains
        SOCKS_IP=$(nslookup "$SOCKS_SERVER" | grep -A1 "Name:" | tail -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if [ -z "$SOCKS_IP" ]; then
            debug_echo "Failed to resolve SOCKS server IP, using hostname anyway."
            SOCKS_IP="$SOCKS_SERVER"
        fi
        debug_echo "SOCKS server IP: $SOCKS_IP"

        # Create proxychains configuration
        PROXYCHAINS_CONF="/tmp/proxychains.conf"
        cat > "$PROXYCHAINS_CONF" << EOF
[ProxyList]
socks5  $SOCKS_IP 1080 ${NORDVPN_USER} ${NORDVPN_PASS}
EOF
        SOCKS_PROXY_CMD="proxychains -f $PROXYCHAINS_CONF"
    else
        debug_echo "SOCKS proxy not reachable, trying without VPN."
        SOCKS_PROXY_CMD=""
    fi
    debug_echo "SOCKS proxy command constructed: $SOCKS_PROXY_CMD"
else
    debug_echo "User chose not to use VPN."
fi

# --- Determine Action Choice ---
action_choice_num=""
DEFAULT_ACTION_CHOICE="1" # Default to Stream

# Check if a choice was provided as an argument ($1)
if [ -n "$1" ]; then
    action_choice_num="$1"
    debug_echo "Action choice provided as argument: '$action_choice_num'"
else
    echo "What would you like to do?"
    action_list=("Stream" "Capture" "Stream & Capture")
    debug_echo "Action list array: $(printf '%s ' "${action_list[@]}")"

    gum_choices=()
    for i in "${!action_list[@]}"; do
        choice_num=$((i+1))
        action_name="${action_list[$i]}"
        if [ "$DEFAULT_ACTION_CHOICE" == "$choice_num" ]; then
            gum_choices+=("$choice_num. $action_name (default)")
        else
            gum_choices+=("$choice_num. $action_name")
        fi
    done

    # Use gum choose for action selection.
    debug_echo "Gum choices array: $(printf '%s ' "${gum_choices[@]}")"
    action_choice_num=$(gum choose "${gum_choices[@]}")
    debug_echo "User chose action interactively: '$action_choice_num'"

    # Extract only the number from the gum choose output (e.g., "1. Stream (default)" -> "1")
    action_choice_num=$(echo "$action_choice_num" | grep -oE '^[0-9]+')
fi

# --- Validate Action Choice ---
action_choice_num=$(echo "$action_choice_num" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if ! [[ "$action_choice_num" =~ ^[0-9]+$ ]]; then
    echo "Invalid input. Please enter a number (1, 2, or 3)."
    debug_echo "Exiting due to invalid numeric input."
    exit 1
fi

# --- Validate Action Index ---
action_index=$((action_choice_num - 1))
if [ "$action_index" -lt 0 ] || [ "$action_index" -ge "${#action_list[@]}" ]; then
    echo "Invalid choice. Please select a valid number (1, 2, or 3)."
    debug_echo "Exiting due to out-of-bounds action index."
    exit 1
fi

SELECTED_ACTION="${action_list[$action_index]}"
debug_echo "Selected action: '$SELECTED_ACTION'"

# --- Determine Channel Choice ---
channel_choice_num=""
DEFAULT_CHANNEL_CHOICE="1" # Default to N1

# Check if a choice was provided as an argument ($2 for channel when action was $1)
if [ -n "$2" ] && [ -n "$1" ]; then
    channel_choice_num="$2"
    debug_echo "Channel choice provided as argument: '$channel_choice_num'"
else
    echo "Which channel would you like to ${SELECTED_ACTION,,}?"
    channel_list=()
    for key in "${!PAGE_URLS[@]}"; do
        channel_list+=("$key")
    done
    debug_echo "Channel list array: $(printf '%s ' "${channel_list[@]}")"
    IFS=$'\n' read -r -d '' -a sorted_channels < <(printf '%s\n' "${channel_list[@]}" | sort && printf '\0')
    debug_echo "Sorted channels array: $(printf '%s ' "${sorted_channels[@]}")"

    gum_choices=()
    for i in "${!sorted_channels[@]}"; do
        choice_num=$((i+1))
        channel_name="${sorted_channels[$i]}"
        if [ "$DEFAULT_CHANNEL_CHOICE" == "$choice_num" ]; then
            gum_choices+=("$choice_num. $channel_name (default)")
        else
            gum_choices+=("$choice_num. $channel_name")
        fi
    done

    # Use gum choose for channel selection.
    debug_echo "Gum choices array: $(printf '%s ' "${gum_choices[@]}")"
    channel_choice_num=$(gum choose "${gum_choices[@]}")
    debug_echo "User chose channel interactively: '$channel_choice_num'"

    # Extract only the number from the gum choose output (e.g., "1. N1 (default)" -> "1")
    channel_choice_num=$(echo "$channel_choice_num" | grep -oE '^[0-9]+')
fi

# --- Validate Choice ---
channel_choice_num=$(echo "$channel_choice_num" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if ! [[ "$channel_choice_num" =~ ^[0-9]+$ ]]; then
    echo "Invalid input. Please enter a number (1 or 2)."
    debug_echo "Exiting due to invalid numeric input."
    exit 1
fi

# --- Prepare Channel List and Validate Choice Index ---
channel_list=()
for key in "${!PAGE_URLS[@]}"; do
    channel_list+=("$key")
done
printf '%s\n' "${channel_list[@]}" | sort | mapfile -t sorted_channels

channel_index=$((channel_choice_num - 1))
if [ "$channel_index" -lt 0 ] || [ "$channel_index" -ge "${#sorted_channels[@]}" ]; then
    echo "Invalid choice. Please select a valid number (1 or 2)."
    debug_echo "Exiting due to out-of-bounds choice index."
    exit 1
fi

SELECTED_CHANNEL_NAME="${sorted_channels[$channel_index]}"
SELECTED_PAGE_URL="${PAGE_URLS[$SELECTED_CHANNEL_NAME]}"
debug_echo "Selected channel name: '$SELECTED_CHANNEL_NAME', Page URL: '$SELECTED_PAGE_URL'"

# --- Extract the stream URL ---
STREAM_URL=$(extract_stream_url "$SELECTED_PAGE_URL" 2>/dev/null)
debug_echo "STREAM_URL captured from function output: '$STREAM_URL'"

# --- Check if we found a URL ---
if [ -z "$STREAM_URL" ]; then
  echo "Could not automatically extract a stream URL for '$SELECTED_CHANNEL_NAME'."
  echo "The website structure might have changed, or the stream is unavailable."
  debug_echo "Exiting because STREAM_URL is empty."
  exit 1
fi

# --- Execute Action ---
if [ "$SELECTED_ACTION" = "Stream" ]; then
    echo "Attempting to play stream for $SELECTED_CHANNEL_NAME..."

    PLAYER_CMD="$PLAYER_EXEC_CMD"

    if [ "$USE_VPN_CHOICE" = "true" ]; then # Explicitly check for the string "true"
        if [ -n "$SOCKS_PROXY_CMD" ]; then
            # Use proxychains for both VLC and MPV in VPN mode
            # For VLC, set Wayland compatibility and use proxychains
            if [ "$PLAYER_EXEC_CMD" = "vlc" ]; then
                PLAYER_CMD="$SOCKS_PROXY_CMD env QT_QPA_PLATFORM=xcb $PLAYER_EXEC_CMD"
            else
                PLAYER_CMD="$SOCKS_PROXY_CMD $PLAYER_EXEC_CMD"
            fi
            debug_echo "Using proxychains with $PLAYER_EXEC_CMD for streaming."
        else
            echo "Warning: VPN selected but SOCKS proxy not reachable. Continuing without VPN."
            PLAYER_CMD="$PLAYER_EXEC_CMD"
        fi
    fi

    CMD_STRING="$PLAYER_CMD \"$STREAM_URL\""
    debug_echo "Final command string to eval: '$CMD_STRING'"

    if eval "$CMD_STRING"; then
        echo "Player command executed successfully."
        debug_echo "Script finished successfully."
    else
        echo "Error executing player command. Check player for details."
        debug_echo "Script finished with execution error."
    fi
elif [ "$SELECTED_ACTION" = "Capture" ]; then
    echo "Preparing to capture stream for $SELECTED_CHANNEL_NAME..."

    # Build capture command arguments
    CAPTURE_ARGS=("$SELECTED_CHANNEL_NAME" "$STREAM_URL")

    if [ "$USE_VPN_CHOICE" = "true" ] && [ -n "$SOCKS_PROXY_CMD" ]; then
        CAPTURE_ARGS+=("true" "$SOCKS_PROXY_CMD")
        debug_echo "Using proxy for capture: $SOCKS_PROXY_CMD"
    else
        CAPTURE_ARGS+=("false" "")
    fi

    # Execute capture script
    debug_echo "Capture command: ./capture.sh ${CAPTURE_ARGS[*]}"

    if ./capture.sh "${CAPTURE_ARGS[@]}"; then
        echo "Capture completed successfully."
        debug_echo "Script finished successfully."
    else
        echo "Error during capture. Check capture script output for details."
        debug_echo "Script finished with capture error."
        exit 1
    fi
elif [ "$SELECTED_ACTION" = "Stream & Capture" ]; then
    echo "Preparing to stream AND capture stream for $SELECTED_CHANNEL_NAME..."
    echo "Note: Both operations will run simultaneously. Press Ctrl+C to stop both."

    # Use the same authenticated stream URL for both operations
    # but add delays to avoid session conflicts
    echo "Using authenticated stream URL for both operations..."

    # Build capture command arguments
    CAPTURE_ARGS=("$SELECTED_CHANNEL_NAME" "$STREAM_URL")

    if [ "$USE_VPN_CHOICE" = "true" ] && [ -n "$SOCKS_PROXY_CMD" ]; then
        CAPTURE_ARGS+=("true" "$SOCKS_PROXY_CMD")
        debug_echo "Using proxy for capture: $SOCKS_PROXY_CMD"
    else
        CAPTURE_ARGS+=("false" "")
    fi

    # Build player command
    PLAYER_CMD="$PLAYER_EXEC_CMD"
    if [ "$USE_VPN_CHOICE" = "true" ] && [ -n "$SOCKS_PROXY_CMD" ]; then
        # For VLC, set Wayland compatibility and use proxychains
        if [ "$PLAYER_EXEC_CMD" = "vlc" ]; then
            PLAYER_CMD="$SOCKS_PROXY_CMD env QT_QPA_PLATFORM=xcb $PLAYER_EXEC_CMD"
        else
            PLAYER_CMD="$SOCKS_PROXY_CMD $PLAYER_EXEC_CMD"
        fi
        debug_echo "Using proxychains with $PLAYER_EXEC_CMD for streaming."
    fi

    # Start capture in background first
    echo "Starting capture in background..."
    debug_echo "Capture command: ./capture.sh ${CAPTURE_ARGS[*]}"
    ./capture.sh "${CAPTURE_ARGS[@]}" &
    CAPTURE_PID=$!

    # Give capture more time to initialize before starting player
    # to avoid session conflicts with the same URL
    echo "Waiting for capture to initialize (10 seconds)..."
    sleep 10

    # Start player in foreground
    echo "Starting player..."
    CMD_STRING="$PLAYER_CMD \"$STREAM_URL\""
    debug_echo "Player command: $CMD_STRING"

    # Set up trap to clean up background process on exit
    trap 'echo "Stopping capture process..."; kill $CAPTURE_PID 2>/dev/null; wait $CAPTURE_PID 2>/dev/null; echo "Capture stopped."' EXIT INT TERM

    # Start player
    if eval "$CMD_STRING"; then
        echo "Player command executed successfully."
    else
        echo "Error executing player command. Check player for details."
    fi

    # Wait for capture process to finish
    echo "Waiting for capture to complete..."
    wait $CAPTURE_PID
    CAPTURE_EXIT_CODE=$?

    if [ $CAPTURE_EXIT_CODE -eq 0 ]; then
        echo "Both streaming and capture completed successfully."
        debug_echo "Script finished successfully."
    else
        echo "Capture process ended with error code $CAPTURE_EXIT_CODE."
        debug_echo "Script finished with capture error."
    fi

    # Clear the trap
    trap - EXIT INT TERM
else
    echo "Error: Unknown action '$SELECTED_ACTION'"
    debug_echo "Script finished with unknown action error."
    exit 1
fi

# Cleanup: remove proxychains configuration
if [ -n "$PROXYCHAINS_CONF" ] && [ -f "$PROXYCHAINS_CONF" ]; then
    debug_echo "Cleaning up proxychains configuration..."
    rm -f "$PROXYCHAINS_CONF"
    debug_echo "Proxychains configuration removed."
fi

exit 0
