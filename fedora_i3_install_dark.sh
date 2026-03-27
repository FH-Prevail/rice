#!/usr/bin/env bash
# ================================================================
#  Fedora 43 i3 Spin — Production Rice
#  Catppuccin Mocha · Full daily-driver setup
#
#  What this script does:
#    - Installs i3 extras, compositing, theming
#    - Asks which browser to install
#    - Configures dunst (notifications, Catppuccin themed)
#    - Configures betterlockscreen (blurred lock + clock)
#    - Configures xss-lock (auto-lock on suspend / lid close)
#    - Configures brightnessctl (brightness keys)
#    - Configures libinput (tap-to-click, natural scroll)
#    - Configures xclip clipboard
#    - Configures unclutter (hides idle cursor)
#    - Configures tlp (battery/power optimisation)
#    - Writes .Xresources (cursor theme, DPI, font rendering)
#    - Multi-monitor: autorandr + arandr + Super+Shift+M workflow
#    - fish shell + oh-my-fish + tide prompt (Catppuccin)
#    - ranger file manager (Catppuccin theme)
#    - All configs Catppuccin Mocha throughout
#
#  Usage:
#    bash <(curl -fsSL https://raw.githubusercontent.com/FH-Prevail/rice/main/fedora_i3_install_dark.sh)
# ================================================================

# Strict mode but handle dnf exit codes manually
set -uo pipefail

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  echo "Please run this script as your normal user, not root."
  exit 1
fi

