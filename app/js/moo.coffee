
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
    "$resource", "$q", "CowUrl"
    ($resource, $q, CowUrl) ->


        # When receiving a list it wraps it in a object with one key, the list.
        # This will extract the list, if data: is an object, has a single key, key's value is array
        fixJaxbObjectArray = (resource) ->
            # If it is an array no modification necessary
            return resource if angular.isArray(resource)

            keys = Object.keys(resource)
            # We are only interested in objects with exactly one key
            return resource unless keys.length == 1

            value = resource[keys[0]]
            # If the value isn't an array, then the data is just an object with a single key
            return resource unless angular.isArray(value)
            return value


        knownObjectArrayKeys = ["variables", "variable", "outcome", "outcomes"]

        fixObjectResource = (resource) ->
            return resource unless resource?
            for key in knownObjectArrayKeys
                if resource[key]?
                    resource[key] = fixJaxbObjectArray(resource[key])
            return resource



        fixResource = (resource) ->
            return resource unless resource?
            arrayResource = fixJaxbObjectArray(resource)
            if angular.isArray(arrayResource)
                fixObjectResource(r) for r in arrayResource
                return arrayResource
            else
                return fixObjectResource(resource)



        setDefaults = (action) ->
            action.responseType = "json"
            action.withCredentials = true
            action.transformResponse = [ fixResource ]


        actionTemplates =
            get: ->
                method: "GET"
            query: ->
                method: "GET"
                isArray: true
            save: ->
                method: "POST"
            post: ->
                method: "POST"
            update: ->
                method: "PUT"
            delete: ->
                method: "DELETE"
            remove: ->
                method: "DELETE"

        buildDefaultAction = (templateType) ->
            action = actionTemplates[templateType]?() ? { }
            setDefaults(action)
            return action

        defaultActions = ->
            actions = { }
            for own templateType of actionTemplates
                actions[templateType] = buildDefaultAction(templateType)
            return actions



        # These are properties that can just be copied when an action doesn't specify its own value
        defaultPropsToCopy = [ "method", "isArray", "responseType", "withCredentials"]

        combineWithDefaults = (action, defaultAction) ->
            for prop in defaultPropsToCopy
                # only copy from defaultAction when not defined in action
                action[prop] ?= defaultAction[prop]

            # Can't just copy transformResponse because it is an array
            defaultXform = defaultAction.transformResponse ? []
            if action.transformResponse?
                # If action defines a transform, append to the end of the list of transforms
                defaultXform.push(action.transformResponse)
            action.transformResponse = defaultXform


        configureAction = (name, action) ->
            if action.path?
                action.url = CowUrl(action.path)
            defaultAction = buildDefaultAction(action.template ? name)
            combineWithDefaults(action, defaultAction)
            return action


        return (path, actions, paramDefaults = { }) ->
            ngActions = defaultActions()
            if actions?
                for own name, action of actions
                    ngActions[name] = configureAction(name, action)
            return $resource(CowUrl(path), paramDefaults, ngActions)
]


# Provide access to the currently logged in user
.factory "CurrentUser", [
    "MooResource", "ServiceUrls"
    (MooResource) ->

        whoamiResource = MooResource "whoami",
            get:
                transformResponse: (userData) ->
                    return {
                        name: userData.id
                        groups: (m.group for m in userData.membership)
                    }
        user = whoamiResource.get()
        return user
]



.factory "RunningWorkflows", [
    "MooResource"
    (MooResource) ->
        workflowsResource = MooResource "processInstances/:id",
            status:
                path: "processInstances/:id/status"
                template: "get"
                transformResponse: (wflowStatus) ->
#                    wflowStatus = angular.fromJson(data)
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
                template: "post"
                path: "processInstances"



        statuses = []
        getAllStatuses = ->
            statuses.m$clear()
            workflowsResource.all (workflows) ->
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

            start: (workflowName, variables, callbacks...) ->
                req = buildStartRequest(workflowName, variables)
                workflowsResource.start({ }, req, callbacks...)

            status: (wflowIdNum, onSuccess, onFailure) ->
                workflowsResource.status(id: wflowIdNum, onSuccess, onFailure)

            allStatuses: getAllStatuses

            delete: (id, onSuccess, onFailure) ->
                id = id.m$rightOf(".")
                workflowsResource.delete(id: id, onSuccess, onFailure)

        }
]


.factory "Workflows", [
    "MooResource"
    (MooResource) ->
        processResource = MooResource "processes/:id",
            query:
                path: "processDefinitions"
                transformResponse: (definitions) ->
                    return (d.key for d in definitions)
            update:
                method: "PUT"
                headers:
                    "Content-Type": "application/xml"

            instances:
                template: "query"
                path: "processes/:id/processInstances"

            deleteInstances:
                template: "delete"
                path: "processes/:id/processInstances"


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

