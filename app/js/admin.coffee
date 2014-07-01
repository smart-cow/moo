
## Controllers ##
angular.module "moo.admin.controllers", [

]

.controller "AdminCtrl", [
    "$scope", "$q", "RunningWorkflows"
    ($scope, $q, RunningWorkflows) ->
        # TODO: Disable form while updating

        $scope.workflows =
            instances: [ ]
            types: [ ]


        $scope.selectedWorkflowInstance = null
        $scope.deleteWorkflowInstance = ->
            console.log("controller")
            RunningWorkflows.deleteInstance($scope.selectedWorkflowInstance.id).$promise.then ->
                getWorkflowInfo()

        $scope.selectedWorkflowType = null
        $scope.deleteWorkflowType = ->
            RunningWorkflows.deleteAllInstancesOfType($scope.selectedWorkflowType).$promise.then ->
                getWorkflowInfo()

        $scope.deleteAllWorkflows = ->
            promises = (RunningWorkflows.deleteAllInstancesOfType(wflow).$promise for wflow in types)
            # Refresh data after all workflows have been deleted
            $q.all(promises).then ->
                getWorkflowInfo()

        getWorkflowInfo = ->
            $scope.workflows.instances = RunningWorkflows.workflows()

            $scope.workflows.instances.$promise.then (data) ->
                $scope.workflows.types = new Set(workflow.key for workflow in data)
#                $scope.workflows.types = (workflow.key for workflow in data).m$unique()
        getWorkflowInfo()

]
