#! /bin/bash

# Run at the dotfiles path, otherwise the ls and the pwd won't work.

files=$(ls -a | grep -E '^\.[^.]' | grep -v '.git' )


for file in $files ;do
	if [[ -e ~/$file ]]; then
		rm ~/$file;
	fi	
	ln -s $(pwd)/$file ~/$file	;
done
