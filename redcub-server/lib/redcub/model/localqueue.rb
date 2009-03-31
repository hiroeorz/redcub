module RedCub
  module Model
    class Localqueue < Queue
      @@mogile_domain_type = "localqueue"

      include DataMapper::Resource

      storage_names[:default] = "localqueues"

      after :destroy, :mogile_queue_delete
   
      property :id, Integer, :serial => true, :key => true
      property :message_id, String, :nullable => false
      property :helo_name, String, :nullable => false
      property :mail_from, String, :nullable => false
      property :recipients, String, :nullable => false
      property :orig_to, String, :nullable => false
      property :receive_date, DateTime
      property :lock_flg, Integer, :nullable => false, :default => 1

      def mogile_domain_type
        return @@mogile_domain_type
      end
    end
  end
end
