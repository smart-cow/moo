## Controllers ##
angular.module "moo.active-workflows.controllers", []

.controller "ActiveWorkflowsCtrl", [
    "$scope", "RunningWorkflows"
    ($scope, RunningWorkflows) ->
        $scope.statuses = RunningWorkflows.getStatuses()
]


