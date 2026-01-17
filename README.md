# United Media Streamer & Capture

A powerful Bash script for streaming and capturing N1 and Nova channels through NordVPN SOCKS proxy with VPN isolation. The script supports MPV player for streaming and multiple tools (ffmpeg, streamlink, yt-dlp) for capturing streams to MP4 files. It provides automatic dependency detection and installation instructions for multiple Linux distributions.

## 🎯 Features

- **VPN Isolation**: Routes only the media player/capture through NordVPN SOCKS proxy
- **MPV Player**: Support for MPV media player for streaming
- **Stream Capturing**: Capture streams to MP4 files with multiple capture tools
- **Simultaneous Operations**: Stream and capture at the same time
- **Multiple Capture Tools**: Supports ffmpeg, streamlink, and yt-dlp for capture
- **Channel Support**: Stream N1 and Nova channels
- **Cross-Platform**: Works on Fedora, Debian, Arch, NixOS, Alpine, FreeBSD, OpenSUSE
- **Smart Dependencies**: Automatic detection and installation instructions
- **Secure Credential Storage**: Encrypted storage of NordVPN credentials
- **Debug Mode**: Verbose logging for troubleshooting

## 📦 Dependencies

### Required Dependencies
- `curl` - HTTP client for testing connectivity
- `grep` - Text processing utility
- `sed` - Stream editor for text manipulation
- `bash` - Shell environment (version 4.0+)
- `nordvpn` - NordVPN client
- `gum` - Interactive CLI tool for prompts

### Media Players (required)
- `mpv` - Lightweight media player

### Capture Tools (at least one required)
- `ffmpeg` - Versatile multimedia framework (default)
- `streamlink` - Professional live streaming capture tool (recommended)
- `yt-dlp` - Universal media downloader (recommended)

### Optional Dependencies
- `proxychains4` - For SOCKS proxy routing on Ubuntu/Debian (automatically handled)
- `proxychains` - For SOCKS proxy routing on other distributions (automatically handled)

## 🚀 Installation

### Quick Start

1. Clone or download the script:
```bash
git clone <repository-url>
cd unitedmedia
chmod +x um.sh capture.sh
```

2. Run the script:
```bash
./um.sh
```

The script will automatically detect missing dependencies and provide installation commands for your distribution.

### Distribution-Specific Installation

#### Fedora/RHEL/CentOS
```bash
sudo dnf install curl grep sed bash nordvpn gum mpv ffmpeg
# For MPV (if not in repos):
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install mpv
# For streamlink (recommended for capture):
sudo pip install streamlink
# For yt-dlp (alternative capture tool):
sudo pip install yt-dlp
```

#### Debian/Ubuntu/Mint/Pop
```bash
sudo apt update
sudo apt install curl grep sed bash nordvpn gum mpv ffmpeg proxychains4
# For gum (if not in repos):
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum
# For streamlink (recommended for capture):
sudo pip install streamlink
# For yt-dlp (alternative capture tool):
sudo pip install yt-dlp
```

#### Arch/Manjaro/EndeavourOS
```bash
sudo pacman -S curl grep sed bash nordvpn gum mpv ffmpeg streamlink yt-dlp
# For gum (AUR):
yay -S gum
# or
paru -S gum
```

#### NixOS
Add to your `configuration.nix`:
```nix
environment.systemPackages = with pkgs; [
  curl grep sed bash nordvpn gum mpv ffmpeg streamlink yt-dlp
];
```
Then run: `sudo nixos-rebuild switch`

#### Alpine
```bash
sudo apk add curl grep sed bash nordvpn gum mpv ffmpeg streamlink yt-dlp
```

#### FreeBSD
```bash
sudo pkg install curl grep sed bash nordvpn gum mpv ffmpeg streamlink yt-dlp
```

#### OpenSUSE
```bash
sudo zypper install curl grep sed bash nordvpn gum mpv ffmpeg streamlink yt-dlp
```

## ⚙️ Configuration

### Automatic Configuration

The script will automatically create a configuration file when you first run it:

