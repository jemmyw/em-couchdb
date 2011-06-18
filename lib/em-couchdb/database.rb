require 'rubygems'
require 'eventmachine'
require "em-http"
require "json"
require "uri"
require 'em-couchdb/document'
require 'em-couchdb/design_document'

module EventMachine
  module CouchDB
    class Database
      attr_reader :name, :connection

      def initialize(connection, name)
        @connection = connection
        @name = name
      end
      
      def command(path, method, options = {}, head = {"Content-Type" => "application/json"}, &callback)
        connection.command("/#{name}#{path}", method, options, head, &callback)
      end

      def create
        connection.create_db(name).tap do |c|
          c.callback(&Proc.new) if block_given?
        end
      end

      def destroy
        command("/", :delete).tap do |c|
          c.callback(&Proc.new) if block_given?
        end
      end

      def compact
        command("/_compact", :post).tap do |c|
          c.callback(&Proc.new) if block_given?
        end
      end

      # Document API
      
      def get(id)
        command("/#{id}", :get) do |http|
          if id =~ /^_design\/(.+?)$?/
            DesignDocument.new(self, nil, JSON.load(http.response))
          else
            Document.new(self, JSON.load(http.response))
          end
        end.tap do |c|
          c.callback(&Proc.new) if block_given?
        end
      end

      def new(doc = {})
        d = Document.new(self, doc)
        yield d if block_given?
        d
      end

      # Views
      
      def create_view(doc_name, view_name, mapjs, reducejs=nil)
        df = DefaultDeferrable.new
        df.callback(&Proc.new) if block_given?

        create_view = proc do |doc|
          doc.build_view(view_name, mapjs, reducejs)
          cm = doc.save
          cm.callback { df.succeed }
          cm.errback  { df.fail "error creating view" }
        end

        create_doc = proc do
          doc = DesignDocument.new(self, doc_name)
          create_view.call(doc)
        end

        get_doc = get("_design/#{doc_name}")
        get_doc.callback do |doc|
          if doc.nil?
            create_doc.call
          else
            if view = doc.views[view_name]
              if view.map == mapjs && view.reduce == reducejs
                df.succeed
              else
                create_view.call(doc)
              end
            else
              create_view.call(doc)
            end
          end
        end
        get_doc.errback(&create_doc)

        df
      end
      
      def execute_view(doc, view, options = {})
        map_docs = options.delete(:map_docs)

        command("/_design/#{doc}/_view/#{view}", :get, :query => options) do |http|
          JSON.load(http.response).tap do |response|
            response["rows"] = response["rows"].map do |doc|
              Document.new(self, doc["value"])
            end if map_docs
          end
        end.tap do |c|
          c.callback(&Proc.new) if block_given?
        end
      end
      
      def execute_temp_view(mapjs, options = {})
        map_docs = options.delete(:map_docs)
        js = {"map" => "function(doc){ #{mapjs} }"}
        reduce = options.delete(:reduce)
        js["reduce"] = "function(keys, values) { #{reduce} }" if reduce
        query = options.map{|k,v| [k,v].join('=')}.join('&')

        command("/_temp_view", :post, :query => query, :body => JSON.dump(js)) do |http|
          JSON.load(http.response).tap do |response|
            response["rows"] = response["rows"].map do |doc|
              Document.new(self, doc["value"])
            end if map_docs
          end
        end.tap do |c|
          c.callback(&Proc.new) if block_given?
        end
      end
    end
  end
end
