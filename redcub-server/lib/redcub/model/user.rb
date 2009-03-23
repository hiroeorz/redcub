module RedCub
  module Model
    class User
      include DataMapper::Resource
   
      storage_names[:default] = "users"
   
      property :id, Integer, :serial => true
      property :name, String, :nullable => false
      property :person_name, String, :nullable => false
      property :crypted_password, String, :nullable => false
      property :mailaddress, String, :nullable => false
      property :salt, String, :nullable => false

      has n, :mail, :class_name => "Mail"

      def User.exist?(name)
        user = self.first(:name => name)
        return !user.nil?
      end

      def friendly_address
        return "#{self.person_name}<#{self.mailaddress}>"
      end

      def friendly_encoded_address
        name = NKF.nkf("-j --utf8-input", self.person_name)

        encoded_name = "=?ISO-2022-JP?B?#{Base64.encode64(name).chomp}?="
        encoded_name.concat("<#{self.mailaddress}>")
        encoded_name.gsub!(/\n/, "\\n")

        return encoded_name
      end
    end
  end
end
