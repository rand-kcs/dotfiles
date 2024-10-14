# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/huang/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

autoload -Uz vcs_info 
precmd() { vcs_info }

zstyle ':vcs_info:git:*' formats '%b ' 
setopt PROMPT_SUBST
PROMPT='%F{blue}%~%f %F{cyan}${vcs_info_msg_0_}%f '
