angular.module "moo.cow.web-service", [
    "ngResource"
]

.factory "CowUrl", [
    "ServiceUrls",
    (ServiceUrls) ->
        return (resourcePath) ->
            if resourcePath[0] == "/"
                resourcePath = resourcePath.substring(1)
            return ServiceUrls.cowServer + resourcePath

]


.factory "MooResource", [
    "$resource", "CowUrl"
    ($resource, CowUrl) ->


        # When receiving a list it wraps it in a object with one key, the list.
        # This will extract the list, if data: is an object, has a single key, key's value is array
        fixJaxbObjectArray = (resource) ->
            # If it is an array no modification necessary
            return resource if angular.isArray(resource)

            keys = Object.keys(resource)
            # We are only interested in objects with exactly one key
            return resource unless keys.length == 1

            value = resource[keys[0]]
            # If the value isn't an array, then the data is just an object with a single key
            return resource unless angular.isArray(value)
            return value


        knownObjectArrayKeys = ["variables", "variable", "outcome", "outcomes"]

        fixObjectResource = (resource) ->
            return resource unless resource?
            for key in knownObjectArrayKeys
                if resource[key]?
                    resource[key] = fixJaxbObjectArray(resource[key])
            return resource



        fixResource = (resource) ->
            return resource unless resource?
            arrayResource = fixJaxbObjectArray(resource)
            if angular.isArray(arrayResource)
                fixObjectResource(r) for r in arrayResource
                return arrayResource
            else
                return fixObjectResource(resource)



        setDefaults = (action) ->
            action.responseType = "json"
            action.withCredentials = true
            action.transformResponse = [ fixResource ]


        actionTemplates =
            get: ->
                method: "GET"
            query: ->
                method: "GET"
                isArray: true
            save: ->
                method: "POST"
            post: ->
                method: "POST"
            update: ->
                method: "PUT"
            delete: ->
                method: "DELETE"
            remove: ->
                method: "DELETE"

        buildDefaultAction = (templateType) ->
            action = actionTemplates[templateType]?() ? { }
            setDefaults(action)
            return action

        defaultActions = ->
            actions = { }
            for own templateType of actionTemplates
                actions[templateType] = buildDefaultAction(templateType)
            return actions



        # These are properties that can just be copied when an action doesn't specify its own value
        defaultPropsToCopy = [ "method", "isArray", "responseType", "withCredentials"]

        combineWithDefaults = (action, defaultAction) ->
            for prop in defaultPropsToCopy
                # only copy from defaultAction when not defined in action
                action[prop] ?= defaultAction[prop]

            # Can't just copy transformResponse because it is an array
            defaultXform = defaultAction.transformResponse ? []
            if action.transformResponse?
                # If action defines a transform, append to the end of the list of transforms
                defaultXform.push(action.transformResponse)
            action.transformResponse = defaultXform


        configureAction = (name, action) ->
            if action.path?
                action.url = CowUrl(action.path)
            defaultAction = buildDefaultAction(action.template ? name)
            combineWithDefaults(action, defaultAction)
            return action


        return (path, actions, paramDefaults = { }) ->
            ngActions = defaultActions()
            if actions?
                for own name, action of actions
                    ngActions[name] = configureAction(name, action)
            return $resource(CowUrl(path), paramDefaults, ngActions)
]

# Helper methods for interacting with scow api objects
.constant "ResourceHelpers", {
    fixVars: (resource) ->
        unless angular.isArray(resource.variables)
            resource.variables = resource.variables?.variable ? resource.variables?.variables ? []
        return resource

    fixOutcomes: (resource) ->
        unless angular.isArray(resource.outcomes)
            resource.outcomes = resource.outcome ? resource.outcomes ? []
            delete resource.outcome
        return resource


    encodeVars: (variables) ->
        return ("#{v.name}:#{v.value}" for v in variables)

    promiseParam: (promise, isArray, serviceCall) ->
        resolvedObj = if isArray then [] else { }
        promiseThen = promise.then ? promise.$promise.then
        promiseThen (promisedData) ->
            serviceCall(promisedData).$promise.then (serviceData) ->
                for own k, v of serviceData
                    resolvedObj[k] = v
        return resolvedObj

}


# Provide access to the currently logged in user
.factory "CurrentUser", [
    "MooResource", "ServiceUrls"
    (MooResource) ->

        whoamiResource = MooResource "whoami",
            get:
                transformResponse: (userData) ->
                    return {
                    name: userData.id
                    groups: (m.group for m in userData.membership)
                    }
        user = whoamiResource.get()
        return user
]



