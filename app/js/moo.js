// Generated by CoffeeScript 1.7.1
(function() {
  var __slice = [].slice,
    __hasProp = {}.hasOwnProperty;

  angular.module("moo.services", ["ngResource"]).factory("CowUrl", [
    "ServiceUrls", function(ServiceUrls) {
      return function(resourcePath) {
        if (resourcePath[0] === "/") {
          resourcePath = resourcePath.substring(1);
        }
        return ServiceUrls.cowServer + resourcePath;
      };
    }
  ]).constant("ResourceHelpers", {
    fixVars: function(resource) {
      var _ref, _ref1, _ref2, _ref3;
      if (!angular.isArray(resource.variables)) {
        resource.variables = (_ref = (_ref1 = (_ref2 = resource.variables) != null ? _ref2.variable : void 0) != null ? _ref1 : (_ref3 = resource.variables) != null ? _ref3.variables : void 0) != null ? _ref : [];
      }
      return resource;
    },
    fixOutcomes: function(resource) {
      var _ref, _ref1;
      if (!angular.isArray(resource.outcomes)) {
        resource.outcomes = (_ref = (_ref1 = resource.outcome) != null ? _ref1 : resource.outcomes) != null ? _ref : [];
        delete resource.outcome;
      }
      return resource;
    },
    encodeVars: function(variables) {
      var v;
      return (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = variables.length; _i < _len; _i++) {
          v = variables[_i];
          _results.push("" + v.name + ":" + v.value);
        }
        return _results;
      })();
    },
    promiseParam: function(promise, isArray, serviceCall) {
      var promiseThen, resolvedObj, _ref;
      resolvedObj = isArray ? [] : {};
      promiseThen = (_ref = promise.then) != null ? _ref : promise.$promise.then;
      promiseThen(function(promisedData) {
        return serviceCall(promisedData).$promise.then(function(serviceData) {
          var k, v, _results;
          _results = [];
          for (k in serviceData) {
            if (!__hasProp.call(serviceData, k)) continue;
            v = serviceData[k];
            _results.push(resolvedObj[k] = v);
          }
          return _results;
        });
      });
      return resolvedObj;
    }
  }).factory("MooResource", [
    "$resource", "$q", "CowUrl", function($resource, $q, CowUrl) {
      var actionTemplates, buildDefaultAction, combineWithDefaults, configureAction, defaultActions, defaultPropsToCopy, fixJaxbObjectArray, fixObjectResource, fixResource, knownObjectArrayKeys, setDefaults;
      fixJaxbObjectArray = function(resource) {
        var keys, value;
        if (angular.isArray(resource)) {
          return resource;
        }
        keys = Object.keys(resource);
        if (keys.length !== 1) {
          return resource;
        }
        value = resource[keys[0]];
        if (!angular.isArray(value)) {
          return resource;
        }
        return value;
      };
      knownObjectArrayKeys = ["variables", "variable", "outcome", "outcomes"];
      fixObjectResource = function(resource) {
        var key, _i, _len;
        if (resource == null) {
          return resource;
        }
        for (_i = 0, _len = knownObjectArrayKeys.length; _i < _len; _i++) {
          key = knownObjectArrayKeys[_i];
          if (resource[key] != null) {
            resource[key] = fixJaxbObjectArray(resource[key]);
          }
        }
        return resource;
      };
      fixResource = function(resource) {
        var arrayResource, r, _i, _len;
        if (resource == null) {
          return resource;
        }
        arrayResource = fixJaxbObjectArray(resource);
        if (angular.isArray(arrayResource)) {
          for (_i = 0, _len = arrayResource.length; _i < _len; _i++) {
            r = arrayResource[_i];
            fixObjectResource(r);
          }
          return arrayResource;
        } else {
          return fixObjectResource(resource);
        }
      };
      setDefaults = function(action) {
        action.responseType = "json";
        action.withCredentials = true;
        return action.transformResponse = [fixResource];
      };
      actionTemplates = {
        get: function() {
          return {
            method: "GET"
          };
        },
        query: function() {
          return {
            method: "GET",
            isArray: true
          };
        },
        save: function() {
          return {
            method: "POST"
          };
        },
        post: function() {
          return {
            method: "POST"
          };
        },
        update: function() {
          return {
            method: "PUT"
          };
        },
        "delete": function() {
          return {
            method: "DELETE"
          };
        },
        remove: function() {
          return {
            method: "DELETE"
          };
        }
      };
      buildDefaultAction = function(templateType) {
        var action, _ref;
        action = (_ref = typeof actionTemplates[templateType] === "function" ? actionTemplates[templateType]() : void 0) != null ? _ref : {};
        setDefaults(action);
        return action;
      };
      defaultActions = function() {
        var actions, templateType;
        actions = {};
        for (templateType in actionTemplates) {
          if (!__hasProp.call(actionTemplates, templateType)) continue;
          actions[templateType] = buildDefaultAction(templateType);
        }
        return actions;
      };
      defaultPropsToCopy = ["method", "isArray", "responseType", "withCredentials"];
      combineWithDefaults = function(action, defaultAction) {
        var defaultXform, prop, _i, _len, _ref;
        for (_i = 0, _len = defaultPropsToCopy.length; _i < _len; _i++) {
          prop = defaultPropsToCopy[_i];
          if (action[prop] == null) {
            action[prop] = defaultAction[prop];
          }
        }
        defaultXform = (_ref = defaultAction.transformResponse) != null ? _ref : [];
        if (action.transformResponse != null) {
          defaultXform.push(action.transformResponse);
        }
        return action.transformResponse = defaultXform;
      };
      configureAction = function(name, action) {
        var defaultAction, _ref;
        if (action.path != null) {
          action.url = CowUrl(action.path);
        }
        defaultAction = buildDefaultAction((_ref = action.template) != null ? _ref : name);
        combineWithDefaults(action, defaultAction);
        return action;
      };
      return function(path, actions, paramDefaults) {
        var action, name, ngActions;
        if (paramDefaults == null) {
          paramDefaults = {};
        }
        ngActions = defaultActions();
        if (actions != null) {
          for (name in actions) {
            if (!__hasProp.call(actions, name)) continue;
            action = actions[name];
            ngActions[name] = configureAction(name, action);
          }
        }
        return $resource(CowUrl(path), paramDefaults, ngActions);
      };
    }
  ]).factory("CurrentUser", [
    "MooResource", "ServiceUrls", function(MooResource) {
      var user, whoamiResource;
      whoamiResource = MooResource("whoami", {
        get: {
          transformResponse: function(userData) {
            var m;
            return {
              name: userData.id,
              groups: (function() {
                var _i, _len, _ref, _results;
                _ref = userData.membership;
                _results = [];
                for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                  m = _ref[_i];
                  _results.push(m.group);
                }
                return _results;
              })()
            };
          }
        }
      });
      user = whoamiResource.get();
      return user;
    }
  ]).factory("RunningWorkflows", [
    "MooResource", function(MooResource) {
      var buildStartRequest, getAllStatuses, statuses, workflowsResource;
      workflowsResource = MooResource("processInstances/:id", {
        status: {
          path: "processInstances/:id/status",
          template: "get",
          transformResponse: function(wflowStatus) {
            var ss, statusSummary, statuses;
            statusSummary = wflowStatus.statusSummary;
            statuses = (function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = statusSummary.length; _i < _len; _i++) {
                ss = statusSummary[_i];
                _results.push({
                  name: ss.name,
                  status: ss.status,
                  task: ss.task[0].name
                });
              }
              return _results;
            })();
            return {
              name: wflowStatus.id,
              statuses: statuses
            };
          }
        },
        start: {
          template: "post",
          path: "processInstances"
        }
      });
      statuses = [];
      getAllStatuses = function() {
        statuses.m$clear();
        workflowsResource.all(function(workflows) {
          var idNum, wf, _i, _len, _results;
          _results = [];
          for (_i = 0, _len = workflows.length; _i < _len; _i++) {
            wf = workflows[_i];
            idNum = wf.id.m$rightOf(".");
            _results.push(statuses.push(workflowsResource.status({
              id: idNum
            })));
          }
          return _results;
        });
        return statuses;
      };
      buildStartRequest = function(workflowName, variables) {
        var reqBody, requestVariables, v;
        reqBody = {
          processDefinitionKey: workflowName
        };
        if (variables.length > 0) {
          requestVariables = (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = variables.length; _i < _len; _i++) {
              v = variables[_i];
              _results.push({
                name: v.name,
                value: v.value
              });
            }
            return _results;
          })();
          reqBody.variables = {
            variable: requestVariables
          };
        }
        return reqBody;
      };
      return {
        query: workflowsResource.query,
        start: function() {
          var callbacks, req, variables, workflowName;
          workflowName = arguments[0], variables = arguments[1], callbacks = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
          req = buildStartRequest(workflowName, variables);
          return workflowsResource.start.apply(workflowsResource, [{}, req].concat(__slice.call(callbacks)));
        },
        status: function(wflowIdNum, onSuccess, onFailure) {
          return workflowsResource.status({
            id: wflowIdNum
          }, onSuccess, onFailure);
        },
        allStatuses: getAllStatuses,
        "delete": function(id, onSuccess, onFailure) {
          id = id.m$rightOf(".");
          return workflowsResource["delete"]({
            id: id
          }, onSuccess, onFailure);
        }
      };
    }
  ]).factory("Workflows", [
    "MooResource", function(MooResource) {
      var processResource;
      processResource = MooResource("processes/:id", {
        query: {
          path: "processDefinitions",
          transformResponse: function(definitions) {
            var d;
            return (function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = definitions.length; _i < _len; _i++) {
                d = definitions[_i];
                _results.push(d.key);
              }
              return _results;
            })();
          }
        },
        update: {
          method: "PUT",
          headers: {
            "Content-Type": "application/xml"
          }
        },
        instances: {
          template: "query",
          path: "processes/:id/processInstances"
        },
        deleteInstances: {
          template: "delete",
          path: "processes/:id/processInstances"
        }
      });
      return {
        get: function(id, onSuccess, onFailure) {
          return processResource.get({
            id: id
          }, onSuccess, onFailure);
        },
        query: function(onSuccess, onFailure) {
          return processResource.query(onSuccess, onFailure);
        },
        update: function(name, workflowXml, onSuccess, onFailure) {
          var workflowString;
          workflowString = new XMLSerializer().serializeToString(workflowXml);
          return processResource.update({
            id: name
          }, workflowString, onSuccess, onFailure);
        },
        instances: function(name, onSuccess, onFailure) {
          return processResource.instances({
            id: name
          }, onSuccess, onFailure);
        },
        deleteInstances: function(name, onSuccess, onFailure) {
          return processResource.deleteInstances({
            id: name
          }, onSuccess, onFailure);
        }
      };
    }
  ]).factory("ScowPush", [
    "ServiceUrls", function(ServiceUrls) {
      var addSubscription, init;
      addSubscription = function() {};
      init = function() {
        var amqpInfo, amqpSubscribe, isConnected, stomp, stompConnect, subscriptions;
        amqpInfo = ServiceUrls.amqp;
        stomp = Stomp.over(new SockJS(amqpInfo.url));
        stomp.debug = function() {};
        subscriptions = [];
        isConnected = false;
        addSubscription = function(subscription) {
          subscriptions.push(subscription);
          if (isConnected) {
            return amqpSubscribe(subscription);
          }
        };
        amqpSubscribe = function(subscription) {
          var destination;
          destination = amqpInfo.exchange + subscription.routingKey;
          return stomp.subscribe(destination, function(message) {
            var parsedBody, routingKey;
            routingKey = message.headers.destination.m$rightOf("/");
            parsedBody = angular.fromJson(message.body);
            return subscription.onReceive(parsedBody, routingKey);
          });
        };
        stompConnect = function() {
          var onConnect, onError;
          onConnect = function() {
            var s, _i, _len, _results;
            console.log("Stomp connected");
            isConnected = true;
            _results = [];
            for (_i = 0, _len = subscriptions.length; _i < _len; _i++) {
              s = subscriptions[_i];
              _results.push(amqpSubscribe(s));
            }
            return _results;
          };
          onError = function() {
            isConnected = false;
            return console.log("Error: disconnected from AMQP: %o", arguments);
          };
          return stomp.connect(amqpInfo.username, amqpInfo.password, onConnect, onError);
        };
        return stompConnect();
      };
      init();
      return {
        subscribe: function(routingKey, onReceive) {
          console.log(routingKey);
          return addSubscription({
            routingKey: routingKey,
            onReceive: onReceive
          });
        }
      };
    }
  ]);

  angular.module("moo.directives", []).directive("mooNavMenu", [
    "$route", "Areas", function($route, Areas) {
      return {
        restrict: "E",
        templateUrl: "partials/nav-menu.html",
        link: function($scope) {
          var area;
          $scope.tabs = (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = Areas.length; _i < _len; _i++) {
              area = Areas[_i];
              _results.push({
                title: area.name,
                url: "#" + area.defaultRoute.url,
                selected: area.name === $route.current.provide.area
              });
            }
            return _results;
          })();
          return $scope.$on("$routeChangeSuccess", function(evt, newRoute) {
            var tab, _i, _len, _ref, _results;
            _ref = $scope.tabs;
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              tab = _ref[_i];
              _results.push(tab.selected = tab.title === newRoute.provide.area);
            }
            return _results;
          });
        }
      };
    }
  ]).directive("mooAjaxSpinner", [
    "$http", function($http) {
      return {
        restrict: "E",
        templateUrl: "partials/ajax-spinner.html",
        scope: {},
        link: function($scope, $element) {
          var spinner;
          $scope.isLoading = function() {
            return $http.pendingRequests.length > 0;
          };
          spinner = $element.find("#spinner");
          return $scope.$watch($scope.isLoading, function(v) {
            if (v) {
              return spinner.show();
            } else {
              return spinner.hide();
            }
          });
        }
      };
    }
  ]).directive("mooEditableVariables", [
    function() {
      return {
        restrict: "E",
        templateUrl: "partials/editable-variables.html",
        scope: {
          variables: "="
        },
        link: function($scope, element) {
          element.on("keypress", function(evt) {
            return evt.which !== 13;
          });
          $scope.addVariable = function() {
            return $scope.variables.push({
              name: "",
              value: ""
            });
          };
          return $scope.removeVariable = function(variableToRemove) {
            return $scope.variables.m$removeFirst(function(v) {
              return variableToRemove.name === v.name && variableToRemove.value === v.value;
            });
          };
        }
      };
    }
  ]).directive("mooReadOnlyVariables", [
    function() {
      return {
        restrict: "E",
        templateUrl: "partials/read-only-variables.html",
        scope: {
          variables: "="
        }
      };
    }
  ]).directive("mooWorkflowTree", [
    "Workflows", function(Workflows) {
      return {
        restrict: "E",
        templateUrl: "partials/workflow-tree.html",
        scope: {
          wflowName: "=?",
          editable: "=",
          showFields: "=?",
          treeId: "=?"
        },
        link: function($scope) {
          var givenId, treeSelector;
          givenId = $scope.treeId;
          if ($scope.treeId == null) {
            $scope.treeId = $scope.wflowName != null ? $scope.wflowName + "-tree" : "tree";
          }
          if ($scope.showFields == null) {
            $scope.showFields = true;
          }
          treeSelector = "#" + $scope.treeId;
          $scope.$watch((function() {
            return $scope.treeId;
          }), function() {
            var afterLoad, onNoExistingWorkflow, onSuccess;
            afterLoad = function(workflow) {
              $scope.$emit("workflow.tree.loaded." + givenId);
              $scope.workflow = workflow;
              return workflow.selectedActivityChanged(function() {
                return $scope.$apply();
              });
            };
            onNoExistingWorkflow = function() {
              var errorMsg;
              if ($scope.editable) {
                return afterLoad(ACT_FACTORY.createEmptyWorkflow(treeSelector, $scope.editable, $scope.wflowName));
              } else {
                errorMsg = "If workflow is not editable, then workflow must already exist, but workflow: " + $scope.wflowName + " doesn't exist.";
                alert(errorMsg);
                return console.error(errorMsg);
              }
            };
            if ($scope.wflowName != null) {
              onSuccess = function(wflowData) {
                return afterLoad(ACT_FACTORY.createWorkflow(wflowData, treeSelector, $scope.editable));
              };
              return Workflows.get($scope.wflowName, onSuccess, onNoExistingWorkflow);
            } else {
              return onNoExistingWorkflow();
            }
          });
          if (!$scope.editable) {
            return;
          }
          $scope.workflowComponents = ACT_FACTORY.draggableActivities();
          $(".trash").droppable({
            drop: function(event, ui) {
              var sourceNode;
              sourceNode = $(ui.helper).data("ftSourceNode");
              return sourceNode.remove();
            }
          });
          return $scope.save = function() {
            var onFail, onSuccess, xml;
            xml = $scope.workflow.toXml();
            console.log(xml);
            onSuccess = function() {
              return alert("Workflow saved");
            };
            onFail = function(data) {
              console.log("Error: %o", data);
              if (data.status !== 409) {
                alert("Error see console");
              }
              return $scope.$emit("moo.workflow.save.error." + data.status, {
                name: $scope.workflow.name(),
                instances: data.data,
                retry: $scope.save
              });
            };
            return Workflows.update($scope.workflow.name(), xml, onSuccess, onFail);
          };
        }
      };
    }
  ]).directive("mooWorkflowComponent", [
    function() {
      return {
        restrict: "E",
        templateUrl: "partials/workflow-component.html",
        scope: {
          component: "="
        },
        link: function($scope, element) {
          return element.find("div").draggable({
            helper: "clone",
            cursorAt: {
              top: -5,
              left: -5
            },
            connectToFancytree: true
          });
        }
      };
    }
  ]);

  angular.module("moo.filters", []).filter("escapeDot", [
    function() {
      return function(text) {
        return text.replace(".", "_");
      };
    }
  ]).filter("wflowIdToName", [
    function() {
      return function(text) {
        return text.m$leftOf(".");
      };
    }
  ]);

}).call(this);

//# sourceMappingURL=moo.map
