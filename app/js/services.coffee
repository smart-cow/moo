## Services ##

angular.module "moo.services", [
    "ngResource"
]



.constant "ResourceHelpers", {
    queryBuilder: (action, key = null) ->
        if key
            return (param, callBack) ->
                paramObj = { }
                paramObj[key] = param
                action(paramObj, callBack)
        else
            return (callBack) ->
                action(callBack)

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
    "$rootScope", "$http", "$resource", "CurrentUser", "ServiceUrls", "ResourceHelpers"
    ($rootScope, $http, $resource, CurrentUser, ServiceUrls, ResourceHelpers) ->
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


        qb = ResourceHelpers.queryBuilder
        return {
            all: qb(taskResource.query)
            find: qb(taskResource.get, "id")
            assigned: qb(taskResource.query, "assignee")
            candidate: qb(taskResource.query, "candidate")

            take: (task) ->
                CurrentUser.then (userData) ->
                    task.assignee = userData
                    taskResource.take task, (taskData) ->
                        $rootScope.$broadcast("task.take", taskData)

            complete: (task) ->
                url = "#{ServiceUrls.cowServer}/tasks/#{task.id}"
                vars = ResourceHelpers.encodeVars(task.variables)
                if vars?
                    url += "?#{vars}"
                $http.delete(url).success ->
                    $rootScope.$broadcast("task.complete", task)

        }
]