.factory "Tasks", [
    "$rootScope", "MooResource", "CurrentUser", "ResourceHelpers", "ScowPush"
    ($rootScope, MooResource, CurrentUser, ResourceHelpers, ScowPush) ->

        taskResource = { }
        userTasks =
            myTasks: []
            availableTasks: []

        # Correct for issues with scow's json serializer
        setOutcome = (task) ->
            if task.outcomes?.length is 1
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


        # Configure access to cow-server's tasks
        taskResource = MooResource "/tasks/:id",
            get:
                transformResponse: setOutcome
            query:
                isArray: true
                transformResponse: (tasks) ->
                    return (setOutcome(task) for task in tasks)
            take:
                path: "tasks/:id/take"
                params:
                    id: "@id"
                    assignee: "@assignee"
                template: "post"
            complete:
                path: "tasks/:id"
                method: "DELETE"
                params:
                    id: "@id"
                    outcome: "@selectedOutcome"
                    vars: "@encodedVars"
            history:
                isArray: true
                path: "/tasks/history"
                params:
                #TODO: Use a better data range
                    start: (new Date().getFullYear() - 1) + "-1-1"
                    end: (new Date().getFullYear() + 1) + "-1-1"

        # Need to know which user is connected, so we have to wait until after the service call completes
        CurrentUser.$promise.then (user) ->
            getTaskList = (qsKey) ->
                queryString = { }
                queryString[qsKey] = user.name
                taskResource.query queryString, (tasks) ->
                    updateTask(t) for t in tasks
            getTaskList("assignee")
            getTaskList("candidate")


        CurrentUser.$promise.then (user) ->
            console.log("set setup subscription for %o", user)
            updateTaskFromPush = (data) ->
                $rootScope.$apply ->
                    updateTask(data)
            ScowPush.subscribe("#.tasks.#.user." + user.name, updateTaskFromPush)
            ScowPush.subscribe("#.tasks.#.group." + group, updateTaskFromPush) for group in user.groups



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


.factory "Workflows", [
    "MooResource"
    (MooResource) ->
        processResource = MooResource "processes/:id",
            query:
                path: "processDefinitions"
                transformResponse: (definitions) ->
                    return (d.key for d in definitions)
            update:
                method: "PUT"
                headers:
                    "Content-Type": "application/xml"

            instances:
                template: "query"
                path: "processes/:id/processInstances"

            deleteInstances:
                template: "delete"
                path: "processes/:id/processInstances"


        return {
            get: (id, onSuccess, onFailure) ->
                processResource.get(id: id, onSuccess, onFailure)

            query: (onSuccess, onFailure) ->
                processResource.query(onSuccess, onFailure)

            update: (name, workflowXml, onSuccess, onFailure) ->
                workflowString = new XMLSerializer().serializeToString(workflowXml);
                processResource.update(id: name, workflowString, onSuccess, onFailure)

            instances: (name, onSuccess, onFailure) ->
                processResource.instances(id: name, onSuccess, onFailure)

            deleteInstances: (name, onSuccess, onFailure) ->
                processResource.deleteInstances(id: name, onSuccess, onFailure)
        }
]

.factory "RunningWorkflows", [
    "MooResource"
    (MooResource) ->
        workflowsResource = MooResource "processInstances/:id",
            statusSummary:
                path: "processInstances/:id/status"
                template: "get"
                transformResponse: (wflowStatus) ->
                    statusSummary = wflowStatus.statusSummary

                    statuses = for ss in statusSummary
                        name: ss.name
                        status: ss.status
                        task: ss.task[0].name
                    return {
                        name: wflowStatus.id
                        statuses: statuses
                    }
            fullStatus:
                path: "processInstances/:id/status"
                template: "get"
            start:
                template: "post"
                path: "processInstances"



        statuses = []
        getAllStatusSummaries = ->
            statuses.m$clear()
            workflowsResource.all (workflows) ->
                for wf in workflows
                    idNum = wf.id.m$rightOf(".")
                    statuses.push(workflowsResource.statusSummary(id: idNum))
            return statuses


        buildStartRequest = (workflowName, variables) ->
            reqBody = processDefinitionKey: workflowName
            if variables?.length > 0
                requestVariables = (name: v.name, value: v.value for v in variables)
                reqBody.variables = variable: requestVariables
            return reqBody


        return {
            query: workflowsResource.query

            start: (workflowName, variables, callbacks...) ->
                req = buildStartRequest(workflowName, variables)
                workflowsResource.start({ }, req, callbacks...)

            fullStatus: (wflowIdNum, onSuccess, onFailure) ->
                workflowsResource.fullStatus(id: wflowIdNum, onSuccess, onFailure)

            statusSummary: (wflowIdNum, onSuccess, onFailure) ->
                workflowsResource.statusSummary(id: wflowIdNum, onSuccess, onFailure)

            allStatusSummaries: getAllStatusSummaries

            delete: (id, onSuccess, onFailure) ->
                id = id.m$rightOf(".")
                workflowsResource.delete(id: id, onSuccess, onFailure)
        }
]




# Used to subscribe to AMQP messages
.factory "ScowPush", [
    "ServiceUrls"
    (ServiceUrls) ->

        addSubscription = ->

        init = ->
            amqpInfo = ServiceUrls.amqp

            stomp = Stomp.over(new SockJS(amqpInfo.url))
            stomp.debug = ->
            subscriptions = []
            isConnected = false

            addSubscription = (subscription) ->
                subscriptions.push(subscription)
                amqpSubscribe(subscription) if isConnected

            amqpSubscribe = (subscription) ->
                destination = amqpInfo.exchange + subscription.routingKey
                stomp.subscribe destination, (message) ->
                    routingKey = message.headers.destination.m$rightOf("/")
                    parsedBody = angular.fromJson(message.body)
                    subscription.onReceive(parsedBody, routingKey)

            stompConnect = ->
                onConnect = ->
                    console.log("Stomp connected")
                    isConnected = true
                    amqpSubscribe(s) for s in subscriptions

                onError = ->
                    isConnected = false
                    console.log("Error: disconnected from AMQP: %o", arguments)
                stomp.connect(amqpInfo.username, amqpInfo.password, onConnect, onError)
            stompConnect()
        init()


        return {
        subscribe: (routingKey, onReceive) ->
            console.log(routingKey)
            addSubscription(routingKey: routingKey, onReceive: onReceive)
        }
]