log()      { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
success()  { printf '\033[1;32m  ✓ %s\033[0m\n' "$*"; }
info()     { printf '\033[1;33m  → %s\033[0m\n' "$*"; }
warn()     { printf '\033[1;31m  ⚠ %s\033[0m\n' "$*"; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1"; exit 1; }; }

need_cmd sudo
need_cmd dnf
need_cmd curl
need_cmd git

# ================================================================
#  Package installation
#  --skip-unavailable: ignore packages not in repos silently
#  --best --allowerasing: resolve conflicts automatically
# ================================================================
log "Refreshing repositories"
sudo dnf check-update --refresh || true   # returns 100 when updates exist — not an error

log "Installing core packages"
sudo dnf install -y --skip-unavailable \
  xorg-x11-xinit xorg-x11-server-Xorg xorg-x11-utils \
  i3 i3status i3lock \
  xsettingsd \
  rofi picom feh dex lxappearance arandr autorandr \
  alacritty \
  thunar thunar-archive-plugin thunar-volman \
  gvfs gvfs-fuse tumbler file-roller \
  pavucontrol pipewire-pulseaudio wireplumber \
  network-manager-applet blueman \
  dunst libnotify \
  xss-lock \
  brightnessctl \
  xclip xdotool \
  unclutter \
  tlp tlp-rdw \
  flameshot playerctl \
  ranger python3-pillow w3m \
  fish \
  ImageMagick bc \
  unzip wget git curl \
  @development-tools autoconf make pkgconf \
  pam-devel cairo-devel fontconfig-devel \
  libxcb-devel libev-devel libX11-devel \
  libxkbcommon-devel libxkbcommon-x11-devel \
  xcb-util-image-devel xcb-util-devel xcb-util-xrm-devel \
  libjpeg-turbo-devel \
  fontawesome-fonts \
  google-noto-fonts-common \
  google-noto-emoji-fonts \
  jetbrains-mono-fonts \
  arc-theme papirus-icon-theme \
  lightdm lightdm-gtk-greeter \
  xdg-utils \
  polkit-gnome

success "Core packages installed"

# Add user to video group — needed for brightnessctl without sudo
sudo usermod -aG video "$USER"
success "Added $USER to video group (brightness control)"

# ================================================================
#  i3lock-color — build from source (not in Fedora repos)
#  betterlockscreen depends on it for themed lock screen
# ================================================================
log "Building i3lock-color from source"
LOCKCOLOR_DIR="$(mktemp -d)"
git clone --depth=1 https://github.com/Raymo111/i3lock-color.git "$LOCKCOLOR_DIR"
pushd "$LOCKCOLOR_DIR" >/dev/null
  bash install-i3lock-color.sh
popd >/dev/null
rm -rf "$LOCKCOLOR_DIR"
success "i3lock-color built and installed"

# ================================================================
#  betterlockscreen — Catppuccin themed lock with blur + clock
# ================================================================
log "Installing betterlockscreen"
curl -fsSLo /tmp/betterlockscreen \
  https://raw.githubusercontent.com/betterlockscreen/betterlockscreen/main/betterlockscreen
sudo install -m 755 /tmp/betterlockscreen /usr/local/bin/betterlockscreen
rm -f /tmp/betterlockscreen

sudo curl -fsSLo /usr/lib/systemd/system/betterlockscreen@.service \
  "https://raw.githubusercontent.com/betterlockscreen/betterlockscreen/main/system/betterlockscreen%40.service"
sudo systemctl enable "betterlockscreen@${USER}" || true
success "betterlockscreen installed and service enabled"

# ================================================================
#  Betterlockscreen config — Catppuccin Mocha palette
# ================================================================
log "Writing betterlockscreen config"
mkdir -p "$HOME/.config/betterlockscreen"
cat > "$HOME/.config/betterlockscreen/betterlockscreenrc" <<'BETTERLOCKRC'
# ── Effects ─────────────────────────────────────────────────────
blur_level=1
dim_level=40

# ── Clock ────────────────────────────────────────────────────────
time_format="%H:%M"
date_format="%A, %d %B"

# ── Layout ──────────────────────────────────────────────────────
time_pos="ix:iy-120"
date_pos="ix:iy-60"
indicator_pos="ix:iy+40"
greeter_pos="ix:iy+120"

# ── Time ────────────────────────────────────────────────────────
time_font="JetBrains Mono Bold"
time_size=64
time_color="cdd6f4ff"

# ── Date ────────────────────────────────────────────────────────
date_font="JetBrains Mono"
date_size=22
date_color="a6adc8ff"

# ── Greeter ─────────────────────────────────────────────────────
greeter_text="Type password to unlock"
greeter_font="JetBrains Mono"
greeter_size=14
greeter_color="6c7086ff"

# ── Ring ────────────────────────────────────────────────────────
ring_color="313244ff"
ring_ver_color="89b4faff"
ring_wrong_color="f38ba8ff"
key_hl_color="cba6f7ff"
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
#  Lock screen wallpaper
# ================================================================
log "Lock screen wallpaper setup"
echo ""
echo "  betterlockscreen blurs your wallpaper for the lock screen."
echo "  You can set it now or skip and run manually later:"
echo "    betterlockscreen --update ~/Pictures/wallpaper.jpg"
echo ""
echo "    1) Enter a path to an image on this machine"
echo "    2) Skip for now"
echo ""
while true; do
  read -rp "  Enter choice [1-2]: " LOCK_CHOICE
  case "$LOCK_CHOICE" in 1|2) break ;; *) echo "  Please enter 1 or 2." ;; esac
done

if [[ "$LOCK_CHOICE" == "1" ]]; then
  while true; do
    read -rp "  Image path: " LOCK_IMG_RAW
    LOCK_IMG="${LOCK_IMG_RAW/#\~/$HOME}"
    if [[ -f "$LOCK_IMG" ]]; then break
    else echo "  File not found: $LOCK_IMG — try again."; fi
  done
  log "Pre-rendering lock screen — this takes a moment..."
  betterlockscreen --update "$LOCK_IMG" --display 1
  success "Lock screen image set"
else
  info "Skipped — run 'betterlockscreen --update <image>' later"
fi

