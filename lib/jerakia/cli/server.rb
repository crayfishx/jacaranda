class Jerakia
  class CLI < Thor
    module Server
      def self.included(thor)
        thor.class_eval do
          desc 'server <options>', 'Start the Jerakia REST server'
          option :config,
                 aliases: :c,
                 type: :string,
                 desc: 'Configuration file'
          option :log_level,
                 aliases: :l,
                 type: :string,
                 desc: 'Log level'
          option :verbose,
                 aliases: :v,
                 type: :boolean,
                 desc: 'Log to STDOUT in verbose mode'
          option :debug,
                 aliases: :D,
                 type: :boolean,
                 desc: 'Log to STDOUT in debug mode'
          def server
            case true
            when options[:verbose]
              loglevel = 'verbose'
              logfile  = STDOUT
            when options[:debug]
              loglevel = 'debug'
              logfile  = STDOUT
            else
              logfile = nil
              loglevel = options[:log_level]
            end

            jerakia_opts = {
              :config => options[:config],
              :logfile  => logfile,
              :loglevel => loglevel,
              :trace    => options[:trace]
            }

            require 'jerakia/server'
            Jerakia::Server.start(jerakia_opts)
          end
        end
      end
    end
  end
end
