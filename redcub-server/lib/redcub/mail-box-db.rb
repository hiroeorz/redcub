module RedCub
  class MailBoxDB < Database
    include Util

    def initialize
      @config = Config.instance
      @dbname = @config["database"]["mailbox_dbname"]

      super(@dbname)
    end

    def insert(message_id, helo_host, from, to, receive_date, data)
      tmail = TMail::Mail.parse(data)

      helo_host_id = get_host_id(helo_host)
      from_id = get_address_id(from)
      to_id = get_user_id(to)

      message = escape_html_tag(get_message_body(tmail)).toutf8

      data_part = get_data_part(message)
      data_size = data.size / 1024

      exec("insert into mails values (NULL, %s, %s, %s, %s, %s, %s, %s)",
           message_id, helo_host_id, from_id, to_id, receive_date,
           data_part, data_size)

      result = query("select id from mails order by id desc limit 1")

      if result.empty?
        id = 1
      else
        id = result[0].id
      end

      exec("insert into maildatas values (NULL %s, %s, %s)",
           id, message_id, data)
    end

    def get_data_part(data, count = 64)
      if data.jlength < count
        return data
      end

      result = ""

      data.each_char do |c|
        break if c.jlength >= count
        result.concat(c)
      end

      return result
    end

    def get_host_id(hostname)
      result = query("select id from hosts where name = %s",
                     hostname)

      return result[0].id unless result.empty?

      begin
        exec("insert into hosts values(NULL, %s)", hostname)
      rescue Mysql::Error
      end

      return get_host_id(hostname)
    end

    def get_address_id(address)
      result = query("select id from addresses where address = %s",
                     address)

      return result[0].id unless result.empty?

      begin
        exec("insert into addresses values(NULL, %s)", address)
      rescue Mysql::Error
      end

      return get_address_id(address)     
    end

    def get_user_id(name)
      result = query("select id from users where name = %s", name)
      if result.empty?
        raise NoSuchUserError.new("name=#{name}")
      end
      return result[0].id
    end

    def get_user_password(name)
      result = query("select password from users where name = %s", name)
      if result.empty?
        raise NoSuchUserError.new("name=#{name}")
      end
      return result[0].password
    end

    def get_mailbox_info(username)
      # get userid
      userid = get_user_id(username)

      # mail total count
      result = query("select count(mail_to) as cnt from mails
                                                   where mail_to = %s",
                     userid)
      totalcnt = 0
      totalcnt = result[0].cnt.to_i unless result.empty?
      
      # mail total size
      result = query("select sum(data_size) as size from mails
                                                    where mail_to = %s",
                     userid)
      totalsize = "0"
      totalsize = sprintf("%o", result[0].size) unless result.empty?

      return totalcnt, totalsize.to_i
    end

    def get_mailbox_list(username, mail_num = nil)
      # get userid
      userid = get_user_id(username)

      # mail total count
      response = []
      if mail_num.nil?
        # get all
        result = query("select * from mails
                                 where mail_to = %s
                                 order by id asc", userid)
        response = result
      else
        # get target message by mail_num
        result = query("select * from mails
                                 where mail_to = %s
                                 order by id asc", userid)
        response = result[mail_num]
      end
      return response
    end




  end
end
