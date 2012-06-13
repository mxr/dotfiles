#!/usr/bin/zsh

homedirfiles=( .vimrc .zshenv )

for file in $homedirfiles
do
  # TODO why do I need the absolute path of the source?
  ln -s `pwd`/$file $HOME/$file
done
