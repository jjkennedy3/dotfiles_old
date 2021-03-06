#!/bin/zsh --emulate sh
set -uo pipefail
IFS=$'\n\t'

print() {
  # strict mode my ass 🤷‍
  local IFS=" "
  printf "\r\033[2K  [ \033[00;32m%s\033[0m ] %s\n" "$(date +'%r')" "$*"
}

fail() {
  local IFS=" "
  printf "\r\033[2K  [ \033[00;31m%s\033[0m ] 🛑 %s\n" "$(date +'%r')" "$*"
}

info() {
  local IFS=" "
  printf "  [ \033[00;34m%s\033[0m ] %s\n" "$(date +'%r')" "$*"
}

_run_cmd() {
  output_file=$(mktemp)
  if command -v "ptail" > /dev/null; then
    # shellcheck disable=SC2068
    if ! $@ 2>&1 | tee "${output_file}" | ptail; then
      fail "There was an error running" "$@"
      fail "You can view the full output file here: ${output_file}"
      return 1
    fi
  else
    # shellcheck disable=SC2068
    if ! $@ &>>"${output_file}"; then
      cat "${output_file}"
      fail "There was an error running" "$@"
      fail "You can view the output above for diagnostics."
      return 1
    fi
  fi
  return 0
}

run_cmd() {
  info "Running" "$@"
  # shellcheck disable=SC2068
  if ! _run_cmd $@; then
    exit 1
  fi
}

run_cmd_ignore_errors() {
  info "Running (ignoring errors)" "$@"
  # shellcheck disable=SC2068
  _run_cmd $@
}

SKIP_SLOW_DEPENDENCIES="${SKIP_SLOW_DEPENDENCIES:-0}"
REPO="${REPO:-git@github.com:orf/dotfiles.git}"
DOTFILES_REF=${DOTFILES_REF:-master}

if [[ $(uname) == "Darwin" ]]; then
IS_MAC=true
else
IS_MAC=false
fi

export DOTFILES_GIT_DIR="$HOME"/.dotfiles

if [ ! -d "$DOTFILES_GIT_DIR" ]; then
  print "Cloning dotfiles from ${REPO}, branch ${DOTFILES_REF}"
  # The ultimate git checkout for dotfiles.
  # Clone the dotfiles at a given reference, into a specific git directory (~/.dotfiles)
  # We specify --no-checkout here so that we can exclude some files from the checkout
  run_cmd git clone --separate-git-dir="$DOTFILES_GIT_DIR" --no-checkout "${REPO}" my-dotfiles-tmp
  # Enable sparse checkouts and exclude .github/ and README.md. The order matters, /* must be the first rule.
  run_cmd git --git-dir="$DOTFILES_GIT_DIR" config --local core.sparsecheckout true
  cat <<EOF >>"$DOTFILES_GIT_DIR"/info/sparse-checkout
/*
!.github/
!README.md
EOF
  # Checkout the dotfiles
  run_cmd git --git-dir="$DOTFILES_GIT_DIR" --work-tree=my-dotfiles-tmp/ checkout "${DOTFILES_REF}"
  # Update the submodules. This requires changing directory, as git submodule does not work with --work-tree
  cd my-dotfiles-tmp/ && run_cmd git --git-dir="$DOTFILES_GIT_DIR" submodule update --init && cd ../
  # Copy all files from the temporary working directory to $HOME.
  run_cmd rsync --recursive --verbose --links --exclude '.git' my-dotfiles-tmp/ "$HOME"/ -q
  # Remove the temporary directory
  rm -R my-dotfiles-tmp
  # Disable untracked files. We do not want to show them in our home directory!
  git --git-dir="$DOTFILES_GIT_DIR" --work-tree="$HOME" config status.showUntrackedFiles no
else
  print "Dotfiles directory already cloned. Pulling."
  run_cmd git --git-dir="$DOTFILES_GIT_DIR" --work-tree="$HOME" pull --recurse-submodules
fi

if [ "$IS_MAC" = false ]; then
    echo "OS is not MacOS, skipping bootstrapping"
    exit
fi

# The "echo |" ensures it's a silent install.
if ! [ -f "/usr/local/bin/brew" ]; then
  print "Installing homebrew"
  brew_script_location=$(mktemp)
  run_cmd curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install --output "$brew_script_location"
  run_cmd /usr/bin/ruby "$brew_script_location"
fi

# Install ptail, used in run_cmd
run_cmd brew tap orf/brew
run_cmd brew install ptail

run_cmd brew update
run_cmd_ignore_errors brew bundle -v --global

if ! grep -Fxq "/usr/local/bin/fish" /etc/shells; then
  print "Fish not in /etc/shells, adding"
  echo "/usr/local/bin/fish" | sudo tee -a /etc/shells
fi
# This fails on github actions due to it having no password set. We assume it works locally.
chsh -s /usr/local/bin/fish || true

print "Installing misc utilities (git lfs, fzf, nvm)"
run_cmd git lfs install
run_cmd fish -c "/usr/local/opt/fzf/install --all --xdg"
run_cmd curl https://git.io/fisher --create-dirs -sLo ~/.config/fish/functions/fisher.fish
run_cmd fish -c "fisher"
run_cmd fish -c "nvm install"

run_cmd defaultbrowser firefoxdeveloperedition
run_cmd fish -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y -c clippy rustfmt"

# Non-homebrew install stuff
if ! [ -d "/Applications/Little Snitch Configuration.app" ]; then
  if [[ -n "/usr/local/Caskroom/little-snitch/*/LittleSnitch-*.dmg" ]]; then
    print "Opening little snitch"
    run_cmd open /usr/local/Caskroom/little-snitch/*/LittleSnitch-*.dmg
  else
    print "Cannot find little snitch installer!"
  fi
fi

print "Configuring git"
# SSH fingerprints
ssh-keyscan github.com >>~/.ssh/known_hosts 2>&1
ssh-keyscan gitlab.com >>~/.ssh/known_hosts 2>&1

# User stuff
git config --global user.name "Tom Forbes"
git config --global user.email "tom@tomforb.es"
git config --global core.excludesfile ~/.gitignore

print "Configuring MacOS defaults"
# MacOS stuff
mkdir -p ~/Pictures/screenshots/
defaults write com.apple.screencapture location ~/Pictures/screenshots/
defaults write com.apple.finder NewWindowTargetPath file://"$HOME"/
defaults write com.apple.finder AppleShowAllFiles -boolean true
defaults write com.apple.dock autohide -boolean true
defaults write com.apple.dock show-recents -boolean false
defaults write com.apple.bird optimize-storage -boolean false
# Disable Zoom video by default
sudo defaults write /Library/Preferences/us.zoom.config.plist ZDisableVideo 1
run_cmd killall Dock Finder
print "Setting firewall to stealth mode"
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

print "Adding /usr/local/bin to the launchctl path"
sudo launchctl config user path "/usr/local/bin:$PATH"

if [ "${SKIP_SLOW_DEPENDENCIES}" -eq "0" ]; then
  print "Running slow operation: installing cargo dependencies"
  run_cmd fish -c "cargo install --force cargo-edit cargo-tree cargo-bloat cargo-release cargo-update cargo-outdated cargo-watch cargo-fix"

  print "Installing Python versions"
  # Install Python versions
  run_cmd fish -c "pyenv latest install 3.6 -s"
  run_cmd fish -c "pyenv latest install 2.7 -s"
fi

print "Bootstrapped!"
