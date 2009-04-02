module RedCub
  module Model
    class Queue < Model
      def data
        return mogile_queue_read
      end

      def data=(data)
        @data = data
      end

      def save_queue
        transaction do
          self.save
          mogile_queue_store
          self.update_attributes(:lock_flg => 0)
        end
      end

      private

      def mogile_queue_store
        begin
          domain = "#{@@mogile_domain_key}.#{mogile_domain_type}"
          mogile = MogileFS::MogileFS.new(:domain => domain, 
                                          :hosts => @@mogile_hosts)

          if Syslog.opened?
            Syslog.debug("saving queue file to mogilefs (domain: #{domain}, key: #{self.id})")
          end
          
          mogile.store_content(self.id, "normal", @data)

          if Syslog.opened?
            Syslog.debug("saved queue id=#{self.id}")
          end
          
        rescue MogileFS::Backend::UnregDomainError
          Syslog.err("mogilefs domain not found. setup now...")
          setup_mogilefs_queue
          Syslog.err("setup process ok retry queue store.")
        end
      end

      def mogile_queue_read
        begin
          domain = "#{@@mogile_domain_key}.#{mogile_domain_type}"
          
          mogile = MogileFS::MogileFS.new(:domain => domain, 
                                          :hosts => @@mogile_hosts)

          return mogile.get_file_data(self.id)

        rescue MogileFS::Backend::UnregDomainError
          setup_mogilefs_queue
        end
      end

      def mogile_queue_delete
        domain = "#{@@mogile_domain_key}.#{mogile_domain_type}"
        
        mogile = MogileFS::MogileFS.new(:domain => domain, 
                                        :hosts => @@mogile_hosts)
        mogile.delete(self.id)
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
  
