# frozen_string_literal: true

require 'yaml' if RUBY_VERSION.include?('2.0.0')
require 'forwardable'
require 'concurrent/mutable_struct'
require 'ostruct'

require 'sidekiq_unique_jobs/version'
require 'sidekiq_unique_jobs/constants'
require 'sidekiq_unique_jobs/logging'
require 'sidekiq_unique_jobs/sidekiq_worker_methods'
require 'sidekiq_unique_jobs/connection'
require 'sidekiq_unique_jobs/exceptions'
require 'sidekiq_unique_jobs/util'
require 'sidekiq_unique_jobs/cli'
require 'sidekiq_unique_jobs/core_ext'
require 'sidekiq_unique_jobs/timeout'
require 'sidekiq_unique_jobs/scripts'
require 'sidekiq_unique_jobs/unique_args'
require 'sidekiq_unique_jobs/unlockable'
require 'sidekiq_unique_jobs/locksmith'
require 'sidekiq_unique_jobs/options_with_fallback'
require 'sidekiq_unique_jobs/middleware'
require 'sidekiq_unique_jobs/sidekiq_unique_ext'

module SidekiqUniqueJobs
  include SidekiqUniqueJobs::Connection

  module_function

  Concurrent::MutableStruct.new(
    'Config',
    :default_lock_timeout,
    :enabled,
    :unique_prefix,
    :logger,
  )

  def config
    # Arguments here need to match the definition of the new class (see above)
    @config ||= Concurrent::MutableStruct::Config.new(
      0,
      true,
      'uniquejobs',
      Sidekiq.logger,
    )
  end

  def logger
    config.logger
  end

  def logger=(other)
    config.logger = other
  end

  def use_config(tmp_config)
    fail ::ArgumentError, "#{name}.#{__method__} needs a block" unless block_given?

    old_config = config.to_h
    configure(tmp_config)
    yield
    configure(old_config)
  end

  def configure(options = {})
    if block_given?
      yield config
    else
      options.each do |key, val|
        config.send("#{key}=", val)
      end
    end
  end

  def redis_version
    @redis_version ||= redis { |conn| conn.info('server')['redis_version'] }
  end
end
