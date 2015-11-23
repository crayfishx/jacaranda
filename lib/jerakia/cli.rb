require 'thor'
require 'jerakia'
require 'json'

class Jerakia
  class CLI < Thor
    desc 'lookup [KEY]', 'Lookup [KEY] with Jerakia'
    option :config,
           aliases: :c,
           type: :string,
           default: '/etc/jerakia/jerakia.yaml',
           desc: 'Configuration file'
    option :policy,
           aliases: :p,
           type: :string,
           default: 'default',
           desc: 'Lookup policy'
    option :namespace,
           aliases: :n,
           type: :string,
           desc: 'Lookup namespace'
    option :type,
           aliases: :t,
           type: :string,
           default: 'first',
           desc: 'Lookup type'
    option :scope,
           aliases: :s,
           type: :string,
           desc: 'Scope handler'
    option :merge_type,
           aliases: :m,
           type: :string,
           default: 'array',
           desc: 'Merge type'
    option :log_level,
           aliases: :l,
           type: :string,
           desc: 'Log level'
    option :metadata,
           aliases: :d,
           type: :hash,
           desc: 'Key/value pairs to be used as metadata for the lookup'
    def lookup(key)
      jac = Jerakia.new({:config => options[:config]})
      req = Jerakia::Request.new(
        :key         => key,
        :namespace   => options[:namespace].split(/::/),
        :policy      => options[:policy].to_sym,
        :lookup_type => options[:type].to_sym,
        :merge       => options[:merge_type].to_sym,
        :loglevel    => options[:log_level],
        :metadata    => options[:metadata]
      )

      answer = jac.lookup(req)
      puts answer.payload.to_json
    end
  end
end
