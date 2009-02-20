class OrderHash < Hash
  def initialize
    @keys = Array.new
    attr_accessor = @keys
  end
  
  #superとして、Hash#[]=を呼び出す
  def []=(key, value)
    super(key, value)
    unless @keys.include?(key)
      @keys.push(key)
    end
  end
  
  def clear
    @keys.clear
    super
  end
  
  def delete(key)
    if @keys.include?(key)
      @keys.delete(key)
      super(key)
    elsif
      yield(key)
    end
  end
  
  def each
    @keys.each{|k|
      arr_tmp = Array.new
      arr_tmp << k
      arr_tmp << self[k]
      yield(arr_tmp)
    }
    return self
  end
  
  def each_pair
    @keys.each{|k|
      yield(k, self[k])
    }
    return self
  end
  
  def map
    arr_tmp = Array.new
    @keys.each{|k|
      arg_arr = Array.new
      arg_arr << k
      arg_arr << self[k]
      arr_tmp << yield(arg_arr)
    }
    return arr_tmp
  end
  
  def sort_hash(&block)
    if block_given?
      arr_tmp = self.sort(&block)
    elsif
      arr_tmp = self.sort
    end
    
    hash_tmp = OrderHash.new
    arr_tmp.each{|item|
      hash_tmp[item[0]] = item[1]
    }
    return hash_tmp
  end
end
