
## Services ##

angular.module "moo.services", [
    "ngResource"
]



# Helper methods for interacting with scow api objects
.constant "ResourceHelpers", {
    fixVars: (resource) ->
        unless angular.isArray(resource.variables)
            resource.variables = resource.variables?.variable ? resource.variables?.variables ? []
        return resource

    fixOutcomes: (resource) ->
        unless angular.isArray(resource.outcomes)
            resource.outcomes = resource.outcome ? resource.outcomes ? []
            delete resource.outcome
        return resource


    encodeVars: (variables) ->
        return ("#{v.name}:#{v.value}" for v in variables)

    promiseParam: (promise, isArray, serviceCall) ->
        resolvedObj = if isArray then [] else { }
        promiseThen = promise.then ? promise.$promise.then
        promiseThen (promisedData) ->
            serviceCall(promisedData).$promise.then (serviceData) ->
                for own k, v of serviceData
                    resolvedObj[k] = v
        return resolvedObj

}


# Provide access to the currently logged in user
.factory "CurrentUser", [
    "$resource", "ServiceUrls"
    ($resource, ServiceUrls) ->
        whoamiResource = $resource "#{ServiceUrls.cowServer}/whoami", {},
            get:
                transformResponse: (data) ->
                    userData = angular.fromJson(data)
                    return {
                        name: userData.id
                        groups: (m.group for m in userData.membership)
                    }
        user = whoamiResource.get()
        return user
]



.factory "RunningWorkflows", [
    "$resource", "ServiceUrls"
    ($resource, ServiceUrls) ->
        workflowsResource = $resource ServiceUrls.url("processInstances/:id"), {},
            query:
                isArray: true
                transformResponse: (data) -> angular.fromJson(data).processInstance

            status:
                url: ServiceUrls.url("processInstances/:id/status")
                transformResponse: (data) ->
                    wflowStatus = angular.fromJson(data)
                    statusSummary = wflowStatus.statusSummary

                    statuses = for ss in statusSummary
                        name: ss.name
                        status: ss.status
                        task: ss.task[0].name
                    return {
                        name: wflowStatus.id
                        statuses: statuses
                    }



        statuses = []
        getAllStatuses = ->
            statuses.m$clear()
            workflowsResource.query (workflows) ->
                for wf in workflows
                    idNum = wf.id.m$rightOf(".")
                    statuses.push(workflowsResource.status(id: idNum))
            return statuses


        return {
            query: workflowsResource.query

            status: (wflowIdNum, onSuccess, onFailure) ->
                workflowsResource.status(id: wflowIdNum, onSuccess, onFailure)

            allStatuses: getAllStatuses

            delete: (id, onSuccess, onFailure) ->
                id = id.m$rightOf(".")
                workflowsResource.delete(id: id, onSuccess, onFailure)

        }
]


.factory "Workflows", [
    "$resource", "ServiceUrls"
    ($resource, ServiceUrls) ->
        processResource = $resource ServiceUrls.url("processes/:id"), { },
            update:
                method: "PUT"
                headers:
                    "Content-Type": "application/xml"
            instances:
                isArray: true
                url: ServiceUrls.url("processes/:id/processInstances")
                transformResponse: (data) ->
                    return angular.fromJson(data).processInstance

            deleteInstances:
                url: ServiceUrls.url("processes/:id/processInstances")
                method: "DELETE"



        return {
            get: (id, onSuccess, onFailure) ->
                processResource.get(id: id, onSuccess, onFailure)

            update: (name, workflowXml, onSuccess, onFailure) ->
                workflowString = new XMLSerializer().serializeToString(workflowXml);
                processResource.update(id: name, workflowString, onSuccess, onFailure)

            instances: (name, onSuccess, onFailure) ->
                processResource.instances(id: name, onSuccess, onFailure)

            deleteInstances: (name, onSuccess, onFailure) ->
                processResource.deleteInstances(id: name, onSuccess, onFailure)
        }
]



# Used to subscribe to AMQP messages
.factory "ScowPush", [
    "ServiceUrls"
    (ServiceUrls) ->

        addSubscription = ->

        init = ->
            amqpInfo = ServiceUrls.amqp

            stomp = Stomp.over(new SockJS(amqpInfo.url))
            stomp.debug = ->
            subscriptions = []
            isConnected = false

            addSubscription = (subscription) ->
                subscriptions.push(subscription)
                amqpSubscribe(subscription) if isConnected

            amqpSubscribe = (subscription) ->
                destination = amqpInfo.exchange + subscription.routingKey
                stomp.subscribe destination, (message) ->
                    routingKey = message.headers.destination.m$rightOf("/")
                    parsedBody = angular.fromJson(message.body)
                    subscription.onReceive(parsedBody, routingKey)

            stompConnect = ->
                onConnect = ->
                    console.log("Stomp connected")
                    isConnected = true
                    amqpSubscribe(s) for s in subscriptions

                onError = ->
                    isConnected = false
                    console.log("Error: disconnected from AMQP: %o", arguments)
                stomp.connect(amqpInfo.username, amqpInfo.password, onConnect, onError)
            stompConnect()
        init()


        return {
            subscribe: (routingKey, onReceive) ->
                console.log(routingKey)
                addSubscription(routingKey: routingKey, onReceive: onReceive)
        }
]


