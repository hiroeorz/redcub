module RedCub
  module Model
    class MailData
      include DataMapper::Resource
      
      storage_names[:default] = "datas"
      
      property :id, Integer, :serial => true
      property :mail_id, Integer, :nullable => false
      property :message_id, String
      property :receive_date, DateTime
      property :header, Object
      property :body, Text
    end
  end
end
