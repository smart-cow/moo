## Controllers ##
angular.module "moo.active-workflows.controllers", [
    "moo.active-workflows.services"
    "moo.active-workflows.directives"
]

.controller "ActiveWorkflowsCtrl", [
    "$scope", "WorkflowSummary"
    ($scope, WorkflowSummary) ->


        $scope.workflowSummaries = WorkflowSummary()

        selectedWorkflows = { }

        $scope.selectWorkflow = (wflowName) ->
            selectedWorkflows[wflowName] ?= false
            selectedWorkflows[wflowName] = !selectedWorkflows[wflowName]

        $scope.isSelected = (wflowName) ->
            selectedWorkflows[wflowName] ? false
]


.controller "ActiveTypesCtrl", [
    "$scope", "$routeParams", "RunningWorkflows"
    ($scope, $routeParams, RunningWorkflows) ->
        $scope.workflowTypes = [ ]
        if $routeParams.workflowType?
            $scope.workflowTypes.push($routeParams.workflowType)

        $scope.runningTypes = []
        RunningWorkflows.query (data) ->
            $scope.runningTypes = (wflow.key for wflow in data).m$unique();

        $scope.showType = (type) ->
            $scope.workflowTypes.push(type)
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
            promises = (s.$promise for s in summaries)

            $q.all(promises).then ->
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
    "$q", "Workflows", "RunningWorkflows"
    ($q, Workflows, RunningWorkflows) ->

        sortByName = (statuses) ->
            statuses.sort (a, b) ->
                if a.name < b.name
                    return -1
                if a.name > b.name
                    return 1
                return 0

        getTasks = (statusList) ->
            tasks = { }
            for st in statusList
                tasks[st.task] = st.status
            return tasks

        onInstancesReceive = (instanceData, onComplete) ->
            idNums = (instance.id.m$rightOf(".") for instance in instanceData)
            promises = (RunningWorkflows.status(idNum).$promise for idNum in idNums)

            $q.all(promises).then (statuses) ->
                sortByName(statuses)
                for st in statuses
                    st.tasks = getTasks(st.statuses)
                onComplete(statuses)


        getStatuses = (type, onComplete) ->
            Workflows.instances type, (data) ->
                onInstancesReceive(data, onComplete)

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
        template: '<moo-workflow-tree wflow-name="name" editable="false" show-fields="false" tree-id="instanceName"></moo-workflow-tree>'
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


.directive "mooWorkflowTreeTable", [
    "Workflows", "TypeStatuses"
    (Workflows, TypeStatuses) ->
        restrict: "E"
        templateUrl: "partials/active-workflows/tree-table.html"
        scope:
            wflowName: "="
            statuses: "="
        link: ($scope, $element) ->


            setTableCells = ->
                for row in $element.find("tbody tr")
                    task = $(row).find("td:first-child").text().trim()
                    for st in $scope.statuses
                        $(row).append("<td class='#{st.tasks[task]}'></td>")

            getStatuses = ->
                TypeStatuses $scope.wflowName, (statuses) ->
                    $scope.statuses = statuses
                    setTableCells()
                    return statuses

            Workflows.get $scope.wflowName, (wflowData) ->
                ACT_FACTORY.createWorkflowTreeTable(wflowData, $element.find(".tree-table"))
                getStatuses()

#            $scope.$on "workflow.tree.loaded.#{$scope.wflowName}"


]
