- **Window Manager** • [Hyprland](https://github.com/hyprwm/Hyprland).
- **Shell** • [Zsh](https://www.zsh.org) & [Starship](https://github.com/starship/starship), [Oh-My-Zsh](https://ohmyz.sh/) addons.
- **Terminal** • [WezTerm](https://github.com/wez/wezterm).
- **Fetch** • [Neofetch](https://github.com/dylanaraps/neofetch) *outdated*.
- **Panel** • [Hyprpanel](https://hyprpanel.com/getting_started/installation.html).
- **Notify Daemon** • [Hyprpanel](https://hyprpanel.com/getting_started/installation.html)(built in).
- **Launcher** • [Rofi](https://github.com/davatorium/rofi).
- **File Manager** • [Dolphin](https://github.com/KDE/dolphin).
- **IDE** • [VSCode](https://code.visualstudio.com/).
- **Music Player** • [Spotify-Adblock](https://aur.archlinux.org/packages/spotify-adblock) & [Spicetify](https://spicetify.app/docs/advanced-usage/installation/) addon.
- **Discord** • [Vencord](https://vencord.dev/download/) addon.
- **Fonts** • [JetBrainsMono](https://archlinux.org/packages/extra/any/ttf-jetbrains-mono/), [JetBrainsMonoNerd](https://archlinux.org/packages/extra/any/ttf-jetbrains-mono-nerd/), [Font Awesome](https://archlinux.org/packages/extra/any/ttf-font-awesome/).

# Installation

_You should have everything installed, this will only make pre-existing config look pretty._

```zsh
git clone https://github.com/foolishaimsxd/dotfiles.git

# Terminal
cp -r ~/dotfiles/wezterm ~/.config/

# Wallpapers
cp -r ~/dotfiles/Wallpapers ~/

# IDE
cp -r ~/dotfiles/VSCDots/* ~/.config/Code/User/
sudo chmod a+wr /opt/visual-studio-code

# Vencord
cp -r ~/dotfiles/vencord/* ~/.config/Vencord/settings/

# Spotify/Spicetify
cp -r ~/dotfiles/spicetify/* ~/.config/spicetify/

# Fetch
cp -r ~/dotfiles/neofetch/ ~/.config/

# Starship
cp -r ~/dotfiles/startship.toml/ ~/.config/
```

### IDE(extra)
- For the css in VSCDots to work you must install [Custom CSS & JS Loader](https://marketplace.visualstudio.com/itemdetails?itemName=be5invis.vscode-custom-css) Extension.
- **Enable** • *Ctrl+Shift+P: Enable CSS & JS Loader*.
- Install AUR [Visual Studio Code](https://aur.archlinux.org/packages/visual-studio-code-bin) for [Custom CSS & JS Loader](https://marketplace.visualstudio.com/itemdetails?itemName=be5invis.vscode-custom-css) To be avaliable within the marketplace.

**Extensions**: Omni Theme, Fluent Icons, Prettier & Github Copilot.

### Hyprpanel Config
Open settings through dashboard and load the hyprland_config.json file through the import function.
