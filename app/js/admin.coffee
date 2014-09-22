
## Controllers ##
angular.module "moo.admin.controllers", [
    "moo.directives"
]

.controller "AdminCtrl", [
    "$scope", "$q", "RunningWorkflows", "Workflows"
    ($scope, $q, RunningWorkflows, Workflows) ->
        # TODO: Disable form while updating

        $scope.workflows =
            instances: [ ]
            types: [ ]


        $scope.selectedWorkflowInstance = null
        $scope.deleteWorkflowInstance = ->
            wfId = $scope.selectedWorkflowInstance.id;
            RunningWorkflows.delete(wfId, getWorkflowInfo)

        $scope.selectedWorkflowType = null
        $scope.deleteWorkflowType = ->
            Workflows.deleteInstances($scope.selectedWorkflowType, getWorkflowInfo)

        $scope.deleteAllWorkflows = ->
            types = $scope.workflows.types
            promises = (RunningWorkflows.deleteAllInstancesOfType(wflow).$promise for wflow in types)
            # Refresh data after all workflows have been deleted
            $q.all(promises).then ->
                getWorkflowInfo()

        getWorkflowInfo = ->
            $scope.workflows.instances = RunningWorkflows.query()

            $scope.workflows.instances.$promise.then (data) ->
                $scope.workflows.types = (workflow.key for workflow in data).m$unique()
        getWorkflowInfo()

]
