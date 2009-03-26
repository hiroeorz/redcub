class Attachedfile < Application

  def index
    render
  end

  def get
    send_attached_data(params[:id])
  end
end
