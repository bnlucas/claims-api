require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Claims
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # config.autoload_paths << Rails.root.join("app/errors")

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    $LOAD_PATH.unshift(Rails.root.join("app/lib").to_s)

    %w[app/errors app/lib lib].each do |dir|
      full_path = Rails.root.join(dir)

      config.autoload_paths << full_path
      config.eager_load_paths << full_path

      Dir[Rails.root.join("#{dir}/**/*.rb")].sort.each { |f| require f }
    end

    config.cache_store = :redis_cache_store, {
      url: ENV.fetch("REDIS_URL") { "redis://#{ENV['REDIS_HOST']}:#{ENV['REDIS_PORT']}" },
      password: ENV.fetch("REDIS_PASSWORD", nil),
      expires_in: 1.hour
    }

    config.action_dispatch.show_exceptions = :none

    config.middleware.insert_before 0, ErrorHandlerMiddleware
    config.middleware.insert_after ErrorHandlerMiddleware, JwtMiddleware
  end
end
