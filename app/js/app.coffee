## Declare app level module which depends on filters, and services ##

app = angular.module 'moo', [
    'ngRoute'
    'ngResource'
    'moo.filters'
    'moo.services'
    'moo.directives'
    'moo.controllers'
]

#.constant "serviceUrls", {
#    cowServer: "http://dfmb2:8080/cow-server/"
#    amqp:
#        url: "http://dfmb2:15674/stomp"
#        exchange: "/exchange/amq.topic/"
#        connectTimeout: 5 * 1000
#}
.constant "ServiceUrls", {
    cowServer: "http://scout2:8080/cow-server/"
    amqp:
        url: "http://scout2:15674/stomp"
        exchange: "/exchange/amq.topic/"
        connectTimeout: 5 * 1000
}


.constant "areas", [
    {
        name: "Tasks"
        defaultRoute:
            url: "/tasks"
            templateUrl: "partials/tasks/task-home.html"
            controller: "TaskListCtrl"
        otherRoutes: [
            {
                url: "/tasks/:taskId"
                templateUrl: "partials/tasks/task-detail.html"
                controller: "TaskDetailCtrl"
            }
        ]
    }
    {
        name: "Active Workflows"
        defaultRoute:
            url: "/active-workflows"
            templateUrl: "partials/active-workflows.html"
            controller: "ActiveWorkflowsCtrl"
    }
]

.config [
    "$routeProvider", "areas"
    ($routeProvider, areas) ->

        addRoute = (areaName, route) ->
            $routeProvider.when route.url,
                templateUrl: route.templateUrl
                controller: route.controller
                provide:
                    area: areaName

        for area in areas
            addRoute(area.name, area.defaultRoute)
            continue unless area.otherRoutes?
            for route in area.otherRoutes
                addRoute(area.name, route)

        $routeProvider.otherwise(redirectTo: "/tasks")
]

## SCOW requires basic auth ##
.config [
    "$httpProvider"
    ($httpProvider) ->
        $httpProvider.defaults.withCredentials = true
]


