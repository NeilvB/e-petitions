ENV['RAILS_ENV'] ||= 'test'
require 'spec_helper'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'webmock/rspec'
require 'savon/mock/spec_helper'

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

include Savon::SpecHelper

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.include Requests::JsonHelpers, type: :request

  config.before(:all) do
    # savon.mock!
  end

  config.after(:all) do
    # savon.unmock!
  end
end
