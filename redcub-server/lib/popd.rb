# $Id: popd.rb,v 1.2 2008/12/26 05:56:35 yomura Exp $
#
# rfc1939
#   The POP3 service by listening on TCP port 110.
#   All responses are terminated by a CRLF pair.


require "tempfile"
require "getssafe"

class POPD
  class Error < StandardError
  end

  def initialize(sock, domain)
    @sock = sock
    @domain = domain
    @error_interval = 5
    class <<@sock
      include GetsSafe
    end
  end

  def start()
    @authenticated = false
    @username = nil
    @password = nil
    @deletelist = []

    # apop timestamp
    @apop_stamp = "<" + Process.pid.to_s + "." + Time.now.tv_sec.to_s + "@" + Socket.gethostname + ">"

    catch :close do
      puts_safe "+OK POP3 server starting. #{@apop_stamp}"
      while comm = @sock.gets_safe do
	catch :next_comm do
	  comm.sub!(/\r?\n/,"")
	  comm, arg, arg2 = comm.split(/\s+/,3)
          break if comm == nil
	  case comm.upcase
	  when "STAT" then comm_stat(arg)
	  when "LIST" then comm_list(arg)
	  when "RETR" then comm_retr(arg)
          when "DELE" then comm_dele(arg)
          when "NOOP" then comm_noop(arg)
          when "RSET" then comm_rset(arg)
	  when "QUIT" then comm_quit(arg)
          when "TOP" then comm_top(arg, arg2)
          when "UIDL" then comm_uidl(arg)
          when "USER" then comm_user(arg)
          when "PASS" then comm_pass(arg)
          when "APOP" then comm_apop(arg, arg2)
	  else
	    reply "-ERR command not implemented"
	  end
	end
      end
    end
  end

  def line_length_limit=(n)
    @sock.maxlength = n
  end

  def input_timeout=(n)
    @sock.timeout = n
  end

  attr_reader :line_length_limit, :input_timeout
  attr_accessor :error_interval
  attr_accessor :use_file, :max_size

  private

  def comm_quit(arg)
    error "-ERR Syntax: QUIT" if arg != nil

    quit_flg = true
    quit_flg = quit_hook if defined? quit_hook
    if quit_flg
      reply "+OK"
    else
      reply "-ERR some deleted messages not removed"
    end
    throw :close
  end

  def comm_stat(arg)
    error "-ERR Syntax: STAT" if arg != nil
    error "-ERR" if @authenticated == false
      
    nn = 0 # number of messages
    mm = 0 # size of maildrop in octets
    nn, mm = stat_hook if defined? stat_hook
    reply "+OK #{nn} #{mm}"
  end

  def comm_list(arg)
    error "-ERR" if @authenticated == false

    msglist = [] # message list
    msgtotalsize = 0  # size in octets

    msglist, msgtotalsize = list_hook(arg) if defined? list_hook
    if msglist.empty?
      reply "-ERR no such message"
    else
      if arg.nil?
        if msglist.length.zero?
          reply "+OK ther is no message"
        else
          if msglist.length == 1
            reply "+OK 1 message (#{msgtotalsize} octets)"
          else
            reply "+OK #{msglist.length} messages (#{msgtotalsize} octets)"
          end
          msglist.each_with_index do |m, i|
            reply "#{i} #{m["size"]}"
          end
        end
      else
        reply "#{arg} #{msglist[0]["size"]}"
      end
    end
  end

  def comm_retr(arg)
    error "-ERR" if @authenticated == false
    error "-ERR Syntax: RETR message-number" if arg.nil?

    msg = Hash.new("size" => 0, "message" => "")  # message hash
    msg = retr_hook(arg) if defined? retr_hook
    if msg.nil?
      reply "-ERR no such message"
    else
      reply "+OK #{msg["size"]} octets"
      reply "#{msg["message"]}"
    end
  end

  def comm_dele(arg)
    error "-ERR" if @authenticated == false
    error "-ERR Syntax: DELE message-number" if arg.nil?

    rmflg = nil  # remove check flag
    rmflg = dele_hook(arg) if defined? dele_hook
    if rmflg.nil?
      reply "-ERR no such message"
    else
      if rmflg
        @deletelist.push(arg)
        reply "+OK message #{arg} deleted"
      else
        reply "-ERR message #{arg} already deleted"
      end
    end
  end

  def comm_noop(arg)
    error "-ERR Syntax: NOOP" if arg != nil

    noop_hook if defined? noop_hook
    reply "+OK"
  end

  def comm_rset(arg)
    error "-ERR Syntax: RSET" if arg != nil

    rset_hook if defined? rset_hook
    reply "+OK"
    @username = nil
    @password = nil
    @authenticated = false
    @deletelist = []
  end

  def comm_top(arg, arg2)
    error "-ERR" if @authenticated == false
    if arg.nil? || arg2.nil?
      reply "-ERR Syntax: TOP message-number non-negative_number_of_line"
    end
    msg = nil  # message
    msg = top_hook(arg, arg2) if defined? top_hook
    if msg.nil?
      reply "-ERR no such message"
    else
      reply "+OK"
      msgstrs = msg.split(/\n/)
      for i in 0...arg2.to_i
        reply msgstrs[i].to_s
      end
    end
  end

  def comm_uidl(arg)
    error "-ERR" if @authenticated == false

    uidlist = nil  # uniqu id list
    uidlist = uidl_hook(arg) if defined? uidl_hook
    if uidlist.nil?
      reply "-ERR no such message"
    else
      if arg.nil?
        reply "+OK"
      else
        uidlist.each_with_index do |u, i|
          reply "#{i} #{u}"
        end
      end
    end
  end

  def comm_user(arg)
    error "-ERR Syntax: USER username" if arg.nil?

    user_hook(arg) if defined? user_hook
    @username = arg
    reply "+OK Password required."
  end

  def comm_pass(arg)
    error "-ERR" if @username.nil?
    error "-ERR Syntax: PASS password" if arg.nil?

    auth_flg = false  # authenticate flag
    auth_flg = pass_hook(arg) if defined? pass_hook
    if auth_flg
      @authenticated = true
      reply "+OK"
    else
      error "-ERR invalid password"
    end
  end

  def comm_apop(arg, arg2)
    error "-ERR Syntax: APOP username digest" if arg.nil? || arg2.nil?

    auth_flg = false  # authenticate flag
    auth_flg = apop_hook(arg, arg2) if defined? apop_hook
    if auth_flg
      @username = arg
      @authenticated = true
      reply "+OK"
    else
      error "-ERR permission denied"
    end
  end

  # ----------------------------
  def reply(msg)
    puts_safe msg
  end

  def error(msg)
    sleep @error_interval if @error_interval
    puts_safe msg
    throw :next_comm
  end

  def puts_safe(str)
    begin
      @sock.puts str+"\r\n"
    rescue
      raise POPD::Error, "cannot send to client: '#{str.gsub(/\s+/," ")}': #{$!.to_s}"
    end
  end
  # ----------------------------

end

POPDError = POPD::Error
