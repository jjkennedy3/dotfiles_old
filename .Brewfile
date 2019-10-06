tap 'homebrew/cask-versions'
tap 'homebrew/cask-fonts'
tap 'homebrew/cask'

# Github actions cannot install these.
if ENV.has_key?('SKIP_MAS') then
    brew "mas"

    mas '1Password', id:1333542190
    mas "Things", id: 904280696
    mas "WhatsApp", id: 1147396723
    mas "Textual 7", id: 1262957439
    mas "Slack", id: 803453959
    mas "Magnet", id: 441258766
    mas "Day One", id:1055511498
end


# Core casks
cask "thingsmacsandboxhelper"
cask "firefox-developer-edition"
cask "little-snitch"
cask "iterm2"
cask "pycharm"
cask "alfred3"
cask "docker"
cask "google-chrome"
cask "flux"
cask "micro-snitch"
cask "vlc"
cask "dash"

# Misc apps
cask "gpg-suite"
cask "istat-menus"
cask "deckset"
cask "postgres"

# Fonts
cask 'font-source-code-pro-for-powerline'
cask 'font-source-code-pro'
cask 'font-source-sans-pro'
cask 'font-source-serif-pro'

# Core brews
brew "fish"
brew "exa"
brew "python"
brew "pyenv"
brew "pipenv"
brew "rustup-init"
brew "node"
brew "nvm"
brew "ipython"

# Standard utils
brew "wget"
brew "git"
brew "git-lfs"
brew "nano"
brew "coreutils"
brew "findutils"
brew "watch"
brew "pkg-config"
brew "screen"
brew "ncdu"
brew "htop"
brew "tmux"
brew "curl"

# Useful utilities
brew "bat"
brew "fd"
brew "httpie"
brew "tokei"
brew "pv"
brew "tldr"
brew "fzf"
brew "tree"
brew "ripgrep"
brew "jq"
brew "youtube-dl"
brew "watchman"
brew "pstree"

# Completion
brew "docker-completion"
brew "cargo-completion"

# Kubernetes and Docker
brew "kubectl"
brew "stern"
brew "kubectx"
brew "dive"

# Other
brew "defaultbrowser"
brew "hugo"

custom_brewfile = "#{Dir.home}/.Brewfile.#{Socket.gethostname}"
if File.file?(custom_brewfile)
	instance_eval(File.read(custom_brewfile))
else
	puts "#{custom_brewfile} does not exist!"
end