# ================================================================
#  Browser selection
# ================================================================
log "Browser selection"
echo ""
echo "  Which browser would you like to install?"
echo ""
echo "    1) Brave   — privacy-focused, Chromium-based"
echo "    2) Firefox — already installed on Fedora, just set as default"
echo "    3) Chrome  — Google Chrome (proprietary)"
echo "    4) Skip    — I will install a browser myself"
echo ""
while true; do
  read -rp "  Enter choice [1-4]: " BROWSER_CHOICE
  case "$BROWSER_CHOICE" in 1|2|3|4) break ;; *) echo "  Please enter 1, 2, 3 or 4." ;; esac
done

BROWSER_DESKTOP=""
BROWSER_BIN=""

case "$BROWSER_CHOICE" in
  1)
    log "Installing Brave"
    if ! rpm -q brave-browser >/dev/null 2>&1; then
      sudo dnf config-manager addrepo \
        --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
      sudo dnf install -y brave-browser
    else
      info "Brave already installed"
    fi
    BROWSER_DESKTOP="brave-browser.desktop"
    BROWSER_BIN="/usr/bin/brave-browser"
    ;;

  2)
    log "Setting Firefox as default"
    if ! rpm -q firefox >/dev/null 2>&1; then
      sudo dnf install -y firefox
    else
      info "Firefox already installed"
    fi
    BROWSER_DESKTOP="firefox.desktop"
    BROWSER_BIN="/usr/bin/firefox"
    ;;

  3)
    log "Installing Google Chrome"
    if ! rpm -q google-chrome-stable >/dev/null 2>&1; then
      sudo dnf install -y \
        https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
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
  log "Setting $BROWSER_DESKTOP as default browser"
  xdg-settings set default-web-browser "$BROWSER_DESKTOP" || true
  xdg-mime default "$BROWSER_DESKTOP" text/html                  || true
  xdg-mime default "$BROWSER_DESKTOP" x-scheme-handler/http      || true
  xdg-mime default "$BROWSER_DESKTOP" x-scheme-handler/https     || true
  I3_BROWSER_CMD="${BROWSER_BIN##*/}"
else
  I3_BROWSER_CMD="xdg-open"
fi

# ================================================================
#  System services
#  Fedora i3 Spin uses lightdm already — we still ensure it and
#  disable gdm/sddm if somehow present
# ================================================================
log "Enabling system services"
sudo systemctl enable NetworkManager || true
sudo systemctl enable tlp            || true
for DM in gdm gdm3 sddm; do
  if systemctl is-enabled "$DM" >/dev/null 2>&1; then
    sudo systemctl disable "$DM" || true
    info "Disabled $DM — keeping LightDM"
  fi
done
sudo systemctl enable lightdm || true
success "NetworkManager, LightDM, TLP enabled"

# ================================================================
#  LightDM greeter — dark Catppuccin
# ================================================================
log "Configuring LightDM greeter"
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
#  Touchpad — libinput
# ================================================================
log "Configuring libinput touchpad"
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/40-libinput.conf >/dev/null <<'TOUCHPAD'
Section "InputClass"
    Identifier "touchpad"
    MatchIsTouchpad "on"
    Driver "libinput"
    Option "Tapping"            "on"
    Option "TappingButtonMap"   "lmr"
    Option "NaturalScrolling"   "true"
    Option "ScrollMethod"       "twofinger"
    Option "DisableWhileTyping" "true"
    Option "ClickMethod"        "clickfinger"
    Option "AccelProfile"       "adaptive"
EndSection
TOUCHPAD
success "Touchpad: tap-to-click, natural scroll, two-finger enabled"

# ================================================================
#  Config directories
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
#  .Xresources
# ================================================================
log "Writing .Xresources"
cat > "$HOME/.Xresources" <<'XRESOURCES'
! ── Cursor ──────────────────────────────────────────────────
Xcursor.theme: Adwaita
Xcursor.size:  24

