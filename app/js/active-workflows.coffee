## Controllers ##
angular.module "moo.active-workflows.controllers", [
    "moo.active-workflows.services"
]

.controller "ActiveWorkflowsCtrl", [
    "$scope", "WorkflowSummary"
    ($scope, WorkflowSummary) ->
        $scope.workflowSummaries = WorkflowSummary

        selectedWorkflows = { }

        $scope.selectWorkflow = (wflowName) ->
            selectedWorkflows[wflowName] ?= false
            selectedWorkflows[wflowName] = !selectedWorkflows[wflowName]

        $scope.isSelected = (wflowName) ->
            selectedWorkflows[wflowName] ? false
]


## Services ##
angular.module "moo.active-workflows.services", [

]

.factory "WorkflowSummary", [
    "$rootScope", "$resource", "ServiceUrls", "ScowPush"
    ($rootScope, $resource, ServiceUrls, ScowPush) ->

        wflowsSummary =
            # List of headings required for table
            headings: { }
            # Content of the rows of the table
            workflows: { }


        updateWorkflow = (wflowName) ->
            id = wflowName.m$rightOf(".")
            wflowResource.status({ id: id }, updateStatus)

        statusPriority = [
            "precluded"
            "completed"
            "contingent"
            "planned"
            "notStarted"
            "open"
        ]

        updateStatus = (newStatuses) ->
            # Convert status list to map to get rid of multiple statuses for a user in a single workflow
            convertToMap = (statuses) ->
                # Determine which status to use when duplicates
                higherPriority = (status1, status2) ->
                    index1 = statusPriority.indexOf(status1)
                    index2 = statusPriority.indexOf(status2)
                    if index1 > index2 then status1 else status2

                statusesMap = { }
                for st in statuses.statuses
                    statusesMap[st.name] = higherPriority(st.status, statusesMap[st.name])
                return statusesMap

            # Add remove headings based on new workflow data
            updateHeadings = (addedNames, removedNames) ->
                # Determine whether a name appears in some other workflow
                nameInOtherWflow = (name) ->
                    # foreach status list
                    for own wflowName, statuses of wflowsSummary.workflows
                        # foreach user in each status whose name matches
                        for own user of statuses when user is name
                            # return true as soon as one match is found
                            return true
                    return false

                for addedName in addedNames
                    wflowsSummary.headings[addedName] = true
                headingsToRemove = (nameInOtherWflow(n) for n in removedNames when not nameInOtherWflow(n))
                for heading in headingsToRemove
                    delete wflowsSummary.headings[heading]

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


        wflowResource = $resource ServiceUrls.url("processInstances/:id"), { },
            query:
                isArray: true
                transformResponse: (data) -> angular.fromJson(data).processInstance

            status:
                url: ServiceUrls.url("processInstances/:id/status")
                transformResponse: (data) ->
                    wflowStatus = angular.fromJson(data)
                    statusSummary = wflowStatus.statusSummary
                    return {
                        name: wflowStatus.id
                        statuses: (name: ss.name, status: ss.status for ss in statusSummary when ss.name isnt "")
                    }

        wflowResource.query (wflowData) ->
            updateWorkflow(w.id) for w in wflowData

        ScowPush.subscribe "#.tasks.#", (task) ->
            $rootScope.$apply ->
                updateWorkflow(task.processInstanceId)



        return wflowsSummary
]