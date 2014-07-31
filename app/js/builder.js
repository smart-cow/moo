// Generated by CoffeeScript 1.7.1
(function() {
  angular.module("moo.builder.controllers", ["moo.builder.directives"]).controller("WorkflowBuilderCtrl", [
    "$scope", "$routeParams", "$timeout", "Workflows", function($scope, $routeParams, $timeout, Workflows) {
      var retrySave;
      $scope.workflowName = $routeParams.wflowName;
      $scope.conflicts = Workflows.instances($scope.workflowName);
      $scope.$on("moo.conflicts.stopped", function() {
        return $scope.conflicts = Workflows.instances($scope.workflowName);
      });
      retrySave = null;
      $scope.$on("moo.conflicts.retry", function() {
        console.log("retry");
        if (typeof retrySave === "function") {
          retrySave();
        }
        return $("#conflicts-modal").modal("hide");
      });
      return $scope.$on("moo.workflow.save.error.409", function(evt, data) {
        console.log("409: %o", arguments);
        $scope.conflicts = data.instances;
        $scope.workflowName = data.name;
        retrySave = data.retry;
        return $("#conflicts-modal").modal("show");
      });
    }
  ]);

  angular.module("moo.builder.directives", []).directive("mooConflictingInstances", [
    function() {
      return {
        restrict: "E",
        templateUrl: "partials/builder/conflicts-list.html",
        scope: {
          wflowName: "=",
          conflicts: "="
        }
      };
    }
  ]).directive("mooStopConflicts", [
    "Workflows", function(Workflows) {
      return {
        restrict: "A",
        scope: {
          wflowName: "=mooStopConflicts",
          retry: "=?"
        },
        link: function($scope, element) {
          return element.bind("click", function() {
            return Workflows.deleteInstances($scope.wflowName, function() {
              $scope.$emit("moo.conflicts.stopped", $scope.wflowName);
              return $scope.$emit("moo.conflicts.retry");
            });
          });
        }
      };
    }
  ]);

}).call(this);

//# sourceMappingURL=builder.map
