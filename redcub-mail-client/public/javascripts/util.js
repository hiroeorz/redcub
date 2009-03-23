function Util(){}

Util.prototype.findID = function(idParts) {
  objDiv = document.getElementsByTagName("div");

  objRegex = new RegExp(idParts);

  var idArray = [];

  for (i = 0; i < objDiv.length; i++) {
    if (objDiv[i].id.match(objRegex)) {
      idArray.push(objDiv[i].id);
    }
  }

  return idArray;
}

var util = new Util;
