#!/usr/bin/env bash

export PATH="/usr/local/rbenv/bin:$PATH"

packages=(
  tmuxinator
)

sudo find /usr/local/rbenv -type d -exec chmod 2775 {} \;

sudo find /usr/local/rbenv -type f -exec chmod ug+rw {} \;

eval "$(rbenv init -)"

rbenv shell {{bossjones__tmuxinator__ruby_version}}
gem install "${packages[@]}"
