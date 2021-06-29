# frozen_string_literal: true
module Hyrax
  class ArkivoConstraint
    def self.matches?(_request)
      # Add your own logic here to authorize trusted connections to
      # the API e.g., if your installation of Arkivo runs on a host
      # with the 10.0.0.3 IP address, you could use:
      # request.remote_ip == '10.0.0.3'
      true
    end
  end
end
