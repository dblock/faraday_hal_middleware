require 'rspec'
require 'webmock/rspec'
require 'faraday'

module EnvCompatibility
  def faraday_env(env)
    if defined?(Faraday::Env)
      Faraday::Env.from(env)
    else
      env
    end
  end
end

module ResponseMiddlewareExampleGroup
  def self.included(base)
    base.let(:options) { {} }
    base.let(:headers) { {} }
    base.let(:middleware) do
      described_class.new(lambda { |env|
        Faraday::Response.new(env)
      }, options)
    end
  end

  def process(body, content_type = nil, options = {})
    env = {
      body: body, request: options,
      request_headers: Faraday::Utils::Headers.new,
      response_headers: Faraday::Utils::Headers.new(headers)
    }
    env[:response_headers]['content-type'] = content_type if content_type
    yield(env) if block_given?
    middleware.call(faraday_env(env))
  end
end

RSpec.configure do |config|
  config.include EnvCompatibility
  config.include ResponseMiddlewareExampleGroup, type: :response
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
