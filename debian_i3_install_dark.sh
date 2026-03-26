#!/usr/bin/env bash
# ================================================================
#  Debian 12 (Bookworm) — i3 Production Rice
#  Catppuccin Mocha · Full daily-driver setup
#
#  What this script does:
#    - Installs i3, X11, compositing, theming
#    - Asks which browser to install
#    - Configures dunst (notifications, Catppuccin themed)
#    - Configures xss-lock → betterlockscreen (auto-lock on suspend / lid close)
#    - Configures brightnessctl (brightness keys)
#    - Configures libinput (tap-to-click, natural scroll)
#    - Configures clipmenu + rofi clipboard history
#    - Configures unclutter (hides idle cursor)
#    - Configures tlp (battery/power optimisation)
#    - Writes .Xresources (cursor theme, DPI, font rendering)
#    - Multi-monitor: autorandr + arandr + Super+Shift+M workflow
#    - All configs Catppuccin Mocha throughout
# ================================================================
set -euo pipefail

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  echo "Please run this script as your normal user, not root."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

log()      { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
success()  { printf '\033[1;32m  ✓ %s\033[0m\n' "$*"; }
info()     { printf '\033[1;33m  → %s\033[0m\n' "$*"; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1"; exit 1; }; }

need_cmd sudo
need_cmd apt
need_cmd curl

# ================================================================
#  Package installation
# ================================================================
log "Updating package lists"
sudo apt update

log "Installing core packages"
sudo apt install -y \
  xorg xinit i3-wm i3status x11-xserver-utils xsettingsd \
  rofi picom feh dex policykit-1-gnome lxappearance arandr autorandr \
  alacritty \
  thunar thunar-archive-plugin thunar-volman gvfs gvfs-backends tumbler file-roller \
  pavucontrol pipewire-pulse wireplumber \
  network-manager-gnome blueman \
  dunst libnotify-bin \
  xss-lock \
  brightnessctl \
  clipmenu xclip xdotool \
  unclutter \
  tlp tlp-rdw \
  flameshot playerctl \
  ranger python3-pil w3m w3m-img \
  fish \
  imagemagick bc xdpyinfo \
  unzip wget git curl build-essential \
  autoconf gcc make pkg-config \
  libpam0g-dev libcairo2-dev libfontconfig1-dev \
  libxcb-composite0-dev libev-dev libx11-xcb-dev \
  libxcb-xkb-dev libxcb-xinerama0-dev libxcb-randr0-dev \
  libxcb-image0-dev libxcb-util-dev libxcb-xrm-dev \
  libxkbcommon-dev libxkbcommon-x11-dev libjpeg-dev \
  fonts-font-awesome fonts-noto fonts-noto-color-emoji fonts-jetbrains-mono \
  arc-theme papirus-icon-theme \
  lightdm lightdm-gtk-greeter \
  xdg-utils

# Add user to video group so brightnessctl works without sudo
sudo usermod -aG video "$USER"
success "Added $USER to video group (brightness control)"

# ================================================================
#  i3lock-color — build from source (not in Debian repos)
#  betterlockscreen depends on it for the themed lock screen
# ================================================================
log "Building i3lock-color from source"
LOCKCOLOR_DIR="$(mktemp -d)"
git clone --depth=1 https://github.com/Raymo111/i3lock-color.git "$LOCKCOLOR_DIR"
pushd "$LOCKCOLOR_DIR" >/dev/null
  ./install-i3lock-color.sh
popd >/dev/null
rm -rf "$LOCKCOLOR_DIR"
success "i3lock-color built and installed"

# ================================================================
#  betterlockscreen — Catppuccin-themed lock with blur + clock
# ================================================================
log "Installing betterlockscreen"
curl -fsSLo /tmp/betterlockscreen \
  https://raw.githubusercontent.com/betterlockscreen/betterlockscreen/main/betterlockscreen
sudo install -m 755 /tmp/betterlockscreen /usr/local/bin/betterlockscreen
rm -f /tmp/betterlockscreen

# Install the systemd service so betterlockscreen locks on suspend
sudo curl -fsSLo /usr/lib/systemd/system/betterlockscreen@.service \
  https://raw.githubusercontent.com/betterlockscreen/betterlockscreen/main/system/betterlockscreen%40.service
sudo systemctl enable "betterlockscreen@${USER}" || true
success "betterlockscreen installed and service enabled"

# ================================================================
#  Betterlockscreen config — Catppuccin Mocha palette
# ================================================================
log "Writing betterlockscreen config"
mkdir -p "$HOME/.config/betterlockscreen"
cat > "$HOME/.config/betterlockscreen/betterlockscreenrc" <<'BETTERLOCKRC'
# ── Effects ─────────────────────────────────────────────────────
# Applied to your wallpaper image at update time
blur_level=1          # 0-5, higher = more blur
dim_level=40          # 0-100, how much to darken the blurred image

# ── Clock ────────────────────────────────────────────────────────
time_format="%H:%M"
date_format="%A, %d %B"

# ── Layout ──────────────────────────────────────────────────────
time_pos="ix:iy-120"        # above center
date_pos="ix:iy-60"
indicator_pos="ix:iy+40"
greeter_pos="ix:iy+120"

# ── Time font ───────────────────────────────────────────────────
time_font="JetBrains Mono Bold"
time_size=64
time_color="cdd6f4ff"       # Catppuccin text

# ── Date font ───────────────────────────────────────────────────
date_font="JetBrains Mono"
date_size=22
date_color="a6adc8ff"       # Catppuccin subtext1

# ── Greeter (idle hint) ─────────────────────────────────────────
greeter_text="Type password to unlock"
greeter_font="JetBrains Mono"
greeter_size=14
greeter_color="6c7086ff"    # Catppuccin overlay0

# ── Input indicator ring ────────────────────────────────────────
ring_color="313244ff"       # Catppuccin surface0
ring_ver_color="89b4faff"   # Catppuccin blue
ring_wrong_color="f38ba8ff" # Catppuccin red
key_hl_color="cba6f7ff"     # Catppuccin mauve
bshl_color="f38ba8ff"

inside_color="11111b88"
inside_ver_color="11111b88"
inside_wrong_color="11111b88"

separator_color="00000000"

line_color="00000000"
line_ver_color="00000000"
line_wrong_color="00000000"

text_color="cdd6f4ff"
text_ver_color="89b4faff"
text_wrong_color="f38ba8ff"
text_caps_lock_color="f9e2afff"

verif_text="Verifying..."
wrong_text="Wrong password"
noinput_text=""
lock_text="Locking..."
lockfailed_text="Lock failed!"
BETTERLOCKRC

# ================================================================
#  Lock screen wallpaper — ask user during setup
# ================================================================
log "Lock screen wallpaper"
echo ""
echo "  betterlockscreen blurs your wallpaper for the lock screen."
echo "  You can set it now or skip and run manually later:"
echo "    betterlockscreen --update ~/Pictures/wallpaper.jpg"
echo ""
echo "  Options:"
echo "    1) Enter a path to an image on this machine"
echo "    2) Skip for now (solid Catppuccin dark background used)"
echo ""
while true; do
  read -rp "  Enter choice [1-2]: " LOCK_CHOICE
  case "$LOCK_CHOICE" in
    1|2) break ;;
    *) echo "  Please enter 1 or 2." ;;
  esac
