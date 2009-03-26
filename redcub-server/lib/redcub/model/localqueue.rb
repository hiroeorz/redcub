module RedCub
  module Model
    class Localqueue < Model
      include DataMapper::Resource

      after :save, :mogile_local_queue_stroe

      storage_names[:default] = "localqueues"
   
      property :message_id, String, :key => true
      property :helo_name, String
      property :mail_from, String
      property :recipients, String
      property :orig_to, String
      property :receive_date, DateTime

      def data
        return mogile_queue_read("localqueue")
      end

      def data=(data)
        @data = data
      end

      def mogile_local_queue_stroe
        mogile_queue_store("localqueue")
      end
    end
  end
end
