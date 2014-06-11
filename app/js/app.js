'use strict';


// Declare app level module which depends on filters, and services
var app = angular.module('scow', [
  'ngRoute',
  'ngResource',
  'scow.filters',
  'scow.services',
  'scow.directives',
  'scow.controllers'
]);

app.config(['$routeProvider', function($routeProvider) {
  $routeProvider.when("/tasks", {
      templateUrl: "partials/task-list.html",
      controller: "TaskListCtrl"
  });
  $routeProvider.when("/tasks/:taskId", {
      templateUrl: "partials/task-detail.html",
      controller: "TaskDetailCtrl"
  });
  $routeProvider.otherwise({redirectTo: '/tasks'});
}]);

/* Scow requires basic auth */
app.config(["$httpProvider", function($httpProvider) {
    $httpProvider.defaults.withCredentials = true;
}]);