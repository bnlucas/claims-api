# frozen_string_literal: true

module TokenBlocklist
  # The Redis namespace used for storing JWT blocklist entries.
  REDIS_NAMESPACE = "jwt:blocklist"

  class << self
    # Checks whether a given JWT ID is currently blocklisted.
    #
    # @param jwt_id [String] The unique ID of the JWT.
    # @return [Boolean] `true` if the JWT ID exists in the blocklist, `false` otherwise.
    def revoked?(jwt_id)
      redis.exists?(redis_key(jwt_id))
    end

    # Adds a JWT ID to the blocklist.
    # The entry is set with an expiration time that matches the token's expiration,
    # ensuring it's automatically removed from the blocklist when the token would have expired.
    #
    # @param jwt_id [String] The unique ID of the JWT.
    # @param exp [Integer] The JWT's expiration timestamp (seconds since epoch).
    # @return [void]
    def revoke!(jwt_id, exp:)
      ttl = exp - Time.now.to_i
      return if ttl <= 0

      redis.set(redis_key(jwt_id), "revoked", ex: ttl)
    end

    # Removes a JWT ID from the blocklist, effectively "unblocking" it.
    # This is useful for rare cases where a revoked token needs to be immediately re-allowed.
    #
    # @param jwt_id [String] The unique ID of the JWT to remove from the blocklist.
    # @return [void]
    def allow!(jwt_id)
      redis.del(redis_key(jwt_id))
    end

    private

    # Builds the Redis key for a given JWT ID by prepending the namespace.
    #
    # @param jwt_id [String] The unique ID of the JWT.
    # @return [String] The Redis key.
    def redis_key(jwt_id)
      "#{REDIS_NAMESPACE}:#{jwt_id}"
    end

    # Instantiates and memoizes a connection to Redis.
    #
    # @return [Redis] A Redis client instance.
    def redis
      @redis ||= Redis.new(url: ENV.fetch("REDIS_URL"))
    end
  end
end
