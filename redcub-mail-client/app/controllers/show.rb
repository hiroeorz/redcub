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

  def boxlist
    @filters = Filter.all(:user_id => session.user.id,
                          :order => [:id])
    partial :traylist
  end

  def delete
    @mail = Mail.first(:id => params[:id],
                       :user_id => session.user.id)
    @mail.trash!
    ""
  end

  def mailview
    @mail = Mail.first(:id => params[:id],
                       :user_id => session.user.id)
    @mail.readed = true

    @header = @mail.header
    @body = @mail.body
    @attached_files = @mail.attached_files

    render(:layout => false)
  end

  def mail_body_only
    @mail = Mail.first(:id => params[:id],
                       :user_id => session.user.id)
    @mail.mail.body
  end

  def cleartrash
    transaction do
      mails = Mail.all(:filter_id => -1)
      
      return "" if mails.empty?

      id_array = []
      
      mails.each do |m|
        id_array.push(m.id)
      end
      
      Merb.logger.debug("id_array=[#{id_array.join(',')}]")

      attached_files = AttachedFile.all(:mail_id => id_array)

      mails.destroy! unless mails.nil?
      attached_files.destroy!
    end

    ""
  end

  private

  def get_mails
    @page_no = params[:page_no].to_i
    @page_no = 1 if @page_no.zero?

    filter_id = params[:filter_id]

    @filter = Filter.get(filter_id)

    if @filter.nil?
      @filter = Filter.new
      @filter.id = filter_id.to_i
    end

    if params[:state].nil?
      state = [0, 1]
    else
      state = params[:state].split(/,/).collect {|i| i.to_i}
    end

    count_per_page = 20

    offset_count = count_per_page * (@page_no - 1)

    @mails = Mail.all(:user_id => session.user.id,
                      :limit => count_per_page,
                      :offset => offset_count,
                      :state => state,
                      :filter_id => @filter.id,
                      :order => [:receive_date.desc, :id.desc])

    @count = Mail.count(:user_id => session.user.id,
                        :filter_id => @filter.id)

    @page_count = @count / count_per_page
    @page_count += 1 unless (@count % count_per_page).zero?
  end
end
