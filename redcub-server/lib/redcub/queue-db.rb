module RedCub
  class QueueDB < Database
    def initialize
      @config = Config.instance
      @dbname = @config["database"]["queue_dbname"]
      super(@dbname)
    end

    def delete(type, message_id)
      exec("delete from #{type.to_s}_mailqueue where message_id = %s",
           message_id)

    end
  end
end
