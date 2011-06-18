Gem::Specification.new do |spec|
  spec.name = "em-couchdb"
  spec.version = "0.0.2"
  spec.platform = Gem::Platform::RUBY
  spec.summary = 'A non-blocking EventMachine client protocol for CouchDB'
  spec.description = <<END_DESC
  em-couchdb is a simple, convenient, and non-blocking client for CouchDB
  implemented as an EventMachine protocol. With em-couchdb, you can easily
  save, query, delete documents, databases to/from a CouchDB database in 
  your favourite language - Ruby. 
END_DESC
  
  spec.requirements << 'CouchDB 0.8.0 and upwards'
  
  spec.add_dependency('json', '>= 1.4.3')
  spec.add_dependency('eventmachine', '>= 0.12.10')
  spec.add_dependency('em-http-request', '>= 0.2.10')
 
  spec.files = Dir['lib/**/*.rb'] + Dir['examples/**/*.rb'] + ['README.rdoc']
  spec.test_files = Dir['test/**/*.rb']

  spec.authors = ['saivenkat (Sai Venkatakrishnan)', 'Jeremy Wells']
  spec.email = ['s.sai.venkat@gmail.com', 'jemmyw@gmail.com']
  spec.homepage = 'http://github.com/jemmyw/em-couchdb'
end
