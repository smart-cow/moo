// Generated by CoffeeScript 1.7.1
(function() {
  angular.module("moo.admin.controllers", []).controller("AdminCtrl", [
    "$scope", "$q", "RunningWorkflows", "Workflows", function($scope, $q, RunningWorkflows, Workflows) {
      var getWorkflowInfo;
      $scope.workflows = {
        instances: [],
        types: []
      };
      $scope.selectedWorkflowInstance = null;
      $scope.deleteWorkflowInstance = function() {
        var wfId;
        wfId = $scope.selectedWorkflowInstance.id;
        return RunningWorkflows["delete"](wfId, getWorkflowInfo);
      };
      $scope.selectedWorkflowType = null;
      $scope.deleteWorkflowType = function() {
        return Workflows.deleteInstances($scope.selectedWorkflowType, getWorkflowInfo);
      };
      $scope.deleteAllWorkflows = function() {
        var promises, types, wflow;
        types = $scope.workflows.types;
        promises = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = types.length; _i < _len; _i++) {
            wflow = types[_i];
            _results.push(RunningWorkflows.deleteAllInstancesOfType(wflow).$promise);
          }
          return _results;
        })();
        return $q.all(promises).then(function() {
          return getWorkflowInfo();
        });
      };
      getWorkflowInfo = function() {
        $scope.workflows.instances = RunningWorkflows.query();
        return $scope.workflows.instances.$promise.then(function(data) {
          var workflow;
          return $scope.workflows.types = ((function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = data.length; _i < _len; _i++) {
              workflow = data[_i];
              _results.push(workflow.key);
            }
            return _results;
          })()).m$unique();
        });
      };
      return getWorkflowInfo();
    }
  ]);

}).call(this);

//# sourceMappingURL=admin.map