! ── DPI / Font rendering ────────────────────────────────────
! Change Xft.dpi to 192 for HiDPI/4K screens
Xft.dpi:       96
Xft.antialias: true
Xft.hinting:   true
Xft.hintstyle: hintslight
Xft.rgba:      rgb
Xft.lcdfilter: lcddefault
XRESOURCES

# ================================================================
#  GTK theme — Arc-Dark / Papirus-Dark
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

# Set fish as Alacritty default shell
FISH_BIN="$(command -v fish 2>/dev/null || echo /usr/bin/fish)"
cat >> "$HOME/.config/alacritty/alacritty.toml" <<ALACRITTY_SHELL

[shell]
program = "$FISH_BIN"
args    = ["--login"]
ALACRITTY_SHELL
success "Alacritty will launch fish by default"

# ================================================================
#  Fish — set as default shell
# ================================================================
log "Setting fish as default shell"
FISH_PATH="$(command -v fish)"
if ! grep -qxF "$FISH_PATH" /etc/shells; then
  echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
fi
sudo chsh -s "$FISH_PATH" "$USER"
success "Default shell → fish ($FISH_PATH)"

# ================================================================
#  Fish — base config + Catppuccin colours
# ================================================================
log "Writing fish config"
mkdir -p "$HOME/.config/fish/functions" "$HOME/.config/fish/conf.d"
cat > "$HOME/.config/fish/config.fish" <<'FISHCONFIG'
set -g fish_greeting ""

set -gx EDITOR     nano
set -gx VISUAL     $EDITOR
set -gx PAGER      less
set -gx LESS       "-R --use-color"
set -gx XDG_CONFIG_HOME "$HOME/.config"

fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/.cargo/bin"

# Catppuccin Mocha syntax colours
set -g fish_color_command           89b4fa
set -g fish_color_param             cdd6f4
set -g fish_color_keyword           cba6f7
set -g fish_color_quote             a6e3a1
set -g fish_color_redirection       f9e2af
set -g fish_color_end               f9e2af
set -g fish_color_error             f38ba8
set -g fish_color_comment           6c7086
set -g fish_color_selection         313244
set -g fish_color_search_match      --background=313244
set -g fish_color_operator          94e2d5
set -g fish_color_escape            f5c2e7
set -g fish_color_autosuggestion    6c7086
set -g fish_color_cancel            f38ba8
set -g fish_pager_color_prefix        cba6f7 --bold
set -g fish_pager_color_completion    cdd6f4
set -g fish_pager_color_description  6c7086
set -g fish_pager_color_progress     a6adc8 --background=313244
set -g fish_pager_color_selected_background --background=313244

# Abbreviations
abbr --add ll  'ls -lah --color=auto'
abbr --add la  'ls -A --color=auto'
abbr --add ..  'cd ..'
abbr --add ... 'cd ../..'
abbr --add g   'git'
abbr --add gs  'git status'
abbr --add gd  'git diff'
abbr --add ga  'git add'
abbr --add gc  'git commit'
abbr --add gp  'git push'
abbr --add r   'ranger'
abbr --add e   '$EDITOR'
FISHCONFIG
success "Fish config written with Catppuccin Mocha colours"

# ================================================================
#  Fisher — plugin manager for tide
# ================================================================
log "Installing Fisher"
fish -c '
  curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish \
    | source && fisher install jorgebucaran/fisher
' && success "Fisher installed"

# ================================================================
#  Tide — Catppuccin prompt
# ================================================================
log "Installing Tide"
fish -c 'fisher install IlanCosman/tide@v6' && success "Tide installed"

log "Configuring Tide"
fish -c '
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

fish -c '
  set -U tide_git_color_branch         89b4fa
  set -U tide_git_color_staged         a6e3a1
  set -U tide_git_color_dirty          f9e2af
  set -U tide_git_color_untracked      89dceb
  set -U tide_git_color_conflicted     f38ba8
  set -U tide_pwd_color_dirs           cba6f7
  set -U tide_pwd_color_anchors        cba6f7
  set -U tide_cmd_duration_color       6c7086
  set -U tide_status_color             a6e3a1
  set -U tide_status_color_failure     f38ba8
  set -U tide_character_color          a6e3a1
  set -U tide_character_color_failure  f38ba8
