
## Controllers ##
angular.module "moo.start-workflow.controllers", [

]



.controller "StartWorkflowCtrl", [
    "$scope", "$location", "$compile", "Workflows", "RunningWorkflows"
    ($scope, $location, $compile, Workflows, RunningWorkflows) ->


        $scope.selectedWorkflow = null;
        $scope.wflowVars = { }

        showVariablesModal = ->
            $("#variables-modal").modal("show")

        hideVariablesModal = ->
            $("#variables-modal").modal("hide")

        showSuccessModal = ->
            $("#success-modal").modal("show")

        hideSuccessModal = (callBack) ->
            console.log("hide")
            if callBack?
                $("#success-modal").on("hidden.bs.modal", callBack)
            $("#success-modal").modal("hide")
            return true


        $scope.$on "moo.workflow.selected", (evt, wfName) ->
            $scope.selectedWorkflow = wfName
            if $scope.wflowVars[wfName]?
                showVariablesModal()
            else
                Workflows.get wfName, (workflow) ->
                    $scope.wflowVars[wfName] = workflow.variables
                    showVariablesModal()
            return null


        $scope.selectedWflowVariables = ->
            return $scope.wflowVars[$scope.selectedWorkflow]


        # Need to wait for modal to fully disappear before leaving the page
        $scope.viewProgress = ->
            hideSuccessModal ->
                $scope.$apply ->
                    $location.path("/workflows/active-by-type/" + $scope.selectedWorkflow)



        $scope.startWorkflow = ->
            # Capture selected, in case the user click on something else while loading
            wflowName = $scope.selectedWorkflow
            variables = $scope.wflowVars[wflowName]
            onSuccess = (data) ->
                $scope.workflowInstanceId = data.key
                hideVariablesModal()
                showSuccessModal()
            onFailure = ->
                alert("Error: #{wflowName} has NOT been started")

            RunningWorkflows.start(wflowName, variables, onSuccess, onFailure)
]