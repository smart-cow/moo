'use strict';

/* Services */


var services = angular.module('scow.services', ["ngResource"]);

services.factory("Task", ["$resource",
    function($resource) {
        return $resource("http://scout2:8080/cow-server/tasks/:id", {}, {
            query: { isArray:true, transformResponse:
                function(data) {
                    return JSON.parse(data).task;
                 }
            }
        });
    }
]);