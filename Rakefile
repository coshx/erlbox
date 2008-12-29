## -------------------------------------------------------------------
##
## Erlang Toolbox: Project rakefile
## Copyright (c) 2008 The Hive.  All rights reserved.
##
## -------------------------------------------------------------------
require 'pathname'
require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'spec'
require 'spec/rake/spectask'
require Pathname('lib/erlbox/version')

RDOC_TITLE = "Erlang Toolbox #{ErlBox::VERSION.latest} documentation"

spec = Gem::Specification.new do |s|
  s.name         = 'erlbox'
  s.version      = ErlBox::VERSION.latest
  s.platform     = Gem::Platform::RUBY
  s.author       = 'Phillip Toland'
  s.email        = 'ptoland@thehive.com'
  s.homepage     = ''
  s.summary      = 'Erlang Toolbox'
  s.description  = 'Rake tasks and helper scripts for building Erlang applications.'
  s.require_path = 'lib'
  s.files        = ['README.txt', 'History.txt', 'Rakefile', '.revision'] +
                    Dir['lib/**/*']

  s.rubyforge_project = 'erlbox'

  # rdoc
  s.has_rdoc         = true
  s.extra_rdoc_files = ['README.txt', 'History.txt']
  s.rdoc_options     = ['--quiet', 
                        '--title', RDOC_TITLE,
                        '--opname', 'index.html',
                        '--line-numbers',
                        '--main', 'README.txt',
                        '--inline-source']

  # Dependencies
  s.add_dependency 'rake', '>= 0.8.3'
end

Rake::GemPackageTask.new(spec) do |package|
  `echo #{ErlBox::VERSION.git_revision} > .revision`
  package.gem_spec = spec
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title = RDOC_TITLE
  rdoc.main = 'README.txt'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.txt')
  rdoc.rdoc_files.include('History.txt')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :default => :gem

desc 'Build and install the gem'
task :install => :gem do
  sh "sudo gem install pkg/erlbox-#{ErlBox::VERSION.latest}.gem"
end