1. Run the script: `./um.sh`
2. When prompted for NordVPN **service credentials**:
   ```
   NordVPN credentials not found or incomplete in './nordvpn_credentials.conf'.
   NordVPN Username: [enter your service username]
   NordVPN Password: [enter your service password, hidden]
   ```
3. The script will create `nordvpn_credentials.conf` with secure permissions (600)

**Note**: You'll need NordVPN service credentials from https://my.nordaccount.com/dashboard/nordvpn/manual-configuration/service-credentials/ - these are different from your regular NordVPN login credentials.

### Manual Configuration

**Important**: This script requires NordVPN **service credentials**, not your regular NordVPN account credentials.

#### Getting NordVPN Service Credentials

1. Visit the NordVPN Service Credentials page: https://my.nordaccount.com/dashboard/nordvpn/manual-configuration/service-credentials/
2. Log in with your NordVPN account
3. Click "Create new credentials" or use existing ones
4. Copy the **Username** and **Password** fields
5. Use these service credentials in the configuration file

**Note**: Service credentials are different from your main NordVPN login credentials. They are specifically designed for manual configurations and SOCKS proxy access.

Create a file named `nordvpn_credentials.conf` in the same directory as the script:

```bash
# Copy the example file
cp nordvpn_credentials.conf.example nordvpn_credentials.conf
```

Edit the file with your NordVPN **service credentials**:

```bash
NORDVPN_USER="your_nordvpn_service_username"
NORDVPN_PASS="your_nordvpn_service_password"
```

**Important**: Set secure permissions:
```bash
chmod 600 nordvpn_credentials.conf
```

### Configuration File Location

- **Default location**: `./nordvpn_credentials.conf` (same directory as script)
- **Format**: Shell variables with quoted values
- **Security**: File is automatically set to 600 permissions (owner read/write only)
- **Git protection**: File is included in `.gitignore` to prevent accidental commits

## 🎮 Usage

### Basic Usage

```bash
./um.sh
```

### Command Line Options

```bash
# Select action and channel (1=Stream, 2=Capture, 3=Stream & Capture; 1=N1, 2=Nova)
./um.sh 1 1    # Stream N1
./um.sh 1 2    # Stream Nova
./um.sh 2 1    # Capture N1
./um.sh 2 2    # Capture Nova
./um.sh 3 1    # Stream & Capture N1
./um.sh 3 2    # Stream & Capture Nova
```

### Interactive Flow

1. **Action Selection**: Choose between Stream, Capture, or Stream & Capture
2. **Player Selection**: Choose MPV (only for streaming)
3. **VPN Choice**: Select whether to use NordVPN proxy
4. **Country Selection**: Choose VPN country (if VPN enabled)
5. **Channel Selection**: Choose between N1 and Nova channels

### Stream Capturing

When you choose the "Capture" option, the script will:
- Capture the stream to a MP4 file in the `./captures/` directory
- Use the format `[channel]_[timestamp].mp4` (e.g., `N1_20231214_143022.mp4`)
- Support VPN proxy routing for capture
- Allow you to stop recording with Ctrl+C
- Show file size after successful capture
- **Tool Selection**: Automatically uses the best available capture tool (streamlink → yt-dlp → ffmpeg)

**Capture Tool Priority:**
1. **streamlink** (recommended) - Professional live streaming capture
2. **yt-dlp** (recommended) - Universal media downloader
3. **ffmpeg** - Basic fallback option

**Note**: At least one capture tool must be installed. The script will warn you if none are available.

### Stream & Capture (Simultaneous)

When you choose the "Stream & Capture" option, the script will:
- Start both streaming and capturing simultaneously
- Stream to your chosen media player (MPV) in the foreground
- Capture to MP4 file in the background using the best available tool
- Use the same VPN proxy settings for both operations
- Stop both processes when you press Ctrl+C
- Show capture status and file size when complete

**Benefits of Stream & Capture:**
- Watch the stream while recording it
- Single command to do both operations
- Synchronized start/stop of both processes
- Same VPN routing for both streaming and capture
- Professional-grade capture with streamlink/yt-dlp

