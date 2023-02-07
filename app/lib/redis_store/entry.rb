# frozen_string_literal: true

module RedisStore
  class NotConnected < StandardError; end

  class Entry < Dry::Struct
    include Helpers::CoreCommands
    extend Helpers::CoreCommands::ClassMethods

    attribute :key, Types::String

    def id
      self.class.without_redis_key_prefix(key)
    end

    class << self
      def new(id:, **attributes)
        attrs_with_defaults = fill_in_missing_keys(**attributes)
        super(key: id, **attrs_with_defaults)
      end

      def create(id:, **attributes)
        new(id: id, **attributes).save
      end

      def find(id)
        value = read_by(id)
        return if value.nil?

        new(id: id, **value)
      end

      def redis=(conn)
        @redis = ConnectionPoolProxy.proxy_if_needed(conn)
      end

      def redis
        @redis ||= begin
                     non_prod_like = Rails.env.test? || Rails.env.development?
                     raise(NotConnected, "#{name}.redis not set to a Redis.new connection pool") unless non_prod_like

                     redis_connection = Rails.env.test? ? MockRedis.new : Redis.new(host: 'localhost', port: 6379)
                     ConnectionPoolProxy.proxy_if_needed(ConnectionPool::Wrapper.new(size: 5, timeout: 5) { redis_connection })
                   end
      end

      def without_redis_key_prefix(id)
        return if id.nil?

        id.gsub(/^(.*):/, '')
      end

      private

      def fill_in_missing_keys(**attributes)
        keys = attribute_names - [:key]
        missing_keys = keys - attributes.keys
        return attributes if missing_keys.empty?

        missing_hash = Hash[missing_keys.map { |x| [x, nil] }]
        missing_hash.merge(attributes)
      end
    end

    def attributes
      super.except(:key)
    end

    def redis
      self.class.redis
    end

    def save
      set_hash(attributes.except(:key))

      self
    end
  end
end
