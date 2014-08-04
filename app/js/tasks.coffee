## Controllers ##
angular.module "moo.tasks.controllers", [
    "moo.tasks.directives"
    "moo.cow.web-service"
]

.controller "TaskListCtrl", [
    "$scope", "Tasks"
    ($scope, Tasks) ->
        userTasks = Tasks.userTaskInfo
        $scope.myTasks = userTasks.myTasks
        $scope.availableTasks = userTasks.availableTasks
]

.controller "TaskDetailCtrl", [
    "$scope", "$routeParams", "Tasks"
    ($scope, $routeParams, Tasks) ->
        $scope.task = Tasks.find($routeParams.taskId)
]







## Directives ##
angular.module "moo.tasks.directives", [
    "moo.cow.web-service"
]

.directive "mooTaskDetails", [
    ->
        restrict: "E"
        templateUrl: "partials/tasks/task-detail.html"
        scope:
            task: "="
            canComplete: "="
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
            $scope.idToInt = (task) -> +task.id
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
            $scope.idToInt = (task) -> +task.id
]

.directive "mooTaskHistory", [
    "Tasks"
    (Tasks) ->
        restrict: "E"
        templateUrl: "partials/tasks/task-history.html"
        scope: { }
        link: ($scope) ->
            $scope.historyShown = false

            $scope.showHistory = () ->
                $scope.historyShown = true
                $scope.historyTasks = Tasks.historyTasks()

            $scope.hideHistory = () ->
                $scope.historyShown = false
                $scope.historyTasks = []
]



.directive "mooCompleteTaskButton", [
    "Tasks"
    (Tasks) ->
        restrict: "A"
        scope:
            task: "="
        link: ($scope, element) ->
            element.bind "click", ->
                Tasks.complete($scope.task)
]

.directive "mooTakeTaskButton", [
    "Tasks"
    (Tasks) ->
        restrict: "A"
        scope:
            task: "="
        link: ($scope, element) ->
            element.bind "click", ->
                Tasks.take($scope.task)
]
