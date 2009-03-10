module RedCub
  module Model
    class MailData
      include DataMapper::Resource
      
      storage_names[:default] = "datas"
      
      property :id, Integer, :serial => true
      property :message_id, String
      property :data, Object
      property :receive_date, DateTime
      property :subject, String
      property :body, Text

    end
  end
end