**Note**: This mode requires both a media player (MPV) and at least one capture tool to be installed.

### Distribution-Specific Proxychains

The script automatically detects your Linux distribution and uses the appropriate proxychains configuration:

#### Arch Linux & Derivatives
- **Binary**: `proxychains` (symlink to proxychains4)
- **Config**: Simple format with space-separated values
- **DNS**: External DNS fallback (8.8.8.8) for reliability
- **Installation**: `sudo pacman -S proxychains4` (provides proxychains symlink)

#### Ubuntu/Debian & Derivatives
- **Binary**: `proxychains4` (separate package from proxychains)
- **Config**: Simple format with space-separated values
- **DNS**: External DNS fallback (8.8.8.8) for reliability
- **Installation**: `sudo apt install proxychains4` (not proxychains)

#### Other Distributions
- **Binary**: Auto-detection (proxychains4 preferred, fallback to proxychains)
- **Config**: Simple format with space-separated values
- **DNS**: External DNS fallback (8.8.8.8) for reliability

**Important**: Ubuntu/Debian users must install `proxychains4`, not `proxychains`, as the latter is an incompatible version.

### VPN Countries Supported

- `nl` - Netherlands (default)
- `de` - Germany  
- `us` - United States
- `uk` - United Kingdom
- `fr` - France
- `se` - Sweden
- `no` - Norway

## 🔧 Technical Details

### VPN Isolation

The script uses NordVPN SOCKS5 proxy servers to route only the media player traffic through the VPN, leaving your other applications unaffected:

- **SOCKS5 Proxy**: `nordhold.net` servers with authentication
- **Proxy Method**: Uses `proxychains` for reliable SOCKS routing
- **Process Isolation**: Only the media player uses the VPN
- **Cleanup**: Automatic cleanup of proxy configurations

### Tool Compatibility

- **MPV**: Uses proxychains for SOCKS proxy routing (streaming/capture)
- **streamlink**: Uses proxychains for SOCKS proxy routing (capture only)
- **yt-dlp**: Uses proxychains for SOCKS proxy routing (capture only)
- **ffmpeg**: Uses proxychains for SOCKS proxy routing (capture only)
- **Fallback**: Graceful fallback if proxy is unavailable

### Debug Mode

Enable verbose debugging by editing the script:

```bash
# Change this line in um.sh
DEBUG_MODE=true  # Set to true to enable verbose debugging output
```

Debug output includes:
- Dependency checking
- Player detection
- VPN connection status
- Proxy configuration
- Stream URL extraction
- Command execution details

## 🛠️ Troubleshooting

### Common Issues

1. **Dependencies Missing**
   - Run the script - it will detect and provide installation commands
   - Follow the distribution-specific instructions provided

2. **Ubuntu/Debian Proxychains Issue**
   - **Error**: `/usr/bin/proxychains: 9: exec: -f: not found`
   - **Cause**: Ubuntu's default `proxychains` package (v3.1) doesn't support the `-f` flag
   - **Solution**: Install `proxychains4` instead:
     ```bash
     sudo apt install proxychains4
     sudo apt remove proxychains  # Optional: remove old version
     ```
   - **Note**: The script automatically detects and uses the correct binary

3. **VPN Connection Fails**
   - Check NordVPN **service credentials** in `nordvpn_credentials.conf`
   - Verify credentials are from https://my.nordaccount.com/dashboard/nordvpn/manual-configuration/service-credentials/
   - Ensure you're using service credentials, not regular login credentials
   - Verify NordVPN subscription is active
   - Try different VPN country

4. **Stream Won't Play/Capture**
   - Check internet connectivity
   - Try without VPN first
   - Verify media player installation
   - For capture: ensure at least one capture tool is installed (streamlink/yt-dlp/ffmpeg)

5. **Capture Issues**
   - Install capture tools: `sudo pacman -S streamlink yt-dlp` (Arch) or `sudo pip install streamlink yt-dlp`
   - Check disk space in captures directory
   - Ensure you have write permissions to ./captures/
   - Try different capture tools if one fails
   - streamlink and yt-dlp work better than ffmpeg for complex HLS streams

