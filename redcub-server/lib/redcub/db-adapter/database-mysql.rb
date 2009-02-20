require "mysql"
require "kconv"

module RedCub
  class MySQLDatabase
    attr_reader :host, :port, :options, :tty, :dbname,
      :user, :conn, :client_encoding

    SQL_STRING_PARSER = Proc.new { |s| s }
    SQL_BOOLEAN_PARSER = Proc.new { |s| s == "t" }
    SQL_INTEGER_PARSER = Proc.new { |s| s.to_i }
    SQL_FLOAT_PARSER = Proc.new { |s| s.to_f }
    SQL_NUMERIC_PARSER = Proc.new { |s|
      if /\A-?\d+\z/ =~ s
        s.to_i
      elsif /\A-?\d+.\d+\z/ =~ s
        s.to_f
      else
        s
      end
    }
    SQL_TIMESTAMP_PARSER = Proc.new { |s|
      if /(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)(?:\.(\d{1,6}))?/ =~ s
        if $7
          usec = ($7 + "0" * (6 - $7.length)).to_i
        else
          usec = 0
        end
        Time.mktime($1.to_i, $2.to_i, $3.to_i,
                    $4.to_i, $5.to_i, $6.to_i, usec)
      else
        raise ArgumentError.new("invalid timestamp '#{s}'")
      end
    }

    KCONV_ENCODE_TYPE = {
      "UTF8" => Kconv::UTF8,
      "UTF16" => Kconv::UTF16,
      "UNICODE" => Kconv::UTF8,
      "JIS" => Kconv::JIS,
      "EUC_JP" => Kconv::EUC,
      "SJIS" => Kconv::SJIS
    }

    TYPE_CONVERTER = {
      Mysql::Field::TYPE_DECIMAL => nil,
      Mysql::Field::TYPE_TINY => "to_i",
      Mysql::Field::TYPE_SHORT => "to_i",
      Mysql::Field::TYPE_LONG => "to_i",
      Mysql::Field::TYPE_FLOAT => "to_f",
      Mysql::Field::TYPE_DOUBLE => "to_f",
      Mysql::Field::TYPE_NULL => nil,
      Mysql::Field::TYPE_TIMESTAMP => "to_time",
      Mysql::Field::TYPE_LONGLONG => "to_f",
      Mysql::Field::TYPE_INT24 => "to_i",
      Mysql::Field::TYPE_DATE => "to_date",
      Mysql::Field::TYPE_TIME => "to_time",
      Mysql::Field::TYPE_DATETIME => "to_time",
      Mysql::Field::TYPE_YEAR => "to_i",
      #Mysql::Field::TYPE_NEWDATE => "to_date",
      Mysql::Field::TYPE_ENUM => nil,
      Mysql::Field::TYPE_SET => nil,
      #Mysql::Field::TYPE_TINY_BLOB => nil,
      #Mysql::Field::TYPE_MEDIUM_BLOB => nil,
      #Mysql::Field::TYPE_LONG_BLOB => nil,
      Mysql::Field::TYPE_BLOB => nil,
      Mysql::Field::TYPE_VAR_STRING => nil,
      Mysql::Field::TYPE_STRING => nil,
      #Mysql::Field::TYPE_GEOMETRY => nil,
      Mysql::Field::TYPE_CHAR => nil,
      #Mysql::Field::TYPE_INTERVAL => nil
    }


    class << MySQLDatabase
      def new(*args)
        db = super
        if block_given?
          begin
            return yield(db)
          ensure
            db.close
          end
        else
          return db
        end
      end

      alias open new
    end

    @@default_client_encoding = nil

    def MySQLDatabase.default_client_encoding=(encoding)
      @@default_client_encoding = encoding
    end

    def MySQLDatabase.default_client_encoding
      return @@default_client_encoding
    end

    def initialize(dbname)
      config = Config.instance
      @options = ""
      @tty = ""
      @dbname = dbname
      @host = config["database"]["host"]
      @port = config["database"]["port"]
      @user = config["database"]["username"]
      @password = config["database"]["password"]
      @in_transaction = false
      @conn = nil
      @aborted = false
      @client_encoding = "utf8"
      @busy_timeout = config["database"]["timeout"]

      if @@default_client_encoding
	self.client_encoding = @@default_client_encoding
      end

      Mysql.init.options(Mysql::SET_CHARSET_NAME, @client_encoding)

      connect
    end

    def close
      if @conn
	begin
	  @conn.close
	rescue
	end
	@conn = nil
      end
    end

    def closed?
      return @conn.nil?
    end

    def client_encoding=(encoding)
      @client_encoding = encoding

      if !encoding.nil? and !@conn.nil?
        exec("SET NAMES #{encoding}")
      end
    end

    def exec(fmt, *args)
      sql = format_sql(fmt, *args)
      result = @conn.query(sql)
    end

    def query(fmt, *args)
      sql = format_sql(fmt, *args)
      result = nil
      
      if @in_transaction
        result = @conn.query(sql)
      else
        retry_on_connection_error do
          result = @conn.query(sql)
        end
      end

      return parse_result(result)
    end

    def retry_on_connection_error
      begin
        if @conn.nil?
          raise Mysql::Error.new("MySQL server has gone away")
        end

	yield
      rescue Mysql::Error
	if /Can't connect|MySQL server has gone away/ =~ $!.to_s
          sleep 1
          Syslog.err("NOTICE! retry connect to MySQL Server.")
          begin
            connect
          rescue Mysql::Error
          end
	  retry
	else
	  raise
	end
      end
    end

    def transaction
      begin
        if @in_transaction
          raise TransactionError.new("nested transaction")
        end
        @aborted = false
        @conn.query("BEGIN")
        @in_transaction = true
        yield
      rescue Exception
        @conn.query("ROLLBACK")
        raise
      ensure
        @conn.query("COMMIT") unless @aborted
        @in_transaction = false
      end
    end

    def rollback
      @conn.rollback
      @aborted = true
    end

    def error
      return @conn.error
    end

    def get_year_table(tablename, tabletype, year)
      if year < 100
	long_year = year + 2000
      else
	long_year = year
      end
      return format("%s_%s_%s_tbl", tablename, long_year, tabletype).intern
    end

    def split_point(point)
      return point[0, 4].to_i, point[4, 4].to_i
    end

    def hourmin_to_min(s)
      return s[0..-3].to_i * 60 + s[-2..-1].to_i
    end

    def min_to_hourmin(m, hour_size = 2)
      return format("%0#{hour_size}d%02d", m / 60, m % 60)
    end

    def format_sql(fmt, *args)
      sql_args = args.collect { |i|
	i.to_sql
      }

      return format(fmt, *sql_args)
    end

    private

    def connect
      close
      @conn = Mysql::new(@host, @user, @password, @dbname)

      unless @conn.nil?
        Syslog.info("reconnected to MySQL Server.")
      end
    end
    
    def parse_result(result_record)
      result = []
      result_record.each do |row|
        result.push(row)
      end

      if result.length.zero?
        return []
      end

      num_fields = result_record.num_fields
      num_tuples = result_record.num_rows

      members = []
      call_methods = []

      result_record.fetch_fields.each do |field_obj|
        members.push(field_obj.name.intern)
        call_methods.push(TYPE_CONVERTER[field_obj.type])
      end

      struct = Struct.new(*members)
      ary = []

      for i in 0 .. num_tuples - 1
	tuple = struct.new
	for j in 0 .. num_fields - 1
          value = result[i][j]
          
          if !value.nil? and !call_methods[j].nil?
            value = value.send(call_methods[j])
          end

	  tuple[j] = value
	end
	ary.push(tuple)
      end

      return ary
    end
  end

  class DatabaseError < StandardError
  end

  class TransactionError < DatabaseError
  end
end
