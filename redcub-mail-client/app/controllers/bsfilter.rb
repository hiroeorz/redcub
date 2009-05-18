class Bsfilter < Application
  include RedCub

  def index
    render
  end

  def white
    mail = Mail.first(:id => params[:id])
    lean(mail, "--add-clean")

    mail.spam = false
    ""
  end

  def black
    mail = Mail.first(:id => params[:id])
    lean(mail, "--add-spam")

    mail.spam = true
    ""    
  end

  private

  def lean(mail, option)
    tmp_dir = File.join(Merb.root, "tmp", "bsfilter")
    File.makedirs(tmp_dir)

    path = File.join(tmp_dir, params[:id].to_s)

    File.open(path, "wb") do |f|
      f.write(mail.data)
    end

    begin
      config = Merb::Config[:bsfilter]
      
      command = "#{config['command']}"
      command << " --homedir #{config['homedir']}"
      command << " --jtokenizer #{config['jtokenizer']}"
      command << " #{option} #{path}"
      command << " 2>&1"

      Merb.logger.debug("exec: #{command}")
      result = `#{command}`

      Merb.logger.debug("lean result: #{result}")

      update_command = `#{config['command']} --update`
    ensure
      File.unlink(path)
    end
  end
end
