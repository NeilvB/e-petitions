require "savon/mock/spec_helper"

include Savon::SpecHelper

Before do
  default_url_options[:protocol] = 'https'
end

Before do
  RateLimit.create!(
    burst_rate: 10, burst_period: 60,
    sustained_rate: 20, sustained_period: 300,
    allowed_domains: "example.com", allowed_ips: "127.0.0.1"
  )
end

Before do
  savon.mock!
end

After do
  Site.reload
end

After do
  savon.unmock!
end

Before('@admin') do
  Capybara.app_host = 'https://moderate.petitions.gov.je'
  Capybara.default_host = 'https://moderate.petitions.gov.je'
end

Before('~@admin') do
  Capybara.app_host = 'https://petitions.gov.je'
  Capybara.default_host = 'https://petitions.gov.je'
end
