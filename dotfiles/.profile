alias ls='ls -hF'
alias la='ls -Al'
alias cp='cp -v'
alias mv='mv -v'
alias rm='rm -v'
alias mkdir='mkdir -v'
alias ..='cd ..'
alias x='exit'

alias du2='du -ach --max-depth=1'
alias t='tmux new -As0'
alias 1='ping one.one.one.one'
alias port='echo $((RANDOM % (65535 - 49152 + 1) + 49152))'
alias randport='port'

export VISUAL=micro
export EDITOR="$VISUAL"
export MICRO_CONFIG_HOME="$HOME/.micro"

bold="\e[1m"
reset="\e[0m"
red="\e[31m"
white="\e[37m"
yellow="\e[33m"

# Highlight the user name when logged in as root.
if [ "$USER" = "root" ]; then
  userStyle="$red"
else
  userStyle="$white" # Default color
fi

# Shortened Path Function
sps() {
  current_path=$(echo "$PWD" | sed "s|$HOME|~|")

  if [ "$current_path" = "~" ]; then
    echo "$current_path"
  else
    path_parent="${current_path%/*}"
    path_parent_short=$(echo "$path_parent" | sed -r 's|/([^/]{2})[^/]{2,}|/\1|g')
    directory="${current_path##*/}"
    echo "$path_parent_short/$directory"
  fi
}

# Set the prompt
PS1="${userStyle}\u@${white}\h${reset}:${white}\$(sps)${reset}\$ "
PS2="${yellow}→ ${reset}"
export PS1 PS2