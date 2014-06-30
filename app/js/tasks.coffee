
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
    "$rootScope", "$resource", "CurrentUser", "ServiceUrls", "ResourceHelpers", "ScowPush"
    ($rootScope, $resource, CurrentUser, ServiceUrls, ResourceHelpers, ScowPush) ->

        taskResource = { }
        userTasks = { }

        fixUpTask = (task) ->
            ResourceHelpers.fixVars(task)
            ResourceHelpers.fixOutcomes(task)
            if task.outcomes.length is 1
                task.selectedOutcome = task.outcomes[0]
            return task

        updateTask = (newTaskData) ->
            ResourceHelpers.fixVars(newTaskData)
            userTasks.myTasks.m$remove (t) -> t.id is newTaskData.id
            userTasks.availableTasks.m$remove (t) -> t.id is newTaskData.id

            if newTaskData.state is "Ready"
                userTasks.availableTasks.push(newTaskData)
            if newTaskData.state is "Reserved" and newTaskData.assignee is CurrentUser.name
                userTasks.myTasks.push(newTaskData)


        init = ->
            taskResource = (initResourceLib = ->
                actions = {
                    get:
                        transformResponse: (data) ->
                            fixUpTask(angular.fromJson(data))
                    query:
                        isArray: true
                        transformResponse: (data) ->
                            tasks = angular.fromJson(data).task
                            return (fixUpTask(task) for task in tasks)

                    take:
                        url: ServiceUrls.url("tasks/:id/take")
                        params:
                            id: "@id"
                            assignee: "@assignee"
                        method: "POST"

                    complete:
                        url: ServiceUrls.url("tasks/:id")
                        method: "DELETE"
                        params:
                            id: "@id"
                            outcome: "@selectedOutcome"
                            vars: "@encodedVars"

                    history:
                        isArray: true
                        url: ServiceUrls.url("/tasks/history")
                        params:
                            start: (new Date().getFullYear() - 1) + "-1-1"
                            end: (new Date().getFullYear() + 1) + "-1-1"
                        transformResponse: (data) ->
                            JSON.parse(data).historyTask
                }
                return $resource(ServiceUrls.url("/tasks/:id"), {}, actions)
            )()

            userTasks = (initializeUserTasks = ->
                CurrentUser.$promise.then (user) ->
                    getTaskList = (qsKey) ->
                        queryString = { }
                        queryString[qsKey] = user.name
                        taskResource.query queryString, (tasks) ->
                            updateTask(t) for t in tasks
                    getTaskList("assignee")
                    getTaskList("candidate")
                return {
                    myTasks: []
                    availableTasks: []
                }
            )()

            (initPushSubscription = ->
                CurrentUser.$promise.then (user) ->
                    console.log("set setup subscription for %o", user)
                    updateTaskFromPush = (data) ->
                        $rootScope.$apply ->
                            updateTask(data)
                    ScowPush.subscribe("#.tasks.#.user." + user.name, updateTaskFromPush)
                    ScowPush.subscribe("#.tasks.#.group." + group, updateTaskFromPush) for group in user.groups
            )()
        init()



        return {
            find: (id) -> taskResource.get(id: id)

            userTaskInfo: userTasks

            historyTasks: ->
                ResourceHelpers.promiseParam CurrentUser, true, (user) ->
                    taskResource.history(assignee: user.name)

            take: (task) ->
                task.assignee = CurrentUser.name
                taskResource.take(task, updateTask)

            complete: (task) ->
                taskResource.complete({
                    id: task.id
                    outcome: task.selectedOutcome
                    var: ResourceHelpers.encodeVars(task.variables)
                }, ->
                    userTasks.myTasks.m$remove (e) ->
                        e.id == task.id
                )
        }
]



## Directives ##
angular.module "moo.tasks.directives", [
    "moo.tasks.services"
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
