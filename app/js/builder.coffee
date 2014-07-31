
## Controllers ##
angular.module "moo.builder.controllers", [
    "moo.builder.directives"
]

.controller "WorkflowBuilderCtrl", [
    "$scope", "$routeParams", "$timeout", "Workflows"
    ($scope, $routeParams, $timeout, Workflows) ->
        $scope.workflowName = $routeParams.wflowName



        $scope.conflicts = Workflows.instances($scope.workflowName)



        # If any of the conflicts is stopped we need to refresh the list of conflicts
        $scope.$on "moo.conflicts.stopped", ->
            $scope.conflicts = Workflows.instances($scope.workflowName)

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
