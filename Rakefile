require File.join(File.dirname(__FILE__), 'lib/em-couchdb')
require 'rubygems'
require 'rake'
require 'rake/gempackagetask'
require 'rake/packagetask'
require 'rake/rdoctask'
require 'rake/testtask'

PACKAGE_NAME = 'EM-CouchDB'
PACKAGE_VERSION = EMCouchDB.version

task :default => :test

desc 'Remove generated products (pkg/rcov/docs)'
task :clean => [ :clobber_package, :clobber_rdoc ]

task :gem => [ :test ]

spec = Gem::Specification.load('em-couchdb.gemspec')
Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_zip = true
end

# Generate the RDoc documentation
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.main = 'README.rdoc'
  rdoc.title = PACKAGE_NAME + ' Documentation'
  rdoc.options << '--line-numbers'
  rdoc.options << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc', 'lib/**/*.rb')
end

desc 'Run tests'
Rake::TestTask.new :test do |t|
  t.test_files = FileList.new do |fl|
    fl.include 'test/**/*_test.rb'
  end
  t.verbose = true
  t.warning = true
end

desc 'Report version'
task :version do
  puts [PACKAGE_NAME, PACKAGE_VERSION].join(': ')
end
