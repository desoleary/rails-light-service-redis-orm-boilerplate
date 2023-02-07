RSpec.configure do |config|
  config.before(:each) do
    # [RedisModel].each{|klass| klass.redis.flushdb }
  end
end
