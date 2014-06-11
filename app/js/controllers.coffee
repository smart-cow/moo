## Controllers ##

angular.module("moo.controllers", [])

.controller "TaskListCtrl", [
    "$scope", "Task"
    ($scope, Task) ->
        $scope.tasks = Task.query()
]

.controller "TaskDetailCtrl", [
    "$scope", "$routeParams", "Task"
    ($scope, $routeParams, Task) ->
        $scope.task = Task.get(id: $routeParams.taskId)
]


.controller "ActiveWorkflowsCtrl", [
    "$scope"
    ($scope) ->
]