module WatchHistories
    class WatchHistoriesService
        MEDIA_TYPES = %w[Movie Episode].freeze

        def self.my_histories(account_id, page: 1, per_page: 20)
            relation = WatchHistory.where(account_id: account_id).order(created_at: :desc)
            total_count = relation.count

            return empty_result if total_count == 0

            # Initialisation de Pagy manuellement dans le service
            pagy = Pagy.new(count: total_count, page: page, items: per_page)

            # Application de la pagination native ActiveRecord via limit et offset
            paginated_histories = relation.offset(pagy.offset).limit(pagy.items)

            media_requests = paginated_histories.select { |h| MEDIA_TYPES.include?(h.watchable_type) }
                                                .map { |h| { type: h.watchable_type, id: h.watchable_id } }

            resolved = {} # clé composite "Type-id" => item

            if media_requests.present?
                fetch_safely("MediaService") { Media::MediaServiceClient.fetch_batch(media_requests) }
                .each { |item| resolved["#{item[:type]}-#{item[:id]}"] = item }
            end

            items = paginated_histories.map do |history|
                {
                    id: history.id,
                    uuid: history.uuid,
                    created_at: history.created_at,
                    watchable_type: history.watchable_type,
                    watchable_id: history.watchable_id,
                    item: resolved["#{history.watchable_type}-#{history.watchable_id}"]
                }
            end

            # Utilisation des variables de l'objet Pagy pour le retour
            { items: items, total_count: pagy.count, total_pages: pagy.pages }
        end

        def self.fetch_safely(service_name)
            yield
        rescue StandardError => e
            Rails.logger.error("[WatchHistoriesService] #{service_name} fetch_batch failed: #{e.class} #{e.message}")
            []
        end
        private_class_method :fetch_safely

        def self.empty_result
            { items: [], total_count: 0, total_pages: 0 }
        end
        private_class_method :empty_result
    end
end