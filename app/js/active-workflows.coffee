## Controllers ##
angular.module "moo.active-workflows.controllers", [
    "moo.active-workflows.services"
    "moo.active-workflows.directives"
]

.controller "ActiveWorkflowsCtrl", [
    "$scope", "WorkflowSummary"
    ($scope, WorkflowSummary) ->

        $scope.workflowSummaries = WorkflowSummary -> console.log("q resolved")

        selectedWorkflows = { }

        $scope.selectWorkflow = (wflowName) ->
            selectedWorkflows[wflowName] ?= false
            selectedWorkflows[wflowName] = !selectedWorkflows[wflowName]

        $scope.isSelected = (wflowName) ->
            selectedWorkflows[wflowName] ? false
]


.controller "ActiveTypesCtrl", [
    "$scope", "$routeParams", "TypeStatuses"
    ($scope, $routeParams, TypeStatuses) ->
        $scope.wflowName = $routeParams.workflowType
        $scope.statuses = TypeStatuses($scope.wflowName)
]

## Services ##
angular.module "moo.active-workflows.services", [

]

.factory "WorkflowSummary", [
    "$rootScope", "$q", "RunningWorkflows", "ScowPush"
    ($rootScope, $q, RunningWorkflows, ScowPush) ->

        wflowsSummary =
            # List of headings required for table
            headings: { }
            # Content of the rows of the table
            workflows: { }


        updateWorkflow = (wflowName) ->
            id = wflowName.m$rightOf(".")
            return RunningWorkflows.status(id, updateStatus)


        statusPriority = [
            "precluded"
            "completed"
            "contingent"
            "planned"
            "notStarted"
            "open"
        ]

        higherPriority = (status1, status2) ->
            index1 = statusPriority.indexOf(status1)
            index2 = statusPriority.indexOf(status2)
            if index1 > index2 then status1 else status2

        # Convert status list to map to get rid of multiple statuses for a user in a single workflow
        convertToMap = (statuses) ->
            # Determine which status to use when duplicates
            statusesMap = { }
            for st in statuses.statuses
                statusesMap[st.name] = higherPriority(st.status, statusesMap[st.name])
            return statusesMap

        nameInOtherWflow = (name) ->
            # foreach status list
            for own wflowName, statuses of wflowsSummary.workflows
                # foreach user in each status whose name matches
                for own user of statuses when user is name
                    # return true as soon as one match is found
                    return true
            return false


        # Add remove headings based on new workflow data
        updateHeadings = (addedNames, removedNames) ->
            for addedName in addedNames
                wflowsSummary.headings[addedName] = true
            headingsToRemove = (nameInOtherWflow(n) for n in removedNames when not nameInOtherWflow(n))
            for heading in headingsToRemove
                delete wflowsSummary.headings[heading]


        updateStatus = (newStatuses) ->
            # Initialize summary to empty object
            wflowsSummary.workflows[newStatuses.name] ?= { }
            existingStatuses = wflowsSummary.workflows[newStatuses.name]

            newStatusesMap = convertToMap(newStatuses)
            addedNames = [ ]
            for own name, status of newStatusesMap
                # Add name to added when it isn't already in the existing status
                unless existingStatuses[name]?
                    addedNames.push(name)
                existingStatuses[name] = status

            # Get names that are no longer in the workflows status summary
            removedNames = [ ]
            for own name of existingStatuses
                unless newStatusesMap[name]?
                    removedNames.push(name)
                    delete existingStatuses[name]
            updateHeadings(addedNames, removedNames)



        deferred = $q.defer()

        RunningWorkflows.query (wflowData) ->
            summaries = (updateWorkflow(w.id) for w in wflowData)
            summariesPromise = $q.all(summaries)
            summariesPromise.then ->
                deferred.resolve(wflowsSummary)

        ScowPush.subscribe "#.tasks.#", (task) ->
            $rootScope.$apply ->
                updateWorkflow(task.processInstanceId)


        return (onLoad = ->) ->
            deferred.promise.then(onLoad)
            return wflowsSummary

#        return wflowsSummary
]

.factory "TypeStatuses", [
    "Workflows", "RunningWorkflows"
    (Workflows, RunningWorkflows) ->


        onStatusReceive = (statusData, instances) ->
            val = { }
            for s in statusData.statuses
                val[s.task] = s.status
            instances[statusData.name] = val

        onInstancesReceive = (instanceData, instances) ->
            for instance in instanceData
                idNum = instance.id.m$rightOf(".")
                RunningWorkflows.status idNum, (statusData) ->
                    onStatusReceive(statusData, instances)


        getStatuses = (type) ->
            instances = { }
            Workflows.instances type, (data) ->
                onInstancesReceive(data, instances)
            return instances

        return getStatuses
]



## Directives ##
angular.module "moo.active-workflows.directives", [ ]


.directive "mooLegend", [
    ->
        restrict: "E"
        templateUrl: "partials/active-workflows/legend.html"
        scope: { }
]

.directive "mooInstanceStatus", [
    ->
        restrict: "E"
        templateUrl: "partials/active-workflows/instance-status.html"
        scope:
            name: "="
            instanceName: "="
            statuses: "="
        link: ($scope, element) ->

            taskToSelector = (task) ->
                return ".activity-element-#{task.replace(" ", "-")}"

            $scope.$on "workflow.tree.loaded.#{$scope.instanceName}", ->
                for own task, status of $scope.statuses
                    elements = element.find(taskToSelector(task))
                    elements.addClass("status-" + status)
]

