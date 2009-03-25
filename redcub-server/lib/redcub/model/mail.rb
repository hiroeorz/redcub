module RedCub
  module Model
    class Mail < Model
      include DataMapper::Resource

      storage_names[:default] = "mails"
   
      property :id, Integer, :serial => true, :key => true
      property :user_id, Integer, :nullable => false
      property :message_id, String, :nullable => false
      property :mail_from_id, Integer, :nullable => false
      property :filter_id, Integer, :nullable => true, :default => nil
      property :receive_date, DateTime
      property :state, Integer, :nullable => false, :default => 0
      property :subject, String, :default => ""
      property :body_part, String, :default => ""

      belongs_to :user, 
                 :class_name => "User", 
                 :child_key => [:user_id]

      belongs_to :mail_from, 
                 :class_name => "Address", 
                 :child_key => [:mail_from_id]

      belongs_to :filter, 
                 :class_name => "Filter", 
                 :child_key => [:filter_id]

      has 1, :mail_data,
             :class_name => "MailData"


      has n, :attached_files,
             :class_name => "AttachedFile"

      def readed?
        return !self.state.zero?
      end
      
      def readed=(flag)
        unless (flag == true or flag == false)
          raise ArgumentError.new("Invalid readed flag(#{other.class})")
        end
        
        if self.state.zero? and flag
          self.state = 1
          self.save!
        elsif self.state == 1 and !flag
          self.state = 0
          self.save!
        end
      end
      
      def trash!
        self.state = 1
        self.filter_id = -1
        self.save!
        return true
      end

      def trashed?
        return self.state == 3
      end

      def sended=(flag)
        if flag
          self.state = 1
        else
          self.state = 0
        end

        self.filter_id = -2
        self.save!

        return true
      end
    end
  end
end
