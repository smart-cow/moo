// Generated by CoffeeScript 1.7.1
(function() {
  angular.module("moo.controllers", []).controller("TaskListCtrl", [
    "$scope", "Task", "User", function($scope, Task, User) {
      $scope.myTasks = Task.assigned(User);
      return $scope.availableTasks = Task.candidate(User);
    }
  ]).controller("TaskDetailCtrl", [
    "$scope", "$routeParams", "Task", function($scope, $routeParams, Task) {
      return $scope.task = Task.find($routeParams.taskId);
    }
  ]).controller("ActiveWorkflowsCtrl", ["$scope", function($scope) {}]);

}).call(this);

//# sourceMappingURL=controllers.map
