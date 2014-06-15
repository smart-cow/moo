// Generated by CoffeeScript 1.7.1
(function() {
  angular.module("moo.services", ["ngResource"]).constant("ResourceHelpers", {
    fixVars: function(resource) {
      var _ref, _ref1, _ref2, _ref3;
      return resource.variables = (_ref = (_ref1 = (_ref2 = resource.variables) != null ? _ref2.variable : void 0) != null ? _ref1 : (_ref3 = resource.variables) != null ? _ref3.variables : void 0) != null ? _ref : [];
    },
    encodeVars: function(variables) {
      var v, varPairs;
      if (variables.length === 0) {
        return null;
      }
      varPairs = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = variables.length; _i < _len; _i++) {
          v = variables[_i];
          _results.push("var=" + v.name + ":" + v.value);
        }
        return _results;
      })();
      return varPairs.join("&");
    }
  }).factory("CurrentUser", [
    "$q", "$resource", "ServiceUrls", function($q, $resource, ServiceUrls) {
      var userName, whoamiResource;
      userName = $q.defer();
      whoamiResource = $resource("" + ServiceUrls.cowServer + "/whoami", {}, {});
      whoamiResource.get(function(data) {
        return userName.resolve(data.id);
      });
      return userName.promise;
    }
  ]).factory("Task", [
    "$http", "$resource", "CurrentUser", "ServiceUrls", "ResourceHelpers", function($http, $resource, CurrentUser, ServiceUrls, ResourceHelpers) {
      var taskResource, userTaskInfo;
      taskResource = $resource("" + ServiceUrls.cowServer + "/tasks/:id", {}, {
        get: {
          transformResponse: function(data) {
            var task;
            task = JSON.parse(data);
            ResourceHelpers.fixVars(task);
            return task;
          }
        },
        query: {
          isArray: true,
          transformResponse: function(data) {
            var task, tasks, _i, _len;
            tasks = JSON.parse(data).task;
            for (_i = 0, _len = tasks.length; _i < _len; _i++) {
              task = tasks[_i];
              ResourceHelpers.fixVars(task);
            }
            return tasks;
          }
        },
        take: {
          url: "" + ServiceUrls.cowServer + "/tasks/:id/take",
          params: {
            id: "@id",
            assignee: "@assignee"
          },
          method: "POST"
        }
      });
      userTaskInfo = {};
      CurrentUser.then(function(userName) {
        userTaskInfo.myTasks = taskResource.query({
          assignee: userName
        });
        return userTaskInfo.availTasks = taskResource.query({
          candidate: userName
        });
      });
      return {
        userTasks: userTaskInfo,
        take: function(task) {
          return CurrentUser.then(function(userData) {
            task.assignee = userData;
            return taskResource.take(task, function(taskData) {
              var t;
              return userTaskInfo.availTasks = (function() {
                var _i, _len, _ref, _results;
                _ref = userTaskInfo.availTasks;
                _results = [];
                for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                  t = _ref[_i];
                  if (t.id !== taskData.id) {
                    _results.push(t);
                  }
                }
                return _results;
              })();
            });
          });
        },
        complete: function(task) {
          var url, vars;
          url = "" + ServiceUrls.cowServer + "/tasks/" + task.id;
          vars = ResourceHelpers.encodeVars(task.variables);
          if (vars != null) {
            url += "?" + vars;
          }
          return $http["delete"](url).success(function() {
            var t;
            return userTaskInfo.myTasks = (function() {
              var _i, _len, _ref, _results;
              _ref = userTaskInfo.myTasks;
              _results = [];
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                t = _ref[_i];
                if (t.id !== task.id) {
                  _results.push(t);
                }
              }
              return _results;
            })();
          });
        }
      };
    }
  ]).factory("RunningWorkflow", [
    "$resource", "ServiceUrls", function($resource, ServiceUrls) {
      var statuses, workflowsResource;
      workflowsResource = $resource("" + ServiceUrls.cowServer + "/processInstances/:id", {}, {
        query: {
          isArray: true,
          transformResponse: function(data) {
            return JSON.parse(data).processInstance;
          }
        },
        status: {
          url: "" + ServiceUrls.cowServer + "/processInstances/:id/status"
        }
      });
      statuses = [];
      return {
        workflows: workflowsResource.query(),
        getStatuses: function() {
          workflowsResource.query().$promise.then(function(workflows) {
            var idNum, wf, _i, _len, _results;
            _results = [];
            for (_i = 0, _len = workflows.length; _i < _len; _i++) {
              wf = workflows[_i];
              idNum = wf.id.rightOf(".");
              _results.push(workflowsResource.status({
                id: idNum
              }, function(status) {
                return statuses.push({
                  id: status.id,
                  status: status.statusSummary
                });
              }));
            }
            return _results;
          });
          return statuses;
        }
      };
    }
  ]);

}).call(this);

//# sourceMappingURL=services.map
