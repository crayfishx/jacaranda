require 'lookup_http'

class Jerakia::Datasource::Http < Jerakia::Datasource::Instance

      option :host,                :type => String,  :mandatory => true
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
      option :paths, :type => Array, :mandatory => true

    def lookup
      #
      # Do the lookup

      Jerakia.log.debug("Searching key #{request.key} using the http datasource")

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
      Jerakia.log.debug("Getting our http lookup with these params: #{lookup_params}")
      http_lookup = LookupHttp.new(lookup_params)

      options[:paths].flatten.each do |path|
        Jerakia.log.debug("Attempting to load data from #{path}")
        return unless response.want?

        data = http_lookup.get_parsed(path)
        Jerakia.log.debug("Datasource provided #{data} (#{data.class}) looking for key #{request.key}")

        if data.is_a?(Hash)
          unless data[request.key].nil?
            Jerakia.log.debug("Found data #{data[request.key]}")
            response.submit data[request.key]
          end
        else
          unless options[:output] == 'plain' || options[:failure] == 'graceful'
            raise Jerakia::Error, "HTTP request did not return a hash for #{request.key} #{whoami}"
          end
          response.submit data
        end
      end
    end

end
