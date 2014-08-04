## Declare app level module which depends on filters, and services ##

app = angular.module "moo", [
    "ngRoute"
    "moo.directives"
    "moo.filters"
    "moo.tasks.controllers"
    "moo.active-workflows.controllers"
    "moo.admin.controllers"
    "moo.builder.controllers"
    "moo.start-workflow.controllers"
]


#.constant "ServiceUrls", {
#    cowServer: "http://dfmb2:8080/cow-server/"
#    url: (path) ->
#        @cowServer + path
#    amqp:
#        url: "http://dfmb2:15674/stomp"
#        exchange: "/exchange/amq.topic/"
#        connectTimeout: 5 * 1000
#        username: "guest"
#        password: "guest"
#}

#.constant "ServiceUrls", {
#    cowServer: "http://scout3:8080/cow-server/"
#    url: (path) ->
#        @cowServer + path
#    amqp:
#        url: "http://scout3:15674/stomp"
#        exchange: "/exchange/amq.topic/"
#        connectTimeout: 5 * 1000
#        username: "guest"
#        password: "guest"
#}


.constant "ServiceUrls", {
    cowServer: "http://scout2:8080/cow-server/"
    url: (path) ->
        @cowServer + path
    amqp:
        url: "http://scout2:15674/stomp"
        exchange: "/exchange/amq.topic/"
        connectTimeout: 5 * 1000
        username: "guest"
        password: "guest"
}




## Define Routes ##
# Divide pages into areas. Each area has its modules defined in <areaName>.coffee
.constant "Areas", [
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
            templateUrl: "partials/active-workflows/active-workflows.html"
            controller: "ActiveWorkflowsCtrl"
        otherRoutes: [
            {
                url: "/active-workflows/:workflowType"
                templateUrl: "partials/active-workflows/active-types.html"
                controller: "ActiveTypesCtrl"
            }
        ]
    }
    {
        name: "Start Workflow"
        defaultRoute:
            url: "/workflows/start"
            templateUrl: "partials/start-workflow/start-workflow.html"
            controller: "StartWorkflowCtrl"
    }
    {
        name: "Workflow Builder"
        defaultRoute:
            url: "/builder"
            templateUrl: "partials/builder/builder.html"
            controller: "WorkflowBuilderCtrl"
        otherRoutes: [
            {
                url: "/builder/:wflowName"
                templateUrl: "partials/builder/builder.html"
                controller: "WorkflowBuilderCtrl"
            }
        ]
    }
    {
        name: "Admin"
        defaultRoute:
            url: "/admin"
            templateUrl: "partials/admin/admin.html"
            controller: "AdminCtrl"
    }
]

# Use apply areas to the $routeProvider
.config [
    "$routeProvider", "Areas"
    ($routeProvider, Areas) ->

        addRoute = (areaName, route) ->
            $routeProvider.when route.url,
                templateUrl: route.templateUrl
                controller: route.controller
                # Include area name with route definition
                provide:
                    area: areaName

        for area in Areas
            addRoute(area.name, area.defaultRoute)
            continue unless area.otherRoutes?
            for route in area.otherRoutes
                addRoute(area.name, route)

        $routeProvider.otherwise(redirectTo: "/tasks")
]