done

LOCKSCREEN_IMAGE=""
if [[ "$LOCK_CHOICE" == "1" ]]; then
  while true; do
    read -rp "  Image path (absolute, e.g. /home/$USER/Pictures/wall.jpg): " LOCK_IMG_RAW
    # Expand ~ manually
    LOCK_IMG="${LOCK_IMG_RAW/#\~/$HOME}"
    if [[ -f "$LOCK_IMG" ]]; then
      LOCKSCREEN_IMAGE="$LOCK_IMG"
      break
    else
      echo "  File not found: $LOCK_IMG — try again, or press Ctrl+C to abort."
    fi
  done

  log "Pre-rendering lock screen (blur + dim) — this takes a moment..."
  betterlockscreen --update "$LOCKSCREEN_IMAGE" --display 1
  success "Lock screen image set to: $LOCKSCREEN_IMAGE"
else
  info "Skipped — run 'betterlockscreen --update <image>' after you have a wallpaper"
fi
# ================================================================
log "Browser selection"
echo ""
echo "  Which browser would you like to install?"
echo ""
echo "    1) Brave   — privacy-focused, Chromium-based"
echo "    2) Firefox — open-source, from Debian repos"
echo "    3) Chrome  — Google Chrome (proprietary)"
echo "    4) Skip    — I will install a browser myself"
echo ""
while true; do
  read -rp "  Enter choice [1-4]: " BROWSER_CHOICE
  case "$BROWSER_CHOICE" in
    1|2|3|4) break ;;
    *) echo "  Please enter 1, 2, 3 or 4." ;;
  esac
done

BROWSER_DESKTOP=""
BROWSER_BIN=""

case "$BROWSER_CHOICE" in
  1)
    log "Installing Brave"
    if ! dpkg -s brave-browser >/dev/null 2>&1; then
      sudo mkdir -p /etc/apt/keyrings
      curl -fsSLo /tmp/brave-browser-archive-keyring.gpg \
        https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
      sudo install -m 644 /tmp/brave-browser-archive-keyring.gpg \
        /etc/apt/keyrings/brave-browser-archive-keyring.gpg
      echo 'deb [signed-by=/etc/apt/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main' \
        | sudo tee /etc/apt/sources.list.d/brave-browser-release.list >/dev/null
      sudo apt update
      sudo apt install -y brave-browser
    else
      info "Brave already installed"
    fi
    BROWSER_DESKTOP="brave-browser.desktop"
    BROWSER_BIN="/usr/bin/brave-browser"
    ;;

  2)
    log "Installing Firefox"
    if ! dpkg -s firefox-esr >/dev/null 2>&1; then
      sudo apt install -y firefox-esr
    else
      info "Firefox already installed"
    fi
    BROWSER_DESKTOP="firefox-esr.desktop"
    BROWSER_BIN="/usr/bin/firefox-esr"
    ;;

  3)
    log "Installing Google Chrome"
    if ! dpkg -s google-chrome-stable >/dev/null 2>&1; then
      curl -fsSLo /tmp/google-chrome.deb \
        https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
      sudo apt install -y /tmp/google-chrome.deb
      rm -f /tmp/google-chrome.deb
    else
      info "Chrome already installed"
    fi
    BROWSER_DESKTOP="google-chrome.desktop"
    BROWSER_BIN="/usr/bin/google-chrome-stable"
    ;;

  4)
    log "Skipping browser installation"
    ;;
esac

if [[ -n "$BROWSER_DESKTOP" ]]; then
  log "Setting $BROWSER_DESKTOP as the default browser"
  xdg-settings set default-web-browser "$BROWSER_DESKTOP"          || true
  xdg-mime default "$BROWSER_DESKTOP" text/html                     || true
  xdg-mime default "$BROWSER_DESKTOP" x-scheme-handler/http         || true
  xdg-mime default "$BROWSER_DESKTOP" x-scheme-handler/https        || true
  sudo update-alternatives --set x-www-browser    "$BROWSER_BIN"   || true
  sudo update-alternatives --set gnome-www-browser "$BROWSER_BIN"  || true
  I3_BROWSER_CMD="${BROWSER_BIN##*/}"
else
  I3_BROWSER_CMD="xdg-open"
fi

# ================================================================
#  System services
# ================================================================
log "Enabling system services"
sudo systemctl enable NetworkManager || true
sudo systemctl enable lightdm        || true
sudo systemctl enable tlp            || true
success "NetworkManager, LightDM, TLP enabled"

# ================================================================
#  LightDM greeter
# ================================================================
log "Configuring LightDM dark greeter"
sudo mkdir -p /etc/lightdm
sudo tee /etc/lightdm/lightdm-gtk-greeter.conf >/dev/null <<'GREETER'
[greeter]
theme-name=Arc-Dark
icon-theme-name=Papirus-Dark
font-name=Sans 11
background=#11111b
indicators=~host;~spacer;~clock;~spacer;~language;~session;~power
clock-format=%a, %d %b  %H:%M
GREETER

# ================================================================
#  Touchpad — libinput (tap-to-click, natural scroll, two-finger)
# ================================================================
log "Configuring libinput touchpad"
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/40-libinput.conf >/dev/null <<'TOUCHPAD'
Section "InputClass"
    Identifier "touchpad"
    MatchIsTouchpad "on"
    Driver "libinput"
    Option "Tapping"           "on"
    Option "TappingButtonMap"  "lmr"
    Option "NaturalScrolling"  "true"
    Option "ScrollMethod"      "twofinger"
    Option "DisableWhileTyping" "true"
    Option "ClickMethod"       "clickfinger"
    Option "AccelProfile"      "adaptive"
EndSection
TOUCHPAD
success "Touchpad: tap-to-click, natural scroll, two-finger enabled"

