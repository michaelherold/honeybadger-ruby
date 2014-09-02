require 'pathname'
require 'yaml'

module Honeybadger
  class Config
    class Yaml < ::Hash
      def initialize(path, env = 'production')
        @path = Pathname.new(path)

        if !@path.exist?
          raise ConfigError, "The configuration file #{@path} was not found."
        elsif !@path.file?
          raise ConfigError, "The configuration file #{@path} is not a file."
        elsif !@path.writable?
          raise ConfigError, "The configuration file #{@path} is not writable."
        else
          yaml = YAML.load(@path.read)
          override = yaml.delete(env)
          update(dotify_keys(yaml.merge(override || {})))
        end

      rescue StandardError => e
        raise ConfigError, "An unknown error occured: #{e.class} -- #{e.message}\n\t#{e.backtrace.first}"
      end

      private

      def dotify_keys(hash, key_prefix = nil)
        {}.tap do |new_hash|
          hash.each_pair do |k,v|
            k = [key_prefix, k].compact.join('.')
            if v.kind_of?(Hash)
              new_hash.update(dotify_keys(v, k))
            else
              next if DISALLOWED_KEYS.include?(k.to_sym)
              new_hash[k.to_sym] = v
            end
          end
        end
      end
    end
  end
end
