// Generated by CoffeeScript 1.7.1
(function() {
  angular.module("moo.directives", []).directive("mooNavMenu", [
    "$route", "areas", function($route, areas) {
      return {
        restrict: "E",
        templateUrl: "partials/nav-menu.html",
        link: function($scope) {
          var area;
          $scope.tabs = (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = areas.length; _i < _len; _i++) {
              area = areas[_i];
              _results.push({
                title: area.name,
                url: "#" + area.defaultRoute.url,
                selected: area.name === $route.current.provide.area
              });
            }
            return _results;
          })();
          return $scope.$on("$routeChangeSuccess", function(evt, newRoute) {
            var tab, _i, _len, _ref, _results;
            _ref = $scope.tabs;
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              tab = _ref[_i];
              _results.push(tab.selected = tab.title === newRoute.provide.area);
            }
            return _results;
          });
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
          return $scope.caption = "Your Tasks";
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
          return $scope.caption = "Available Tasks";
        }
      };
    }
  ]).directive("mooTaskDetails", [
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
  ]).directive("mooEditableVariables", [
    function() {
      return {
        restrict: "E",
        templateUrl: "partials/editable-variables.html",
        scope: {
          variables: "="
        }
      };
    }
  ]).directive("mooReadOnlyVariables", [
    function() {
      return {
        restrict: "E",
        templateUrl: "partials/read-only-variables.html",
        scope: {
          variables: "="
        }
      };
    }
  ]).directive("mooCompleteTaskButton", [
    "Task", function(Task) {
      return {
        restrict: "A",
        scope: {
          task: "="
        },
        link: function($scope, element) {
          return element.bind("click", function() {
            return Task.complete($scope.task);
          });
        }
      };
    }
  ]).directive("mooTakeTaskButton", [
    "Task", function(Task) {
      return {
        restrict: "A",
        scope: {
          task: "="
        },
        link: function($scope, element) {
          return element.bind("click", function() {
            return Task.take($scope.task);
          });
        }
      };
    }
  ]);

}).call(this);

//# sourceMappingURL=directives.map
