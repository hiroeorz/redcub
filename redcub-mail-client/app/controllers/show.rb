class Show < Application

  def index
    session["userCD"] = 1
    @mails = Mail.all(:mail_to => session["userCD"],
                      :limit => 50, :order => [:receive_date, :id])
    
    render
  end
  
end
