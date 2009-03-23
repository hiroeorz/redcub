module RedCub
  module Model
    class AttachedFile
      include DataMapper::Resource
      
      storage_names[:default] = "attached_files"

      property :id, Integer, :serial => true
      property :mail_id, Integer, :nullable => false
      property :filename, String, :nullable => false
      property :filetype, String, :nullable => false, :default => "text/plain"
      property :file, Text

      belongs_to :mail
    end
  end
end
