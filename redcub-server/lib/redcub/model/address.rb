module RedCub
  module Model
    class Address < Model
      include DataMapper::Resource

      storage_names[:default] = "addresses"
      
      property :id, Integer, :serial => true
      property :value, String
      property :address_part, String, :nullable => false
      property :name_part, String, :default => nil

      def friendly_address
        if self.name_part.nil?
          return self.address_part
        end

        return "#{self.name_part}<#{self.address_part}>"
      end
    end
  end
end
