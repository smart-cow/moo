## Controllers ##

angular.module("moo.controllers", [])

.controller "TaskListCtrl", [
    "$scope", "Task"
    ($scope, Task) ->
        $scope.userTasks = Task.userTasks
]

.controller "TaskDetailCtrl", [
    "$scope", "$routeParams", "Task"
    ($scope, $routeParams, Task) ->
        $scope.task = Task.find($routeParams.taskId)
]


.controller "ActiveWorkflowsCtrl", [
    "$scope"
    ($scope) ->
]

