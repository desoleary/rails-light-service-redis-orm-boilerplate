# frozen_string_literal: true

module RedisStore
  module Helpers
    module Serializer
      def serialize_value(value)
        return value if value.nil?

        MessagePack.pack(value)
      end

      def deserialize_value(value)
        return if value.nil?

        return deserialize_hash_value(value) if value.is_a?(Hash)

        MessagePack.unpack(value)
      end

      def deserialize_hash_value(hash)
        return if hash.nil?

        hash.transform_values do |v|
          begin
            next v if v.blank?
            next v unless v.is_a?(String)
            next v unless v.encoding == Encoding::ASCII_8BIT

            v.blank? ? v : MessagePack.unpack(v)
          rescue => ex
            next without_invalid_characters(v) if ex.class == ArgumentError

            raise ex
          end
        end.deep_symbolize_keys
      end

      private

      def without_invalid_characters(text)
        return text unless text.is_a?(String)

        text.chars.select(&:valid_encoding?).join
      end
    end

    module CoreCommands
      include Serializer

      module ClassMethods
        include Serializer

        def read_by(key)
          type = redis.type key
          return if type.nil? || type == 'none'
          return read_hash(key) if type == 'hash'

          read_value(key)
        end

        def read_hash(key)
          value = redis.hgetall(key)
          deserialize_value(value)
        end

        def read_value(key)
          value = redis.get(key)
          return if value.nil?

          deserialize_value(value)
        end
      end

      def read
        type = redis.type key
        return if type.nil?

        return read_hash if type == 'hash'

        read_value
      end

      def read_hash
        value = redis.hgetall(key)

        deserialize_value(value)
      end

      def read_value
        value = redis.get(key)
        deserialize_value(value)
      end

      def set(value)
        return set_hash(value) if value.is_a?(Hash)

        redis.set key, serialize_value(value)
        nil
      end

      def set_hash(hash)
        raise ArgumentError, "'hash_value' must be a hash, found type: #{hash_value.class.name}" unless hash.is_a?(Hash)

        hash.each_pair { |sub_key, value| set_subhash(sub_key, value) }
        nil
      end

      def exists
        redis.exists key
      end

      def exists?
        redis.exists? key
      end

      def expire(seconds)
        redis.expire key, seconds
      end

      def ttl
        redis.ttl(key)
      end

      def read_subhash(field)
        value = redis.hget(key, field)
        return if value.nil?

        deserialize_value(value)
      end

      def set_subhash(field, value)
        redis.hset(key, field, serialize_value(value))

        nil
      end
    end
  end
end
