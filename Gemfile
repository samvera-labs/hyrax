# frozen_string_literal: true
source 'https://rubygems.org'
# Please see hyrax.gemspec for dependency information.
gemspec

group :development, :test do
  gem 'benchmark-ips'
  gem 'easy_translate'
  gem 'i18n-tasks'
  gem 'okcomputer'
  gem 'pry' unless ENV['CI']
  gem 'pry-byebug' unless ENV['CI']
  gem 'ruby-prof', require: false
  gem "simplecov", require: false
end

test_app_path = ENV['RAILS_ROOT'] ||
                ENV.fetch('ENGINE_CART_DESTINATION', File.expand_path('.internal_test_app', File.dirname(__FILE__)))
test_app_gemfile = File.expand_path('Gemfile', test_app_path)

# rubocop:disable Bundler/DuplicatedGem
if File.exist?(test_app_gemfile)
  begin
    Bundler.ui.warn "[Hyrax] Including test application dependencies from #{test_app_gemfile}"
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
else
  Bundler.ui.warn '[Hyrax] Skipping all Rails dependency injection'
end
# rubocop:enable Bundler/DuplicatedGem
