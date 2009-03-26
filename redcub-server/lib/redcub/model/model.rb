module RedCub
  module Model
    class Model
      @@config = RedCub::Config.instance
      @@mogile_domain_key = @@config["mogilefs"]["domain"]
      @@mogile_hosts = @@config["mogilefs"]["hosts"]

      private

      def mogile_domain
        return "#{@@mogile_domain_key}.#{self.user_id}"
      end

      def mogile_read
        mogile = MogileFS::MogileFS.new(:domain => mogile_domain, 
                                        :hosts => @@mogile_hosts)
        return mogile.get_file_data(self.id)
      end
      
      def mogile_store
        mogile = MogileFS::MogileFS.new(:domain => mogile_domain, 
                                        :hosts => @@mogile_hosts)

        mogile.store_content(self.id, "normal", @data)
      end

      def mogile_delete
        mogile = MogileFS::MogileFS.new(:domain => mogile_domain, 
                                        :hosts => @@mogile_hosts)
        mogile.delete(self.id)
      end

      def mogile_queue_store(type)
        begin
          domain = "#{@@mogile_domain_key}.#{type}"
          mogile = MogileFS::MogileFS.new(:domain => domain, 
                                          :hosts => @@mogile_hosts)
          
          mogile.store_content(self.id, "normal", @data)
        rescue MogileFS::Backend::UnregDomainError
          setup_mogilefs_queue
        end
      end

      def mogile_queue_read(type)
        begin
          domain = "#{@@mogile_domain_key}.#{type}"
          
          mogile = MogileFS::MogileFS.new(:domain => domain, 
                                          :hosts => @@mogile_hosts)
          return mogile.get_file_data(self.id)

        rescue MogileFS::Backend::UnregDomainError
          setup_mogilefs_queue
        end
      end

      def mogile_queue_delete(type)
        domain = "#{@@mogile_domain_key}.#{type}"
        
        mogile = MogileFS::MogileFS.new(:domain => domain, 
                                        :hosts => @@mogile_hosts)
        mogile.delete(self.id)
      end

      def setup_mogilefs
        data_count = AttachedFile.count(:user_id => self.user_id)
        return if data_count > 1

        mogadm = MogileFS::Admin.new(:hosts => @@mogile_hosts)
        mogadm.create_domain(mogile_domain)
        mogadm.create_class(mogile_domain, "normal", 2)
        mogadm.create_class(mogile_domain, "important", 3)
      end

      def setup_mogilefs_queue
        mogadm = MogileFS::Admin.new(:hosts => @@mogile_hosts)

        mogadm.create_domain("#{@@mogile_domain_key}.sendqueue")
        mogadm.create_class("#{@@mogile_domain_key}.sendqueue", "normal", 2)

        mogadm.create_domain("#{@@mogile_domain_key}.localqueue")
        mogadm.create_class("#{@@mogile_domain_key}.localqueue", "normal", 2)
      end
    end
  end
end
