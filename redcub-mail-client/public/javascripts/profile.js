
function Profile() {
  this.showID = "";
}

Profile.prototype.save = function(id) {
  param = $(id).serialize();
  var showID = this.showID;

  $.post("/profile/save", param, 
	 function(data, state) {
	   $(profile.showID).load("/profile");
	 });  
}

Profile.prototype.changeEditMode = function(id) {
  this.showID = id;
  $(id).load("/profile/edit");
}

profile = new Profile
