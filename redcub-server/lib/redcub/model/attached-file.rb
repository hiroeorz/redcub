module RedCub
  module Model
    class AttachedFile
      CompressMinSize = 1000 # file compressed when CompressMinSize > @file.size

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

      def initialize
        @config = Config.instance
        @mogile_domain_key = @config["mogilefs"]["domain"]
        @mogile_hosts = @config["mogilefs"]["hosts"]
        @file_data = nil
      end

      def file_data
        return mogile_read
      end

      def file_data=(data)
        @file_data = data
      end

      private

      def mogile_read
        mogile = MogileFS::MogileFS.new(:domain => mogile_domain, 
                                        :hosts => @mogile_hosts)
        return Zlib::Inflate.inflate(mogile.get_file_data(self.id))
      end

      def mogile_domain
        return "#{@mogile_domain_key}.#{self.user_id}"
      end
      
      def mogile_store
        setup_mogilefs
        mogile = MogileFS::MogileFS.new(:domain => mogile_domain, 
                                        :hosts => @mogile_hosts)
        compress_level = Zlib::NO_COMPRESSION

        if CompressMinSize < @file_data.size
          compress_level = Zlib::BEST_COMPRESSION
        end

        mogile.store_content(self.id, "normal", 
                             Zlib::Deflate.deflate(@file_data, compress_level))
      end

      def mogile_delete
        mogile = MogileFS::MogileFS.new(:domain => mogile_domain, 
                                        :hosts => @mogile_hosts)
        mogile.delete(self.id)
      end

      def setup_mogilefs
        data_count = AttachedFile.count(:user_id => self.user_id)
        return if data_count > 1

        mogadm = MogileFS::Admin.new(:hosts => @mogile_hosts)
        mogadm.create_domain(mogile_domain)
        mogadm.create_class(mogile_domain, "normal", 2)
        mogadm.create_class(mogile_domain, "important", 3)
      end
    end
  end
end
