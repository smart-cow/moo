## Directives ##

angular.module "moo.directives", []

.directive "mooNavMenu", [
    "$route", "areas"
    ($route, areas) ->
        restrict: "E"
        templateUrl: "partials/nav-menu.html"
        link: ($scope) ->
            $scope.tabs = for area in areas
                title: area.name
                url: "#" + area.defaultRoute.url
                selected: area.name is $route.current.provide.area

            $scope.$on "$routeChangeSuccess", (evt, newRoute) ->
                for tab in $scope.tabs
                    tab.selected = tab.title is newRoute.provide.area
]



.directive "mooAssignedTasksTable", [
    ->
        restrict: "E"
        templateUrl: "partials/tasks/task-table.html"
        scope:
            tasks: "="
        link: ($scope) ->
            $scope.canAssignTasks = false
            $scope.canCompleteTasks = true
            $scope.caption = "Your Tasks"
]

.directive "mooAvailableTasksTable", [
    ->
        restrict: "E"
        templateUrl: "partials/tasks/task-table.html"
        scope:
            tasks: "="
        link: ($scope) ->
            $scope.canAssignTasks = true
            $scope.canCompleteTasks = false
            $scope.caption = "Available Tasks"
]

.directive "mooTaskHistory", [
    "Task"
    (Task) ->
        restrict: "E"
        templateUrl: "partials/tasks/task-history.html"
        scope: { }
        link: ($scope) ->
            $scope.historyShown = false

            $scope.showHistory = () ->
                $scope.historyShown = true
                $scope.historyTasks = Task.historyTasks()

            $scope.hideHistory = () ->
                $scope.historyShown = false
                $scope.historyTasks = []
]

.directive "mooTaskDetails", [
    ->
        restrict: "E"
        templateUrl: "partials/tasks/task-detail.html"
        scope:
            task: "="
            canComplete: "="
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

.directive "mooCompleteTaskButton", [
    "Task"
    (Task) ->
        restrict: "A"
        scope:
            task: "="
        link: ($scope, element) ->
            element.bind "click", ->
                Task.complete($scope.task)
]

.directive "mooTakeTaskButton", [
    "Task"
    (Task) ->
        restrict: "A"
        scope:
            task: "="
        link: ($scope, element) ->
            element.bind "click", ->
                Task.take($scope.task)
]