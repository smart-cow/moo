
## Controllers ##
angular.module "moo.tasks.controllers", [
    "moo.tasks.services"
    "moo.tasks.directives"
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


## Services ##
angular.module "moo.tasks.services", [
    "ngResource"
    "moo.services"
]

.factory "Tasks", [
    "$http", "$resource", "CurrentUser", "ServiceUrls", "ResourceHelpers"
    ($http, $resource, CurrentUser, ServiceUrls, ResourceHelpers) ->
        taskResource = $resource "#{ServiceUrls.cowServer}/tasks/:id", {},
            get:
                transformResponse: (data) ->
                    task = JSON.parse(data)
                    ResourceHelpers.fixVars(task)
                    return task
            query:
                isArray: true
                transformResponse: (data) ->
                    tasks = JSON.parse(data).task
                    ResourceHelpers.fixVars(task) for task in tasks
                    return tasks
            take:
                url: "#{ServiceUrls.cowServer}/tasks/:id/take"
                params:
                    id: "@id"
                    assignee: "@assignee"
                method: "POST"

            history:
                isArray: true
                url: "#{ServiceUrls.cowServer}/tasks/history"
                params:
                    start: (new Date().getFullYear() - 1) + "-1-1"
                    end: (new Date().getFullYear() + 1) + "-1-1"
                transformResponse: (data) ->
                    JSON.parse(data).historyTask


        getTaskList = (getMyTasks) ->
            ResourceHelpers.promiseParam CurrentUser, true, (userName) ->
                taskResource.query(if getMyTasks then assignee: userName else candidate: userName)

        userTasks =
            myTasks: getTaskList(true)
            availableTasks: getTaskList(false)


        return {
            find: (id) -> taskResource.get(id: id)

            userTaskInfo: userTasks

            historyTasks: ->
                ResourceHelpers.promiseParam CurrentUser, true, (userName) ->
                    taskResource.history(assignee: userName)

            take: (task) ->
                ResourceHelpers.promiseParam CurrentUser, false, (userName) ->
                    task.assignee = userName
                    taskResource.take task, (taskData) ->
                        userTasks.availableTasks.m$remove (e) ->
                            e.id == taskData.id
                        userTasks.myTasks.push(taskData)

            complete: (task) ->
                url = "#{ServiceUrls.cowServer}/tasks/#{task.id}"
                vars = ResourceHelpers.encodeVars(task.variables)
                if vars?
                    url += "?#{vars}"
                $http.delete(url).success ->
                    userTasks.myTasks.m$remove (e) ->
                        e.id == task.id
        }
]



## Directives ##
angular.module "moo.tasks.directives", [
    "moo.tasks.services"
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

.directive "mooTaskDetails", [
    ->
        restrict: "E"
        templateUrl: "partials/tasks/task-detail.html"
        scope:
            task: "="
            canComplete: "="
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
