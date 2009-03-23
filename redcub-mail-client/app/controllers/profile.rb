class Profile < Application
  include RedCub
  include Model

  before :ensure_authenticated

  def index
    @user = User.first(:id => session.user.id)
    render :layout => false
  end

  def edit
    @user = User.first(:id => session.user.id)
    render :layout => false
  end

  def save
    profile = params["red_cub::model::user"]
    @user = User.first(:id => session.user.id)
    @user.name = @user.name
    @user.person_name = profile[:person_name]
    @user.mailaddress = profile[:mailaddress]

    if !profile[:password].nil?
      @user.password = @user.password_confirmation = profile[:password]
    end

    @user.save

    redirect :index
  end
end
