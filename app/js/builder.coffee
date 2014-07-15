
## Controllers ##
angular.module "moo.builder.controllers", [
]

.controller "WorkflowBuilderCtrl", [
    "$scope", "$routeParams", "Processes"
    ($scope, $routeParams, Processes) ->
        $scope.workflowName = $routeParams.wflowName
]


