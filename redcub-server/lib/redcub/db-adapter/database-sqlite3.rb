require "sqlite3"
require "kconv"

module RedCub
  class SQLite3Database
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

    class << SQLite3Database
      def new(*args)
        db = super

        File.open(db.dbname) do |f|
          begin
            #f.flock(File::LOCK_EX)          
            if block_given?
              begin
                return yield(db)
              ensure
                db.close
              end
            else
              return db
            end

          ensure
            #f.flock(File::LOCK_UN)
          end
        end
      end

      alias open new
    end

    @@default_client_encoding = nil

    def SQLite3Database.default_client_encoding=(encoding)
      @@default_client_encoding = encoding
    end

    def SQLite3Database.default_client_encoding
      return @@default_client_encoding
    end

    def initialize(dbname)
      config = Config.instance
      @options = ""
      @tty = ""
      @dbname = dbname
      @in_transaction = false
      @conn = nil
      @aborted = false
      @client_encoding = "UTF8"
      @busy_timeout = config["database"]["timeout"]
      connect
      if @@default_client_encoding
	self.client_encoding = @@default_client_encoding
      end
    end

    def close
      if @conn
	begin
	  @conn.close
	rescue SQLite3::SQLException
	end
	@conn = nil
      end
    end

    def closed?
      return @conn.nil?
    end

    def client_encoding=(encoding)
      @client_encoding = encoding
    end

    def exec(fmt, *args)
      sql = format_sql(fmt, *args)
      result = @conn.execute(sql)
    end

    def query(fmt, *args)
      sql = format_sql(fmt, *args)
      result = @conn.execute2(sql)

      return parse_result(result)
    end

    def transaction
      begin
        if @in_transaction
          raise TransactionError.new("nested transaction")
        end

        @aborted = false
        @conn.execute("BEGIN")
        @in_transaction = true
        yield
      rescue Exception
        @conn.execute("ROLLBACK")
        raise
      ensure
        @conn.execute("COMMIT") unless @aborted
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

    private

    def connect
      close
      @conn = SQLite3::Database.new(@dbname)
      @conn.type_translation = true
      @conn.busy_timeout(@busy_timeout)
    end

    def format_sql(fmt, *args)
      sql_args = args.collect { |i|
	i.to_sql
      }
      return format(fmt, *sql_args)
    end

    def parse_result(result)
      if result.length == 1
        return []
      end

      num_fields = result[0].length
      num_tuples = result.length - 1

      fields = result.shift
      members = fields.collect { |name|
	name.intern
      }

      struct = Struct.new(*members)
      ary = []

      for i in 0 .. num_tuples - 1
	tuple = struct.new
	for j in 0 .. num_fields - 1
          value = result[i][j]
          if value.is_a?(String)
            value.reverse_escape
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
