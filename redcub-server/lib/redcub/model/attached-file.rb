module RedCub
  module Model
    class AttachedFile < Model
      include DataMapper::Resource

      after :save, :mogile_store

      storage_names[:default] = "attached_files"

      property :id, Integer, :serial => true
      property :mail_id, Integer, :nullable => false
      property :user_id, Integer, :nullable => false
      property :filename, String, :nullable => false
      property :filetype, String, :nullable => false, :default => "text/plain"
      property :filesize, Integer, :nullable => false, :default => 0

      belongs_to :mail

      def file_data
        return mogile_read
      end

      def file_data=(data)
        @data = data
      end
    end
  end
end
