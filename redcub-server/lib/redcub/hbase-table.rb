class NilClass
  def text
    return ""
  end
end
  
module RedCub
  class HBaseTable
    @@url = nil
    
    def initialize(tablename, url = @@url)
      @config = Config.instance
      @url = url
      @table = tablename
      @conn = HBase::Client.new(url)
    end
    
    def HBaseTable.url=(url)
      @@url = url
    end
    
    def HBaseTable.create_table(tablename, *args)
      conn = HBase::Client.new(@@url)
      conn.create_table(tablename, *args)
      conn.enable_table(tablename)
    end
    
    def HBaseTable.delete_table(tablename)
      conn = HBase::Client.new(@@url)
      conn.disable_table(tablename)
      conn.delete_table(tablename)    
    end
    
    class << HBaseTable
      def new(*args)
        db = super
        if block_given?
          begin
            return yield(db)
          ensure
            
          end
        else
          return db
        end
      end
      
      alias open new
    end

    def insert(key, data, time = Time.now)
      @conn.create_row(@table, key, time.to_i, data)
    end

    def inserts(key, data)
      data.each do |column_family, column_data|
        if column_data.is_a?(Hash)
          column_data.each do |name, value|
            insert(key, 
                   :name => "#{column_family}:#{name}",
                   :value => value.to_s)
          end
        else
          insert(key, 
                 :name => "#{column_family}:",
                 :value => column_data.to_s)
        end
      end
    end
    
    def get(key)
      row = @conn.show_row(@table, key).columns
      data = OrderHash.new
      
      row.each do |r|
        name_array = r.name.split(/:/)
        
        if name_array.length == 1
          familly = name_array[0]
          data[familly.to_sym] = r.value
        else
          familly = name_array[0]
          column = name_array[1]
          
          unless data.key?(familly.to_sym)
            data[familly.to_sym] = OrderHash.new
          end
          
          data[familly.to_s.to_sym][column.to_s.to_sym] = r.value
        end
      end
      
      return data
    end
    
    def get_records(column_familly)
      scanner = nil
      
      begin
        scanner = @conn.open_scanner(@table, column_familly.to_s + ":")
        rows = @conn.get_rows(scanner)
        @conn.close_scanner(scanner) unless scanner.nil?
      rescue
        return []
      end

      array = []
      
      rows.each do |row|
        data = OrderHash.new
        row.columns.each do |r|
          name = r.name.sub(column_familly.to_s + ":", "")
          data[name.to_sym] = r.value
        end
        
        row = {
          :key => row.name,
          :column => data
        }
        
        array.push(row)
      end
      
      return array
    end
    
    def delete(key, *args)
      if args.empty?
        @conn.delete_row(@table, key, nil)
        return
      end
      
      familly = args[0]
      column = args[1]
      
      if args.length == 1
        @conn.delete_row(@table, key, nil, "#{familly}:")
      else
        @conn.delete_row(@table, key, nil, "#{familly}:#{column}")
      end
    end
  end
end
