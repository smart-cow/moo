// Generated by CoffeeScript 1.7.1
(function() {
  var app;

  app = angular.module("moo", ["ngRoute", "moo.directives", "moo.tasks.controllers", "moo.active-workflows.controllers", "moo.admin.controllers"]).constant("ServiceUrls", {
    cowServer: "http://scout2:8080/cow-server/",
    url: function(path) {
      return this.cowServer + path;
    },
    amqp: {
      url: "http://scout2:15674/stomp",
      exchange: "/exchange/amq.topic/",
      connectTimeout: 5 * 1000,
      username: "guest",
      password: "guest"
    }
  }).constant("Areas", [
    {
      name: "Tasks",
      defaultRoute: {
        url: "/tasks",
        templateUrl: "partials/tasks/task-home.html",
        controller: "TaskListCtrl"
      },
      otherRoutes: [
        {
          url: "/tasks/:taskId",
          templateUrl: "partials/tasks/task-detail.html",
          controller: "TaskDetailCtrl"
        }
      ]
    }, {
      name: "Active Workflows",
      defaultRoute: {
        url: "/active-workflows",
        templateUrl: "partials/active-workflows/active-workflows.html",
        controller: "ActiveWorkflowsCtrl"
      }
    }, {
      name: "Admin",
      defaultRoute: {
        url: "/admin",
        templateUrl: "partials/admin/admin.html",
        controller: "AdminCtrl"
      }
    }
  ]).config([
    "$routeProvider", "Areas", function($routeProvider, Areas) {
      var addRoute, area, route, _i, _j, _len, _len1, _ref;
      addRoute = function(areaName, route) {
        return $routeProvider.when(route.url, {
          templateUrl: route.templateUrl,
          controller: route.controller,
          provide: {
            area: areaName
          }
        });
      };
      for (_i = 0, _len = Areas.length; _i < _len; _i++) {
        area = Areas[_i];
        addRoute(area.name, area.defaultRoute);
        if (area.otherRoutes == null) {
          continue;
        }
        _ref = area.otherRoutes;
        for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
          route = _ref[_j];
          addRoute(area.name, route);
        }
      }
      return $routeProvider.otherwise({
        redirectTo: "/tasks"
      });
    }
  ]).config([
    "$httpProvider", function($httpProvider) {
      return $httpProvider.defaults.withCredentials = true;
    }
  ]);

}).call(this);

//# sourceMappingURL=app.map
