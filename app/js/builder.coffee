
## Controllers ##
angular.module "moo.builder.controllers", [

]

.controller "WorkflowBuilderCtrl", [
    "$scope", "$routeParams"
    ($scope, $routeParams) ->
        $scope.workflowName = $routeParams.wflowName ? "New Workflow"
]