## Directives ##
angular.module "moo.directives", []

.directive "mooNavMenu", [
    "$route", "Areas"
    ($route, Areas) ->
        restrict: "E"
        templateUrl: "partials/nav-menu.html"
        link: ($scope) ->
            $scope.tabs = for area in Areas
                title: area.name
                url: "#" + area.defaultRoute.url
                selected: area.name is $route.current.provide.area

            # Keep selected tab in sync with current page
            $scope.$on "$routeChangeSuccess", (evt, newRoute) ->
                for tab in $scope.tabs
                    tab.selected = tab.title is newRoute.provide.area
]


.directive "mooEditableVariables", [
    ->
        restrict: "E"
        templateUrl: "partials/editable-variables.html"
        scope:
            variables: "="
        link: ($scope) ->

            $scope.addVariable = ->
                $scope.variables.push
                    name: ""
                    value: ""

            $scope.removeVariable = (variableToRemove) ->
               $scope.variables.m$removeFirst (v) ->
                   variableToRemove.name is v.name and variableToRemove.value is v.value


]

.directive "mooReadOnlyVariables", [
    ->
        restrict: "E"
        templateUrl: "partials/read-only-variables.html"
        scope:
            variables: "="
]

.directive "mooWorkflowTree", [
    "Workflows"
    (Workflows) ->
        restrict: "E"
        templateUrl: "partials/workflow-tree.html"
        scope:
            wflowName: "=?"
            editable: "="
            showFields: "=?"
            treeId: "=?"
        link: ($scope) ->
            givenId = $scope.treeId
            # treeId to passed in, so that a single page can have multiple trees with different ids
            $scope.treeId ?= if $scope.wflowName? then $scope.wflowName + "-tree" else "tree"
            $scope.showFields ?= true

            treeSelector = "#" + $scope.treeId

            # Since treeId is configured here we need to wait until after initialization to access the tree div
            $scope.$watch $scope.treeId, ->
                afterLoad = (workflow) ->
                    $scope.$emit("workflow.tree.loaded." + givenId)
                    $scope.workflow = workflow
                    # When a user clicks on a workflow element, change the form that is displayed
                    workflow.selectedActivityChanged ->
                        $scope.$apply()

                onNoExistingWorkflow = ->
                    if $scope.editable
                        afterLoad(ACT_FACTORY.createEmptyWorkflow(treeSelector, $scope.editable, $scope.wflowName))
                    else
                        errorMsg = "If workflow is not editable, then workflow must already exist,
                                    but workflow: #{$scope.wflowName} doesn't exist."
                        alert(errorMsg)
                        console.error(errorMsg)

                if $scope.wflowName?
                    onSuccess = (wflowData) ->
                        afterLoad(ACT_FACTORY.createWorkflow(wflowData, treeSelector, $scope.editable))
                    Workflows.get($scope.wflowName, onSuccess, onNoExistingWorkflow)
                else
                    onNoExistingWorkflow()

            return unless $scope.editable
            # Below is only necessary if the tree is editable


            # Configure trash droppable
            $(".trash").droppable
                drop: (event, ui) ->
                    sourceNode = $(ui.helper).data("ftSourceNode")
                    sourceNode.remove()


            $scope.workflowComponents = ACT_FACTORY.draggableActivities()
            # Enable dragging AFTER the workflowComponents have been added to the page,
            $scope.$watch $scope.workflowComponents, ->
                $(".draggable").draggable
                    helper: "clone"
                    cursorAt: {top: -5, left: -5}
                    connectToFancytree: true


            $scope.save = ->
                xml = $scope.workflow.toXml()
                console.log(xml)
                onSuccess = -> alert("Workflow saved")
                onFail = ->
                    alert("Error see console")
                    console.log("Error: %o", arguments)

                Workflows.update($scope.workflow.name(), xml, onSuccess, onFail)
]


## Filters ##
angular.module "moo.filters", []

.filter "escapeDot", [
    ->
        (text) ->
            text.replace(".", "_")
]

