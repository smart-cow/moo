// Generated by CoffeeScript 1.7.1
(function() {
  angular.module("moo.tasks.controllers", ["moo.tasks.directives", "moo.cow.web-service"]).controller("TaskListCtrl", [
    "$scope", "Tasks", function($scope, Tasks) {
      var userTasks;
      userTasks = Tasks.userTaskInfo;
      $scope.myTasks = userTasks.myTasks;
      return $scope.availableTasks = userTasks.availableTasks;
    }
  ]).controller("TaskDetailCtrl", [
    "$scope", "$routeParams", "Tasks", function($scope, $routeParams, Tasks) {
      return $scope.task = Tasks.find($routeParams.taskId);
    }
  ]);

  angular.module("moo.tasks.directives", ["moo.cow.web-service"]).directive("mooTaskDetails", [
    function() {
      return {
        restrict: "E",
        templateUrl: "partials/tasks/task-detail.html",
        scope: {
          task: "=",
          canComplete: "="
        }
      };
    }
  ]).directive("mooAssignedTasksTable", [
    function() {
      return {
        restrict: "E",
        templateUrl: "partials/tasks/task-table.html",
        scope: {
          tasks: "="
        },
        link: function($scope) {
          $scope.canAssignTasks = false;
          $scope.canCompleteTasks = true;
          $scope.caption = "Your Tasks";
          return $scope.idToInt = function(task) {
            return +task.id;
          };
        }
      };
    }
  ]).directive("mooAvailableTasksTable", [
    function() {
      return {
        restrict: "E",
        templateUrl: "partials/tasks/task-table.html",
        scope: {
          tasks: "="
        },
        link: function($scope) {
          $scope.canAssignTasks = true;
          $scope.canCompleteTasks = false;
          $scope.caption = "Available Tasks";
          return $scope.idToInt = function(task) {
            return +task.id;
          };
        }
      };
    }
  ]).directive("mooTaskHistory", [
    "Tasks", function(Tasks) {
      return {
        restrict: "E",
        templateUrl: "partials/tasks/task-history.html",
        scope: {},
        link: function($scope) {
          $scope.historyShown = false;
          $scope.showHistory = function() {
            $scope.historyShown = true;
            return $scope.historyTasks = Tasks.historyTasks();
          };
          return $scope.hideHistory = function() {
            $scope.historyShown = false;
            return $scope.historyTasks = [];
          };
        }
      };
    }
  ]).directive("mooCompleteTaskButton", [
    "Tasks", function(Tasks) {
      return {
        restrict: "A",
        scope: {
          task: "="
        },
        link: function($scope, element) {
          return element.bind("click", function() {
            return Tasks.complete($scope.task);
          });
        }
      };
    }
  ]).directive("mooTakeTaskButton", [
    "Tasks", function(Tasks) {
      return {
        restrict: "A",
        scope: {
          task: "="
        },
        link: function($scope, element) {
          return element.bind("click", function() {
            return Tasks.take($scope.task);
          });
        }
      };
    }
  ]);

}).call(this);

//# sourceMappingURL=tasks.map