# ================================================================
#  Directories
# ================================================================
log "Creating config directories"
mkdir -p \
  "$HOME/.config/i3" \
  "$HOME/.config/i3/scripts" \
  "$HOME/.config/i3status" \
  "$HOME/.config/picom" \
  "$HOME/.config/rofi" \
  "$HOME/.config/alacritty" \
  "$HOME/.config/dunst" \
  "$HOME/.config/gtk-3.0" \
  "$HOME/.config/gtk-4.0" \
  "$HOME/.config/xsettingsd" \
  "$HOME/.local/share/themes" \
  "$HOME/.local/share/icons"

backup_file() {
  local f="$1"
  if [[ -f "$f" && ! -f "$f.pre-rice-backup" ]]; then
    cp "$f" "$f.pre-rice-backup"
    info "Backed up $f"
  fi
}

backup_file "$HOME/.config/i3/config"
backup_file "$HOME/.config/i3status/config"
backup_file "$HOME/.config/picom/picom.conf"
backup_file "$HOME/.config/rofi/config.rasi"
backup_file "$HOME/.config/alacritty/alacritty.toml"
backup_file "$HOME/.config/dunst/dunstrc"
backup_file "$HOME/.gtkrc-2.0"
backup_file "$HOME/.xinitrc"
backup_file "$HOME/.Xresources"

# ================================================================
#  .Xresources — cursor theme, DPI, font rendering
# ================================================================
log "Writing .Xresources"
cat > "$HOME/.Xresources" <<'XRESOURCES'
! ── Cursor ──────────────────────────────────────────────────
Xcursor.theme: Adwaita
Xcursor.size:  24

! ── DPI / Font rendering ────────────────────────────────────
! Change Xft.dpi to 192 if you have a HiDPI/4K screen
Xft.dpi:       96
Xft.antialias: true
Xft.hinting:   true
Xft.hintstyle: hintslight
Xft.rgba:      rgb
Xft.lcdfilter: lcddefault
XRESOURCES

# ================================================================
#  GTK theme — Catppuccin/Arc-Dark
# ================================================================
log "Writing GTK theme settings"
cat > "$HOME/.gtkrc-2.0" <<'GTK2'
gtk-theme-name="Arc-Dark"
gtk-icon-theme-name="Papirus-Dark"
gtk-font-name="Sans 10"
gtk-cursor-theme-name="Adwaita"
gtk-button-images=0
gtk-menu-images=0
GTK2

cat > "$HOME/.config/gtk-3.0/settings.ini" <<'GTK3'
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-application-prefer-dark-theme=1
gtk-button-images=0
gtk-menu-images=0
GTK3

cat > "$HOME/.config/gtk-4.0/settings.ini" <<'GTK4'
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-application-prefer-dark-theme=1
GTK4

cat > "$HOME/.config/xsettingsd/xsettingsd.conf" <<'XSET'
Net/ThemeName "Arc-Dark"
Net/IconThemeName "Papirus-Dark"
Gtk/CursorThemeName "Adwaita"
Gtk/FontName "Sans 10"
XSET

# ================================================================
#  Alacritty — Catppuccin Mocha
# ================================================================
log "Writing Alacritty config"
cat > "$HOME/.config/alacritty/alacritty.toml" <<'ALACRITTY'
[window]
padding = { x = 12, y = 12 }
dynamic_padding = true
opacity = 0.95
decorations = "none"

[font]
size = 11.5
normal  = { family = "JetBrains Mono", style = "Regular" }
bold    = { family = "JetBrains Mono", style = "Bold" }
italic  = { family = "JetBrains Mono", style = "Italic" }

[cursor]
style = { shape = "Beam", blinking = "On" }
blink_interval = 500

[scrolling]
history = 10000

[colors.primary]
background = "#11111b"
foreground = "#cdd6f4"

[colors.cursor]
text   = "#11111b"
cursor = "#f5e0dc"

[colors.selection]
text       = "#11111b"
background = "#cba6f7"

[colors.normal]
black   = "#45475a"
red     = "#f38ba8"
green   = "#a6e3a1"
yellow  = "#f9e2af"
blue    = "#89b4fa"
magenta = "#f5c2e7"
cyan    = "#94e2d5"
white   = "#bac2de"

[colors.bright]
black   = "#585b70"
red     = "#f38ba8"
green   = "#a6e3a1"
yellow  = "#f9e2af"
blue    = "#89b4fa"
magenta = "#f5c2e7"
cyan    = "#94e2d5"
white   = "#a6adc8"
ALACRITTY

# ================================================================
#  Alacritty — set fish as default shell
# ================================================================
log "Configuring Alacritty to use fish"
cat >> "$HOME/.config/alacritty/alacritty.toml" <<ALACRITTY_SHELL

[shell]
program = "$(which fish)"
args    = ["--login"]
ALACRITTY_SHELL
success "Alacritty will launch fish by default"

# ================================================================
#  Fish shell — set as default login shell
# ================================================================
log "Setting fish as default shell"
FISH_PATH="$(which fish)"
if ! grep -qxF "$FISH_PATH" /etc/shells; then
  echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
fi
sudo chsh -s "$FISH_PATH" "$USER"
success "Default shell set to fish ($FISH_PATH)"

# ================================================================
#  Fish shell — base config (greeting, env, Catppuccin colours)
# ================================================================
log "Writing fish config"
mkdir -p "$HOME/.config/fish/functions" "$HOME/.config/fish/conf.d"

cat > "$HOME/.config/fish/config.fish" <<'FISHCONFIG'
# ── Disable greeting (tide handles the prompt) ──────────────────
set -g fish_greeting ""

# ── Environment ─────────────────────────────────────────────────
set -gx EDITOR     nvim 2>/dev/null; or set -gx EDITOR nano
set -gx VISUAL     $EDITOR
set -gx PAGER      less
set -gx LESS       "-R --use-color"
set -gx XDG_CONFIG_HOME "$HOME/.config"

# Local bin on PATH
fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/.cargo/bin"

# ── Catppuccin Mocha syntax highlighting colours ─────────────────
set -g fish_color_command           89b4fa   # blue   — commands
set -g fish_color_param             cdd6f4   # text   — arguments
set -g fish_color_keyword           cba6f7   # mauve  — keywords (if/for/…)
set -g fish_color_quote             a6e3a1   # green  — strings
set -g fish_color_redirection       f9e2af   # yellow — redirects
set -g fish_color_end               f9e2af   # yellow — semicolons/&
set -g fish_color_error             f38ba8   # red    — errors
set -g fish_color_comment           6c7086   # overlay0 — comments
set -g fish_color_selection         313244   # surface0 — selection bg
set -g fish_color_search_match      --background=313244
set -g fish_color_operator          94e2d5   # teal   — operators
set -g fish_color_escape            f5c2e7   # pink   — escape sequences
set -g fish_color_autosuggestion    6c7086   # overlay0 — ghost text
set -g fish_color_cancel            f38ba8

