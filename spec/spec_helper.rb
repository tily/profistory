require 'rack/test'
require 'rspec'

ENV['RACK_ENV'] = 'development'

require_relative '../api'

module RSpecMixin
  include Rack::Test::Methods
  def app() described_class end
end

RSpec.configure { |c| c.include RSpecMixin }