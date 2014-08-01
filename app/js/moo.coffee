
## Services ##

angular.module "moo.services", [
    "ngResource"
]


.factory "CowUrl", [
    "ServiceUrls",
    (ServiceUrls) ->
        (resourcePath) ->
            if resourcePath[0] == "/"
                resourcePath = resourcePath.substring(1)
            return ServiceUrls.cowServer + resourcePath

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


.factory "MooResource", [
    "$resource", "CowUrl"
    ($resource, CowUrl) ->
        fixJaxbIssues = (data) ->
            return data if angular.isArray(data)

            keys = Object.keys(data)
            return data unless keys.length == 1

            value = data[keys[0]]

            return data unless angular.isArray(value)
            return value

        fixByKey = (data, key) ->
            fixJaxbIssues(data[key])


        setDefaults = (action) ->
            action.responseType = "json"
            action.withCredentials = true

        actionTemplates =
            get: ->
                method: "GET"
            all: ->
                method: "GET"
                isArray: true
                transformResponse: [
                    (data) ->
                        return fixJaxbIssues(data)
                ]
            save: ->
                method: "POST"
            update: ->
                method: "PUT"
            delete: ->
                method: "DELETE"

        buildDefaultAction = (templateType) ->
            action = actionTemplates[templateType]?() ? { }
            setDefaults(action)

        defaultActions = ->
            (templateType: buildDefaultAction(templateType) for own templateType of actionTemplates)

        overrideDefaults = (action, defaultAction) ->
            angular.extend(defaultAction, action)

        configureAction = (action) ->
            defaultAction = buildDefaultAction(action.template)
            overrideDefaults(action, defaultAction)


        return (url, paramDefaults = { }, actions) ->
            if angular.isArray(actions) and actions.length > 0
                configureAction(action) for action in actions
            else
                actions = defaultActions()
            return $resource(CowUrl(url), paramDefaults, actions)

]


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
            start:
                url: ServiceUrls.url("processInstances")
                method: "POST"

        statuses = []
        getAllStatuses = ->
            statuses.m$clear()
            workflowsResource.query (workflows) ->
                for wf in workflows
                    idNum = wf.id.m$rightOf(".")
                    statuses.push(workflowsResource.status(id: idNum))
            return statuses


        buildStartRequest = (workflowName, variables) ->
            reqBody = processDefinitionKey: workflowName
            if variables.length > 0
                requestVariables = (name: v.name, value: v.value for v in variables)
                reqBody.variables = variable: requestVariables
            return reqBody



        return {
            query: workflowsResource.query

            start: (workflowName, variables, onSuccess, onFailure) ->
                req = buildStartRequest(workflowName, variables)
                workflowsResource.start({ }, req, onSuccess, onFailure)

            status: (wflowIdNum, onSuccess, onFailure) ->
                workflowsResource.status(id: wflowIdNum, onSuccess, onFailure)

            allStatuses: getAllStatuses

            delete: (id, onSuccess, onFailure) ->
                id = id.m$rightOf(".")
                workflowsResource.delete(id: id, onSuccess, onFailure)

        }
]


.factory "Workflows", [
    "$resource", "ServiceUrls", "ResourceHelpers"
    ($resource, ServiceUrls, ResourceHelpers) ->
        processResource = $resource ServiceUrls.url("processes/:id"), { },
            get:
                transformResponse: (data) ->
                    workflow = angular.fromJson(data)
                    ResourceHelpers.fixVars(workflow)
                    return workflow
            query:
                isArray: true
                url: ServiceUrls.url("processDefinitions")
                transformResponse: (data) ->
                    definitions = angular.fromJson(data).processDefinition
                    return (d.key for d in definitions)
            update:
                method: "PUT"
                headers:
                    "Content-Type": "application/xml"
                transformResponse: (data) ->
                    angular.fromJson(data).processInstance

            instances:
                isArray: true
                url: ServiceUrls.url("processes/:id/processInstances")
                transformResponse: (data) ->
                    angular.fromJson(data).processInstance

            deleteInstances:
                url: ServiceUrls.url("processes/:id/processInstances")
                method: "DELETE"


        return {
            get: (id, onSuccess, onFailure) ->
                processResource.get(id: id, onSuccess, onFailure)

            query: (onSuccess, onFailure) ->
                processResource.query(onSuccess, onFailure)

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

.directive "mooAjaxSpinner", [
    "$http"
    ($http) ->
        restrict: "E"
        templateUrl: "partials/ajax-spinner.html"
        scope: { }
        link: ($scope, $element) ->
            $scope.isLoading = ->
                $http.pendingRequests.length > 0

            spinner = $element.find("#spinner")

            $scope.$watch $scope.isLoading, (v) ->
                if v then spinner.show() else spinner.hide()
]



.directive "mooEditableVariables", [
    ->
        restrict: "E"
        templateUrl: "partials/editable-variables.html"
        scope:
            variables: "="
        link: ($scope, element) ->

            # Prevent enter key from deleting variables
            element.on "keypress", (evt) ->
                evt.which isnt 13


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
            $scope.$watch (-> $scope.treeId), ->
                afterLoad = (workflow) ->
                    $scope.$emit("workflow.tree.loaded." + givenId)
                    $scope.workflow = workflow

#                    $scope.$watch (-> $scope.workflow.name()), (newVal) ->
#                        $scope.wflowName = newVal
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


            $scope.workflowComponents = ACT_FACTORY.draggableActivities()
            # Configure trash droppable
            $(".trash").droppable
                drop: (event, ui) ->
                    sourceNode = $(ui.helper).data("ftSourceNode")
                    sourceNode.remove()





            $scope.save = ->
                xml = $scope.workflow.toXml()
                console.log(xml)
                onSuccess = -> alert("Workflow saved")
                onFail = (data) ->
                    console.log("Error: %o", data)
                    unless data.status is 409 # Conflict
                        alert("Error see console")
                    $scope.$emit("moo.workflow.save.error.#{data.status}",
                            { name: $scope.workflow.name(), instances: data.data, retry: $scope.save} )

                Workflows.update($scope.workflow.name(), xml, onSuccess, onFail)
]

.directive "mooWorkflowComponent", [
    ->
        restrict: "E"
        templateUrl: "partials/workflow-component.html"
        scope:
            component: "="
        link: ($scope, element) ->
            element.find("div").draggable
                helper: "clone"
                cursorAt: {top: -5, left: -5}
                connectToFancytree: true

]


## Filters ##
angular.module "moo.filters", []

.filter "escapeDot", [
    ->
        (text) ->
            text.replace(".", "_")
]

.filter "wflowIdToName", [
    ->
        (text) -> text.m$leftOf(".")
]

