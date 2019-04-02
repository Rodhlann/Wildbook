(function (global, factory) {
  if (typeof define === "function" && define.amd) {
    define([], factory);
  } else if (typeof exports !== "undefined") {
    factory();
  } else {
    var mod = {
      exports: {}
    };
    factory();
    global.bootstrapTableI18nEnhance = mod.exports;
  }
})(this, function () {
  'use strict';

  /**
   * @author: Jewway
   * @version: v1.0.0
   */

  !function ($) {
    'use strict';

    var BootstrapTable = $.fn.bootstrapTable.Constructor;

    BootstrapTable.prototype.changeTitle = function (locale) {
      $.each(this.options.columns, function (idx, columnList) {
        $.each(columnList, function (idx, column) {
          if (column.field) {
            column.title = locale[column.field];
          }
        });
      });
      this.initHeader();
      this.initBody();
      this.initToolbar();
    };

    BootstrapTable.prototype.changeLocale = function (localeId) {
      this.options.locale = localeId;
      this.initLocale();
      this.initPagination();
      this.initBody();
      this.initToolbar();
    };

    $.fn.bootstrapTable.methods.push('changeTitle');
    $.fn.bootstrapTable.methods.push('changeLocale');
  }(jQuery);
});