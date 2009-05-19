var Filter = function() {
    this.init();
}

Filter.prototype = {
 init: function() {
  },

 save: function(id) {
    var param = $(id).serialize();
    var url = $("#filter-id").attr("action");

    $.post(url, param,
	   function(data, state) {
	     alert("設定しました");
	     mailer.updateBoxList();
	   })
  },

 del: function(id) {
    var filter_id = $("#" + id).attr("filter_id");

    $.post("/mail_filter/delete/" + filter_id, {},
	   function(data, state) {
	     alert("削除しました");
	     mailer.updateBoxList();
	   });
  },

 edit: function(id, url, thumbnailID) {
    var obj = document.getElementById(id);
    obj.href = url;
    
    if (thumbnailID == undefined){thumbnailID = id}
    
    return hs.htmlExpand(obj, {objectType: 'ajax',
	  cacheAjax: false,
	  preservedContent: false,
	  width: 370,
	  height: 260,
	  align: "center",
	  thumbnailID: thumbnailID});
  },

 doFilter: function() {
    $.post("/mail_filter/do_filter", {},
	   function(data, state) {
	     alert("フィルタを実行しました。");
	     mailer.updateMailList();
	     mailer.updateBoxList();
	   });
  }
}

  var filter = new Filter();
