module RedCub
  module Model
    class Sendqueue < Model
      include DataMapper::Resource

      before :save, :mogile_send_queue_stroe
      after :destroy, :mogile_send_queue_delete

      storage_names[:default] = "sendqueues"
   
      property :message_id, String, :key => true
      property :helo_name, String
      property :mail_from, String
      property :recipients, String
      property :orig_to, String
      property :receive_date, DateTime

      def data
        return mogile_queue_read("sendqueue")
      end

      def data=(data)
        @data = data
      end

      def mogile_send_queue_stroe
        mogile_queue_store("sendqueue")
      end

      def mogile_send_queue_delete
        mogile_queue_delete("sendqueue")
      end
    end
  end
end
