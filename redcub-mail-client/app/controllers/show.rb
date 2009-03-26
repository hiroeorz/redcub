class Show < Application
  include RedCub
  include Model

  before :ensure_authenticated

  def index
    redirect(:list)
  end

  def list
    @filters = Filter.all(:user_id => session.user.id,
                          :order => [:id])
    get_mails
    render 
  end

  def list_ajax
    get_mails
    partial :maillist
  end

  def delete
    @mail = Mail.first(:id => params[:id],
                       :user_id => session.user.id)
    @mail.trash!

    redirect :list_ajax
  end

  def mailview
    @mail = Mail.first(:id => params[:id],
                       :user_id => session.user.id)
    @mail.readed = true

    @header = @mail.mail_data.header
    @body = @mail.mail_data.body
    render(:layout => false)
  end

  private

  def get_mails
    @pageNo = params[:pageNo]
    @filter_name = params[:filter]

    @filter = Filter.first(:name => @filter_name)

    if @filter.nil?
      @filter = Filter.new
      @filter.id = 0

      case @filter_name
      when "trash"
        @filter.id = -1
      when "sended"
        @filter.id = -2
      end
    end

    if params[:state].nil?
      state = [0, 1]
    else
      state = params[:state].split(/,/).collect {|i| i.to_i}
    end

    @mails = Mail.all(:user_id => session.user.id,
                      :limit => 30, 
                      :state => state,
                      :filter_id => @filter.id,
                      :order => [:receive_date.desc, :id.desc])
  end

  def authenticate

  end
end