# ── Pager colours ────────────────────────────────────────────────
set -g fish_pager_color_prefix        cba6f7 --bold
set -g fish_pager_color_completion    cdd6f4
set -g fish_pager_color_description  6c7086
set -g fish_pager_color_progress     a6adc8 --background=313244
set -g fish_pager_color_selected_background --background=313244

# ── Handy abbreviations ──────────────────────────────────────────
abbr --add ll    'ls -lah --color=auto'
abbr --add la    'ls -A --color=auto'
abbr --add ..    'cd ..'
abbr --add ...   'cd ../..'
abbr --add g     'git'
abbr --add gs    'git status'
abbr --add gd    'git diff'
abbr --add ga    'git add'
abbr --add gc    'git commit'
abbr --add gp    'git push'
abbr --add r     'ranger'
abbr --add e     '$EDITOR'
abbr --add v     'nvim'
FISHCONFIG
success "Fish config written with Catppuccin Mocha colours"

# ================================================================
#  Oh My Fish — install non-interactively
# ================================================================
log "Installing Oh My Fish"
OMF_INSTALL_DIR="$HOME/.local/share/omf"
if [[ ! -d "$OMF_INSTALL_DIR" ]]; then
  curl -fsSLo /tmp/omf-install https://get.oh-my.fish
  # --noninteractive skips the setup wizard so we can drive it via fish -c
  fish /tmp/omf-install --path="$OMF_INSTALL_DIR" \
    --config="$HOME/.config/omf" --noninteractive --yes
  rm -f /tmp/omf-install
  success "Oh My Fish installed"
else
  info "Oh My Fish already installed"
fi

# ================================================================
#  Fisher — install (tide needs fisher, omf can coexist)
# ================================================================
log "Installing Fisher plugin manager"
fish -c '
  curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish \
    | source
  fisher install jorgebucaran/fisher
' && success "Fisher installed"

# ================================================================
#  Tide — Catppuccin-friendly prompt
#  Configure non-interactively (lean two-line, 24-bit colour)
# ================================================================
log "Installing Tide prompt"
fish -c 'fisher install IlanCosman/tide@v6' \
  && success "Tide installed"

log "Configuring Tide (lean two-line, Catppuccin palette)"
fish -c '
  # Run tide configure non-interactively
  tide configure \
    --auto \
    --style=Lean \
    --prompt_colors=True_color \
    --show_time=No \
    --lean_prompt_height=Two_lines \
    --prompt_connection=Disconnected \
    --prompt_spacing=Sparse \
    --icons=Few \
    --transient=No
' && success "Tide configured"

# Fine-tune Tide colours to Catppuccin Mocha
fish -c '
  # Git colours
  set -U tide_git_color_branch         89b4fa   # blue
  set -U tide_git_color_operation      f9e2af   # yellow
  set -U tide_git_color_staged         a6e3a1   # green
  set -U tide_git_color_dirty          f9e2af   # yellow
  set -U tide_git_color_untracked      89dceb   # sky
  set -U tide_git_color_conflicted     f38ba8   # red
  set -U tide_git_color_upstream       cba6f7   # mauve

  # Directory colour
  set -U tide_pwd_color_dirs           cba6f7   # mauve
  set -U tide_pwd_color_anchors        cba6f7 --bold

  # Status colours
  set -U tide_cmd_duration_color       6c7086   # overlay0
  set -U tide_status_color             a6e3a1   # green (success)
  set -U tide_status_color_failure     f38ba8   # red   (failure)

  # Vi mode indicator
  set -U tide_vi_mode_color_default    89b4fa
  set -U tide_vi_mode_color_insert     a6e3a1
  set -U tide_vi_mode_color_replace    f9e2af
  set -U tide_vi_mode_color_visual     cba6f7

  # Prompt character
  set -U tide_character_color          a6e3a1   # green
  set -U tide_character_color_failure  f38ba8   # red
'
success "Tide Catppuccin Mocha colours applied"

# ================================================================
#  Ranger — config + Catppuccin Mocha colorscheme
# ================================================================
log "Writing Ranger config"
ranger --copy-config=all 2>/dev/null || true
mkdir -p "$HOME/.config/ranger/colorschemes"

# Main rc.conf
cat > "$HOME/.config/ranger/rc.conf" <<'RANGERRC'
# ── Look & feel ──────────────────────────────────────────────────
set colorscheme catppuccin
set preview_images false        # set true if you install ueberzug
set preview_images_method w3m
set unicode_ellipsis true
set show_hidden false
set show_cursor false
set draw_borders separators
set dirname_in_tabs true
set mouse_enabled true

# ── Column ratios ────────────────────────────────────────────────
set column_ratios 2,3,4

# ── Preview ─────────────────────────────────────────────────────
set use_preview_script true
set preview_script ~/.config/ranger/scope.sh
set preview_max_size 104857600

# ── Behaviour ────────────────────────────────────────────────────
set confirm_on_delete multiple
set save_console_history true
set scroll_offset 5
set tilde_in_titlebar true
set update_title true
set vcs_aware true
set vcs_backend_git enabled

# ── Key: open terminal here ──────────────────────────────────────
map <C-t> shell alacritty &

# ── Key: toggle hidden files ─────────────────────────────────────
map . toggle_option show_hidden

# ── Key: extract archive ─────────────────────────────────────────
map ex shell bash -c 'aunpack %f' &

# ── Open defaults ────────────────────────────────────────────────
default_linemode devicons
RANGERRC

# Catppuccin Mocha colorscheme for ranger
cat > "$HOME/.config/ranger/colorschemes/catppuccin.py" <<'RANGERTHEME'
# Catppuccin Mocha colorscheme for ranger
# All 256-colour terminals supported; True-colour terminals look best.
from ranger.gui.colorscheme import ColorScheme
from ranger.gui.color import (
    default_colors, default, reverse,
    bold, dim, normal,
    COLOR_RESET,
)

# Catppuccin Mocha palette mapped to 256-color xterm indices
# (closest approximations — a true-color terminal renders them exactly)
ROSEWATER = 224
FLAMINGO  = 218
PINK      = 219
MAUVE     = 183
RED       = 210
MAROON    = 217
PEACH     = 216
YELLOW    = 229
GREEN     = 157
TEAL      = 159
SKY       = 153
SAPPHIRE  = 117
BLUE      = 111
LAVENDER  = 189
TEXT      = 253
SUBTEXT1  = 250
SUBTEXT0  = 246
OVERLAY2  = 244
OVERLAY1  = 242
OVERLAY0  = 240
SURFACE2  = 238
SURFACE1  = 237
SURFACE0  = 236
BASE      = 234
MANTLE    = 233
CRUST     = 232


