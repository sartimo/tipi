require File.dirname(__FILE__) + '/lib/tipi/version'
require 'date'

Gem::Specification.new do |s|
  s.name = 'tipi'
  s.version = Tipi::VERSION
  s.date = Date.today.to_s

  s.authors = ['Timo Sarkar']
  s.email = ['timosarkar@duck.com']
  s.summary = 'authoring markup language'
  s.description = 'Tipi is a lightweight authoring markup language.'
  s.extra_rdoc_files = %w(README.tipi)
  s.rubyforge_project = s.name

  s.files         = `git ls-files`.split("\n")
  s.executables   = ['tipi']
  s.require_paths = %w(lib)

  s.homepage = 'http://github.com/sartimo/tipi'
  s.license  = 'Ruby'
end
