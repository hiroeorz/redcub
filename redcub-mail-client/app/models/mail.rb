class Mail
  include DataMapper::Resource
  
  property :id, Serial
  property :message_id, String
  property :host_id, Integer
  property :mail_from, Integer
  property :mail_to, Integer
  property :receive_date, DateTime
  property :data_part, String
  property :data_size, Integer

end