class Catppuccin(ColorScheme):
    def use(self, context):
        fg, bg, attr = default_colors

        if context.reset:
            return default_colors

        elif context.in_browser:
            fg = TEXT
            if context.selected:
                attr = reverse
            if context.empty or context.error:
                fg = RED
            if context.border:
                fg = SURFACE1
            if context.media:
                fg = PINK
            if context.image:
                fg = PINK
            if context.video:
                fg = MAUVE
            if context.audio:
                fg = TEAL
            if context.document:
                fg = YELLOW
            if context.container:
                fg = PEACH; attr |= bold
            if context.directory:
                fg = BLUE; attr |= bold
            elif context.executable and not any((
                context.media, context.container, context.fifo,
                context.socket,
            )):
                fg = GREEN; attr |= bold
            if context.socket:
                fg = YELLOW; attr |= bold
            if context.fifo or context.device:
                fg = PEACH; attr |= bold
            if context.link:
                fg = TEAL if context.good else RED
            if context.bad:
                fg = RED
            if context.tag_marker and not context.selected:
                attr |= bold
                fg = RED if context.tag_marker == '*' else YELLOW
            if not context.selected and (context.cut or context.copied):
                attr |= bold
                fg = MAROON

        elif context.in_titlebar:
            if context.hostname:
                fg = MAUVE; attr |= bold
            elif context.directory:
                fg = BLUE
            elif context.tab:
                fg = LAVENDER if context.good else OVERLAY1
            elif context.link:
                fg = TEAL
            else:
                fg = TEXT

        elif context.in_statusbar:
            if context.permissions:
                fg = GREEN if context.good else RED
            if context.marked:
                fg = PEACH; attr |= bold
            if context.message:
                fg = YELLOW if context.bad else TEXT
            if context.loaded:
                fg = GREEN
            if context.vcsinfo:
                fg = BLUE
            if context.vcscommit:
                fg = YELLOW
            if context.vcsdate:
                fg = TEAL

        if context.text:
            attr |= bold

        if context.main_column:
            if context.selected:
                attr |= bold
            if context.empty:
                fg = OVERLAY0

        if context.header:
            attr |= bold
            fg = LAVENDER

        if context.vcsfile and not context.selected:
            if context.vcsunknown:  fg = OVERLAY1
            elif context.vcsstaged:   fg = GREEN
            elif context.vcschanged:  fg = YELLOW
            elif context.vcsuntracked: fg = SKY
            elif context.vcsmissing:  fg = RED
            elif context.vcsconflict: fg = RED; attr |= bold

        if context.vcsremote and not context.selected:
            if context.vcssync:      fg = GREEN
            elif context.vcsbehind:  fg = PEACH
            elif context.vcsahead:   fg = BLUE
            elif context.vcsdiverged: fg = MAUVE
            elif context.vcsunknown: fg = OVERLAY1

        return fg, bg, attr
RANGERTHEME

success "Ranger config + Catppuccin Mocha theme written"

# ================================================================
#  Picom — GLX, rounded corners, blur, shadows
# ================================================================
log "Writing Picom config"
cat > "$HOME/.config/picom/picom.conf" <<'PICOM'
backend       = "glx";
vsync         = true;
corner-radius = 10;
rounded-corners-exclude = [
  "class_g = 'i3bar'",
  "class_g = 'Rofi'",
  "class_g = 'dunst'"
];

shadow          = true;
shadow-radius   = 18;
shadow-opacity  = 0.25;
shadow-offset-x = -10;
shadow-offset-y = -10;
shadow-exclude = [
  "class_g = 'i3bar'",
  "class_g = 'Rofi'"
];

fade-in-step  = 0.04;
fade-out-step = 0.04;
fading = true;

active-opacity   = 1.0;
inactive-opacity = 0.92;
frame-opacity    = 0.95;

blur-method     = "dual_kawase";
blur-strength   = 5;
blur-background = false;

opacity-rule = [
  "95:class_g = 'Alacritty'",
  "92:class_g = 'Thunar'",
  "100:class_g = 'Rofi'",
  "100:class_g = 'dunst'"
];
PICOM

# ================================================================
#  Dunst — Catppuccin Mocha notification daemon
# ================================================================
log "Writing Dunst config"
cat > "$HOME/.config/dunst/dunstrc" <<'DUNST'
[global]
    monitor                = 0
    follow                 = mouse
    width                  = 320
    height                 = 300
    origin                 = top-right
    offset                 = 12x12
    scale                  = 0
    notification_limit     = 5

    progress_bar           = true
    progress_bar_height    = 6
    progress_bar_frame_width = 1
    progress_bar_min_width = 150
    progress_bar_max_width = 300
    progress_bar_corner_radius = 3

    indicate_hidden        = yes
    transparency           = 5
    separator_height       = 2
    padding                = 12
    horizontal_padding     = 14
    text_icon_padding      = 8
    frame_width            = 2
    frame_color            = "#89b4fa"
    gap_size               = 6
    separator_color        = frame
    sort                   = urgency_descending

    font                   = JetBrains Mono 10
    line_height            = 2
    markup                 = full
    format                 = "<b>%s</b>\n%b"
    alignment              = left
    vertical_alignment     = center
    show_age_threshold     = 60
    ellipsize              = middle
    ignore_newline         = no
    stack_duplicates       = true
    hide_duplicate_count   = false
    show_indicators        = yes

    icon_theme             = Papirus-Dark
    enable_recursive_icon_lookup = true
    icon_position          = left
    min_icon_size          = 32
    max_icon_size          = 32

    corner_radius          = 10

    mouse_left_click       = close_current
    mouse_middle_click     = do_action, close_current
    mouse_right_click      = close_all

    history_length         = 20
    sticky_history         = yes
    browser                = /usr/bin/xdg-open
    always_run_script      = true
    title                  = Dunst
    class                  = Dunst

[urgency_low]
    background  = "#1e1e2e"
    foreground  = "#a6adc8"
    frame_color = "#313244"
    timeout     = 4
    default_icon = dialog-information

[urgency_normal]
    background  = "#1e1e2e"
    foreground  = "#cdd6f4"
    frame_color = "#89b4fa"
    timeout     = 6
    default_icon = dialog-information

[urgency_critical]
    background  = "#1e1e2e"
    foreground  = "#f38ba8"
    frame_color = "#f38ba8"
    timeout     = 0
    default_icon = dialog-error
DUNST

