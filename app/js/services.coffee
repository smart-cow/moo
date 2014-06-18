## Services ##

angular.module "moo.services", [
    "ngResource"
]



.constant "ResourceHelpers", {
    fixVars: (resource) ->
        resource.variables = resource.variables?.variable ? resource.variables?.variables ? []

    encodeVars: (variables) ->
        return null if variables.length is 0
        varPairs = ("var=#{v.name}:#{v.value}" for v in variables)
        varPairs.join("&")
}


.factory "CurrentUser", [
    "$q", "$resource", "ServiceUrls"
    ($q, $resource, ServiceUrls) ->
        userName = $q.defer()

        whoamiResource = $resource("#{ServiceUrls.cowServer}/whoami", {}, {})
        whoamiResource.get (data) ->
            userName.resolve(data.id)

        return userName.promise
]


.factory "Task", [
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



.factory "RunningWorkflow", [
    "$resource", "ServiceUrls"
    ($resource, ServiceUrls) ->
        workflowsResource = $resource "#{ServiceUrls.cowServer}/processInstances/:id", {},
            query:
                isArray: true
                transformResponse: (data) ->
                    JSON.parse(data).processInstance
            status:
                url: "#{ServiceUrls.cowServer}/processInstances/:id/status"

        statuses = []

        return {
            workflows: workflowsResource.query()
            getStatuses: ->
                workflowsResource.query().$promise.then (workflows) ->
                    for wf in workflows
                        idNum = wf.id.rightOf(".")
                        workflowsResource.status id: idNum, (status) ->
                            statuses.push
                                id: status.id
                                status: status.statusSummary
                return statuses
        }
]

