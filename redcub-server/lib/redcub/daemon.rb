require "redcub"

module RedCub
  class Daemon
    attr_accessor :daemon, :pid_file

    def initialize(name)
      @config = Config.instance
      @pid_file = @config["pid_file"][name]
      @daemon = false

      @log_facility = RedCub::LOG_FACILITIES[@config["log_facility"]]
      
      unless @log_facility
        STDERR.print("no such facility: %s", @config["log_facility"])
        exit(1)
      end
      
      if Syslog.opened?
	Syslog.reopen("redcab",
		      Syslog::LOG_PID | Syslog::LOG_CONS,
		      @log_facility)
      else
	Syslog.open("redcab",
		    Syslog::LOG_PID | Syslog::LOG_CONS,
		    @log_facility)
      end
    end

    def start
      daemon if @daemon

      begin
        File.open(@pid_file, "w") do |f|
          f.puts(Process.pid)
          f.truncate(f.tell)
        end
      end
    end

    private

    def daemon
      exit if fork
      exit if fork
      Process.setsid
      STDIN.close
      STDOUT.reopen("/dev/null", "w")
      STDERR.reopen("/dev/null", "w")
    end
  end
end