# ================================================================
#  Rofi — Catppuccin Mocha launcher + clipboard
# ================================================================
log "Writing Rofi config"
cat > "$HOME/.config/rofi/config.rasi" <<'ROFI'
configuration {
  modi: "drun,run,window,keys";
  show-icons: true;
  icon-theme: "Papirus-Dark";
  display-drun:   " Apps";
  display-run:    " Run";
  display-window: " Windows";
  display-keys:   " Keys";
  font: "JetBrains Mono 11";
  drun-display-format: "{name}";
  disable-history: false;
  hover-select: true;
  me-select-entry: "";
  me-accept-entry: "MousePrimary";
  kb-cancel: "Escape,Super+d";
}

* {
  bg:            #11111bf2;
  bg-alt:        #181825;
  bg-hover:      #1e1e2e;
  fg:            #cdd6f4;
  fg-muted:      #a6adc8;
  border:        #89b4fa;
  urgent:        #f38ba8;
  selected:      #89b4fa;
  selected-text: #11111b;
  border-radius: 14px;
}

window {
  width: 40%;
  location: center;
  anchor: center;
  transparency: "real";
  background-color: @bg;
  border: 2px;
  border-color: @border;
  border-radius: @border-radius;
  padding: 18px;
}

mainbox { spacing: 12px; }

inputbar {
  children: [ prompt, entry ];
  background-color: @bg-alt;
  border-radius: 12px;
  padding: 10px 12px;
  spacing: 10px;
}

prompt { text-color: @border; }

entry {
  text-color: @fg;
  placeholder: "Search...";
  placeholder-color: @fg-muted;
}

listview {
  lines: 10;
  columns: 1;
  fixed-height: false;
  background-color: transparent;
  spacing: 6px;
  scrollbar: false;
}

element {
  background-color: @bg-alt;
  text-color: @fg;
  border-radius: 10px;
  padding: 10px 12px;
}

