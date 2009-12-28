A simple but awesome couchdb client based on EventMachine. 

Example:

<pre>require "rubygems"
require "eventmachine"
require "../lib/em-couchdb"

EventMachine.run {
  couch = EventMachine::Protocols::CouchDB.connect :host => 'localhost', :port => 5984, :database => 'unicef-region-data'
  couch.get_all_dbs {|dbs| puts dbs}
  couch.save({:name => "couchd", "description" => "awesome"}) do |doc| 
    couch.get(doc["id"]) do |doc|
      puts doc
      couch.delete(doc){
        EventMachine.stop
      }
    end
  end
}
</pre>