'
success "Tide Catppuccin colours applied"

# ================================================================
#  Ranger — config + Catppuccin colorscheme
# ================================================================
log "Writing Ranger config"
ranger --copy-config=all 2>/dev/null || true
mkdir -p "$HOME/.config/ranger/colorschemes"

cat > "$HOME/.config/ranger/rc.conf" <<'RANGERRC'
set colorscheme catppuccin
set preview_images false
set preview_images_method w3m
set unicode_ellipsis true
set show_hidden false
set show_cursor false
set draw_borders separators
set dirname_in_tabs true
set mouse_enabled true
set column_ratios 2,3,4
set use_preview_script true
set preview_max_size 104857600
set confirm_on_delete multiple
set save_console_history true
set scroll_offset 5
set tilde_in_titlebar true
set update_title true
set vcs_aware true
set vcs_backend_git enabled
map <C-t> shell alacritty &
map . toggle_option show_hidden
RANGERRC

cat > "$HOME/.config/ranger/colorschemes/catppuccin.py" <<'RANGERTHEME'
from ranger.gui.colorscheme import ColorScheme
from ranger.gui.color import default_colors, default, reverse, bold, normal

MAUVE=183; RED=210; PEACH=216; YELLOW=229; GREEN=157
TEAL=159; SKY=153; BLUE=111; LAVENDER=189; TEXT=253
SUBTEXT1=250; OVERLAY0=240; SURFACE0=236; BASE=234

class Catppuccin(ColorScheme):
    def use(self, context):
        fg, bg, attr = default_colors
        if context.reset:
            return default_colors
        elif context.in_browser:
            fg = TEXT
            if context.selected:    attr = reverse
            if context.empty or context.error: fg = RED
            if context.directory:   fg = BLUE;   attr |= bold
            elif context.executable: fg = GREEN;  attr |= bold
            if context.link:        fg = TEAL if context.good else RED
            if context.image:       fg = MAUVE
            if context.audio:       fg = TEAL
            if context.video:       fg = MAUVE
            if context.document:    fg = YELLOW
            if context.container:   fg = PEACH;  attr |= bold
            if context.socket:      fg = YELLOW; attr |= bold
        elif context.in_titlebar:
            if context.hostname:    fg = MAUVE;    attr |= bold
            elif context.directory: fg = BLUE
            elif context.tab:       fg = LAVENDER if context.good else OVERLAY0
            elif context.link:      fg = TEAL
            else:                   fg = TEXT
        elif context.in_statusbar:
            if context.permissions: fg = GREEN if context.good else RED
            if context.marked:      fg = PEACH;  attr |= bold
            if context.message:     fg = YELLOW if context.bad else TEXT
        if context.header:
            attr |= bold; fg = LAVENDER
        return fg, bg, attr
RANGERTHEME
success "Ranger configured with Catppuccin theme"

# ================================================================
#  Picom — rounded corners, blur, shadows
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
shadow-exclude  = [ "class_g = 'i3bar'", "class_g = 'Rofi'" ];
fade-in-step    = 0.04;
fade-out-step   = 0.04;
fading          = true;
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
#  Dunst — Catppuccin Mocha notifications
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
    notification_limit     = 5
    progress_bar           = true
    progress_bar_height    = 6
    progress_bar_frame_width = 1
    progress_bar_corner_radius = 3
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
    stack_duplicates       = true
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

[urgency_low]
    background  = "#1e1e2e"
    foreground  = "#a6adc8"
    frame_color = "#313244"
    timeout     = 4

[urgency_normal]
    background  = "#1e1e2e"
    foreground  = "#cdd6f4"
    frame_color = "#89b4fa"
    timeout     = 6

