
## Services ##

angular.module "moo.services", [
    "ngResource"
]



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
                transformResponse: (data) ->
                    JSON.parse(data).processInstance
            status:
                url: ServiceUrls.url("processInstances/:id/status")

            deleteAllOfType:
                url: ServiceUrls.url("processes/:id/processInstances")
                method: "DELETE"

        statuses = []

        return {
            workflows: workflowsResource.query
            getStatuses: ->
                workflowsResource.query().$promise.then (workflows) ->
                    for wf in workflows
                        idNum = wf.id.m$rightOf(".")
                        workflowsResource.status id: idNum, (status) ->
                            statuses.push
                                id: status.id
                                status: status.statusSummary
                return statuses

            deleteInstance: (id) ->
                id = id.m$rightOf(".")
                workflowsResource.delete(id: id)

            deleteAllInstancesOfType: (name) ->
                workflowsResource.deleteAllOfType(id: name)
        }
]

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
                    console.log("Error while trying to connect to AMQP")
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
]

.directive "mooReadOnlyVariables", [
    ->
        restrict: "E"
        templateUrl: "partials/read-only-variables.html"
        scope:
            variables: "="
]