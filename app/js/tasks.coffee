
## Controllers ##
angular.module "moo.tasks.controllers", [
    "moo.tasks.services"
]

.controller "TaskListCtrl", [
    "$scope", "Tasks"
    ($scope, Tasks) ->
        $scope.userTasks = Tasks.userTasks
]

.controller "TaskDetailCtrl", [
    "$scope", "$routeParams", "Tasks"
    ($scope, $routeParams, Tasks) ->
        $scope.task = Tasks.find($routeParams.taskId)
        console.log($scope.task)
]


## Services ##
angular.module "moo.tasks.services", [
    "ngResource"
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


        userTaskInfo = { }
        CurrentUser.then (userName) ->
            userTaskInfo.myTasks = taskResource.query(assignee: userName)
            userTaskInfo.availTasks = taskResource.query(candidate: userName)

        return {
            userTasks: userTaskInfo

            find: (id) -> taskResource.get(id: id)

            historyTasks: () ->
                tasks = []
                CurrentUser.then (userName) ->
                    taskResource.history assignee: userName, (taskData) ->
                        tasks.push(td) for td in taskData
                return tasks



            take: (task) ->
                CurrentUser.then (userData) ->
                    task.assignee = userData
                    taskResource.take task, (taskData) ->
                        userTaskInfo.availTasks = (t for t in userTaskInfo.availTasks when t.id isnt taskData.id)

            complete: (task) ->
                url = "#{ServiceUrls.cowServer}/tasks/#{task.id}"
                vars = ResourceHelpers.encodeVars(task.variables)
                if vars?
                    url += "?#{vars}"
                $http.delete(url).success ->
                    userTaskInfo.myTasks = (t for t in userTaskInfo.myTasks when t.id isnt task.id )
        }
]



## Directives ##
angular.module "moo.tasks.directives", []

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
