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
            headings: { }
            workflows: { }


        updateWorkflow = (wflowName) ->
            id = wflowName.m$rightOf(".")
            wflowResource.status(id: id)

        statusPriority = [
            "precluded"
            "completed"
            "contingent"
            "planned"
            "notStarted"
            "open"
        ]

        updateStatus = (newStatuses) ->
            convertToMap = (statuses) ->
                higherPriority = (status1, status2) ->
                    index1 = statusPriority.indexOf(status1)
                    index2 = statusPriority.indexOf(status2)
                    if index1 > index2 then status1 else status2

                statusesMap = { }
                for st in statuses.statuses
                    statusesMap[st.name] = higherPriority(st.status, statusesMap[st.name])
                return statusesMap

            updateHeadings = (addedNames, removedNames) ->
                nameInOtherWflow = (name) ->
                    for own wflowName, statuses of wflowsSummary.workflows
                        for own user, status of statuses when user is name
                            return true
                    return false

                for addedName in addedNames
                    wflowsSummary.headings[addedName] = true
                headingsToRemove = (nameInOtherWflow(n) for n in removedNames when not nameInOtherWflow(n))
                for heading in headingsToRemove
                    delete wflowsSummary.headings[heading]



            wflowsSummary.workflows[newStatuses.name] ?= { }
            existingStatuses = wflowsSummary.workflows[newStatuses.name]

            newStatusesMap = convertToMap(newStatuses)
            addedNames = [ ]
            for own name, status of newStatusesMap
                unless existingStatuses[name]?
                    addedNames.push(name)
                existingStatuses[name] = status

            removedNames = [ ]
            for own name, status of existingStatuses
                unless newStatusesMap[name]?
                    removedNames.push(name)
                    delete existingStatuses[name]
            updateHeadings(addedNames, removedNames)


        wflowResource = $resource ServiceUrls.url("processInstances/:id"), { },
            query:
                isArray: true
                transformResponse: (data) ->
                    wflowInstances = angular.fromJson(data).processInstance
                    names = []
                    for wflow in wflowInstances
                        name = wflow.id
                        updateWorkflow(name)
                        names.push(name)
                    return names

            status:
                url: ServiceUrls.url("processInstances/:id/status")
                transformResponse: (data) ->
                    wflowStatus = angular.fromJson(data)
                    name = wflowStatus.id
                    statusSummary = wflowStatus.statusSummary
                    status =
                        name: name
                        statuses: (name: ss.name, status:ss.status for ss in statusSummary when ss.name isnt "")
                    updateStatus(status)
                    return status

        wflowResource.query()

        ScowPush.subscribe "#.tasks.#", (task) ->
            $rootScope.$apply ->
                updateWorkflow(task.processInstanceId)



        return wflowsSummary
]