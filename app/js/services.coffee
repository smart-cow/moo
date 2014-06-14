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
    "$resource", "CurrentUser", "ServiceUrls", "ResourceHelpers"
    ($resource, CurrentUser, ServiceUrls, ResourceHelpers) ->
        taskResource = $resource "#{ServiceUrls.cowServer}/tasks/:id", {},
            query:
                isArray: true
                transformResponse: (data) -> JSON.parse(data).task

        qb = ResourceHelpers.queryBuilder
        return {
            all: qb(taskResource.query)
            find: qb(taskResource.get, "id")
            assigned: qb(taskResource.query, "assignee")
            candidate: qb(taskResource.query, "candidate")
        }
]


