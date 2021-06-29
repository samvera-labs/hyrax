# frozen_string_literal: true
source 'https://rubygems.org' do
  # Please see hyrax.gemspec for dependency information.
  gemspec

  group :development, :test do
    gem 'coveralls', require: false
    gem 'i18n-tasks'
    gem 'pry' unless ENV['CI']
    gem 'pry-byebug' unless ENV['CI']
    gem "simplecov", require: false
  end
end

test_app_path = ENV['RAILS_ROOT'] ||
                ENV.fetch('ENGINE_CART_DESTINATION', File.expand_path('.internal_test_app', File.dirname(__FILE__)))
test_app_gemfile = File.expand_path('Gemfile', test_app_path)

# rubocop:disable Bundler/DuplicatedGem
if File.exist?(test_app_gemfile)
  begin
    eval_gemfile test_app_gemfile
  rescue Bundler::GemfileError => e
    Bundler.ui.warn '[Hyrax] Skipping Rails application dependencies:'
    Bundler.ui.warn e.message
  end
elsif ENV['RAILS_VERSION'] == 'edge'
  gem 'rails', github: 'rails/rails', source: 'https://rubygems.org'
  ENV['ENGINE_CART_RAILS_OPTIONS'] = '--edge --skip-turbolinks'
elsif ENV['RAILS_VERSION']
  gem 'rails', ENV['RAILS_VERSION'], source: 'https://rubygems.org'
end
# rubocop:enable Bundler/DuplicatedGem
