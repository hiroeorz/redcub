module RedCub
  module Model
    class Mail
      include DataMapper::Resource
   
      storage_names[:default] = "mails"
   
      property :id, Integer, :serial => true, :key => true
      property :message_id, String, :nullable => false
      property :mail_from_id, Integer, :nullable => false
      property :mail_to_id, Integer, :nullable => false
      property :receive_date, DateTime
      property :subject, String
      property :mail_data_id, Integer, :nullable => false
      
      belongs_to :mail_from, 
                 :class_name => "Address", 
                 :child_key => [:mail_from_id]

      belongs_to :mail_to, 
                 :class_name => "User", 
                 :child_key => [:mail_to_id]

      belongs_to :data, 
                 :class_name => "MailData", 
                 :child_key => [:mail_data_id]
    end
  end
end
