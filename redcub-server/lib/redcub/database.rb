config = RedCub::Config.instance
adapter = config["database"]["adapter"]
database_lib = "redcub/db-adapter/database-#{adapter}.rb"
require database_lib

succession_class = nil

case config["database"]["adapter"]
when "sqlite3"
  $succession_class = RedCub::SQLite3Database
when "postgresql"
  $succession_class = RedCub::PostgreSQLDatabase
when "mysql"
  $succession_class = RedCub::MySQLDatabase
end

class Object
  def to_sql
    raise ScriptError.new("subclass must override this method (#{self.class})")
  end
end

class NilClass
  def to_sql
    return "null"
  end
end

class TrueClass
  def to_sql
    return "TRUE"
  end
end

class FalseClass
  def to_sql
    return "FALSE"
  end
end

class Numeric
  def to_sql
    return self.to_s
  end
end

class Blob < String
  SQL_ESCAPE_SEQUENCE = {}

  def initialize(str)
    @value = str
    super(str)
  end

  def to_sql
    return "'" + @value + "'"
  end
end

class String
  SQL_ESCAPE_SEQUENCE = {
    "\0" => "\\000",
    "\r" => "\\r",
    "\n" => "\\n",
    "\\" => "\\\\",
    "'" => "\\'",
    '"' => '\\"'
  }

  def to_sql
    return "'" + self.gsub(/[\0\r\n\\'"]/n) { |s|
      SQL_ESCAPE_SEQUENCE[s]
    } + "'"
  end

  def reverse_escape
    SQL_ESCAPE_SEQUENCE.each do |key, value|
      self.gsub!(value, key)
    end
  end

  def to_time
    parts = self.split(/\s/)
    date_parts = parts[0].split(/\-/)
    time_parts = parts[1].split(/:/)

    year = date_parts[0].to_i
    month = date_parts[1].to_i
    day = date_parts[2].to_i
    hour = time_parts[0].to_i
    minute = time_parts[1].to_i
    second = time_parts[2].to_i

    return Time.mktime(year, month, day, hour, minute, second)
  end

  def to_date
    date_parts = self.split(/\-/)

    year = date_parts[0].to_i
    month = date_parts[1].to_i
    day = date_parts[2].to_i

    return Date.new(year, month, day)
  end

  def to_blob
    return Blob.new(self)
  end
end

class Time
  def to_sql
    return format("'%s.%06d'",
		  strftime("%Y-%m-%d %H:%M:%S"),
		  tv_usec)
  end
end

class Symbol
  def to_sql
    return id2name
  end
end

module RedCub
  class Database < $succession_class
  end
end
