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
            return RunningWorkflows.statusSummary(id, updateStatus)


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
    "$q", "Workflows", "RunningWorkflows", "ExtractStatuses"
    ($q, Workflows, RunningWorkflows, ExtractStatuses) ->


        getTaskStatuses = (status) ->
            workflow = ACT_FACTORY.create(status.process.activity)
            return ExtractStatuses(workflow)


        onInstancesReceive = (instanceData, onComplete) ->
            idNums = (instance.id.m$rightOf(".") for instance in instanceData)
            promises = (RunningWorkflows.fullStatus(idNum).$promise for idNum in idNums)

            $q.all(promises).then (statusData) ->
                workflowStatuses = [ ]
                for stDatum in statusData
                    workflowStatuses.push
                        workflowId: stDatum.id
                        tasks: getTaskStatuses(stDatum)
                onComplete(workflowStatuses)


        getStatuses = (type, onComplete) ->
            Workflows.instances type, (data) ->
                onInstancesReceive(data, onComplete)

        return getStatuses
]


.factory "ExtractStatuses", [
    ->
        class ExtractStatusesVisitor
            constructor: (rootActivity) ->
                @activityStatuses = { "$root": rootActivity.data.completionState }
                @visitChildren(rootActivity, rootActivity.children)


            addStatus: (node) =>
                @activityStatuses[node.data.name] = node.data.completionState


            visit: (node) ->
                node.accept(@, node)

            visitAggregate: (node) =>
                @addStatus(node)
                @visitChildren(node, node.children)


            visitChildren: (node, children) =>
                return if children == null
                @visit(child) for child in children


            visitLoop: (node) => @visitAggregate(node)
            visitOption: (node) => @visitAggregate(node)
            visitDecision: (node) => @visitAggregate(node)
            visitActivities: (node) => @visitAggregate(node)


            visitExit: (node) => @addStatus(node)
            visitScript: (node) => @addStatus(node)
            visitSignal: (node) => @addStatus(node)
            visitHumanTask: (node) => @addStatus(node)
            visitSubprocess: (node) => @addStatus(node)
            visitServiceTask: (node) => @addStatus(node)


        return (workflow) -> new ExtractStatusesVisitor(workflow).activityStatuses

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
        link: ($scope, $element) ->

            setTableCells = ->
                # Handle process name and top level lists separately
                for row in $element.find("tbody tr:lt(2)")
                    for st in $scope.statuses
                        taskStatus = st.tasks["$root"]
                        $(row).append("<td class='#{taskStatus}'></td>")

                for row in $element.find("tbody tr:gt(1)")
                    taskName = $(row).find("td:first-child").text().trim()
                    for st in $scope.statuses
                        taskStatus = st.tasks[taskName]
                        $(row).append("<td class='#{taskStatus}'></td>")

            getStatuses = ->
                TypeStatuses $scope.wflowName, (statuses) ->
                    $scope.statuses = statuses
                    $scope.statuses.m$sortBy("workflowId")
                    setTableCells()
                    return statuses

            Workflows.get $scope.wflowName, (wflowData) ->
                ACT_FACTORY.createWorkflowTreeTable(wflowData, $element.find(".tree-table"))
                getStatuses()
]
