module RedCub
  module Model
    class Address
      include DataMapper::Resource

      storage_names[:default] = "addresses"
      
      property :id, Integer, :serial => true
      property :value, String

    end
  end
end
