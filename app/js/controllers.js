// Generated by CoffeeScript 1.7.1
(function() {
  angular.module("moo.controllers", []).controller("TaskListCtrl", [
    "$scope", "Task", function($scope, Task) {
      return $scope.tasks = Task.query();
    }
  ]).controller("TaskDetailCtrl", [
    "$scope", "$routeParams", "Task", function($scope, $routeParams, Task) {
      return $scope.task = Task.get({
        id: $routeParams.taskId
      });
    }
  ]).controller("ActiveWorkflowsCtrl", ["$scope", function($scope) {}]);

}).call(this);

//# sourceMappingURL=controllers.map
