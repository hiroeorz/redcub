class MailFilter < Application
  include RedCub

  before :ensure_authenticated

  def new
    @filter = Filter.new

    render :filter_edit, :layout => false
  end

  def edit
    @filter = Filter.get(params[:id])

    render :filter_edit, :layout => false
  end

  def save
    if params[:id].to_i.zero?
      filter = Model::Filter.new
    else
      filter = Model::Filter.first(:id => params[:id])
    end
    
    filter_data = params["filter"]
    
    filter.user_id = session.user.id
    filter.exec_no = next_filter_no
    filter.name = filter_data[:name]
    filter.target = filter_data[:target]
    filter.keyword = filter_data[:keyword]
    filter.save!
    ""
  end

  def delete
    transaction do
      filter = Filter.get(params[:id])
      filter.destroy

      mails = Mail.all(:filter_id => params[:id] )
      mails.update!(:filter_id => 0)
    end

    ""
  end

  def do_filter
    Mail.all(:filter_id => 0).each do |mail|
      tmail = TMail::Mail.parse(mail.data)
      new_filter_id = Filter.filter_id(tmail, session.user.id)


      if mail.filter_id == new_filter_id
        next
      end

      mail.filter_id = new_filter_id
      mail.save!

      Merb.logger.debug("filter exected(new filter => #{mail.filter_id})")
    end

    Filter.update_mail_count(session.user.id)

    ""
  end

  def readed_all
    filter_id = params[:id]
    mails = Mail.all(:filter_id => filter_id)

    mails.each do |mail|
      unless mail.readed?
        mail.readed = true
        mail.save
      end
    end

    ""
  end

  private

  def next_filter_no
    filter = Model::Filter.first(:user_id => session.user.id,
                                 :order => [:exec_no.desc])
    if filter.nil?
      return 1
    end

    return filter.exec_no + 1
  end
end
