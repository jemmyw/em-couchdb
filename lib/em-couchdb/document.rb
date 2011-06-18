require 'em-couchdb/attachments'

module EventMachine
  module CouchDB
    class Document
      attr_reader :doc, :database, :connection, :attachments

      def initialize(database, doc = {})
        @database = database
        @connection = database.connection
        @doc = doc
        @attachments = Attachments.new(self)
      end

      def method_missing(name, *args, &block)
        if @doc.respond_to?(name)
          @doc.send(name, *args, &block)
        elsif @doc.has_key?(name.to_s)
          @doc[name.to_s]
        elsif name.to_s =~ /(.*)=$/ && args.length == 1
          @doc[$1] = args.first
        else
          super
        end
      end

      def id
        @doc["_id"] || @doc["id"]
      end

      def rev
        @doc["_rev"] || @doc["rev"]
      end

      def doc=(new_doc)
        new_doc.merge("_id" => id, "_rev" => rev) unless new_record?
        @doc = new_doc
      end

      def inspect
        @doc.inspect
      end

      def new_record?
        @doc['_id'].nil?
      end

      def save(&callback)
        df = EM::DefaultDeferrable.new
        df.callback(&callback) if block_given?

        save_cm = if new_record?
          create
        else
          update
        end

        save_cm.callback do
          at_cm = save_attachments
          at_cm.callback { df.succeed }
          at_cm.errback {|*args| df.fail(*args) }
        end
        save_cm.errback {|*args| df.fail(*args) }

        df
      end

      def create
        database.command("/", :post, :body => JSON.dump(doc)) do |http|
          JSON.load(http.response)
        end.tap do |c|
          c.callback do |response|
            self._id = response["id"]
            self._rev = response["rev"]
          end
          c.callback(&Proc.new) if block_given?
        end
      end

      def update
        database.command("/#{id}", :put, :body => JSON.dump(doc)) do |http|
          JSON.load(http.response)
        end.tap do |c|
          c.callback do |response|
            self._rev = response["rev"]
          end
          c.callback(&Proc.new) if block_given?
        end
      end

      def save_attachments
        attachments.save
      end

      def destroy
        database.command("/#{id}?rev=#{rev}", :delete).tap do |c|
          c.callback(&Proc.new) if block_given?
        end
      end
    end
  end
end
