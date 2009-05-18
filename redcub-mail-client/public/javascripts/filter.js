var Filter = function() {
    this.init();
}

Filter.prototype = {
 init: function() {
  },

 save: function(id) {
    var param = $(id).serialize();

    $.post("/mail_filter/save", param,
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

 create: function(id, url, thumbnailID) {
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
  }
}

  var filter = new Filter();
