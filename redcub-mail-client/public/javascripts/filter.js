var Filter = function() {
    this.init();
}

Filter.prototype = {
 init: function() {
  },

 save: function(id) {
    alert(id);
    var param = $(id).serialize();
    alert($(id))

    $.post("/filter/save", param, function(data, state) {
	alert("設定しました");
      })
  },

 delete: function(id) {
    var filter_id = $("#" + id).attr("filter_id");

    $.post("/filter/delete/" + filter_id, {}, function(data, state) {
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
