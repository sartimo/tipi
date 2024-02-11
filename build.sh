apt install ruby-dev
gem install bundler

bundle
gem build tipi.gemspec
gem install tipi-0.1.0alpha.gem
tipi -v