element normal.normal  { background-color: @bg-alt;  text-color: @fg; }
element normal.urgent  { background-color: @urgent;  text-color: #11111b; }
element selected.normal { background-color: @selected; text-color: @selected-text; }
element selected.urgent { background-color: @urgent;  text-color: #11111b; }

element-icon { size: 1.1em; }

message {
  background-color: @bg-alt;
  border-radius: 10px;
  padding: 10px;
}

textbox { text-color: @fg-muted; }
ROFI

# ================================================================
#  i3status — bar content
# ================================================================
log "Writing i3status config"
cat > "$HOME/.config/i3status/config" <<'I3STATUS'
general {
    colors   = true
    interval = 2
    color_good     = "#a6e3a1"
    color_degraded = "#f9e2af"
    color_bad      = "#f38ba8"
}

order += "wireless _first_"
order += "ethernet _first_"
order += "battery all"
order += "volume master"
order += "cpu_usage"
order += "memory"
order += "tztime local"

wireless _first_ {
    format_up   = "  %essid %quality"
    format_down = "  disconnected"
}

ethernet _first_ {
    format_up   = "  wired"
    format_down = ""
}

battery all {
    format        = "%status %percentage %remaining"
    format_down   = ""
    status_chr    = " "
    status_bat    = " "
    status_unk    = " "
    status_full   = " "
    low_threshold = 15
    last_full_capacity = true
}

volume master {
    format       = "  %volume"
    format_muted = "  muted"
    device       = "default"
    mixer        = "Master"
    mixer_idx    = 0
}

cpu_usage {
    format = "  %usage"
    max_threshold = 90
    degraded_threshold = 70
}

memory {
    format             = "  %used"
    threshold_degraded = "1G"
    format_degraded    = "  %available left"
}

tztime local {
    format = "  %a %d %b  %H:%M"
}
I3STATUS

# ================================================================
#  Monitor setup script — arandr + autorandr integration
# ================================================================
log "Writing monitor setup script"
cat > "$HOME/.config/i3/scripts/monitor-setup.sh" <<'MONITOR_SCRIPT'
#!/usr/bin/env bash
# Opens arandr, then auto-saves an autorandr profile on close.
# Bound to Super+Shift+M in i3.
#
# Profile names are built from connected output names, e.g.:
#   laptop only  → "eDP-1"
#   docked       → "eDP-1-HDMI-1-DP-2"
# autorandr matches by EDID fingerprint on next plug-in.

get_profile_name() {
  xrandr --query \
    | awk '/ connected/ {print $1}' \
    | sort \
    | paste -sd '-'
}

# Open arandr — arrange monitors, click Apply, close window
arandr

# Snapshot current xrandr state into autorandr
PROFILE="$(get_profile_name)"

if autorandr --save "$PROFILE" --force 2>/dev/null; then
  notify-send \
    --icon=display \
    --urgency=normal \
    "Monitor layout saved" \
    "Profile: <b>$PROFILE</b>\nPlug/unplug dock to test auto-apply."
else
  notify-send \
    --icon=dialog-error \
    --urgency=critical \
    "Monitor save failed" \
    "Could not save autorandr profile '$PROFILE'."
fi
MONITOR_SCRIPT
chmod +x "$HOME/.config/i3/scripts/monitor-setup.sh"

# ================================================================
#  i3 config — production-ready
# ================================================================
log "Writing i3 config"
cat > "$HOME/.config/i3/config" <<'I3EOF'
# ================================================================
#  Debian 12 — i3 Production Rice · Catppuccin Mocha
# ================================================================

# ── Variables (easy to tweak) ───────────────────────────────────
set $mod         Mod4
set $terminal    alacritty
set $filemanager thunar
set $termfiles   alacritty -e ranger
set $menu        rofi -show drun
set $launcher    rofi -show run
set $winpicker   rofi -show window
set $clipboard   CM_LAUNCHER=rofi clipmenu
set $lock        betterlockscreen -l blur
set $monitor_setup ~/.config/i3/scripts/monitor-setup.sh
set $browser     BROWSER_PLACEHOLDER

# vim-style directional focus
# NOTE: $mod+h = focus left ONLY.
#       Horizontal split → $mod+\ to avoid conflict.
set $left  h
set $down  j
set $up    k
set $right l

# ── General ─────────────────────────────────────────────────────
font pango:JetBrains Mono 10
floating_modifier $mod
focus_follows_mouse no
mouse_warping none
workspace_auto_back_and_forth yes
hide_edge_borders smart
smart_gaps on
smart_borders on
gaps inner 12
gaps outer 8
default_border pixel 2
default_floating_border pixel 2

# ── Startup (exec = once per login, no duplicates on reload) ────
exec --no-startup-id dex --autostart --environment i3
exec --no-startup-id nm-applet
exec --no-startup-id blueman-applet
exec --no-startup-id dunst
exec --no-startup-id picom --config ~/.config/picom/picom.conf
exec --no-startup-id clipmenud
exec --no-startup-id unclutter --timeout 3 --jitter 5 --start-hidden
exec --no-startup-id xss-lock --transfer-sleep-lock -- betterlockscreen -l blur
exec --no-startup-id /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1

# ── exec_always (re-runs on every reload/restart) ───────────────
exec_always --no-startup-id xsettingsd
exec_always --no-startup-id xsetroot -cursor_name left_ptr
exec_always --no-startup-id sh -c 'xset -b; xset s off -dpms'
exec_always --no-startup-id setxkbmap -model pc104 -layout us,ir -variant ,, -option grp:alt_shift_toggle
exec_always --no-startup-id xrdb -merge ~/.Xresources

# Auto-apply saved monitor layout (does nothing if no profile matches)
exec_always --no-startup-id autorandr --change

# Solid Catppuccin background (replace with feh --bg-fill once you have a wallpaper)
exec_always --no-startup-id feh --bg-color '#11111b'

# Save laptop-only profile as "mobile" on first login if not already saved
exec --no-startup-id sh -c 'sleep 5 && autorandr --list 2>/dev/null | grep -q "^mobile$" || autorandr --save mobile --force'

# ── App launchers ───────────────────────────────────────────────
bindsym $mod+Return    exec $terminal
bindsym $mod+d         exec $menu
bindsym $mod+Shift+d   exec $launcher
bindsym $mod+Tab       exec $winpicker
bindsym $mod+b         exec $browser
bindsym $mod+e         exec $filemanager
bindsym $mod+Shift+e   exec $termfiles
bindsym $mod+c         exec --no-startup-id $clipboard

# ── Screenshots ─────────────────────────────────────────────────
bindsym Print          exec --no-startup-id flameshot full
bindsym $mod+Print     exec --no-startup-id flameshot gui
bindsym $mod+Shift+s   exec --no-startup-id flameshot gui

# ── Session ─────────────────────────────────────────────────────
bindsym $mod+Shift+x   exec $lock
bindsym $mod+Shift+q   kill
bindsym $mod+Shift+c   reload
bindsym $mod+Shift+r   restart
bindsym $mod+Shift+e   exec "i3-nagbar -t warning -m 'Exit i3?' -B 'Yes' 'i3-msg exit'"

# ── Monitor management ──────────────────────────────────────────
# 1. Plug in dock  2. Press Super+Shift+M  3. Arrange in arandr
# 4. Close arandr → layout saved automatically (notification confirms)
# 5. Next dock connect → autorandr applies profile by itself
bindsym $mod+Shift+m   exec $monitor_setup

# ── Focus ───────────────────────────────────────────────────────
bindsym $mod+$left  focus left
bindsym $mod+$down  focus down
bindsym $mod+$up    focus up
bindsym $mod+$right focus right
bindsym $mod+Left   focus left
bindsym $mod+Down   focus down
bindsym $mod+Up     focus up
bindsym $mod+Right  focus right

# ── Move ────────────────────────────────────────────────────────
bindsym $mod+Shift+$left  move left
bindsym $mod+Shift+$down  move down
bindsym $mod+Shift+$up    move up
bindsym $mod+Shift+$right move right
bindsym $mod+Shift+Left   move left
bindsym $mod+Shift+Down   move down
bindsym $mod+Shift+Up     move up
bindsym $mod+Shift+Right  move right

# ── Layout ──────────────────────────────────────────────────────
# $mod+\ = horizontal split ($mod+h conflicts with focus left)
bindsym $mod+backslash  split h
bindsym $mod+v          split v
bindsym $mod+f          fullscreen toggle
bindsym $mod+s          layout stacking
bindsym $mod+w          layout tabbed
bindsym $mod+Shift+space floating toggle
bindsym $mod+space       focus mode_toggle
bindsym $mod+a           focus parent

# ── Workspaces ──────────────────────────────────────────────────
set $ws1  "1"
set $ws2  "2"
set $ws3  "3"
set $ws4  "4"
set $ws5  "5"
set $ws6  "6"
set $ws7  "7"
set $ws8  "8"
set $ws9  "9"
set $ws10 "10"

bindsym $mod+1  workspace $ws1
bindsym $mod+2  workspace $ws2
bindsym $mod+3  workspace $ws3
bindsym $mod+4  workspace $ws4
bindsym $mod+5  workspace $ws5
bindsym $mod+6  workspace $ws6
bindsym $mod+7  workspace $ws7
bindsym $mod+8  workspace $ws8
bindsym $mod+9  workspace $ws9
bindsym $mod+0  workspace $ws10

bindsym $mod+Shift+1  move container to workspace $ws1;  workspace $ws1
bindsym $mod+Shift+2  move container to workspace $ws2;  workspace $ws2
bindsym $mod+Shift+3  move container to workspace $ws3;  workspace $ws3
bindsym $mod+Shift+4  move container to workspace $ws4;  workspace $ws4
bindsym $mod+Shift+5  move container to workspace $ws5;  workspace $ws5
bindsym $mod+Shift+6  move container to workspace $ws6;  workspace $ws6
bindsym $mod+Shift+7  move container to workspace $ws7;  workspace $ws7
bindsym $mod+Shift+8  move container to workspace $ws8;  workspace $ws8
bindsym $mod+Shift+9  move container to workspace $ws9;  workspace $ws9
bindsym $mod+Shift+0  move container to workspace $ws10; workspace $ws10

# ── Multi-monitor workspace assignment ──────────────────────────
# Uncomment and adjust output names after running: xrandr --query
# Common names: eDP-1 (laptop), HDMI-1, DP-1, DP-2 (dock outputs)
#
# workspace $ws1  output eDP-1
# workspace $ws2  output eDP-1
# workspace $ws3  output eDP-1
# workspace $ws4  output eDP-1
# workspace $ws5  output eDP-1
# workspace $ws6  output HDMI-1
# workspace $ws7  output HDMI-1
# workspace $ws8  output DP-1
# workspace $ws9  output DP-1
# workspace $ws10 output DP-1

# ── Resize mode ─────────────────────────────────────────────────
mode "resize" {
    bindsym $left  resize shrink width  10 px or 10 ppt
    bindsym $down  resize grow   height 10 px or 10 ppt
    bindsym $up    resize shrink height 10 px or 10 ppt
    bindsym $right resize grow   width  10 px or 10 ppt
    bindsym Left  resize shrink width  10 px or 10 ppt
    bindsym Down  resize grow   height 10 px or 10 ppt
    bindsym Up    resize shrink height 10 px or 10 ppt
    bindsym Right resize grow   width  10 px or 10 ppt
    bindsym Return mode "default"
    bindsym Escape mode "default"
    bindsym $mod+r mode "default"
}
bindsym $mod+r mode "resize"

# ── Volume keys (PipeWire/pactl) ────────────────────────────────
bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +5% && notify-send -t 1500 -h string:x-canonical-private-synchronous:volume " Volume" "$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1)"
bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -5% && notify-send -t 1500 -h string:x-canonical-private-synchronous:volume " Volume" "$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1)"
bindsym XF86AudioMute        exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle && notify-send -t 1500 -h string:x-canonical-private-synchronous:volume " Volume" "toggled"

# ── Brightness keys (brightnessctl) ─────────────────────────────
bindsym XF86MonBrightnessUp   exec --no-startup-id brightnessctl set +5% && notify-send -t 1200 -h string:x-canonical-private-synchronous:brightness " Brightness" "$(brightnessctl -m | cut -d, -f4)"
bindsym XF86MonBrightnessDown exec --no-startup-id brightnessctl set 5%- && notify-send -t 1200 -h string:x-canonical-private-synchronous:brightness " Brightness" "$(brightnessctl -m | cut -d, -f4)"

# ── Media keys ──────────────────────────────────────────────────
bindsym XF86AudioPlay exec --no-startup-id playerctl play-pause
bindsym XF86AudioNext exec --no-startup-id playerctl next
bindsym XF86AudioPrev exec --no-startup-id playerctl previous

# ── Scratchpad ──────────────────────────────────────────────────
bindsym $mod+minus       scratchpad show
bindsym $mod+Shift+minus move scratchpad

# ── Bar ─────────────────────────────────────────────────────────
bar {
    position top
    status_command i3status -c ~/.config/i3status/config
    tray_output primary
    font pango:JetBrains Mono, Font Awesome 6 Free 10
    separator_symbol "  "
    colors {
        background #11111b
        statusline #cdd6f4
        separator  #45475a
        focused_workspace  #89b4fa #89b4fa #11111b
        active_workspace   #313244 #313244 #cdd6f4
        inactive_workspace #11111b #11111b #6c7086
        urgent_workspace   #f38ba8 #f38ba8 #11111b
        binding_mode       #f9e2af #f9e2af #11111b
    }
}

# ── Window colors (Catppuccin Mocha) ────────────────────────────
# border         background  text     indicator  child_border
client.focused          #89b4fa #89b4fa #11111b #cba6f7 #89b4fa
client.focused_inactive #313244 #313244 #cdd6f4 #313244 #313244
client.unfocused        #1e1e2e #1e1e2e #6c7086 #1e1e2e #1e1e2e
client.urgent           #f38ba8 #f38ba8 #11111b #f38ba8 #f38ba8
client.placeholder      #1e1e2e #1e1e2e #a6adc8 #1e1e2e #1e1e2e
client.background       #11111b

# ── Floating rules ──────────────────────────────────────────────
for_window [class="Lxappearance"]    floating enable, resize set 600 400
for_window [class="Arandr"]          floating enable, resize set 800 500
for_window [class="Pavucontrol"]     floating enable, resize set 700 450
for_window [class="Blueman-manager"] floating enable, resize set 600 450
for_window [class="flameshot"]       floating enable
for_window [title=".*[Pp]references.*"] floating enable
for_window [window_role="pop-up"]    floating enable
for_window [window_role="bubble"]    floating enable
for_window [window_role="dialog"]    floating enable
for_window [window_type="dialog"]    floating enable
I3EOF

# Patch browser placeholder
sed -i "s|BROWSER_PLACEHOLDER|${I3_BROWSER_CMD}|" "$HOME/.config/i3/config"
success "i3 config written, browser set to: $I3_BROWSER_CMD"

# ================================================================
#  .xinitrc — TTY fallback (without LightDM)
# ================================================================
log "Writing .xinitrc"
cat > "$HOME/.xinitrc" <<'XINIT'
# Apply X resources (cursor, DPI, font rendering)
xrdb -merge ~/.Xresources

exec i3
XINIT

# ================================================================
#  Final summary
# ================================================================
echo ""
echo ""
printf '\033[1;34m════════════════════════════════════════════════════════\033[0m\n'
printf '\033[1;32m  Production rice installed successfully!\033[0m\n'
printf '\033[1;34m════════════════════════════════════════════════════════\033[0m\n'
echo ""
printf '\033[1m  Reboot and choose i3 at the LightDM login screen.\033[0m\n'
echo ""
printf '\033[1;33m  Key shortcuts:\033[0m\n'
printf '    Super+Return     → terminal (alacritty)\n'
printf '    Super+D          → app launcher (rofi)\n'
printf '    Super+B          → browser (%s)\n' "$I3_BROWSER_CMD"
printf '    Super+E          → file manager (thunar GUI)\n'
printf '    Super+Shift+E    → ranger (terminal file manager)\n'
printf '    Super+C          → clipboard history (rofi)\n'
printf '    Super+Tab        → window switcher (rofi)\n'
printf '    Super+Shift+M    → arrange monitors (arandr + autorandr)\n'
printf '    Super+Shift+X    → lock screen (betterlockscreen blur)\n'
printf '    Print            → screenshot (fullscreen)\n'
printf '    Super+Print      → screenshot (region select)\n'
printf '    Super+Minus      → scratchpad toggle\n'
printf '    Brightness keys  → brightnessctl\n'
printf '    Volume keys      → pactl + notification\n'
printf '    Alt+Shift        → switch keyboard US ↔ Persian\n'
echo ""
printf '\033[1;33m  First-time multi-monitor setup:\033[0m\n'
printf '    1. Plug in dock\n'
printf '    2. Press Super+Shift+M\n'
printf '    3. Arrange monitors in arandr → Apply → close\n'
printf '    4. Layout auto-saved (notification confirms)\n'
printf '    5. All future dock connects apply it automatically\n'
echo ""
printf '\033[1;33m  Customise:\033[0m\n'
printf '    Shell:      fish is your default shell\n'
printf '                omf + tide are installed and themed\n'
printf '                abbreviations: r=ranger, gs=git status, ll=ls -lah, ..\n'
printf '    Ranger:     hjkl navigation, . = toggle hidden, q = quit\n'
printf '                Super+Shift+E opens it in alacritty\n'
printf '    Tide:       run "tide configure" to change prompt style\n'
printf '    Lock screen: betterlockscreen --update ~/Pictures/wall.jpg\n'
printf '                 edit ~/.config/betterlockscreen/betterlockscreenrc\n'
printf '    Wallpaper:  edit ~/.config/i3/config\n'
printf '                feh --bg-color → feh --bg-fill ~/Pictures/wall.jpg\n'
printf '    Multi-mon:  uncomment workspace→output lines in i3 config\n'
printf '    Touchpad:   edit /etc/X11/xorg.conf.d/40-libinput.conf\n'
printf '    HiDPI:      set Xft.dpi=192 in ~/.Xresources\n'
echo ""
