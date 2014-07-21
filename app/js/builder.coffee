
## Controllers ##
angular.module "moo.builder.controllers", [
]

.controller "WorkflowBuilderCtrl", [
    "$scope", "$routeParams", "RunningWorkflows"
    ($scope, $routeParams, RunningWorkflows) ->
        $scope.workflowName = $routeParams.wflowName

]


