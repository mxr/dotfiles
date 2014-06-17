#!/usr/bin/zsh

homedirfiles=( .vimrc .zshenv )

for file in $homedirfiles
do
  ln -s `pwd`/$file $HOME/$file
done
