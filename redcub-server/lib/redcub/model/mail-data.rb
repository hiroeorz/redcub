module RedCub
  module Model
    class MailData < Model
      include DataMapper::Resource

      storage_names[:default] = "datas"
      
      property :id, Integer, :serial => true
      property :mail_id, Integer, :nullable => false
      property :header, Object

      after :save, :mogile_store
      after :destroy, :mogile_delete

      def mogile_domain
        return "#{@@mogile_domain_key}.maildata.#{self.user_id}"
      end

      def body
        return mogile_read
      end

      def body=(data)
        @data = data
      end
    end
  end
end
