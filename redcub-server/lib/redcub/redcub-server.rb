require "redcub"

module RedCub
  class RedCubServer < Daemon
    def start
      super

      receiver = Receiver.new
      receiver.daemon = true
      receiver.start
    end
  end
end
