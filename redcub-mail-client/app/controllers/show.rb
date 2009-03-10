class Show < Application
  include RedCub
  include Model

  def index
    redirect(:list)
  end

  def list
    session["userCD"] = 1
    @pageNo = params[:pageNo]
    @mailCount = 50

    @mails = Mail.all(:mail_to_id => session["userCD"],
                      :limit => 50, 
                      :order => [:receive_date, :id])
    
    render  
  end
end
