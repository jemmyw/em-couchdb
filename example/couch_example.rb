require "rubygems"
require "eventmachine"
require "../lib/em-couchdb"

EventMachine.run do
  couch = EventMachine::Protocols::CouchDB.connect :host => 'localhost', :port => 5984
  couch.get_all_dbs {|dbs| puts dbs}
  couch.create_db("test-project")
  couch.get_all_dbs {|dbs| puts dbs}
  couch.get_db("test-project") do |db|
    puts db
    couch.save(db["db_name"], {:name => "couchd", "description" => "awesome"}) do |doc| 
      couch.get(db["db_name"], doc["id"]) do |doc|
        puts doc
        couch.delete(db["db_name"], doc) do
          couch.delete_db(db["db_name"]){
            EventMachine.stop
          }
        end
      end
    end
  end
end
