class MailFilter < Application
  include RedCub

  def new
    @filter = Filter.new

    render :filter_edit, :layout => false
  end


  def save
    if params[:id].nil?
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
      filter = Model::Filter.first(:id => params[:id])
      filter.destroy

      mails = Model::Mail.all(:filter_id => params[:id])
      mails.update!(:filter_id => 0)
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
