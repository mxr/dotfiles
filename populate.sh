#!/usr/bin/zsh

homedirfiles=( .vimrc )

for file in $homedirfiles
do
  ln -s `pwd`/$file $HOME/$file
done
