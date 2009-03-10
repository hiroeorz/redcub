module RedCub
  module Model
    class Sendqueue
      include DataMapper::Resource
   
      storage_names[:default] = "sendqueue"
   
      property :message_id, String, :key => true
      property :helo_name, String
      property :sender, String
      property :recipients, String
      property :orig_to, String
      property :receive_date, DateTime
      property :data, Object
    end
  end
end