[urgency_critical]
    background  = "#1e1e2e"
    foreground  = "#f38ba8"
    frame_color = "#f38ba8"
    timeout     = 0
DUNST

# ================================================================
#  Rofi — Catppuccin Mocha launcher
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
  font: "JetBrains Mono 11";
  drun-display-format: "{name}";
  disable-history: false;
  hover-select: true;
  me-select-entry: "";
  me-accept-entry: "MousePrimary";
}

* {
  bg:            #11111bf2;
  bg-alt:        #181825;
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
entry  { text-color: @fg; placeholder: "Search..."; placeholder-color: @fg-muted; }

listview {
  lines: 10; columns: 1; fixed-height: false;
  background-color: transparent; spacing: 6px; scrollbar: false;
}

element {
  background-color: @bg-alt; text-color: @fg;
  border-radius: 10px; padding: 10px 12px;
}

element selected.normal { background-color: @selected; text-color: @selected-text; }
element normal.urgent    { background-color: @urgent;   text-color: #11111b; }
element-icon { size: 1.1em; }

message { background-color: @bg-alt; border-radius: 10px; padding: 10px; }
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
#  Monitor setup script
# ================================================================
log "Writing monitor setup script"
cat > "$HOME/.config/i3/scripts/monitor-setup.sh" <<'MONITOR_SCRIPT'
#!/usr/bin/env bash
get_profile_name() {
  xrandr --query | awk '/ connected/ {print $1}' | sort | paste -sd '-'
}
arandr
PROFILE="$(get_profile_name)"
if autorandr --save "$PROFILE" --force 2>/dev/null; then
  notify-send --icon=display --urgency=normal \
    "Monitor layout saved" "Profile: <b>$PROFILE</b>"
else
  notify-send --icon=dialog-error --urgency=critical \
    "Monitor save failed" "Could not save profile '$PROFILE'"
fi
MONITOR_SCRIPT
chmod +x "$HOME/.config/i3/scripts/monitor-setup.sh"

# ================================================================
#  i3 config — production ready
# ================================================================
log "Writing i3 config"
cat > "$HOME/.config/i3/config" <<'I3EOF'
# ================================================================
#  Fedora — i3 Production Rice · Catppuccin Mocha
# ================================================================

# ── Variables ───────────────────────────────────────────────────
set $mod         Mod4
set $terminal    alacritty
set $filemanager thunar
set $termfiles   alacritty -e ranger
set $menu        rofi -show drun
set $launcher    rofi -show run
set $winpicker   rofi -show window
set $lock        betterlockscreen -l blur
set $monitor_setup ~/.config/i3/scripts/monitor-setup.sh
set $browser     BROWSER_PLACEHOLDER

# vim-style focus — $mod+h = focus left ONLY
# Horizontal split → $mod+\ (avoids conflict)
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

# ── Startup — exec once at login ─────────────────────────────────
exec --no-startup-id dex --autostart --environment i3
exec --no-startup-id nm-applet
exec --no-startup-id blueman-applet
exec --no-startup-id dunst
exec --no-startup-id picom --config ~/.config/picom/picom.conf
exec --no-startup-id unclutter --timeout 3 --jitter 5 --start-hidden
exec --no-startup-id xss-lock --transfer-sleep-lock -- betterlockscreen -l blur
exec --no-startup-id /usr/libexec/polkit-gnome-authentication-agent-1

# ── exec_always — re-run on every reload/restart ─────────────────
exec_always --no-startup-id xsettingsd
exec_always --no-startup-id xsetroot -cursor_name left_ptr
exec_always --no-startup-id sh -c 'xset -b; xset s off -dpms'
exec_always --no-startup-id setxkbmap -model pc104 -layout us,ir -variant ,, -option grp:alt_shift_toggle
exec_always --no-startup-id xrdb -merge ~/.Xresources
exec_always --no-startup-id autorandr --change

# Wallpaper — replace with: exec_always feh --bg-fill ~/Pictures/wall.jpg
exec_always --no-startup-id feh --bg-color '#11111b'

# Save laptop-only profile on first login if not already saved
exec --no-startup-id sh -c 'sleep 5 && autorandr --list 2>/dev/null | grep -q "^mobile$" || autorandr --save mobile --force'

# ── Launchers ────────────────────────────────────────────────────
bindsym $mod+Return    exec $terminal
bindsym $mod+d         exec $menu
bindsym $mod+Shift+d   exec $launcher
bindsym $mod+Tab       exec $winpicker
bindsym $mod+b         exec $browser
bindsym $mod+e         exec $filemanager
bindsym $mod+Shift+e   exec $termfiles
bindsym $mod+c         exec --no-startup-id xclip -sel clip

# ── Screenshots ──────────────────────────────────────────────────
bindsym Print          exec --no-startup-id flameshot full
bindsym $mod+Print     exec --no-startup-id flameshot gui
bindsym $mod+Shift+s   exec --no-startup-id flameshot gui

# ── Session ──────────────────────────────────────────────────────
bindsym $mod+Shift+x   exec $lock
bindsym $mod+Shift+q   kill
bindsym $mod+Shift+c   reload
bindsym $mod+Shift+r   restart
bindsym $mod+Shift+e   exec "i3-nagbar -t warning -m 'Exit i3?' -B 'Yes' 'i3-msg exit'"

# ── Monitors ─────────────────────────────────────────────────────
bindsym $mod+Shift+m   exec $monitor_setup

# ── Focus ────────────────────────────────────────────────────────
bindsym $mod+$left  focus left
bindsym $mod+$down  focus down
bindsym $mod+$up    focus up
bindsym $mod+$right focus right
bindsym $mod+Left   focus left
bindsym $mod+Down   focus down
bindsym $mod+Up     focus up
bindsym $mod+Right  focus right

# ── Move ─────────────────────────────────────────────────────────
bindsym $mod+Shift+$left  move left
bindsym $mod+Shift+$down  move down
bindsym $mod+Shift+$up    move up
bindsym $mod+Shift+$right move right
bindsym $mod+Shift+Left   move left
bindsym $mod+Shift+Down   move down
bindsym $mod+Shift+Up     move up
bindsym $mod+Shift+Right  move right

# ── Layout ───────────────────────────────────────────────────────
bindsym $mod+backslash  split h
bindsym $mod+v          split v
bindsym $mod+f          fullscreen toggle
bindsym $mod+s          layout stacking
bindsym $mod+w          layout tabbed
bindsym $mod+Shift+space floating toggle
bindsym $mod+space       focus mode_toggle
bindsym $mod+a           focus parent

# ── Workspaces ───────────────────────────────────────────────────
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

# ── Multi-monitor workspace assignment ───────────────────────────
# Uncomment after running: xrandr --query
# workspace $ws1  output eDP-1
# workspace $ws6  output HDMI-1
# workspace $ws8  output DP-1

# ── Resize ───────────────────────────────────────────────────────
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

# ── Volume ───────────────────────────────────────────────────────
bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +5% && notify-send -t 1500 -h string:x-canonical-private-synchronous:volume " Volume" "$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1)"
bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -5% && notify-send -t 1500 -h string:x-canonical-private-synchronous:volume " Volume" "$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1)"
bindsym XF86AudioMute        exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle && notify-send -t 1500 -h string:x-canonical-private-synchronous:volume " Volume" "toggled"

# ── Brightness ───────────────────────────────────────────────────
bindsym XF86MonBrightnessUp   exec --no-startup-id brightnessctl set +5% && notify-send -t 1200 -h string:x-canonical-private-synchronous:brightness " Brightness" "$(brightnessctl -m | cut -d, -f4)"
bindsym XF86MonBrightnessDown exec --no-startup-id brightnessctl set 5%- && notify-send -t 1200 -h string:x-canonical-private-synchronous:brightness " Brightness" "$(brightnessctl -m | cut -d, -f4)"

# ── Media ─────────────────────────────────────────────────────────
bindsym XF86AudioPlay exec --no-startup-id playerctl play-pause
bindsym XF86AudioNext exec --no-startup-id playerctl next
bindsym XF86AudioPrev exec --no-startup-id playerctl previous

# ── Scratchpad ───────────────────────────────────────────────────
bindsym $mod+minus       scratchpad show
bindsym $mod+Shift+minus move scratchpad

# ── Bar ──────────────────────────────────────────────────────────
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

# ── Window colors ────────────────────────────────────────────────
client.focused          #89b4fa #89b4fa #11111b #cba6f7 #89b4fa
client.focused_inactive #313244 #313244 #cdd6f4 #313244 #313244
client.unfocused        #1e1e2e #1e1e2e #6c7086 #1e1e2e #1e1e2e
client.urgent           #f38ba8 #f38ba8 #11111b #f38ba8 #f38ba8
client.placeholder      #1e1e2e #1e1e2e #a6adc8 #1e1e2e #1e1e2e
client.background       #11111b

# ── Floating rules ───────────────────────────────────────────────
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
success "i3 config written — browser: $I3_BROWSER_CMD"

# ================================================================
#  .xinitrc — TTY fallback
# ================================================================
log "Writing .xinitrc"
cat > "$HOME/.xinitrc" <<'XINIT'
xrdb -merge ~/.Xresources
exec i3
XINIT

# ================================================================
#  Final summary
# ================================================================
echo ""
printf '\033[1;34m════════════════════════════════════════════════════════\033[0m\n'
printf '\033[1;32m  Fedora i3 rice installed successfully!\033[0m\n'
printf '\033[1;34m════════════════════════════════════════════════════════\033[0m\n'
echo ""
printf '\033[1m  Log out and choose i3 at the login screen.\033[0m\n'
printf '\033[1m  (or reboot if you are not already in i3)\033[0m\n'
echo ""
printf '\033[1;33m  Key shortcuts:\033[0m\n'
printf '    Super+Return     → terminal (alacritty + fish)\n'
printf '    Super+D          → app launcher (rofi)\n'
printf '    Super+B          → browser (%s)\n' "$I3_BROWSER_CMD"
printf '    Super+E          → file manager (thunar GUI)\n'
printf '    Super+Shift+E    → ranger (terminal file manager)\n'
printf '    Super+Tab        → window switcher\n'
printf '    Super+Shift+M    → arrange monitors\n'
printf '    Super+Shift+X    → lock screen (betterlockscreen)\n'
printf '    Print            → screenshot fullscreen\n'
printf '    Super+Print      → screenshot region select\n'
printf '    Super+Minus      → scratchpad toggle\n'
printf '    Brightness keys  → brightnessctl\n'
printf '    Volume keys      → pactl + OSD notification\n'
printf '    Alt+Shift        → switch keyboard US ↔ Persian\n'
echo ""
printf '\033[1;33m  First-time monitor setup:\033[0m\n'
printf '    1. Plug in dock  2. Super+Shift+M\n'
printf '    3. Arrange in arandr → Apply → close\n'
printf '    4. Saved automatically, auto-applies next time\n'
echo ""
printf '\033[1;33m  Customise:\033[0m\n'
printf '    Wallpaper:   feh --bg-color in i3 config → feh --bg-fill ~/Pictures/wall.jpg\n'
printf '    Lock screen: betterlockscreen --update ~/Pictures/wall.jpg\n'
printf '    HiDPI:       set Xft.dpi=192 in ~/.Xresources\n'
printf '    Touchpad:    edit /etc/X11/xorg.conf.d/40-libinput.conf\n'
printf '    Tide prompt: run "tide configure" in fish\n'
echo ""
