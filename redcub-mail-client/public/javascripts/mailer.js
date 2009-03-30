
function Mailer(){
}

var Mailer = function() {
  this.init();
};

Mailer.prototype = {

 init: function() {
  this.headerDisplayFlags = new Object;
  this.targetMailState = [0, 1];
  this.filterID = 0;
  this.selectedMailbox = "mailbox-name";
  this.pageNo = 1;
  },

/* displayHeader : メールのヘッダを表示する。 */
 displayHeader: function(mailID) {
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
  },

 updateMailList: function(filterID, state, id, pageNo) {
    
    /*** set default value if undefined***/
    if (filterID == undefined){filterID = this.filterID;}
    this.filterID = filterID;
    
    if (state == undefined){state = this.targetMailState;}
    this.targetMailState = state;
    
    if (id == undefined) {id = this.selectedMailbox;}
    this.selectedMailbox = id;

    if (pageNo == undefined) {pageNo = this.pageNo;}
    this.pageNo = pageNo;
    
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
    
    $("#mailList").load("/show/list_ajax/" + filterID + "/" + pageNo, 
                        {state : state.join(",")},
			function(){new RightClickMenu();});
  },

 deleteMail: function(mailID) {
    var divObj = $("#maillist-" + mailID)
    
    $.post("/show/delete/" + mailID, {}, function(data, state) {
	divObj.hide("first");
      }
      );
  },
 
 deleteMailByID: function(id) {
    var mail_id = $("#" + id).attr("mail_id");
    this.deleteMail(mail_id);
  },

 returnMail: function(mailID) {
    $("#mailview").load("/edit/return_mail/" + mailID)
  },

 updateBoxList: function() {
    $("#mailbox-list").load("/show/boxlist", {}, 
			    function(){new RightClickMenu()});
  },

 clearTrash: function() {
    var filterID = this.filterID;
    
    $.post("/show/cleartrash", {}, 
	   function(data, state) {
	     if (filterID == -1) {mailer.updateMailList();}
	     new RightClickMenu();
	   });
  }
}

var mailer = new Mailer;
