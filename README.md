# Virtual Display Setup Script

This script provides multiple options for setting up virtual displays with different desktop environments and remote access protocols on Linux systems.

## Features

- Multiple setup options:
  - Headless (Xvfb + Openbox + Xterm + TigerVNC)
  - GUI (Xvfb + XFCE4 + XRDP)
  - XFCE4 + XRDP + VNC
  - All-in-One (Complete solution)
- Automatic service configuration
- Secure VNC password setup
- Systemd service integration

## Prerequisites

- Ubuntu/Debian-based Linux distribution
- sudo privileges
- Internet connection

## Installation & Usage

1. Download the script:
   ```bash
   curl -O https://raw.githubusercontent.com/mikfilltrade/virtual-display-setup/refs/heads/main/setup_virtual_display.sh
   chmod +x setup.sh
   ```

2. Run the script:
   ```bash
   ./setup_virtual_display.sh
   ```

3. Select your preferred option from the menu.

## Setup Options

### Option 1: Headless Setup (Xvfb + Openbox + Xterm + TigerVNC)
- Creates a lightweight virtual display
- Includes:
  - Xvfb (X virtual framebuffer)
  - Openbox (minimal window manager)
  - Xterm (terminal emulator)
  - TigerVNC (remote access)
- Automatically creates a systemd service for Xvfb
- Sets up VNC with password protection
- Default VNC port: 5910

### Option 2: GUI Setup (Xvfb + XFCE4 + XRDP)
- Installs a full XFCE4 desktop environment
- Includes:
  - Xvfb
  - XFCE4 desktop
  - XRDP for RDP access
- Automatically configures XRDP to use XFCE4
- Default RDP port: 3389

### Option 3: XFCE4 + XRDP + VNC
- Combines XFCE4 with both RDP and VNC access
- Includes password-protected VNC
- Default ports:
  - VNC: 5901
  - RDP: 3389

### Option 4: All-in-One Setup
- Complete solution combining all features:
  - Xvfb on display :10
  - Openbox + XFCE4
  - Xterm
  - TigerVNC (port 5910)
  - XRDP (port 3389)

## Environment Variables

You can preset the VNC password using:
```bash
export VNC_PASS="yourpassword"
./setup.sh
```

## Post-Installation

### For VNC Connections:
- Use a VNC client to connect to:
  - `localhost:5901` (Option 3)
  - `localhost:5910` (Options 1 & 4)

### For RDP Connections:
- Use any RDP client to connect to:
  - `localhost:3389` (Options 2, 3 & 4)

## Management Commands

### Xvfb Service:
```bash
sudo systemctl status xvfb@10
sudo systemctl restart xvfb@10
```

### XRDP Service:
```bash
sudo systemctl status xrdp
sudo systemctl restart xrdp
```

### VNC Server:
```bash
# Start
vncserver :1

# Stop
vncserver -kill :1
```

## Customization

### Resolution:
Edit the Xvfb service file to change resolution:
```bash
sudo nano /etc/systemd/system/xvfb@.service
```
Modify the `-screen 0` parameter (e.g., `1280x1024x24`)

### VNC Configuration:
Edit the startup script:
```bash
nano ~/.vnc/xstartup
```

## Security Notes

- VNC passwords are stored in `~/.vnc/passwd`
- For production use, consider:
  - Setting up SSH tunneling
  - Using more secure authentication methods
  - Configuring firewalls to restrict access

## Troubleshooting

### Common Issues:

1. **Blank screen on VNC connection**:
   - Verify the xstartup file has execute permissions
   - Check that the DISPLAY variable matches your Xvfb display

2. **XRDP not starting XFCE4**:
   - Verify ~/.xsession exists with "xfce4-session"
   - Check /etc/xrdp/startwm.sh modifications

3. **VNC password not working**:
   - Regenerate the password file using `vncpasswd`

### Logs:
- Xvfb: `journalctl -u xvfb@10 -f`
- XRDP: `/var/log/xrdp.log`
- VNC: `~/.vnc/*.log`

## Uninstallation

To remove all components:
```bash
sudo apt remove xvfb xfce4 xfce4-goodies openbox xterm tigervnc-standalone-server tigervnc-common xrdp
sudo rm /etc/systemd/system/xvfb@.service
sudo systemctl daemon-reload
```

## License

MIT License - Free for personal and commercial use
