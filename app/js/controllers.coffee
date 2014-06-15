## Controllers ##

angular.module("moo.controllers", [])

.controller "TaskListCtrl", [
    "$scope", "Task", "User"
    ($scope, Task, User) ->
        $scope.myTasks = Task.assigned(User)
        $scope.availableTasks = Task.candidate(User)

        $scope.$on "task.take", (event, takenTask) ->
            $scope.availableTasks = (t for t in $scope.availableTasks when t.id isnt takenTask.id)
            if takenTask.assignee is User
                $scope.myTasks.push(takenTask)

        $scope.$on "task.complete", (event, completedTask) ->
            $scope.myTasks = (t for t in $scope.myTasks when t.id isnt completedTask.id)
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

