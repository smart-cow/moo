
## Controllers ##
angular.module "moo.start-workflow.controllers", [ ]


.controller "StartWorkflowCtrl", [
    "$scope", "Workflows"
    ($scope, Workflows) ->
        $scope.workflows = Workflows.query()

]

