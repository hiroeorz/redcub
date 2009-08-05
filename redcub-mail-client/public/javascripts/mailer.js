
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
    
    $("#mail-list").load(root_url + "/show/list_ajax/" + 
			 filterID + "/" + pageNo, 
                        {state : state.join(",")},
			function(){new RightClickMenu();});
  },

 deleteMail: function(mailID) {
    var divObj = $("#maillist-" + mailID)
    
    $.post(root_url + "/show/delete/" + mailID, {}, function(data, state) {
	divObj.hide("first");
      }
      );
  },
 
 deleteMailByID: function(id) {
    var mail_id = $("#" + id).attr("mail_id");
    this.deleteMail(mail_id);
  },

 addBlackList: function(id) {
    var mail_id = $("#" + id).attr("mail_id");
    $.post(root_url + "/bsfilter/black/" + mail_id, {},
	   function() {alert("スパムを報告しました");});

    if (this.filterID != -3) {
      $("#" + id).hide("first");
    }
  },

 addWhiteList: function(id) {
    var mail_id = $("#" + id).attr("mail_id");
    $.post(root_url + "/bsfilter/white/" + mail_id, {},
	   function() {alert("無実を報告しました");});

    if (this.filterID == -3) {
      $("#" + id).hide("first");
    }
  },

 returnMail: function(mailID) {
    $("#mailview").load(root_url + "/edit/return_mail/" + mailID)
  },

 returnMailByID: function(id) {
    var mail_id = $("#" + id).attr("mail_id");
    this.returnMail(mailID);
  },

 updateBoxList: function() {
    $("#mailbox-list").load(root_url + "/show/boxlist", {}, 
			    function(){new RightClickMenu()});
  },

 clearTrash: function() {
    var filterID = this.filterID;
    
    $.post(root_url + "/show/cleartrash", {}, 
	   function(data, state) {
	     if (filterID == -1) {mailer.updateMailList();}
	     new RightClickMenu();
	   });
  },
 
 sendmail: function(id) {
    var params = $("#" + id).serialize();

    $.post(root_url + "/edit/sendmail", params, 
	   function(data, state){
	     alert("メールを送信しました。");
	   })
  },

 readedAll: function(filter_id) {
    if (filter_id == undefined) {filter_id = this.filter_id}

    $.post(root_url + "/mail_filter/readed_all/" + filter_id, {},
	   function() {
	     mailer.updateBoxList();
	     mailer.updateMailList();
	   });
  }
}

var mailer = new Mailer;
