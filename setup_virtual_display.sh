#!/usr/bin/env bash
set -e

# Colors
GREEN="\033[0;32m"
NC="\033[0m"

echo -e "${GREEN}Virtual Display Setup Menu${NC}"
echo "1) Headless: Xvfb + Openbox + Xterm + TigerVNC"
echo "2) GUI: Xvfb + XFCE4 + XRDP"
echo "3) XFCE4 + XRDP + VNC (with password prompt/env)"
echo "4) All-in-One (Option 3 + extras)"
read -p "Select option [1-4]: " choice

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

    vncserver :10
    echo -e "${GREEN}Headless setup complete! Connect to VNC on port 5910${NC}"
    ;;
2)
    echo -e "${GREEN}Installing GUI (XFCE4 + XRDP)...${NC}"
    sudo apt update
    sudo apt install -y xvfb xfce4 xfce4-goodies xrdp dbus-x11

    sudo systemctl enable --now xrdp

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
xrdb $HOME/.Xresources
startxfce4 &
EOF
    chmod +x ~/.vnc/xstartup

    vncserver :1
    echo -e "${GREEN}XFCE4 + XRDP + VNC setup complete!${NC}"
    echo "VNC: :1 (port 5901), RDP: port 3389"
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

    vncserver :10
    echo -e "${GREEN}All-in-One setup complete!${NC}"
    echo "VNC: :10 (port 5910), RDP: port 3389"
    ;;
*)
    echo "Invalid choice."
    exit 1
    ;;
esac
