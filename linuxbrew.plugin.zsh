local function brew-prefix() {
  local brew_prefix
  for prefix in $HOME /home/linuxbrew $HOME/linuxbrew; do
    maybe_brew_prefix="$prefix/.linuxbrew"
    test -d $maybe_brew_prefix && brew_prefix=$maybe_brew_prefix
  done
  echo $brew_prefix
}

local function export-env() {
  local brew_prefix="$(brew-prefix)"
  if [[ -n "$brew_prefix" ]]; then
    export PATH="$brew_prefix/bin:$brew_prefix/sbin:$PATH"
    export MANPATH="$brew_prefix/share/man:$MANPATH"
    export INFOPATH="$brew_prefix/share/info:$INFOPATH"
    export XDG_DATA_DIRS="$brew_prefix/share:$XDG_DATA_DIRS"
    fpath=( "$brew_prefix/completions/zsh" $fpath )
  fi
}

local function handle-install-failure() {
  (>&2 echo "failed linuxbrew install")
  return 1
}

local ensure-command-package() {
  if (( $+commands[$1] )); then
  else
    pkg install $2
  fi
}

export-env

function brew() {
  local install_linuxbrew='sh -c "$(curl -fsSL https://raw.githubusercontent.com/emanresusername/install/termux-friendly/install.sh)"'

  if [[ $OSTYPE == linux-android ]]; then
    ensure-command-package termux-chroot proot
    ensure-command-package git git

    # https://github.com/Linuxbrew/install/blob/bec02c30d2223e4d298416d2a9041e11149397fa/install#L159
    export GIT=`which git`
    # work around https://github.com/Homebrew/brew/blob/3e6adb7/bin/brew#L63
    # otherwise CANNOT LINK EXECUTABLE: library "libandroid-support.so" not found
    export HOMEBREW_NO_ENV_FILTERING=1

    if (( $+commands[brew] )); then
      termux-chroot "$commands[brew] $@"
    else
      # https://github.com/Linuxbrew/homebrew-core/issues/3880#issuecomment-324961662
      (termux-chroot "$install_linuxbrew" || \
         handle-install-failure) && \
        (ln -s /system/bin/linker64 "$(brew-prefix)/lib/ld.so" || \
           ln -s /system/bin/linker "$(brew-prefix)/lib/ld.so") && \
        export-env && brew "$@"
    fi
  else
    if (( $+commands[brew] )); then
      $commands[brew] "$@"
    else
      ($install_linuxbrew || \
         handle-install-failure) && \
        export-env && brew "$@"
    fi
  fi
}
