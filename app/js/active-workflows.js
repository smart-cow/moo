// Generated by CoffeeScript 1.7.1
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty;

  angular.module("moo.active-workflows.controllers", ["moo.active-workflows.services", "moo.active-workflows.directives"]).controller("ActiveWorkflowsCtrl", [
    "$scope", "WorkflowSummary", function($scope, WorkflowSummary) {
      var selectedWorkflows;
      $scope.workflowSummaries = WorkflowSummary();
      selectedWorkflows = {};
      $scope.selectWorkflow = function(wflowName) {
        if (selectedWorkflows[wflowName] == null) {
          selectedWorkflows[wflowName] = false;
        }
        return selectedWorkflows[wflowName] = !selectedWorkflows[wflowName];
      };
      return $scope.isSelected = function(wflowName) {
        var _ref;
        return (_ref = selectedWorkflows[wflowName]) != null ? _ref : false;
      };
    }
  ]).controller("ActiveTypesCtrl", [
    "$scope", "$routeParams", "RunningWorkflows", function($scope, $routeParams, RunningWorkflows) {
      var initSelectable, typeIsShown;
      window.testScope = $scope;
      $scope.shownTypes = [];
      $scope.selectableTypes = [];
      typeIsShown = function(t) {
        return $scope.shownTypes.m$contains(t);
      };
      $scope.showType = function(type) {
        if ((type == null) || typeIsShown(type)) {
          return false;
        }
        $scope.shownTypes.push(type);
        return $scope.selectableTypes.m$remove(typeIsShown);
      };
      initSelectable = function() {
        return RunningWorkflows.query(function(data) {
          var d;
          return $scope.selectableTypes = ((function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = data.length; _i < _len; _i++) {
              d = data[_i];
              if (!typeIsShown(d.key)) {
                _results.push(d.key);
              }
            }
            return _results;
          })()).m$unique();
        });
      };
      initSelectable();
      if ($routeParams.workflowType != null) {
        return $scope.showType($routeParams.workflowType);
      }
    }
  ]);

  angular.module("moo.active-workflows.services", []).factory("WorkflowSummary", [
    "$rootScope", "$q", "RunningWorkflows", "ScowPush", function($rootScope, $q, RunningWorkflows, ScowPush) {
      var convertToMap, deferred, higherPriority, nameInOtherWflow, statusPriority, updateHeadings, updateStatus, updateWorkflow, wflowsSummary;
      wflowsSummary = {
        headings: {},
        workflows: {}
      };
      updateWorkflow = function(wflowName) {
        var id;
        id = wflowName.m$rightOf(".");
        return RunningWorkflows.statusSummary(id, updateStatus);
      };
      statusPriority = ["precluded", "completed", "contingent", "planned", "notStarted", "open"];
      higherPriority = function(status1, status2) {
        var index1, index2;
        index1 = statusPriority.indexOf(status1);
        index2 = statusPriority.indexOf(status2);
        if (index1 > index2) {
          return status1;
        } else {
          return status2;
        }
      };
      convertToMap = function(statuses) {
        var st, statusesMap, _i, _len, _ref;
        statusesMap = {};
        _ref = statuses.statuses;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          st = _ref[_i];
          statusesMap[st.name] = higherPriority(st.status, statusesMap[st.name]);
        }
        return statusesMap;
      };
      nameInOtherWflow = function(name) {
        var statuses, user, wflowName, _ref;
        _ref = wflowsSummary.workflows;
        for (wflowName in _ref) {
          if (!__hasProp.call(_ref, wflowName)) continue;
          statuses = _ref[wflowName];
          for (user in statuses) {
            if (!__hasProp.call(statuses, user)) continue;
            if (user === name) {
              return true;
            }
          }
        }
        return false;
      };
      updateHeadings = function(addedNames, removedNames) {
        var addedName, heading, headingsToRemove, n, _i, _j, _len, _len1, _results;
        for (_i = 0, _len = addedNames.length; _i < _len; _i++) {
          addedName = addedNames[_i];
          wflowsSummary.headings[addedName] = true;
        }
        headingsToRemove = (function() {
          var _j, _len1, _results;
          _results = [];
          for (_j = 0, _len1 = removedNames.length; _j < _len1; _j++) {
            n = removedNames[_j];
            if (!nameInOtherWflow(n)) {
              _results.push(nameInOtherWflow(n));
            }
          }
          return _results;
        })();
        _results = [];
        for (_j = 0, _len1 = headingsToRemove.length; _j < _len1; _j++) {
          heading = headingsToRemove[_j];
          _results.push(delete wflowsSummary.headings[heading]);
        }
        return _results;
      };
      updateStatus = function(newStatuses) {
        var addedNames, existingStatuses, name, newStatusesMap, removedNames, status, _base, _name;
        if ((_base = wflowsSummary.workflows)[_name = newStatuses.name] == null) {
          _base[_name] = {};
        }
        existingStatuses = wflowsSummary.workflows[newStatuses.name];
        newStatusesMap = convertToMap(newStatuses);
        addedNames = [];
        for (name in newStatusesMap) {
          if (!__hasProp.call(newStatusesMap, name)) continue;
          status = newStatusesMap[name];
          if (existingStatuses[name] == null) {
            addedNames.push(name);
          }
          existingStatuses[name] = status;
        }
        removedNames = [];
        for (name in existingStatuses) {
          if (!__hasProp.call(existingStatuses, name)) continue;
          if (newStatusesMap[name] == null) {
            removedNames.push(name);
            delete existingStatuses[name];
          }
        }
        return updateHeadings(addedNames, removedNames);
      };
      deferred = $q.defer();
      RunningWorkflows.query(function(wflowData) {
        var promises, s, summaries, w;
        summaries = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = wflowData.length; _i < _len; _i++) {
            w = wflowData[_i];
            _results.push(updateWorkflow(w.id));
          }
          return _results;
        })();
        promises = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = summaries.length; _i < _len; _i++) {
            s = summaries[_i];
            _results.push(s.$promise);
          }
          return _results;
        })();
        return $q.all(promises).then(function() {
          return deferred.resolve(wflowsSummary);
        });
      });
      ScowPush.subscribe("#.tasks.#", function(task) {
        return $rootScope.$apply(function() {
          return updateWorkflow(task.processInstanceId);
        });
      });
      return function(onLoad) {
        if (onLoad == null) {
          onLoad = function() {};
        }
        deferred.promise.then(onLoad);
        return wflowsSummary;
      };
    }
  ]).factory("TypeStatuses", [
    "$q", "Workflows", "RunningWorkflows", "ExtractStatuses", function($q, Workflows, RunningWorkflows, ExtractStatuses) {
      var getStatuses, getTaskStatuses, onInstancesReceive;
      getTaskStatuses = function(status) {
        var workflow;
        workflow = ACT_FACTORY.create(status.process.activity);
        return ExtractStatuses(workflow);
      };
      onInstancesReceive = function(instanceData, onComplete) {
        var idNum, idNums, instance, promises;
        idNums = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = instanceData.length; _i < _len; _i++) {
            instance = instanceData[_i];
            _results.push(instance.id.m$rightOf("."));
          }
          return _results;
        })();
        promises = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = idNums.length; _i < _len; _i++) {
            idNum = idNums[_i];
            _results.push(RunningWorkflows.fullStatus(idNum).$promise);
          }
          return _results;
        })();
        return $q.all(promises).then(function(statusData) {
          var stDatum, workflowStatuses, _i, _len;
          workflowStatuses = [];
          for (_i = 0, _len = statusData.length; _i < _len; _i++) {
            stDatum = statusData[_i];
            workflowStatuses.push({
              workflowId: stDatum.id,
              tasks: getTaskStatuses(stDatum)
            });
          }
          return onComplete(workflowStatuses);
        });
      };
      getStatuses = function(type, onComplete) {
        return Workflows.instances(type, function(data) {
          return onInstancesReceive(data, onComplete);
        });
      };
      return getStatuses;
    }
  ]).factory("ExtractStatuses", [
    function() {
      var ExtractStatusesVisitor;
      ExtractStatusesVisitor = (function() {
        function ExtractStatusesVisitor(rootActivity) {
          this.visitServiceTask = __bind(this.visitServiceTask, this);
          this.visitSubprocess = __bind(this.visitSubprocess, this);
          this.visitHumanTask = __bind(this.visitHumanTask, this);
          this.visitSignal = __bind(this.visitSignal, this);
          this.visitScript = __bind(this.visitScript, this);
          this.visitExit = __bind(this.visitExit, this);
          this.visitActivities = __bind(this.visitActivities, this);
          this.visitDecision = __bind(this.visitDecision, this);
          this.visitOption = __bind(this.visitOption, this);
          this.visitLoop = __bind(this.visitLoop, this);
          this.visitChildren = __bind(this.visitChildren, this);
          this.visitAggregate = __bind(this.visitAggregate, this);
          this.addStatus = __bind(this.addStatus, this);
          this.activityStatuses = {
            "$root": rootActivity.data.completionState
          };
          this.visitChildren(rootActivity, rootActivity.children);
        }

        ExtractStatusesVisitor.prototype.addStatus = function(node) {
          return this.activityStatuses[node.data.name] = node.data.completionState;
        };

        ExtractStatusesVisitor.prototype.visit = function(node) {
          return node.accept(this, node);
        };

        ExtractStatusesVisitor.prototype.visitAggregate = function(node) {
          this.addStatus(node);
          return this.visitChildren(node, node.children);
        };

        ExtractStatusesVisitor.prototype.visitChildren = function(node, children) {
          var child, _i, _len, _results;
          if (children === null) {
            return;
          }
          _results = [];
          for (_i = 0, _len = children.length; _i < _len; _i++) {
            child = children[_i];
            _results.push(this.visit(child));
          }
          return _results;
        };

        ExtractStatusesVisitor.prototype.visitLoop = function(node) {
          return this.visitAggregate(node);
        };

        ExtractStatusesVisitor.prototype.visitOption = function(node) {
          return this.visitAggregate(node);
        };

        ExtractStatusesVisitor.prototype.visitDecision = function(node) {
          return this.visitAggregate(node);
        };

        ExtractStatusesVisitor.prototype.visitActivities = function(node) {
          return this.visitAggregate(node);
        };

        ExtractStatusesVisitor.prototype.visitExit = function(node) {
          return this.addStatus(node);
        };

        ExtractStatusesVisitor.prototype.visitScript = function(node) {
          return this.addStatus(node);
        };

        ExtractStatusesVisitor.prototype.visitSignal = function(node) {
          return this.addStatus(node);
        };

        ExtractStatusesVisitor.prototype.visitHumanTask = function(node) {
          return this.addStatus(node);
        };

        ExtractStatusesVisitor.prototype.visitSubprocess = function(node) {
          return this.addStatus(node);
        };

        ExtractStatusesVisitor.prototype.visitServiceTask = function(node) {
          return this.addStatus(node);
        };

        return ExtractStatusesVisitor;

      })();
      return function(workflow) {
        return new ExtractStatusesVisitor(workflow).activityStatuses;
      };
    }
  ]);

  angular.module("moo.active-workflows.directives", []).directive("mooLegend", [
    function() {
      return {
        restrict: "E",
        templateUrl: "partials/active-workflows/legend.html",
        scope: {}
      };
    }
  ]).directive("mooInstanceStatus", [
    function() {
      return {
        restrict: "E",
        template: '<moo-workflow-tree wflow-name="name" editable="false" show-fields="false" tree-id="instanceName"></moo-workflow-tree>',
        scope: {
          name: "=",
          instanceName: "=",
          statuses: "="
        },
        link: function($scope, element) {
          var taskToSelector;
          taskToSelector = function(task) {
            return ".activity-element-" + (task.replace(" ", "-"));
          };
          return $scope.$on("workflow.tree.loaded." + $scope.instanceName, function() {
            var elements, status, task, _ref, _results;
            _ref = $scope.statuses;
            _results = [];
            for (task in _ref) {
              if (!__hasProp.call(_ref, task)) continue;
              status = _ref[task];
              elements = element.find(taskToSelector(task));
              _results.push(elements.addClass("status-" + status));
            }
            return _results;
          });
        }
      };
    }
  ]).directive("mooWorkflowTreeTable", [
    "Workflows", "TypeStatuses", function(Workflows, TypeStatuses) {
      return {
        restrict: "E",
        templateUrl: "partials/active-workflows/tree-table.html",
        scope: {
          wflowName: "="
        },
        link: function($scope, $element) {
          var getStatuses, setTableCells;
          setTableCells = function() {
            var row, st, taskName, taskStatus, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2, _results;
            _ref = $element.find("tbody tr:lt(2)");
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              row = _ref[_i];
              _ref1 = $scope.statuses;
              for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
                st = _ref1[_j];
                taskStatus = st.tasks["$root"];
                $(row).append("<td class='" + taskStatus + "'></td>");
              }
            }
            _ref2 = $element.find("tbody tr:gt(1)");
            _results = [];
            for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
              row = _ref2[_k];
              taskName = $(row).find("td:first-child").text().trim();
              _results.push((function() {
                var _l, _len3, _ref3, _results1;
                _ref3 = $scope.statuses;
                _results1 = [];
                for (_l = 0, _len3 = _ref3.length; _l < _len3; _l++) {
                  st = _ref3[_l];
                  taskStatus = st.tasks[taskName];
                  _results1.push($(row).append("<td class='" + taskStatus + "'></td>"));
                }
                return _results1;
              })());
            }
            return _results;
          };
          getStatuses = function() {
            return TypeStatuses($scope.wflowName, function(statuses) {
              $scope.statuses = statuses;
              $scope.statuses.m$sortBy("workflowId");
              setTableCells();
              return statuses;
            });
          };
          return Workflows.get($scope.wflowName, function(wflowData) {
            ACT_FACTORY.createWorkflowTreeTable(wflowData, $element.find(".tree-table"));
            return getStatuses();
          });
        }
      };
    }
  ]);

}).call(this);

//# sourceMappingURL=active-workflows.map
