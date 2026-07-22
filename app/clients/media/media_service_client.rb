module Media
    class MediaServiceClient < BaseClient

        base_uri ENV.fetch('MEDIA_SERVICE_INTERNAL_URL', 'http://media-service.internal')

        def self.audience_name
            "media-service"
        end

        def self.fetch_batch(ids)
            return [] if ids.blank?

            response = request(:post, "/media/batch", {body: { items: ids }.to_json})

            # BaseClient#request avale les exceptions/timeouts en interne et retourne
            # un hash { 'success' => false, ... } au lieu de lever une exception.
            if response.is_a?(Hash) && response['success'] == false
                Rails.logger.error("[MediaServiceClient] fetch_batch failed: #{response['error']}")
                return []
            end

            items = response.is_a?(Hash) ? (response['items'] || []) : []
            items.map(&:symbolize_keys)
        end
    end
end