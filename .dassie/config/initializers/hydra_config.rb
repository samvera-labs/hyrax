# windows doesn't properly require hydra-head (from the gemfile), so we need to require it explicitly here:
require 'hydra/head' unless defined? Hydra

Hydra.configure do |config|
  config.user_key_field = Devise.authentication_keys.first
end
