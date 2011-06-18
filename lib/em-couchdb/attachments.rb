module EventMachine
  module CouchDB
    class Attachment
      attr_reader :document, :name, :metadata

      def initialize(document, name, metadata = {})
        @document = document
        @name = name
        @metadata = metadata
      end

      def method_missing(name, *args, &block)
        if @metadata.respond_to?(name)
          @metadata.send(name, *args, &block)
        elsif @metadata.has_key?(name.to_s)
          @metadata[name.to_s]
        end
      end

      def data=(data)
        @data = data
        @changed = true
      end

      def changed?
        @changed
      end

      def read
        document.database.command("/#{document.id}/#{name}", :get, {}, {}).tap do |cm|
          cm.callback(&Proc.new) if block_given?
        end
      end

      def write(data)
        document.database.command("/#{document.id}/#{name}?rev=#{document.rev}", :put, {:body => data}, {"Content-Type" => metadata["Content-Type"]}).tap do |cm|
          cm.callback {|http| @changed = false }
          cm.callback(&Proc.new) if block_given?
        end
      end

      def save(&callback)
        df = EM::DefaultDeferrable.new
        df.callback(&callback) if block_given?

        if changed?
          cm = write(@data)
          cm.callback {|*args| df.succeed(*args) }
          cm.errback  {|*args| df.fail(*args)    }
        else
          df.succeed
        end

        df
      end
    end

    class Attachments
      attr_reader :document

      def initialize(document)
        @document = document
        @attachments = []
        load_metadata
      end

      def [](name)
        if name.is_a?(String)
          @attachments.detect{|a| a.name == name}
        else
          @attachments.send(:[], name)
        end
      end

      def method_missing(name, *args, &block)
        if @attachments.respond_to?(name)
          @attachments.send(name, *args, &block)
        else
          super
        end
      end

      def load_metadata
        if document.has_key?("_attachments")
          document['_attachments'].each do |name, metadata|
            @attachments << Attachment.new(document, name, metadata)
          end
        end
      end

      def build(name, content_type, data)
        attachment = Attachment.new(document, name, {"Content-Type" => content_type})
        attachment.data = data
        @attachments << attachment
        attachment
      end

      def save
        df = EM::DefaultDeferrable.new

        attachments_to_save = @attachments.select(&:changed?)

        check_proc = proc do
          if @attachments.none?(&:changed?)
            df.succeed
          end
        end

        attachments_to_save.each do |attachment|
          cm = attachment.save
          cm.callback(&check_proc)
          cm.errback {|*args| df.fail(*args) }
        end

        check_proc.call

        df
      end
    end
  end
end
