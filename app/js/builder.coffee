
## Controllers ##
angular.module "moo.builder.controllers", [
    "moo.builder.directives"
]

.controller "WorkflowBuilderCtrl", [
    "$scope", "$routeParams", "Workflows"
    ($scope, $routeParams, Workflows) ->

        $scope.workflowName = $routeParams.wflowName ? "NewWorkflow"

        $scope.showWorkflows = false
        $scope.toggleShowWorkflows = ->
            $scope.showWorkflows = not $scope.showWorkflows

        updateConflicts = ->
            return unless $scope.workflowName
            $scope.conflicts = Workflows.instances($scope.workflowName)

        updateConflicts()

        selectingSubProc = false
        $scope.$on "moo.workflow.selected", (evt, wfName) ->
            if selectingSubProc
                console.log("subproc")
                console.log($scope)
                $("#subproc-chooser-modal").modal("hide")
                $scope.$broadcast("moo.subproc.selected", wfName)
                return

            if $scope.showWorkflows
                $scope.workflowName = wfName + "-copy"
                $scope.showWorkflows = false
                data = { wfName: wfName, newName: $scope.workflowName }
                $scope.$broadcast("moo.tree.copy", data)


        # If any of the conflicts is stopped we need to refresh the list of conflicts
        $scope.$on "moo.conflicts.stopped", ->
            updateConflicts()


        # Hold on to the retry function. If the stop instances button is clicked we want
        # to try to save the workflow again
        retrySave = null
        $scope.$on "moo.conflicts.retry", ->
            console.log("retry")
            retrySave?()
            $("#conflicts-modal").modal("hide")

        # If a user tries to save a workflow while there are running instances, the server responds
        # with a 409 and contains the conflicting instances
        $scope.$on "moo.workflow.save.error.409", (evt, data) ->
            console.log("409: %o", arguments)
            $scope.conflicts = data.instances
            $scope.workflowName = data.name
            retrySave = data.retry
            $("#conflicts-modal").modal("show")


        $scope.$on "moo.builder.show-chooser", ->
            selectingSubProc = true
            console.log("show chooser")
            $("#subproc-chooser-modal").modal("show")

        $("#subproc-chooser-modal").on "hide.bs.modal", ->
            selectingSubProc = false



]



## Directives ##
angular.module "moo.builder.directives", []

.directive "mooConflictingInstances", [
     ->
        restrict: "E"
        templateUrl: "partials/builder/conflicts-list.html"
        scope:
            wflowName: "="
            conflicts: "="
]



.directive "mooStopConflicts", [
    "Workflows"
    (Workflows) ->
        restrict: "A"
        scope:
            wflowName: "=mooStopConflicts"
            retry: "=?"
        link: ($scope, element) ->
            element.bind "click", ->
                Workflows.deleteInstances $scope.wflowName, ->
                    $scope.$emit("moo.conflicts.stopped", $scope.wflowName)
                    # If clicked in modal, we should try to save it again
                    $scope.$emit("moo.conflicts.retry")
]
