

(function() {
  function B(D) {
    var C = function() {
    };
    C.prototype = D;
    return C
  }

  var A = scheduler._load;
  scheduler._load = function(C, F) {
    C = C || this._load_url;
    if (typeof C == "object") {
      var E = B(this._loaded);
      for (var D = 0; D < C.length; D++) {
        this._loaded = new E();
        A.call(this, C[D], F)
      }
    } else {
      A.apply(this, arguments)
    }
  }
})();