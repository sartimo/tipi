begin
  require_relative 'lib/tipi/version'
rescue LoadError
  require 'tipi/version'
end

Gem::Specification.new do |s|
  s.name = 'tipi'
  s.version = Tipi::VERSION
  s.summary = ''
  s.description = ''
  s.authors = ['Timo Sarkar']
  s.email = ['timosarkar@duck.com']
  s.homepage = ''
  s.license = 'MIT'
  # NOTE required ruby version is informational only; it's not enforced since it can't be overridden and can cause builds to break
  #s.required_ruby_version = '>= 2.5.0'
  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/github/github',
    'changelog_uri' => 'https://github.com/github/github',
    'mailing_list_uri' => 'https://github.com/github/github',
    'source_code_uri' => 'https://github.com/github/github'
  }

  # NOTE the logic to build the list of files is designed to produce a usable package even when the git command is not available
  begin
    files = (result = `git ls-files -z`.split ?\0).empty? ? Dir['**/*'] : result
  rescue
    files = Dir['**/*']
  end
  s.files = files.grep %r/^(?:(?:data|lib|man)\/.+|LICENSE|(?:CHANGELOG|README(?:-\w+)?)\.tipi|\.yardopts|#{s.name}\.gemspec)$/
  s.executables = (files.grep %r/^bin\//).map {|f| File.basename f }
  s.require_paths = ['lib']
  #s.test_files = files.grep %r/^(?:features|test)\/.+$/

  # concurrent-ruby, haml, slim, and tilt are needed for testing custom templates
  s.add_development_dependency 'concurrent-ruby', '~> 1.1.0'
  s.add_development_dependency 'cucumber', '~> 3.1.0'
  # erubi is needed for testing alternate eRuby impls
  s.add_development_dependency 'erubi', '~> 1.10.0'
  s.add_development_dependency 'haml', '~> 6.1.0', '!= 6.1.2'
  s.add_development_dependency 'minitest', '~> 5.14.0'
  s.add_development_dependency 'nokogiri', '~> 1.14.0'
  s.add_development_dependency 'rake', '~> 12.3.0'
  s.add_development_dependency 'slim', '~> 4.1.0'
  s.add_development_dependency 'tilt', '~> 2.0.0'
end