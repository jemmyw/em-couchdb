require 'rubygems'
require 'eventmachine'
require "em-http"
require "json"
require "uri"
require "em-couchdb/command"
require "em-couchdb/database"

module EventMachine
  module CouchDB
    class Connection
      def self.connect connection_params
        self.new(connection_params)
      end

      def initialize(connection_params = {})
        @host = connection_params[:host] || '127.0.0.1'
        @port = connection_params[:port] || 5984
        @timeout = connection_params[:timeout] || 10
        @verbose = connection_params[:verbose] || false

        yield self if block_given?
      end

      def command(path, method, options = {}, head = {"Content-Type" => "application/json"}, &callback)
        Command.new(@host, @port, path, method, options.merge(:verbose => @verbose), head, &callback)
      end

      # DB API

      def get_all_dbs
        command("/_all_dbs/", :get) do |http|
          JSON.load(http.response).map do |name|
            Database.new(self, name)
          end
        end.tap do |c|
          c.callback(&Proc.new) if block_given?
        end
      end

      def create_db(db_name)
        command("/#{db_name}/", :put) do |http|
          Database.new(self, db_name)
        end.tap do |c|
          c.callback(&Proc.new) if block_given?
        end
      end

      def get_db(db_name, create = false, &callback)
        df = EM::DefaultDeferrable.new
        df.callback(&callback) if block_given?

        cm = command("/#{db_name}/", :get) do |http|
          response = JSON.load(http.response)
          if response["error"]
            nil
          else
             Database.new(self, db_name)
          end
        end
        
        cm.callback do |db|
          if db.nil?
            df.fail("Could not fetch database!")
          else
            df.succeed(db)
          end
        end

        cm.errback do |error|
          if create
            ccm = create_db(db_name) do |db|
              df.succeed(db)
            end
            ccm.errback do |error|
              df.fail(error)
            end
          else
            df.fail(error)
          end
        end
        
        df
      end

      def get_id_and_revision(doc)
        if doc.has_key? "_id"
          return doc["_id"], doc["_rev"]
        else
          return doc["id"], doc["rev"]
        end
      end
    end
  end
end
