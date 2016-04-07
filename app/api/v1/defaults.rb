module API
  module V1
    # Default options for all API endpoints and versions
    module Defaults
      extend ActiveSupport::Concern

      included do
        # Common Grape settings
        version 'v1', using: :accept_version_header
        format :json
        prefix :api

        # Global handler for simple not found case
        rescue_from ActiveRecord::RecordNotFound do |e|
          error!({ errors: Array(e.message) }, 404)
        end

        # Global handler for validation errors
        rescue_from Grape::Exceptions::ValidationErrors do |e|
          error!({ errors: e.full_messages }, 400)
        end
      end
    end
  end
end