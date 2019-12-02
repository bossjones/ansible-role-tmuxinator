#!/usr/bin/env bash

git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(rbenv init -)"' >> ~/.zshrc
git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build

# ruby
sudo apt-get install -y build-essential bison ruby-dev rake zlib1g-dev \
    libyaml-dev libssl-dev libreadline-dev libncurses5-dev llvm llvm-dev \
    libeditline-dev libedit-dev
rbenv install 2.2.3
