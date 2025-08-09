#!/usr/bin/env bash
set -e

# Colors
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
  echo -e "${RED}Please do not run this script as root.${NC}"
  exit 1
fi

# Check for required packages
check_dependencies() {
  local missing=()
  for pkg in ssh ufw; do
    if ! command -v $pkg &> /dev/null; then
      missing+=("$pkg")
    fi
  done
  
  if [ ${#missing[@]} -gt 0 ]; then
    echo -e "${YELLOW}Installing missing dependencies: ${missing[*]}${NC}"
    sudo apt update
    sudo apt install -y "${missing[@]}"
  fi
}

setup_firewall() {
  local ports=()
  case $1 in
    1) ports+=(5910) ;;
    2) ports+=(3389) ;;
    3) ports+=(3389 5901) ;;
    4) ports+=(3389 5910) ;;
  esac

  if ! sudo ufw status | grep -q "Status: active"; then
    echo -e "${YELLOW}Enabling UFW firewall${NC}"
    sudo ufw --force enable
  fi

  for port in "${ports[@]}"; do
    if ! sudo ufw status | grep -q "$port"; then
      echo -e "${GREEN}Opening port $port${NC}"
      sudo ufw allow $port
    fi
  done
}

setup_ssh_tunnel() {
  local vnc_port=$1
  local ssh_port=${2:-22}
  
  echo -e "${GREEN}Setting up SSH tunnel instructions for VNC${NC}"
  echo -e "${BLUE}=============================================${NC}"
  echo -e "For secure remote access, connect using SSH tunnel:"
  echo -e "ssh -L 5900:localhost:$vnc_port ${USER}@$(hostname -I | awk '{print $1}') -p $ssh_port"
  echo
  echo -e "Then connect your VNC client to localhost:5900"
  echo -e "${BLUE}=============================================${NC}"
  echo
  
  # Add to user's bashrc for easy reference
  if ! grep -q "VNC_SSH_TUNNEL" ~/.bashrc; then
    echo -e "\n# VNC SSH Tunnel Instructions" >> ~/.bashrc
    echo "alias vnc-tunnel='echo \"ssh -L 5900:localhost:$vnc_port ${USER}@\$(hostname -I | awk '\''{print \$1}'\'') -p $ssh_port\"'" >> ~/.bashrc
  fi
}

echo -e "${GREEN}Virtual Display Setup Menu${NC}"
echo "1) Headless: Xvfb + Openbox + Xterm + TigerVNC (SSH tunneled)"
echo "2) GUI: Xvfb + XFCE4 + XRDP"
echo "3) XFCE4 + XRDP + VNC (with password prompt/env, SSH tunneled)"
echo "4) All-in-One (Option 3 + extras, SSH tunneled)"
read -p "Select option [1-4]: " choice

check_dependencies

case "$choice" in
1)
    echo -e "${GREEN}Installing Headless setup...${NC}"
    sudo apt update
    sudo apt install -y xvfb openbox xterm tigervnc-standalone-server tigervnc-common

    # Create systemd service for Xvfb
    sudo bash -c 'cat >/etc/systemd/system/xvfb@.service' <<EOF
[Unit]
Description=Virtual X Framebuffer Service on display :%i
After=network.target

[Service]
ExecStart=/usr/bin/Xvfb :%i -screen 0 1024x768x24 -nolisten tcp
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable --now xvfb@10

    # Setup TigerVNC
    mkdir -p ~/.vnc
    if [ -z "$VNC_PASS" ]; then
        echo "Enter VNC password:"
        vncpasswd
    else
        echo "$VNC_PASS" | vncpasswd -f > ~/.vnc/passwd
        chmod 600 ~/.vnc/passwd
    fi

    cat >~/.vnc/xstartup <<EOF
