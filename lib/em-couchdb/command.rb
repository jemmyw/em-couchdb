require 'rubygems'
require 'eventmachine'
require "em-http"
require "json"
require "uri"

module EventMachine
  module CouchDB
    class Command
      include EM::Deferrable

      def initialize(host, port, path, method, options, headers = {})
        @host = host
        @port = port
        @path = path
        @method = method
        @options = options
        @body = @options.delete(:body)
        @verbose = @options.delete(:verbose)
        @headers = headers

        if block_given?
          @callback = Proc.new
        end

        execute
      end

      def verbose?
        @verbose
      end

      def execute
        options = {:timeout => 10}.merge(@options)
        options[:body] = @body.respond_to?(:read) ? @body.read : @body
        options[:head] = @headers.dup
        options[:head]['Content-Length'] = options[:body].length if options[:body].respond_to?(:length)

        if verbose?
          puts "#{@method} http://#{@host}:#{@port}#{@path}"
        end

        http = EventMachine::HttpRequest.new("http://#{@host}:#{@port}#{@path}").send(@method, options)

        http.callback do
          if verbose?
            puts "-> #{http.response_header.status}"
          end

          unless (200..399).include?(http.response_header.status.to_i)
            begin
              self.fail JSON.load(http.response)['error']
            rescue
              self.fail http
            end
          else
            response = if @callback
                         @callback.call(http)
                       else
                         http.response
                       end
            succeed(response)
          end
        end

        http.errback{|http| self.fail(http) }
      end
    end
  end
end
