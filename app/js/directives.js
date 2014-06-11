'use strict';

/* Directives */

//Example only
angular.module('scow.directives', []).
  directive('appVersion', ['version', function(version) {
    return function(scope, elm, attrs) {
      elm.text(version);
    };
  }]);
