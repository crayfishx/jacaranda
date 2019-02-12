require 'lookup_http'

class Jerakia::Datasource::Http < Jerakia::Datasource::Instance
  option :host,                :type => String,  :required => true
  option :port,                :type => Integer, :default => 80
  option :output,              :type => String,  :default => 'json'
  option :failure,             :type => String,  :default => 'graceful'
  option :ignore_404,          :default => true
  option :headers,             :type => Hash
  option :http_read_timeout,   :type => Integer
  option :use_ssl
  option :ssl_ca_cert,         :type => String
  option :ssl_cert,            :type => String
  option :ssl_key,             :type => String
  option :ssl_verify
  option :use_auth
  option :auth_user,           :type => String
  option :auth_pass,           :type => String
  option :http_connect_timeout, :type => Integer
  option :paths, :type => Array, :required => true

  # When lookup_key is set to false, the datasource will not attempt to
  # look up the key from a hash that gets returned.  This flag will be
  # set to default of false in Jerakia 3.0
  #
  option(:lookup_key, :default => false) { |opt|
    [TrueClass,FalseClass].include?(opt.class)
  }

  def lookup

    lookup_supported_params = [
      :host,
      :port,
      :output,
      :failure,
      :ignore_404,
      :headers,
      :http_connect_timeout,
      :http_read_timeout,
      :use_ssl,
      :ssl_ca_cert,
      :ssl_cert,
      :ssl_key,
      :ssl_verify,
      :use_auth,
      :auth_user,
      :auth_pass
    ]
    lookup_params = options.select { |p| lookup_supported_params.include?(p) }
    http_lookup = LookupHttp.new(lookup_params)


    paths = options[:paths].flatten
    reply do |response|
      path = paths.shift
      break unless path
      Jerakia.log.debug("Attempting to load data from #{path}")

      data = http_lookup.get_parsed(path)
      Jerakia.log.debug("Datasource provided #{data} (#{data.class}) looking for key #{request.key}")

      if data.is_a?(Hash)
        if options[:lookup_key]
          if data.has_key?(request.key)
            response.namespace(request.namespace).key(request.key).ammend(data[request.key])
          end

        else
          response.namespace(request.namespace).key(request.key).ammend(data)
        end
      else
        unless options[:output] == 'plain' || options[:failure] == 'graceful'
          raise Jerakia::Error, "HTTP request did not return a hash for #{request.key}"
        end
        response.submit data
      end
    end
  end
end
