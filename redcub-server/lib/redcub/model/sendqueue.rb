module RedCub
  module Model
    class Sendqueue
      include DataMapper::Resource
   
      storage_names[:default] = "sendqueues"
   
      property :message_id, String, :key => true
      property :helo_name, String
      property :mail_from, String
      property :recipients, String
      property :orig_to, String
      property :receive_date, DateTime
      property :data, Object
    end
  end
end
