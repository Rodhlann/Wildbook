

scheduler.attachEvent("onTemplatesReady", function() {
  var B = document.body.getElementsByTagName("DIV");
  for (var A = 0; A < B.length; A++) {
    var C = B[A].className || "";
    C = C.split(":");
    if (C.length == 2 && C[0] == "template") {
      var D = 'return "' + (B[A].innerHTML || "").replace(/\"/g, '\\"').replace(/[\n\r]+/g, "") + '";';
      D = unescape(D).replace(/\{event\.([a-z]+)\}/g, function(F, E) {
        return'"+ev.' + E + '+"'
      });
      scheduler.templates[C[1]] = Function("start", "end", "ev", D);
      B[A].style.display = "none"
    }
  }
});