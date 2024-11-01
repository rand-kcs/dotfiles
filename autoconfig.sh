#! /bin/bash

# Run at the dotfiles path, otherwise the ls and the pwd won't work.
# test c

# Lack:
# 1. set zsh as default shell
# 2. download tmux if not installed
# 3. auto config 'auto suggestion' and 'auto smart jump'
# 4. git ssh?

files=$(ls -a | grep -E '^\.[^.]' | grep -v '.git$' )

sudo apt-get install tmux

for file in $files ;do
	if [[ -e ~/$file ]]; then
		rm ~/$file;
	fi	
	ln -s $(pwd)/$file ~/$file	;
done
