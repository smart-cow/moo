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


        userTaskInfo = { }
        CurrentUser.then (userName) ->
            userTaskInfo.myTasks = taskResource.query(assignee: userName)
            userTaskInfo.availTasks = taskResource.query(candidate: userName)

        return {
            userTasks: userTaskInfo

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


