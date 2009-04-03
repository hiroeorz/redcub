module RedCub
  module Model
    class Model
      @@config = RedCub::Config.instance
      @@mogile_domain_key = @@config["mogilefs"]["domain"]

      @@mogile_hosts = @@config["mogilefs"]["hosts"]

      private

      def mogile_domain
        raise "subclass must override this method!"
      end

      def mogile_read(key = self.id)
        begin
          mogile = MogileFS::MogileFS.new(:domain => mogile_domain, 
                                          :hosts => @@mogile_hosts)
          return mogile.get_file_data(key)
        rescue MogileFS::Backend::UnregDomainError
          setup_mogilefs
          sleep(1)
          retry
        end
      end
      
      def mogile_store(key = self.id, data = @data, level = :normal)
        return if @data.nil?

        begin
          mogile = MogileFS::MogileFS.new(:domain => mogile_domain, 
                                          :hosts => @@mogile_hosts)
          
          file_size = mogile.store_content(key, level.to_s, data)
          
          if Syslog.opened?
            Syslog.debug("mogile file saved (domain=>#{mogile_domain}, key=>#{key}, size=>#{file_size})")
          end
        rescue MogileFS::Backend::UnregDomainError
          setup_mogilefs
          sleep(1)
          retry
        end
      end

      def mogile_delete
        mogile = MogileFS::MogileFS.new(:domain => mogile_domain, 
                                        :hosts => @@mogile_hosts)
        mogile.delete(self.id)
      end

      def setup_mogilefs
        mogadm = MogileFS::Admin.new(:hosts => @@mogile_hosts)
        mogadm.create_domain(mogile_domain)
        mogadm.create_class(mogile_domain, "normal", 2)
        mogadm.create_class(mogile_domain, "important", 3)
      end
    end
  end
end
