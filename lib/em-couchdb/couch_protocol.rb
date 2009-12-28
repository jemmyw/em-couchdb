require 'rubygems'
require 'eventmachine'
require "em-http"
require "json"
require "uri"

module EventMachine
  module Protocols
    class CouchDB
      def self.connect connection_params
        puts "*****Connecting" if $debug
        self.new(connection_params)
      end
      def initialize(connection_params)
        @host = connection_params[:host] || '127.0.0.1'
        @port = connection_params[:port] || 80
        @database = connection_params[:database]
        @timeout = connection_params[:timeout] || 10
      end
      def get_all_dbs(&callback)
        http = EventMachine::HttpRequest.new("http://#{@host}:#{@port}/_all_dbs/").get :timeout => @timeout 
        http.callback {
          callback.call(JSON.load(http.response))
        }
        http.errback {
          raise "CouchDB Exception. Unable to get all dbs"
        }
      end
      def get(id, &callback)
        http = EventMachine::HttpRequest.new("http://#{@host}:#{@port}/#{@database}/#{id}").get :timeout => @timeout 
        http.callback {
          callback.call(JSON.load(http.response))
        }
        http.errback {
          raise "CouchDB Exception. Unable to get document"
        }
      end
      def save(doc, &callback)
        http = EventMachine::HttpRequest.new("http://#{@host}:#{@port}/#{@database}/").post :body => JSON.dump(doc)
        http.callback {
          callback.call(JSON.load(http.response))
        }
        http.errback {
          raise "CouchDB Exception. Unable to save document"
        }
      end
      def delete(doc, &callback)
        doc_id, doc_revision = get_revision_and_id(doc)
        http = EventMachine::HttpRequest.new(URI.parse("http://#{@host}:#{@port}/#{@database}/#{doc_id}?rev=#{doc_revision}")).delete
        http.callback{
          callback.call
        }
        http.errback {
          raise "CouchDB Exception. Unable to delete document"
        }
      end
      def get_revision_and_id(doc)
        if doc.has_key? "_id"
          return doc["_id"], doc["_rev"]
        else
          return doc["id"], doc["rev"]
        end
      end
    end
  end
end


