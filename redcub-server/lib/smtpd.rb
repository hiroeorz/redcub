# $Id: smtpd.rb,v 1.1.1.1 2008/12/10 00:59:37 shin Exp $
#
# Copyright (C) 2003-2004 TOMITA Masahiro
# tommy@tmtm.org
#

require "tempfile"
require "getssafe"

class SMTPD
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
    @helo_name = nil
    @sender = nil
    @recipients = []
    catch :close do
      puts_safe "220 #{@domain} service ready"
      while comm = @sock.gets_safe do
	catch :next_comm do
	  comm.sub!(/\r?\n/,"")
	  comm, arg = comm.split(/\s+/,2)
          break if comm == nil
	  case comm.upcase
	  when "EHLO" then comm_helo arg
	  when "HELO" then comm_helo arg
	  when "MAIL" then comm_mail arg
	  when "RCPT" then comm_rcpt arg
	  when "DATA" then comm_data arg
	  when "RSET" then comm_rset arg
	  when "NOOP" then comm_noop arg
	  when "QUIT" then comm_quit arg
	  else
	    error "502 Error: command not implemented"
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
  def comm_helo(arg)
    if arg == nil or arg.split.size != 1 then
      error "501 Syntax: HELO hostname"
    end
    helo_hook arg if defined? helo_hook
    @helo_name = arg
    reply "250 #{@domain}"
  end

  def comm_mail(arg)
    if @sender != nil then
      error "503 Error: nested MAIL command"
    end
    if arg !~ /^FROM:/i then
      error "501 Syntax: MAIL FROM: <address>"
    end
    sender = parse_addr $'
    if sender == nil then
      error "501 Syntax: MAIL FROM: <address>"
    end
    mail_hook sender if defined? mail_hook
    @sender = sender
    reply "250 Ok"
  end

  def comm_rcpt(arg)
    if @sender == nil then
      error "503 Error: need MAIL command"
    end
    if arg !~ /^TO:/i then
      error "501 Syntax: RCPT TO: <address>"
    end
    rcpt = parse_addr $'
    if rcpt == nil then
      error "501 Syntax: RCPT TO: <address>"
    end
    rcpt_hook rcpt if defined? rcpt_hook
    @recipients << rcpt
    reply "250 Ok"
  end

  def comm_data(arg)
    if @recipients.size == 0 then
      error "503 Error: need RCPT command"
    end
    if arg != nil then
      error "501 Syntax: DATA"
    end
    reply "354 End data with <CR><LF>.<CR><LF>"
    if defined? data_hook then
      tmpf = @use_file ? Tempfile::new("smtpd") : ""
    end
    size = 0
    loop do
      l = @sock.gets_safe
      if l == nil then
	raise SMTPD::Error, "unexpected EOF"
      end
      if l.chomp == "." then break end
      if l[0] == ?. then
	l[0,1] = ""
      end
      size += l.size
      if @max_size and @max_size < size then
	error "552 Error: message too large"
      end
      data_each_line l if defined? data_each_line
      tmpf << l if defined? data_hook
    end
    if defined? data_hook then
      if @use_file then
	tmpf.pos = 0
        data_hook tmpf
        tmpf.close(true)
      else
        data_hook tmpf
      end
    end
    reply "250 Ok"
    @sender = nil
    @recipients = []
  end

  def comm_rset(arg)
    if arg != nil then
      error "501 Syntax: RSET"
    end
    rset_hook if defined? rset_hook
    reply "250 Ok"
    @sender = nil
    @recipients = []
  end

  def comm_noop(arg)
    if arg != nil then
      error "501 Syntax: NOOP"
    end
    noop_hook if defined? noop_hook
    reply "250 Ok"
  end

  def comm_quit(arg)
    if arg != nil then
      error "501 Syntax: QUIT"
    end
    quit_hook if defined? quit_hook
    reply "221 Bye"
    throw :close
  end

  def parse_addr(str)
    str = str.strip
    if str == "" then
      return nil
    end
    if str =~ /^<(.*)>$/ then
      return $1.gsub(/\s+/,"")
    end
    if str =~ /\s/ then
      return nil
    end
    str
  end

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
      raise SMTPD::Error, "cannot send to client: '#{str.gsub(/\s+/," ")}': #{$!.to_s}"
    end
  end
end

SMTPDError = SMTPD::Error
