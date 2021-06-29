# frozen_string_literal: true
require 'mini_magick'

MiniMagick.configure do |config|
  config.shell_api = "posix-spawn"
end
