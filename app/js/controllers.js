'use strict';

/* Controllers */

var controllers = angular.module('scow.controllers', []);


controllers.controller("TaskListCtrl", ["$scope", "Task",
    function($scope, Task) {
        $scope.tasks = Task.query();
    }
]);


controllers.controller("TaskDetailCtrl", ["$scope", "$routeParams", "Task",
    function($scope, $routeParams, Task) {
        $scope.task = Task.get({id: $routeParams.taskId});
    }
]);

