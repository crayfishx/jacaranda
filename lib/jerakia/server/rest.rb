require 'sinatra'
require 'jerakia'
require 'jerakia/server/auth'
require 'json'
require 'jerakia/scope/server'

class Jerakia
  class Server
    class Rest < Sinatra::Base
      def self.jerakia
        Jerakia::Server.jerakia
      end

      def initialize
        @authorized_tokens = {}
        super
      end

      def jerakia
        self.class.jerakia
      end

      def auth_denied
        request_failed('unauthorized', 401)
      end

      def token_ttl
        Jerakia::Server.config['token_ttl']
      end

      def token_valid?(token)
        return false unless @authorized_tokens[token].is_a?(Time)
        (Time.now - @authorized_tokens[token]) < token_ttl.to_i
      end

      def authenticate!
        token = env['HTTP_X_AUTHENTICATION']
        auth_denied if token.nil?
        return true if token_valid?(token)
        auth_denied unless Jerakia::Server::Auth.authenticate(token)
        @authorized_tokens[token] = Time.now
      end

      before do
        authenticate!
        content_type 'application/json'
      end

      get '/' do
        auth_denied
      end

      def request_failed(message, status_code = 501)
        halt(status_code, {
          :status => 'failed',
          :message => message
        }.to_json)
      end

      def mandatory_params(mandatory, params)
        mandatory.each do |m|
          unless params.include?(m)
            request_failed("Must include parameter #{m} in request", 400)
          end
        end
      end

      get '/v1/lookup' do
        request_failed('Keyless lookups not supported in this version of Jerakia')
      end

      get '/v1/lookup/:key' do
        mandatory_params(['namespace'], params)
        request_opts = {
          :key => params['key'],
          :namespace => params['namespace'].split(/\//)
        }

        metadata = params.select { |k, _v| k =~ /^metadata_.*/ }
        scope_opts = params.select { |k, _v| k =~ /^scope_.*/ }

        request_opts[:metadata] = Hash[metadata.map { |k, v| [k.gsub(/^metadata_/, ''), v] }]
        request_opts[:scope_options] = Hash[scope_opts.map { |k, v| [k.gsub(/^scope_/, ''), v] }]

        request_opts[:policy] = params['policy'].to_sym if params['policy']
        request_opts[:lookup_type] = params['lookup_type'].to_sym if params['lookup_type']
        request_opts[:merge] = params['merge'].to_sym if params['merge']
        request_opts[:scope] = params['scope'].to_sym if params['scope']
        request_opts[:use_schema] = false if params['use_schema'] == 'false'

        begin
          request = Jerakia::Request.new(request_opts)
          answer = jerakia.lookup(request)
        rescue Jerakia::Error => e
          request_failed(e.message, 501)
        end
        {
          :status => 'ok',
          :payload => answer.payload
        }.to_json
      end

      get '/v1/scope/:realm/:identifier' do
        resource = Jerakia::Scope::Server.find(params['realm'], params['identifier'])
        if resource.nil?
          halt(404, { :status => 'failed', :message => 'No scope data found' }.to_json)
        else
          {
            :status => 'ok',
            :payload => resource.scope
          }.to_json
        end
      end

      put '/v1/scope/:realm/:identifier' do
        scope = JSON.parse(request.body.read)
        uuid = Jerakia::Scope::Server.store(params['realm'], params['identifier'], scope)
        {
          :status => 'ok',
          :uuid => uuid
        }.to_json
      end

      get '/v1/scope/:realm/:identifier/uuid' do
        resource = Jerakia::Scope::Server.find(params['realm'], params['identifier'])
        if resource.nil?
          request_failed('No scope data found', 404)
        else
          {
            :status => 'ok',
            :uuid => resource.uuid
          }.to_json
        end
      end
    end
  end
end
