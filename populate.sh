#!/usr/bin/zsh

homedirfiles=( .vimrc .zshenv )

for file in $homedirfiles
do
  ln -s $file $HOME/$file
done
