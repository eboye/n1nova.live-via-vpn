# United Media Streamer

A powerful Bash script for streaming N1 and Nova channels through NordVPN SOCKS proxy with VPN isolation. The script supports both VLC and MPV players and provides automatic dependency detection and installation instructions for multiple Linux distributions.

## 🎯 Features

- **VPN Isolation**: Routes only the media player through NordVPN SOCKS proxy
- **Multiple Players**: Support for both VLC and MPV with automatic selection
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

### Media Players (at least one required)
- `vlc` - Versatile media player
- `mpv` - Lightweight media player

### Optional Dependencies
- `proxychains` - For SOCKS proxy routing (automatically handled)

## 🚀 Installation

### Quick Start

1. Clone or download the script:
```bash
git clone <repository-url>
cd unitedmedia
chmod +x um.sh
```

2. Run the script:
```bash
./um.sh
```

The script will automatically detect missing dependencies and provide installation commands for your distribution.

### Distribution-Specific Installation

#### Fedora/RHEL/CentOS
```bash
sudo dnf install curl grep sed bash nordvpn gum vlc mpv
# For MPV (if not in repos):
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install mpv
```

#### Debian/Ubuntu/Mint/Pop
```bash
sudo apt update
sudo apt install curl grep sed bash nordvpn gum vlc mpv
# For gum (if not in repos):
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum
```

#### Arch/Manjaro/EndeavourOS
```bash
sudo pacman -S curl grep sed bash nordvpn gum vlc mpv
# For gum (AUR):
yay -S gum
# or
paru -S gum
```

#### NixOS
Add to your `configuration.nix`:
```nix
environment.systemPackages = with pkgs; [
  curl grep sed bash nordvpn gum vlc mpv
];
```
Then run: `sudo nixos-rebuild switch`

#### Alpine
```bash
sudo apk add curl grep sed bash nordvpn gum vlc mpv
```

#### FreeBSD
```bash
sudo pkg install curl grep sed bash nordvpn gum vlc mpv
```

#### OpenSUSE
```bash
sudo zypper install curl grep sed bash nordvpn gum vlc mpv
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
# Select channel directly (1=N1, 2=Nova)
./um.sh 1    # Stream N1
./um.sh 2    # Stream Nova
```

### Interactive Flow

1. **Player Selection**: Choose between VLC and MPV (if both available)
2. **VPN Choice**: Select whether to use NordVPN proxy
3. **Country Selection**: Choose VPN country (if VPN enabled)
4. **Channel Selection**: Choose between N1 and Nova channels

### VPN Countries Supported

- `nl` - Netherlands (default)
- `de` - Germany
- `us` - United States
- `uk` - United Kingdom
- `fr` - France
- `se` - Sweden
- `no` - Norway
- `dk` - Denmark
- `fi` - Finland
- `ch` - Switzerland
- `at` - Austria
- `be` - Belgium
- `es` - Spain
- `it` - Italy
- `pl` - Poland
- `cz` - Czech Republic
- `hu` - Hungary
- `ro` - Romania
- `bg` - Bulgaria
- `hr` - Croatia
- `si` - Slovenia
- `sk` - Slovakia
- `ee` - Estonia
- `lv` - Latvia
- `lt` - Lithuania
- `pt` - Portugal
- `gr` - Greece
- `tr` - Turkey
- `il` - Israel
- `za` - South Africa
- `au` - Australia
- `nz` - New Zealand
- `sg` - Singapore
- `jp` - Japan
- `kr` - South Korea
- `in` - India
- `ca` - Canada
- `mx` - Mexico
- `br` - Brazil
- `ar` - Argentina
- `phoenix` - Phoenix, US
- `san-francisco` - San Francisco, US
- `stockholm` - Stockholm, SE

## 🔧 Technical Details

### VPN Isolation

The script uses NordVPN SOCKS5 proxy servers to route only the media player traffic through the VPN, leaving your other applications unaffected:

- **SOCKS5 Proxy**: `nordhold.net` servers with authentication
- **Proxy Method**: Uses `proxychains` for reliable SOCKS routing
- **Process Isolation**: Only the media player uses the VPN
- **Cleanup**: Automatic cleanup of proxy configurations

### Player Compatibility

- **VLC**: Uses proxychains for SOCKS proxy routing
- **MPV**: Uses proxychains for SOCKS proxy routing
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

2. **VPN Connection Fails**
   - Check NordVPN **service credentials** in `nordvpn_credentials.conf`
   - Verify credentials are from https://my.nordaccount.com/dashboard/nordvpn/manual-configuration/service-credentials/
   - Ensure you're using service credentials, not regular login credentials
   - Verify NordVPN subscription is active
   - Try different VPN country

3. **Stream Won't Play**
   - Check internet connectivity
   - Try without VPN first
   - Verify media player installation

4. **Permission Denied**
   - Ensure script is executable: `chmod +x um.sh`
   - Check credentials file permissions: `chmod 600 nordvpn_credentials.conf`

5. **Proxy Issues**
   - Verify proxychains is installed
   - Check SOCKS proxy connectivity
   - Try different VPN server

### Debug Steps

1. Enable debug mode in the script
2. Run the script and examine output
3. Check for specific error messages
4. Verify all dependencies are installed
5. Test NordVPN credentials manually

## 📁 File Structure

```
unitedmedia/
├── um.sh                           # Main script
├── nordvpn_credentials.conf        # Credentials file (auto-created)
├── nordvpn_credentials.conf.example # Credentials template
├── .gitignore                      # Git ignore file
└── README.md                       # This documentation
```

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
- **VLC** - Excellent cross-platform media player
- **MPV** - Lightweight and powerful media player
- **Gum** - Beautiful interactive CLI tool
- **Proxychains** - Reliable SOCKS proxy routing

## 📞 Support

For issues and questions:
1. Check the troubleshooting section
2. Enable debug mode and examine output
3. Verify all dependencies are installed
4. Create an issue with detailed information about your system and the error

---

**Disclaimer**: This script is for educational and personal use only. Users are responsible for complying with all applicable laws and terms of service of the streaming providers and VPN services.
