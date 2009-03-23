
function Mailer(){
  this.headerDisplayFlags = new Object;
  this.targetMailState = [0, 1];
  this.filter = "";
  this.selectedMailbox = "mailbox-name";
}

/* displayHeader : メールのヘッダを表示する。 */
Mailer.prototype.displayHeader = function(mailID) {
  id = "#header-field-" + mailID;

  if (this.headerDisplayFlags.mailID == undefined) {
    this.headerDisplayFlags.mailID = 0;
  }

  
  if (this.headerDisplayFlags.mailID == 0) {
    $(id).css("display", "block");
    this.headerDisplayFlags.mailID = 1;
  }else{
    $(id).css("display", "none");
    this.headerDisplayFlags.mailID = 0;
  }
}

Mailer.prototype.updateMailList = function(filterName, state, id) {
  
  /*** set default value if undefined***/
  if (filterName == undefined){filterName = this.filter;}
  this.filter = filterName;

  if (state == undefined){state = this.targetMailState;}
  this.targetMailState = state;

  if (id == undefined) {id = this.selectedMailbox;}
  this.selectedMailbox = id;

  /*** selected mailbox set css class value mailbox-name-selected ***/
  var mailBoxList = util.findID("mailbox-name");
  for (i = 0; i < mailBoxList.length; i++) {
    $("#" + mailBoxList[i]).removeClass("mailbox-name-selected"); 
  }
  $("#" + id).addClass("mailbox-name-selected");

  /*** toggle bottom for yet readed mail only ***/
  if (state.join(",") == "0") {
    $("#all-read-bottom").css("display", "block");
    $("#yet-read-bottom").css("display", "none")
  }else{
    $("#all-read-bottom").css("display", "none");
    $("#yet-read-bottom").css("display", "block")
  }

  $("#mailList").load("/show/list_ajax/" + filterName, 
                      {state : state.join(",")})
}

Mailer.prototype.deleteMail = function(mailID) {
  $.post("/show/delete/" + mailID, {}, function() {
      alert("削除しました");
      mailer.updateMailList();}
      );
}

Mailer.prototype.returnMail = function(mailID) {
  $("#mailview").load("/edit/return_mail/" + mailID)
}

Mailer.prototype.sendmail = function(id) {
  var param = $("#" + id).serialize();
  $.post("/edit/sendmail", param, function() {alert("送信しました")});
}

  Mailer.prototype.createNewFilter = function(id, url, thumbnailID) {
  var obj = document.getElementById(id);
  obj.href = url;

  if (thumbnailID == undefined){thumbnailID = id}

  return hs.htmlExpand(obj, {objectType: 'ajax',
	                      cacheAjax: false,
 	                      preservedContent: false,
	                      width: 370,
	                      height: 260,
	                      thumbnailID: thumbnailID})
}

var mailer = new Mailer;
