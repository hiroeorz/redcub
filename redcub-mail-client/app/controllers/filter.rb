class Filter < Application

  def new
    @filter = RedCub::Model::Filter.new

    render :filter_edit, :layout => false
  end


  def save

  end
end
