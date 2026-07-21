# lib/shared_utils/generate.rb
module SharedUtils
    module Generate
        
        def generate_random_number_uid
            current_record = self
          
            if current_record.present?
                unless current_record.uuid.present? 
                    begin
                        current_record.uuid = SecureRandom.random_number(100_000_000_000)
                    end while current_record.class.where(uuid: current_record.uuid).exists?
                end
            end
        end

        def generate_hex_uid
            current_record = self
          
            if current_record.present?
                unless current_record.uuid.present? 
                    begin
                        current_record.uuid = SecureRandom.hex(32)
                    end while current_record.class.where(uuid: current_record.uuid).exists?
                end
            end
        end

        def generate_uuid
            current_record = self
          
            if current_record.present?
                unless current_record.uuid.present? 
                    begin
                        current_record.uuid = SecureRandom.uuid
                    end while current_record.class.where(uuid: current_record.uuid).exists?
                end
            end
        end

        def generate_confirmation_token
            current_record = self
          
            if current_record.present?
                unless current_record.confirmation_token.present? 
                    begin
                        current_record.confirmation_token = SecureRandom.hex(32)
                    end while current_record.class.where(confirmation_token: current_record.confirmation_token).exists?
                end
            end
        end

        
    end
end