/*
  popupmenu.js - simple JavaScript popup menu library.

  Copyright (C) 2008 Jiro Nishiguchi <jiro@cpan.org> All rights reserved.
  This is free software with ABSOLUTELY NO WARRANTY.

  You can redistribute it and/or modify it under the modified BSD license.

  Usage:
    var popup = new PopupMenu();
    popup.add(menuText, function(target){ ... });
    popup.addSeparator();
    popup.bind('targetElement');
    popup.bind(); // target is document;
*/
var PopupMenu = function() {
    this.init();
}
PopupMenu.SEPARATOR = 'PopupMenu.SEPARATOR';
PopupMenu.current = null;
PopupMenu.addEventListener = function(element, name, observer, capture) {
    if (typeof element == 'string') {
        element = document.getElementById(element);
    }
    if (element.addEventListener) {
        element.addEventListener(name, observer, capture);
    } else if (element.attachEvent) {
        element.attachEvent('on' + name, observer);
    }
};
PopupMenu.prototype = {
 init: function() {
    this.items  = [];
    this.width  = 0;
    this.height = 0;
  },
 setSize: function(width, height) {
    this.width  = width;
    this.height = height;
    if (this.element) {
      var self = this;
      with (this.element.style) {
	if (self.width)  width  = self.width  + 'px';
	if (self.height) height = self.height + 'px';
      }
    }
  },
 bind: function(element) {
    var self = this;
    
    if (!element) {
      element = document;
    } else if (typeof element == 'string') {
      element = document.getElementById(element);
    }
    this.target = element;
    this.target.oncontextmenu = function(e) {
      self.show.call(self, e);
      return false;
    };
    var listener = function() { self.hide.call(self) };
    PopupMenu.addEventListener(document, 'click', listener, true);
  },
 add: function(text, callback) {
    this.items.push({ text: text, callback: callback });
  },
 addSeparator: function() {
    this.items.push(PopupMenu.SEPARATOR);
  },
 setPos: function(e) {
    if (!this.element) return;
    if (!e) e = window.event;
    var x, y;
    if (window.opera) {
      x = e.clientX;
      y = e.clientY;
    } else if (document.all) {
      x = document.body.scrollLeft + event.clientX;
      y = document.body.scrollTop + event.clientY;
    } else if (document.layers || document.getElementById) {
      x = e.pageX;
      y = e.pageY;
    }
    this.element.style.top  = y + 'px';
    this.element.style.left = x + 'px';
  },
 show: function(e) {
    if (PopupMenu.current && PopupMenu.current != this) return;
    PopupMenu.current = this;
    if (this.element) {
      this.setPos(e);
      this.element.style.display = '';
    } else {
      this.element = this.createMenu(this.items);
      this.setPos(e);
      document.body.appendChild(this.element);
    }
  },
 hide: function() {
    PopupMenu.current = null;
    if (this.element) this.element.style.display = 'none';
  },
 createMenu: function(items) {
        var self = this;
        var menu = document.createElement('div');
        with (menu.style) {
	  if (self.width)  width  = self.width  + 'px';
	  if (self.height) height = self.height + 'px';
	  border     = "1px solid gray";
	  background = '#FFFFFF';
	  color      = '#000000';
	  position   = 'absolute';
	  display    = 'block';
	  padding    = '2px';
	  cursor     = 'default';
        }
        for (var i = 0; i < items.length; i++) {
	  var item;
	  if (items[i] == PopupMenu.SEPARATOR) {
	    item = this.createSeparator();
	  } else {
	    item = this.createItem(items[i]);
	  }
	  menu.appendChild(item);
        }
        return menu;
  },
 createItem: function(item) {
    var self = this;
    var elem = document.createElement('div');
    elem.style.padding = '4px';
    var callback = item.callback;
    PopupMenu.addEventListener(elem, 'click', function(_callback) {
	return function() {
	  self.hide();
	  _callback(self.target);
	};
      }(callback), true);
    PopupMenu.addEventListener(elem, 'mouseover', function(e) {
	elem.style.background = '#B6BDD2';
      }, true);
    PopupMenu.addEventListener(elem, 'mouseout', function(e) {
	elem.style.background = '#FFFFFF';
      }, true);
    elem.appendChild(document.createTextNode(item.text));
    return elem;
  },
 createSeparator: function() {
    var sep = document.createElement('div');
    with (sep.style) {
      borderTop = '1px dotted #CCCCCC';
      fontSize  = '0px';
      height    = '0px';
    }
    return sep;
  },
};


var RightClickMenu = function() {
    this.init();
}

RightClickMenu.prototype = {
 init: function() {
    var boxList = util.findID("mailbox-name-");
    
    for(i = 0; i < boxList.length + 1; i++) {
      var boxListMenu = new PopupMenu();

      boxListMenu.add("設定", 
		      function(target) {
			var filter_id = $("#" + target.id).attr("filter_id");
			return filter.edit(target.id, 
					   '/mail_filter/edit/' + filter_id)});
    
      boxListMenu.add("新しいフィルタを追加", 
		      function(target) {
			return filter.edit('mailbox-name', 
					   '/mail_filter/new')});
    
      boxListMenu.add("全て既読に", 
		      function(target) {
			var filter_id = $("#" + target.id).attr("filter_id");
			return mailer.readedAll(filter_id)});

      boxListMenu.add("削除",  
		  function(target) {
		    return filter.del(target.id) });

      boxListMenu.bind(boxList[i]);
    }
    
    var boxMenu = new PopupMenu();
    boxMenu.add("設定", 
		function(target) {filter.modify(target.id)});
    
    boxMenu.add("新しいフィルタを追加", 
		function(target) {
		  return filter.edit('mailbox-name', '/mail_filter/new')});

    boxMenu.add("全て既読に", 
		function(target) {return mailer.readedAll(0)});   
    
    boxMenu.add("フィルタを実行", 
		function(target) {
		  return filter.doFilter(); });

    boxMenu.bind("mailbox-name")

    
    var mailList = util.findID("maillist-");

    for (i = 0; i < mailList.length; i++) {
      var maillistMenu = new PopupMenu();
      maillistMenu.add("返信", 
		       function(target) {mailer.returnMailByID(target.id)});
      
      maillistMenu.add("削除", 
		       function(target) {mailer.deleteMailByID(target.id)});

      maillistMenu.add("スパムを報告する", 
		       function(target) {mailer.addBlackList(target.id)});

      maillistMenu.add("無実を報告する", 
		       function(target) {mailer.addWhiteList(target.id)});

      maillistMenu.bind(mailList[i]);
      }  
    
    var trashMenu = new PopupMenu();
    trashMenu.add("ごみ箱を空にする", function(target) {mailer.clearTrash()});
    
    trashMenu.bind("mailbox-name-trash");
  }
}
