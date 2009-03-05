require "yaml"

module RedCub
  class Config    
    @@path = File.join("/etc", "redcub.conf")    
    
    def Config.path=(path)
      @@path = path
    end
    
    def Config.path
      return @@path
    end
    
    def Config.clear
      @__instance__ = nil
    end
    
    def initialize
      @data = {}

      begin
        open(@@path) do |f|
          @data = @data.dup.update(YAML.load(f))
        end
      rescue StandardError, LoadError
	raise ConfigError.new($!, @@path)
      end
    end
    
    def [](name)
      return @data[name]
    end
    
    def []=(name, val)
      @data[name] = val
    end
    
    def Config.instance
      if @__instance__.nil?
	@__instance__ = Config.new
      end
      return @__instance__
    end
  end
  
  class ConfigError < StandardError
    attr_reader :original_error
    
    def initialize(error, filename)
      super(filename + ": " + error.message)
      @original_error = error
    end
  end

  class InvalidServiceNameError < StandardError
  end

  class InvalidHostNameError < StandardError
  end
end
