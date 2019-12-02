#!/usr/bin/env bash

export PATH="/usr/local/rbenv/bin:$PATH"

packages=(
  pry
  bundler
  ruby-debug-ide
  debase
  rcodetools
  rubocop
  fastri
  htmlbeautifier
  hirb
  gem-ctags
  travis
  excon
  pry-doc
  tmuxinator
  solargraph
)

eval "$(rbenv init -)"

if [ ! -d ~/.rbenv/versions/2.4.2 ]
then
  rbenv install 2.4.2
else
  rbenv shell 2.4.2
fi

gem install "${packages[@]}"
