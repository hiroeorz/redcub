module RedCub
  module Model
    class Localqueue < Model
      include DataMapper::Resource

      storage_names[:default] = "localqueues"
   
      property :message_id, String, :key => true
      property :helo_name, String
      property :mail_from, String
      property :recipients, String
      property :orig_to, String
      property :receive_date, DateTime
      property :data, Object

      def initialize
        setup
      end
    end
  end
end
