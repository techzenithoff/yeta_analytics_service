module SharedUtils

    class ServiceResponse
    attr_reader :code, :body, :error

    def initialize(success:, code: nil, body: nil, error: nil)
        @success = success
        @code = code
        @body = body
        @error = error
    end

    def success?
        @success
    end

    def parsed_response
        @body
    end
    end
end