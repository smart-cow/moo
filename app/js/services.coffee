## Services ##

angular.module "moo.services", [
    "ngResource"
]

.factory "Task", [
    "$resource", "serviceUrls"
    ($resource, serviceUrls) ->
        $resource "#{serviceUrls.cowServer}/tasks/:id", { },
            query:
                isArray: true
                transformResponse: (data) -> JSON.parse(data).task
]

