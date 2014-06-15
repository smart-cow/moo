## Controllers ##

angular.module("moo.controllers", [])

.controller "TaskListCtrl", [
    "$scope", "Task", "User"
    ($scope, Task, User) ->
        $scope.myTasks = Task.assigned(User)
        $scope.availableTasks = Task.candidate(User)

        $scope.setSelectedTask = (task) ->
            $scope.selectedTask = task
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