6. **Permission Denied**
   - Ensure script is executable: `chmod +x um.sh capture.sh`
   - Check credentials file permissions: `chmod 600 nordvpn_credentials.conf`

7. **Proxy Issues**
   - Verify proxychains4 is installed on Ubuntu/Debian (not proxychains)
   - Verify proxychains is installed on other distributions
   - Check SOCKS proxy connectivity
   - Try different VPN server

8. **DNS Resolution Issues**
   - **Error**: Local DNS resolves NordVPN servers to `127.0.0.1`
   - **Cause**: Local DNS hijacking or misconfiguration
   - **Solution**: Script automatically uses external DNS (8.8.8.8) for NordVPN servers
   - **Manual Check**: `dig @8.8.8.8 +short nl.socks.nordhold.net`
   - **Note**: This prevents local DNS from interfering with VPN server resolution

9. **Capture Tool Selection**
   - **streamlink** (recommended): Professional live streaming capture
   - **yt-dlp** (recommended): Universal media downloader
   - **ffmpeg** (basic fallback option)
   - The script automatically tries tools in priority order

### Debug Steps

1. Enable debug mode in the script
2. Run the script and examine output
3. Check for specific error messages
4. Verify all dependencies are installed
5. Test NordVPN credentials manually

## 📁 File Structure

```
unitedmedia/
├── um.sh                           # Main streaming script
├── capture.sh                      # Stream capture script (supports multiple tools)
├── nordvpn_credentials.conf        # Credentials file (auto-created)
├── nordvpn_credentials.conf.example # Credentials template
├── captures/                       # Directory for captured videos (auto-created)
├── .gitignore                      # Git ignore file
└── README.md                       # This documentation
```

## 🔧 Technical Details

### Stream Capture Tools

The capture script supports multiple tools with automatic fallback:

1. **streamlink** (highest priority)
   - Professional live streaming capture tool
   - Best for complex HLS streams
   - Command: `streamlink --stdout "$url" best -o "$file"`

2. **yt-dlp** (high priority)
   - Universal media downloader
   - Excellent HLS support
   - Command: `yt-dlp -o "$file" "$url"`

3. **ffmpeg** (fallback priority)
   - Basic capture capability
   - May struggle with complex HLS streams
   - Command: `ffmpeg -i "$url" -c copy "$file"`

### Tool Selection Logic

```bash
if command -v streamlink &> /dev/null; then
    # Use streamlink
elif command -v yt-dlp &> /dev/null; then
    # Use yt-dlp
else
    # Use ffmpeg (must be available)
fi
```

### Session Management

- **Stream URLs**: Extracted from web pages with session tokens
- **Authentication**: Each stream URL contains unique session parameters
- **Conflict Avoidance**: Stream & Capture mode uses same URL with proper timing
- **Proxy Routing**: All tools use proxychains for SOCKS proxy routing

## 🔒 Security Notes

- **Credentials File**: Stored with 600 permissions (owner only)
- **Git Protection**: Credentials file is in `.gitignore`
- **Memory Security**: Credentials are not logged in debug mode
- **Temporary Files**: Proxy configurations are cleaned up automatically

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on multiple distributions
5. Submit a pull request

## 📄 License

This project is provided as-is for educational and personal use. Please respect the terms of service of the streaming providers and NordVPN.

## 🙏 Acknowledgments

- **NordVPN** - For providing SOCKS proxy services
- **MPV** - Lightweight and powerful media player
- **streamlink** - Professional live streaming capture tool
- **yt-dlp** - Universal media downloader
- **Gum** - Beautiful interactive CLI tool
- **Proxychains** - Reliable SOCKS proxy routing
- **ffmpeg** - Versatile multimedia framework

## 📞 Support

For issues and questions:
1. Check the troubleshooting section
2. Enable debug mode and examine output
3. Verify all dependencies are installed
4. Create an issue with detailed information about your system and the error

---

**Disclaimer**: This script is for educational and personal use only. Users are responsible for complying with all applicable laws and terms of service of the streaming providers and VPN services.
