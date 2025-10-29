
class BaseClient
    include HTTParty
    #default_timeout = 5 # secondes max avant timeout

    # Méthode d'appel GET générique
    def self.get_json(path, query: {}, headers: {}, timeout: 5)
        # merge avec headers par défaut
        merged_headers = build_headers.merge(headers)

        response = get(path, query: query, headers: merged_headers, timeout: timeout)

        
        handle_response(response)

    rescue Net::ReadTimeout, Net::OpenTimeout => e
        Rails.logger.error("#{name} Timeout: #{e.message}")
        { "error" => "timeout" }
    rescue => e
        Rails.logger.error("#{name} Error: #{e.message}")
        { "error" => "exception" }
    end

  # ===============================
  # Helpers
  # ===============================
  private

  def self.build_headers(custom_headers = {})
    {
      "Content-Type" => "application/json",
      "Accept" => "application/json",
      "Authorization" => "Bearer #{fetch_service_token}"
    }.merge(custom_headers)
  end

  # Exemple simple — tu peux améliorer en récupérant dynamiquement un vrai token
  def self.fetch_service_token
    ENV["SERVICE_TOKEN"] || "local-dev-token"
  end

  def self.handle_response(response)
    if response.success?
      response.parsed_response
    else
      Rails.logger.warn("#{name} HTTP #{response.code}: #{response.body}")
      { "error" => "http_#{response.code}" }
    end
  end
end
