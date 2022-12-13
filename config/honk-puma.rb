# For development, load the .env files now so we can use their settings
begin
  if require('dotenv')
    Dotenv.load
  end
rescue LoadError
  # Ignored
end

rackup DefaultRackup
port ENV.fetch('PORT', '3000')
workers ENV.fetch('PUMA_MAX_WORKERS', ENV.fetch('WEB_CONCURRENCY', '3'))
worker_culling_strategy :oldest
wait_for_less_busy_worker(0.01)
force_shutdown_after 25
threads 1, 1 # NO Multithreading

dev = ENV.fetch("RAILS_ENV", 'development') == 'development'

# This is broken with most our apps right now
puma_fork_worker_mode = !dev && ENV.fetch("PUMA_ENABLE_FORK_WORKER_MODE", "0") == "1"

preload_app!(!dev && !puma_fork_worker_mode)

##
# nakayoshi_fork:
# When enabled, ::Puma will GC 4 times before forking workers. If available (Ruby 2.7+), we will also call GC.compact. Not recommended for non-MRI Rubies.
#
# Based on the work of Koichi Sasada and Aaron Patterson, this option may decrease memory utilization of preload-enabled cluster-mode Pumas. It will also increase time to boot and fork. See your logs for details on how much time this adds to your boot process. For most apps, it will be less than one second.
#
nakayoshi_fork(true) if !dev && ENV.fetch("PUMA_DISABLE_NAKAYOSHI_FORK", "0") != "1"

if puma_fork_worker_mode
  ##
  # Puma 5 introduces an experimental new cluster-mode configuration option, fork_worker (--fork-worker from the CLI). This mode causes Puma to fork additional workers from worker 0, instead of directly from the master process:
  # Similar to the preload_app! option, the fork_worker option allows your application to be initialized only once for copy-on-write memory savings, and it has two additional advantages:
  # 1. Compatible with phased restart
  # 2. 'Refork' for additional copy-on-write improvements in running applications
  # See: https://github.com/puma/puma/blob/master/docs/fork_worker.md
  #
  restart_randomness_base = ENV.fetch('PUMA_RESTART_WORKERS_AFTER_REQUESTS', 500.0).to_f
  restart_randomness_jitter = ENV.fetch('PUMA_RESTART_WORKERS_AFTER_REQUESTS_JITTER', 0.0).to_f

  restart_randomness = (restart_randomness_base + (rand * restart_randomness_jitter) - (restart_randomness_jitter / 2.0)).to_i
  puts "Will restart workers after #{restart_randomness} requests (base = #{restart_randomness_base}, jitter = #{restart_randomness_jitter})"

  # Due to the randomness of how requests are assigned, at any given time it seems we have workers with like 1k requests and
  # other workers with like 10 requests. So we'll tell puma to refork the process at some randomized interval.
  # This should help reduce memory footprint and optimize the copy-on-write memory benefits.
  #
  fork_worker(restart_randomness)
end

before_fork do
  # we should just need to disconnect redis and it will reconnect on use
  disconnect_redis = -> (redis) {
    if redis.respond_to?(:redis)
      redis = redis.redis
    end

    if defined?(::Redis) && redis.kind_of?(::Redis)
      redis.close
    elsif defined?(::MockRedis) && redis.kind_of?(::MockRedis)
      redis.flushdb
    end

    redis
  }

  disconnect_redis.(::StandaloneRedis.connect) if defined?(::StandaloneRedis)
  disconnect_redis.(::Resque.redis) if defined?(::Resque)
  disconnect_redis.(::Stoplight::Light.default_data_store.instance_variable_get(:@redis)) if defined?(::Stoplight)
  disconnect_redis.(::ActionCable.server.pubsub.redis_connection_for_subscriptions) if defined?(::ActionCable) && ::ActionCable.server.pubsub.kind_of?(::ActionCable::SubscriptionAdapter::Redis)
  disconnect_redis.($redis) if defined?($redis)

  if defined?(::Rails) && ::Rails.cache.respond_to?(:redis)
    disconnect_redis.(::Rails.cache)
  end
end
