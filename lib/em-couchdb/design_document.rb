require 'em-couchdb/document'

module EventMachine
  module CouchDB
    class View
      attr_accessor :name
      attr_reader :doc

      def initialize(document, name, doc = {})
        @name = name
        @doc = doc
        @changed = false
      end

      def map
        @doc['map'] 
      end

      def map=(value)
        @doc['map'] = value
        @changed = true
      end

      def reduce
        @doc['reduce']
      end

      def reduce=(value)
        @doc['reduce'] = value
        @changed = true
      end

      def changed?
        @changed
      end

      def execute(options = {})
        if document.new_record? || changed?
          document.database.execute_temp_view(map, options.merge(:reduce => reduce))
        else
          document.database.execute_view(document.id, name, options)
        end
      end
    end

    class DesignDocument < Document
      attr_reader :name, :views

      def initialize(database, name, doc = {})
        @name = name
        @views = {}
        super(database, doc)
        load_views
        @name = name_from_id if @name.nil?
      end

      def build_view(name, map, reduce = nil)
        View.new(self, name).tap do |view|
          view.map = map
          view.reduce = reduce if reduce
          @views[name] = view
        end
      end

      def save(&callback)
        doc['_id'] = "_design/#{name}"
        doc['views'] = @views.inject({}) do |m,(name, view)|
          m[view.name] = view.doc
          m
        end

        super
      end

      private

      def name_from_id
        if id =~ /_design\/(.*)/
          $1
        end
      end

      def load_views
        if doc['views'] && doc['views'].any?
          doc['views'].each do |name, view|
            @views[name] = View.new(self, name, view)
          end
        end
      end
    end
  end
end
