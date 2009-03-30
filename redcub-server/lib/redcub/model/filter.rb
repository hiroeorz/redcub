module RedCub

  TRASH_BOX_NO = -1
  SENDED_BOX_NO = -2
  SPAM_BOX_NO = -3
  
  module Model
    class Filter < Model
      include DataMapper::Resource

      storage_names[:default] = "filters"

      property :id,  Integer, :serial => true
      property :user_id, Integer, :nullable => false
      property :exec_no, Integer, :nullable => false
      property :name, String, :nullable => false
      property :target, String, :nullable => false
      property :keyword, String


      has n, :mail,
             :class_name => "Mail"

      def Filter.filter_id(tmail, userID)
        filters = self.all(:user_id => userID,
                           :order => [:exec_no])

        if Filter.spam?(tmail)
          return RedCub::SPAM_BOX_NO
        end

        data = {}

        data[:subject] = tmail.subject.toutf8
        data[:body] = RedCub::Util.get_message_body(tmail).toutf8
        data[:from] = tmail.from.to_s.toutf8

        tmail.each_header do |key, value|
          data[key] = value.to_s.toutf8
        end

        filters.each do |f|
          if data[f.target.to_sym] =~ Regexp.new(f.keyword)
            return f.id
          end
        end

        return 0
      end

      def Filter.spam?(tmail)
        data = {}

        data[:subject] = tmail.subject.toutf8
        data[:body] = RedCub::Util.get_message_body(tmail).toutf8
        data[:from] = tmail.from.to_s.toutf8

        tmail.each_header do |key, value|
          data[key] = value.to_s.toutf8
        end

        config = Config.instance

        config["spam"]["spam_merkers"].each do |key, value|
          if data[key.to_sym] =~ Regexp.new(value)
            return true
          end          
        end

        return false
      end
    end
  end
end