#!/bin/sh
export DISPLAY=:10
openbox-session &
xterm &
EOF
    chmod +x ~/.vnc/xstartup

    vncserver :10 -localhost -nolisten tcp
    setup_firewall 1
    setup_ssh_tunnel 5910
    echo -e "${GREEN}Headless setup complete!${NC}"
    echo -e "Connect securely via SSH tunnel (see instructions above)"
    ;;
2)
    echo -e "${GREEN}Installing GUI (XFCE4 + XRDP)...${NC}"
    sudo apt update
    sudo apt install -y xvfb xfce4 xfce4-goodies xrdp dbus-x11

    sudo systemctl enable --now xrdp
    setup_firewall 2

    # Xfce4 session for XRDP
    echo "xfce4-session" >~/.xsession
    sudo sed -i.bak '/fi/a startxfce4' /etc/xrdp/startwm.sh

    echo -e "${GREEN}GUI setup complete! Connect via RDP on port 3389${NC}"
    ;;
3)
    echo -e "${GREEN}Installing XFCE4 + XRDP + VNC...${NC}"
    sudo apt update
    sudo apt install -y xfce4 xfce4-goodies xrdp tigervnc-standalone-server tigervnc-common dbus-x11

    # Setup XRDP
    sudo systemctl enable --now xrdp
    echo "xfce4-session" >~/.xsession
    sudo sed -i.bak '/fi/a startxfce4' /etc/xrdp/startwm.sh

    # Setup VNC
    mkdir -p ~/.vnc
    if [ -z "$VNC_PASS" ]; then
        echo "Enter VNC password:"
        vncpasswd
    else
        echo "$VNC_PASS" | vncpasswd -f > ~/.vnc/passwd
        chmod 600 ~/.vnc/passwd
    fi

    cat >~/.vnc/xstartup <<EOF
#!/bin/sh
xrdb \$HOME/.Xresources
startxfce4 &
EOF
    chmod +x ~/.vnc/xstartup

    vncserver :1 -localhost -nolisten tcp
    setup_firewall 3
    setup_ssh_tunnel 5901
    echo -e "${GREEN}XFCE4 + XRDP + VNC setup complete!${NC}"
    echo -e "VNC: Connect via SSH tunnel (see instructions above)"
    echo -e "RDP: port 3389"
    ;;
4)
    echo -e "${GREEN}Installing All-in-One setup...${NC}"
    sudo apt update
    sudo apt install -y xvfb xfce4 xfce4-goodies openbox xterm tigervnc-standalone-server tigervnc-common xrdp dbus-x11

    # Xvfb
    sudo bash -c 'cat >/etc/systemd/system/xvfb@.service' <<EOF
[Unit]
Description=Virtual X Framebuffer Service on display :%i
After=network.target

[Service]
ExecStart=/usr/bin/Xvfb :%i -screen 0 1024x768x24 -nolisten tcp
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable --now xvfb@10

    # XRDP
    sudo systemctl enable --now xrdp
    echo "xfce4-session" >~/.xsession
    sudo sed -i.bak '/fi/a startxfce4' /etc/xrdp/startwm.sh

    # VNC
    mkdir -p ~/.vnc
    if [ -z "$VNC_PASS" ]; then
        echo "Enter VNC password:"
        vncpasswd
    else
        echo "$VNC_PASS" | vncpasswd -f > ~/.vnc/passwd
        chmod 600 ~/.vnc/passwd
    fi

    cat >~/.vnc/xstartup <<EOF
#!/bin/sh
export DISPLAY=:10
openbox-session &
startxfce4 &
xterm &
EOF
    chmod +x ~/.vnc/xstartup

    vncserver :10 -localhost -nolisten tcp
    setup_firewall 4
    setup_ssh_tunnel 5910
    echo -e "${GREEN}All-in-One setup complete!${NC}"
    echo -e "VNC: Connect via SSH tunnel (see instructions above)"
    echo -e "RDP: port 3389"
    ;;
*)
    echo -e "${RED}Invalid choice.${NC}"
    exit 1
    ;;
esac

echo -e "${GREEN}Setup completed successfully!${NC}"