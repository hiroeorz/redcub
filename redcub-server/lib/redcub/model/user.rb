module RedCub
  module Model
    class User
      include DataMapper::Resource
   
      storage_names[:default] = "users"
   
      property :id, Integer, :serial => true
      property :name, String
      property :password, String

    end
  end
end
