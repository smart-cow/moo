// Generated by CoffeeScript 1.7.1
(function() {
  var ALL_HIT_TYPES, Activities, Activity, ActivityFactory, Decision, Exit, HumanTask, Loop, NON_FOLDER_HIT_TYPES, OVER_HIT_TYPE, Option, ScriptTask, ServiceTask, Signal, Subprocess, Workflow, WorkflowXmlConverter, dndOptions, getUniqKey, usedTreeKeys,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  ALL_HIT_TYPES = ["over", "after", "before"];

  NON_FOLDER_HIT_TYPES = ["before", "after"];

  OVER_HIT_TYPE = ["over"];

  usedTreeKeys = {};

  getUniqKey = function(preferredName) {
    var possibleName, suffix;
    possibleName = preferredName;
    suffix = 1;
    while (usedTreeKeys[possibleName]) {
      suffix += 1;
      possibleName = preferredName + suffix;
    }
    usedTreeKeys[possibleName] = true;
    return possibleName;
  };

  Activity = (function() {
    Activity.prototype.icon = "Icon_Task.png";

    Activity.prototype.displayName = "Error: this is abstract";

    Activity.prototype.isDecision = false;

    Activity.prototype.isActivities = false;

    Activity.prototype.isOption = false;

    Activity.prototype.folder = false;

    function Activity(data) {
      var _ref, _ref1;
      this.data = data;
      this.removeVariable = __bind(this.removeVariable, this);
      this.addVariable = __bind(this.addVariable, this);
      this.readVariables = __bind(this.readVariables, this);
      this.addInvisibleAttr = __bind(this.addInvisibleAttr, this);
      this.addAttr = __bind(this.addAttr, this);
      this.dragDropNewActivity = __bind(this.dragDropNewActivity, this);
      this.dragDropExistingNode = __bind(this.dragDropExistingNode, this);
      this.dragDrop = __bind(this.dragDrop, this);
      this.dragEnter = __bind(this.dragEnter, this);
      this.name = __bind(this.name, this);
      this._name = "";
      this.key = getUniqKey((_ref = (_ref1 = this.data) != null ? _ref1.name : void 0) != null ? _ref : this.constructor.name);
      this.name(this.key);
      this.extraClasses = "activity-element-" + this._name.replace(" ", "-");
      this.draggable = true;
      this.expanded = true;
      this.act = this;
      this.variables = [];
      this.readVariables();
      this.apiAttributes = [];
      this.addAttr("description", "Description");
      this.addAttr("bypassable", "Bypassable", true, "checkbox");
    }

    Activity.prototype.name = function(newName) {
      this._name = newName != null ? newName : this._name;
      this.title = this._name;
      return this._name;
    };

    Activity.prototype.dragEnter = function(treeData) {
      if (this.otherIsOption(treeData)) {
        if (this.isDecision) {
          return OVER_HIT_TYPE;
        } else {
          return false;
        }
      }
      if (this.folder) {
        return OVER_HIT_TYPE;
      } else {
        return NON_FOLDER_HIT_TYPES;
      }
    };

    Activity.prototype.dragDrop = function(treeData) {
      if (treeData.otherNode != null) {
        return this.dragDropExistingNode(treeData);
      } else {
        return this.dragDropNewActivity(treeData);
      }
    };

    Activity.prototype.dragDropExistingNode = function(treeData) {
      var target, targetChild;
      target = treeData.node;
      if (treeData.hitMode !== "over") {
        treeData.otherNode.moveTo(target, treeData.hitMode);
        return;
      }
      if (!this.folder) {
        return null;
      }
      targetChild = target.getFirstChild();
      if (targetChild != null) {
        return treeData.otherNode.moveTo(targetChild, "before");
      } else {
        return treeData.otherNode.moveTo(target, "child", function() {
          return target.setExpanded(true);
        });
      }
    };

    Activity.prototype.dragDropNewActivity = function(treeData) {
      var newActivity;
      newActivity = ActivityFactory.createFromTreeData(treeData);
      if (newActivity != null) {
        return treeData.node.addNode([newActivity], treeData.hitMode);
      }
    };

    Activity.prototype.otherIsActivities = function(treeData) {
      var droppedType, otherNode;
      otherNode = treeData.otherNode;
      if (otherNode != null) {
        return otherNode.data.act.isActivities;
      }
      droppedType = ActivityFactory.typeFromTreeData(treeData);
      return droppedType != null ? droppedType.prototype.isActivities : void 0;
    };

    Activity.prototype.otherIsOption = function(treeData) {
      var droppedType, otherNode;
      otherNode = treeData.otherNode;
      if (otherNode != null) {
        return otherNode.data.act.isOption;
      }
      droppedType = ActivityFactory.typeFromTreeData(treeData);
      return droppedType != null ? droppedType.prototype.isOption : void 0;
    };

    Activity.prototype.addAttr = function(key, label, isXmlAttribute, inputType) {
      var newAttribute, _ref;
      if (isXmlAttribute == null) {
        isXmlAttribute = false;
      }
      if (inputType == null) {
        inputType = "text";
      }
      newAttribute = {
        key: key,
        value: (_ref = this.data) != null ? _ref[key] : void 0,
        label: label,
        isXmlAttribute: isXmlAttribute,
        inputType: inputType
      };
      this.apiAttributes.push(newAttribute);
      return newAttribute;
    };

    Activity.prototype.setApiAttr = function(key, value) {
      var apiAttr;
      apiAttr = this.apiAttributes.m$first(function(e) {
        return e.key === key;
      });
      return apiAttr.value = value;
    };

    Activity.prototype.addInvisibleAttr = function(key, isXmlAttribute) {
      if (isXmlAttribute == null) {
        isXmlAttribute = false;
      }
      return this.addAttr(key, null, isXmlAttribute);
    };

    Activity.prototype.readVariables = function() {
      var v, varList, _i, _len, _ref, _ref1, _results;
      varList = (_ref = this.data) != null ? (_ref1 = _ref.variables) != null ? _ref1.variable : void 0 : void 0;
      if (varList == null) {
        return;
      }
      _results = [];
      for (_i = 0, _len = varList.length; _i < _len; _i++) {
        v = varList[_i];
        _results.push(this.variables.push(v));
      }
      return _results;
    };

    Activity.prototype.addVariable = function() {
      return this.variables.push(this.createVariable());
    };

    Activity.prototype.removeVariable = function(variable) {
      var matchingVar;
      matchingVar = this.variables.m$first(function(v) {
        return v.name === variable.name;
      });
      return this.variables.remove(matchingVar);
    };

    Activity.prototype.createVariable = function() {
      return {
        name: null,
        value: null,
        required: null,
        output: null
      };
    };

    return Activity;

  })();

  dndOptions = {
    autoExpandMS: 400,
    preventVoidMoves: true,
    preventRecursiveMoves: true,
    dragStart: function(target) {
      return target.data.draggable;
    },
    dragEnter: function(target, data) {
      return target.data.act.dragEnter(data);
    },
    dragDrop: function(target, data) {
      var result;
      return result = target.data.act.dragDrop(data);
    }
  };

  Workflow = (function(_super) {
    __extends(Workflow, _super);

    Workflow.prototype.displayName = "Workflow";

    Workflow.prototype.folder = true;

    function Workflow(data, treeSelector, editable, requestedName, isTreeTable) {
      this.data = data;
      if (requestedName == null) {
        requestedName = "NewWorkflow";
      }
      if (isTreeTable == null) {
        isTreeTable = false;
      }
      this.toXml = __bind(this.toXml, this);
      this.name = __bind(this.name, this);
      this.configTreeTable = __bind(this.configTreeTable, this);
      this.configTree = __bind(this.configTree, this);
      Workflow.__super__.constructor.call(this, this.data);
      if (this.data == null) {
        this.name(requestedName);
      }
      if (this.data != null) {
        this.children = [ActivityFactory.create(this.data.activity)];
      } else {
        this.children = [ActivityFactory.createEmpty(Activities.prototype.typeString)];
      }
      this.draggable = false;
      this.addAttr("bypassAssignee", "Bypass Assignee");
      this.addAttr("bypassCandidateUsers", "Bypass Candidate Users");
      this.addAttr("bypassCandidateGroups", "Bypass Candidate Groups");
      this.selectedActivity = this;
      if (isTreeTable) {
        this.configTreeTable(treeSelector);
      } else {
        this.configTree(treeSelector, editable);
      }
      this.activityChangeListener = function() {};
    }

    Workflow.prototype.configTree = function(treeSelector, editable) {
      var _base;
      $(treeSelector).fancytree({
        source: [this],
        imagePath: "img/workflow-icons/",
        icons: false,
        extensions: editable ? ["dnd"] : void 0,
        dnd: editable ? dndOptions : void 0,
        click: (function(_this) {
          return function(event, data) {
            _this.tree.visit(function(node) {
              return node.setTitle(node.data.act.title);
            });
            return _this.setSelectedActivity(data.node.data.act);
          };
        })(this)
      });
      this.tree = $(treeSelector).fancytree("getTree");
      return typeof (_base = this.tree).reload === "function" ? _base.reload([this]) : void 0;
    };

    Workflow.prototype.configTreeTable = function(treeSelector) {
      $(treeSelector).fancytree({
        source: [this],
        imagePath: "img/workflow-icons/",
        icons: false,
        extensions: ["table"]
      });
      return this.tree = $(treeSelector).fancytree("getTree");
    };

    Workflow.prototype.name = function(newName) {
      this._name = newName != null ? newName : this._name;
      this.title = "<span class='glyphicon glyphicon-list-alt'></span> " + this._name;
      return this._name;
    };

    Workflow.prototype.dragEnter = function() {
      return false;
    };

    Workflow.prototype.accept = function(visitor, node) {
      return visitor.visitWorkflow(node);
    };

    Workflow.prototype.selectedActivityChanged = function(listener) {
      return this.activityChangeListener = listener;
    };

    Workflow.prototype.setSelectedActivity = function(activity) {
      this.selectedActivity = activity;
      return this.activityChangeListener(activity);
    };

    Workflow.prototype.toXml = function() {
      return new WorkflowXmlConverter(this.tree).getXml();
    };

    return Workflow;

  })(Activity);

  Activities = (function(_super) {
    __extends(Activities, _super);

    Activities.prototype.typeString = "org.wiredwidgets.cow.server.api.model.v2.Activities";

    Activities.prototype.icon = "Icon_List.png";

    Activities.prototype.displayName = "List";

    Activities.prototype.isActivities = true;

    Activities.prototype.folder = true;

    function Activities(data) {
      this.toOption = __bind(this.toOption, this);
      this.dragEnter = __bind(this.dragEnter, this);
      var childActivitiesData, d, isSequential, newTitle, sequentialAttr, uniqTitle, _ref;
      Activities.__super__.constructor.call(this, data);
      isSequential = data != null ? data.sequential : true;
      if (!(data != null ? data.name : void 0)) {
        newTitle = isSequential ? "List" : "Parallel List";
        uniqTitle = getUniqKey(newTitle);
        this.name(uniqTitle);
        console.log("activities");
        console.log(this);
      }
      childActivitiesData = (_ref = this.data) != null ? _ref.activity : void 0;
      if (childActivitiesData) {
        this.children = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = childActivitiesData.length; _i < _len; _i++) {
            d = childActivitiesData[_i];
            _results.push(ActivityFactory.create(d));
          }
          return _results;
        })();
      } else {
        this.children = [];
      }
      sequentialAttr = this.addAttr("sequential", "Is Sequential", true, "checkbox");
      sequentialAttr.value = isSequential;
      this.addAttr("mergeCondition", "Merge Condition", true);
    }

    Activities.prototype.dragEnter = function(treeData) {
      var parent, _ref;
      if (this.otherIsOption(treeData)) {
        return false;
      }
      parent = ((_ref = treeData.node.getParent()) != null ? _ref.data.act : void 0) != null;
      if (parent.isActivities || ((parent != null ? parent.isDecision : void 0) && this.otherIsActivities(treeData))) {
        return ALL_HIT_TYPES;
      } else {
        return OVER_HIT_TYPE;
      }
    };

    Activities.prototype.accept = function(visitor, node) {
      return visitor.visitActivities(node);
    };

    Activities.prototype.toOption = function() {
      return new Option(this.data);
    };

    return Activities;

  })(Activity);

  HumanTask = (function(_super) {
    __extends(HumanTask, _super);

    HumanTask.prototype.typeString = "org.wiredwidgets.cow.server.api.model.v2.Task";

    HumanTask.prototype.displayName = "Human Task";

    function HumanTask(data) {
      this.data = data;
      HumanTask.__super__.constructor.call(this, this.data);
      if (this.data != null) {
        this.assignee = data.assignee;
        this.candidateGroups = data.candidateGroups;
      }
      this.addAttr("assignee", "Assignee");
      this.addAttr("candidateUsers", "Candidate users");
      this.addAttr("candidateGroups", "Candidate groups");
      this.addAttr("createTime", "Create time");
      this.addAttr("endTime", "End time");
    }

    HumanTask.prototype.accept = function(visitor, node) {
      return visitor.visitHumanTask(node);
    };

    return HumanTask;

  })(Activity);

  ServiceTask = (function(_super) {
    __extends(ServiceTask, _super);

    ServiceTask.prototype.typeString = "org.wiredwidgets.cow.server.api.model.v2.ServiceTask";

    ServiceTask.prototype.icon = "Icon_ServiceTask.png";

    ServiceTask.prototype.displayName = "Service Task";

    function ServiceTask(data) {
      this.data = data;
      ServiceTask.__super__.constructor.call(this, this.data);
      this.addAttr("url", "URL");
      this.addAttr("content", "Content");
      this.addAttr("contentType", "Content type");
      this.addAttr("var", "Result variable");
    }

    ServiceTask.prototype.accept = function(visitor, node) {
      return visitor.visitServiceTask(node);
    };

    return ServiceTask;

  })(Activity);

  ScriptTask = (function(_super) {
    __extends(ScriptTask, _super);

    ScriptTask.prototype.typeString = "org.wiredwidgets.cow.server.api.model.v2.Script";

    ScriptTask.prototype.icon = "Icon_Script.png";

    ScriptTask.prototype.displayName = "Script Task";

    function ScriptTask(data) {
      ScriptTask.__super__.constructor.call(this, data);
      this.addAttr("import", "Imports");
      this.addAttr("content", "Content");
    }

    ScriptTask.prototype.accept = function(visitor, node) {
      return visitor.visitScript(node);
    };

    return ScriptTask;

  })(Activity);

  Decision = (function(_super) {
    __extends(Decision, _super);

    Decision.prototype.typeString = "org.wiredwidgets.cow.server.api.model.v2.Decision";

    Decision.prototype.icon = "Icon_Decision.png";

    Decision.prototype.displayName = "Decision";

    Decision.prototype.isDecision = true;

    Decision.prototype.folder = true;

    function Decision(data) {
      this.dragDrop = __bind(this.dragDrop, this);
      var opt, optionsData;
      Decision.__super__.constructor.call(this, data);
      optionsData = data != null ? data.option : void 0;
      if (optionsData) {
        this.children = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = optionsData.length; _i < _len; _i++) {
            opt = optionsData[_i];
            _results.push(new Option(opt));
          }
          return _results;
        })();
      } else {
        this.children = [];
      }
      this.task = new HumanTask(data != null ? data.task : void 0);
    }

    Decision.prototype.dragDrop = function(treeData) {
      var activities, droppedActivity, droppedType, option, otherActivity, _ref;
      otherActivity = (_ref = treeData.otherNode) != null ? _ref.data.act : void 0;
      if (otherActivity != null) {
        if (otherActivity.isOption) {
          this.dragDropExistingNode(treeData);
        } else if (otherActivity.isActivities) {
          option = ActivityFactory.createEmpty(Option.prototype.typeString);
          option.children[0] = otherActivity;
        }
        return;
      }
      droppedType = ActivityFactory.typeFromTreeData(treeData);
      if (droppedType.prototype.typeString === Option.prototype.typeString) {
        this.dragDropNewActivity(treeData);
        return;
      }
      option = ActivityFactory.createEmpty(Option.prototype.typeString);
      if (droppedType.prototype.typeString !== Activities.prototype.typeString) {
        activities = option.children[0];
        droppedActivity = ActivityFactory.createEmpty(droppedType.prototype.typeString);
        activities.children.push(droppedActivity);
      }
      return treeData.node.addNode([option], treeData.hitMode);
    };

    Decision.prototype.accept = function(visitor, node) {
      return visitor.visitDecision(node);
    };

    return Decision;

  })(Activity);

  Option = (function(_super) {
    __extends(Option, _super);

    Option.prototype.typeString = "org.wiredwidgets.cow.server.api.model.v2.Option";

    Option.prototype.icon = "Icon_Decision_Arrow.png";

    Option.prototype.displayName = "Option";

    Option.prototype.folder = true;

    Option.prototype.isOption = true;

    function Option(data) {
      var childActivitiesData, _ref;
      this.data = data;
      this.dragEnter = __bind(this.dragEnter, this);
      Option.__super__.constructor.call(this, this.data);
      childActivitiesData = (_ref = this.data) != null ? _ref.activity : void 0;
      if (childActivitiesData) {
        this.children = [ActivityFactory.create(childActivitiesData)];
      } else {
        this.children = [ActivityFactory.createEmpty(Activities.prototype.typeString)];
      }
    }

    Option.prototype.dragEnter = function(treeData) {
      if (this.otherIsOption(treeData) || this.otherIsActivities(treeData)) {
        return NON_FOLDER_HIT_TYPES;
      }
    };

    Option.prototype.accept = function(visitor, node) {
      return visitor.visitOption(node);
    };

    return Option;

  })(Activity);

  Exit = (function(_super) {
    __extends(Exit, _super);

    Exit.prototype.typeString = "org.wiredwidgets.cow.server.api.model.v2.Exit";

    Exit.prototype.icon = "Icon_Exit.png";

    Exit.prototype.displayName = "Exit";

    function Exit(data) {
      Exit.__super__.constructor.call(this, data);
      this.addAttr("state", "State", true);
    }

    Exit.prototype.accept = function(visitor, node) {
      return visitor.visitExit(node);
    };

    return Exit;

  })(Activity);

  Signal = (function(_super) {
    __extends(Signal, _super);

    Signal.prototype.typeString = "org.wiredwidgets.cow.server.api.model.v2.Signal";

    Signal.prototype.icon = "Icon_Signal.png";

    Signal.prototype.displayName = "Signal";

    function Signal(data) {
      Signal.__super__.constructor.call(this, data);
      this.addAttr("signalId", "Signal Id", true);
    }

    Signal.prototype.accept = function(visitor, node) {
      return visitor.visitSignal(node);
    };

    return Signal;

  })(Activity);

  Subprocess = (function(_super) {
    __extends(Subprocess, _super);

    Subprocess.prototype.typeString = "org.wiredwidgets.cow.server.api.model.v2.SubProcess";

    Subprocess.prototype.icon = "Icon_SubProcess.png";

    Subprocess.prototype.displayName = "Subprocess";

    function Subprocess(data) {
      Subprocess.__super__.constructor.call(this, data);
      this.addAttr("sub-process-key", "Subprocess", true);
    }

    Subprocess.prototype.accept = function(visitor, node) {
      return visitor.visitSubprocess(node);
    };

    return Subprocess;

  })(Activity);

  Loop = (function(_super) {
    __extends(Loop, _super);

    Loop.prototype.typeString = "org.wiredwidgets.cow.server.api.model.v2.Loop";

    Loop.prototype.icon = "Icon_Loop.png";

    Loop.prototype.displayName = "Loop";

    Loop.prototype.folder = true;

    function Loop(data) {
      var childData, _ref;
      Loop.__super__.constructor.call(this, data);
      childData = (_ref = this.data) != null ? _ref.activity : void 0;
      if (childData) {
        this.children = [ActivityFactory.create(childData)];
      } else {
        this.children = [];
      }
      this.loopTask = new HumanTask(data != null ? data.loopTask : void 0);
      this.addAttr("doneName", "Done name", true);
      this.addAttr("repeatName", "Repeat name", true);
      this.addAttr("executionCount", "Execution count", true);
    }

    Loop.prototype.accept = function(visitor, node) {
      return visitor.visitLoop(node);
    };

    return Loop;

  })(Activity);

  ActivityFactory = (function() {
    function ActivityFactory() {}

    ActivityFactory.typeMap = {};

    ActivityFactory.typeMap[HumanTask.prototype.typeString] = HumanTask;

    ActivityFactory.typeMap[Activities.prototype.typeString] = Activities;

    ActivityFactory.typeMap[Loop.prototype.typeString] = Loop;

    ActivityFactory.typeMap[Decision.prototype.typeString] = Decision;

    ActivityFactory.typeMap[ServiceTask.prototype.typeString] = ServiceTask;

    ActivityFactory.typeMap[ScriptTask.prototype.typeString] = ScriptTask;

    ActivityFactory.typeMap[Signal.prototype.typeString] = Signal;

    ActivityFactory.typeMap[Exit.prototype.typeString] = Exit;

    ActivityFactory.typeMap[Option.prototype.typeString] = Option;

    ActivityFactory.typeMap[Subprocess.prototype.typeString] = Subprocess;

    ActivityFactory.create = function(cowData) {
      return new this.typeMap[cowData.declaredType](cowData.value);
    };

    ActivityFactory.createEmpty = function(typeName) {
      return new this.typeMap[typeName]();
    };

    ActivityFactory.createFromTreeData = function(treeData) {
      var type;
      type = this.typeFromTreeData(treeData);
      if (type) {
        return new type();
      } else {
        return null;
      }
    };

    ActivityFactory.draggableActivities = function() {
      var key, val, _ref, _results;
      _ref = this.typeMap;
      _results = [];
      for (key in _ref) {
        val = _ref[key];
        if (key !== Option.prototype.typeString) {
          _results.push({
            type: key,
            name: val.prototype.displayName,
            icon: "img/workflow-icons/" + val.prototype.icon
          });
        }
      }
      return _results;
    };

    ActivityFactory.getType = function(typeName) {
      return this.typeMap[typeName];
    };

    ActivityFactory.typeNameFromTreeData = function(treeData) {
      var _ref, _ref1;
      return (_ref = treeData.draggable) != null ? (_ref1 = _ref.element) != null ? _ref1.data("component-type") : void 0 : void 0;
    };

    ActivityFactory.typeFromTreeData = function(treeData) {
      return this.getType(this.typeNameFromTreeData(treeData));
    };

    ActivityFactory.createWorkflow = function(cowData, treeSelector, editable) {
      if (!editable) {
        getUniqKey = function(s) {
          return s;
        };
      }
      return new Workflow(cowData, treeSelector, editable);
    };

    ActivityFactory.createWorkflowTreeTable = function(cowData, treeSelector) {
      return new Workflow(cowData, treeSelector, false, null, true);
    };

    ActivityFactory.createEmptyWorkflow = function(treeSelector, editable, name) {
      if (name == null) {
        name = "New Workflow";
      }
      if (!editable) {
        getUniqKey = function(s) {
          return s;
        };
      }
      return new Workflow(null, treeSelector, editable, name);
    };

    return ActivityFactory;

  })();

  window.ACT_FACTORY = ActivityFactory;

  WorkflowXmlConverter = (function() {
    function WorkflowXmlConverter(tree) {
      this.addAttributesToNode = __bind(this.addAttributesToNode, this);
      this.createActivityElement = __bind(this.createActivityElement, this);
      this.visitSubprocess = __bind(this.visitSubprocess, this);
      this.visitSignal = __bind(this.visitSignal, this);
      this.visitExit = __bind(this.visitExit, this);
      this.visitScript = __bind(this.visitScript, this);
      this.visitServiceTask = __bind(this.visitServiceTask, this);
      this.visitHumanTask = __bind(this.visitHumanTask, this);
      this.visitLoop = __bind(this.visitLoop, this);
      this.visitOption = __bind(this.visitOption, this);
      this.visitDecision = __bind(this.visitDecision, this);
      this.visitActivities = __bind(this.visitActivities, this);
      this.visitWorkflow = __bind(this.visitWorkflow, this);
      this.visitChildren = __bind(this.visitChildren, this);
      var workflowRoot;
      this.hasAtLeaskOneTask = false;
      this.xml = $($.parseXML('<process xmlns="http://www.wiredwidgets.org/cow/server/schema/model-v2"></process>'));
      this.parentXml = this.xml;
      workflowRoot = tree.rootNode.children[0];
      this.visit(workflowRoot);
    }

    WorkflowXmlConverter.prototype.getXml = function() {
      return this.xml[0];
    };

    WorkflowXmlConverter.prototype.visit = function(node) {
      return node.data.act.accept(this, node);
    };

    WorkflowXmlConverter.prototype.visitChildren = function(nodeXml, nodeChildren) {
      var child, oldXmlPosition, _i, _len, _ref;
      _ref = [this.parentXml, nodeXml], oldXmlPosition = _ref[0], this.parentXml = _ref[1];
      if (nodeChildren != null) {
        for (_i = 0, _len = nodeChildren.length; _i < _len; _i++) {
          child = nodeChildren[_i];
          this.visit(child);
        }
      }
      return this.parentXml = oldXmlPosition;
    };

    WorkflowXmlConverter.prototype.visitWorkflow = function(node) {
      var process;
      this.name = node.data.act.name();
      process = $(this.parentXml.find("process"));
      process.attr("name", this.name);
      process.attr("key", this.name);
      this.addAttributesToNode(process, node.data.act.apiAttributes);
      this.createVariablesElement(process, node.data.act.variables);
      return this.visitChildren(process, [node.children[0]]);
    };

    WorkflowXmlConverter.prototype.visitActivities = function(node) {
      var xmlActivities, _ref;
      xmlActivities = this.createActivityElement("activities", node);
      this.hasAtLeaskOneTask = ((_ref = node.children) != null ? _ref.length : void 0) > 0;
      return this.visitChildren(xmlActivities, node.children);
    };

    WorkflowXmlConverter.prototype.visitDecision = function(node) {
      var xmlDecision, xmlTask;
      xmlDecision = this.createActivityElement("decision", node);
      xmlTask = this.createTag("task", xmlDecision);
      this.addAttributesToNode(xmlTask, node.data.act.task.apiAttributes);
      return this.visitChildren(xmlDecision, node.children);
    };

    WorkflowXmlConverter.prototype.visitOption = function(node) {
      var xmlOption;
      xmlOption = this.createActivityElement("option", node);
      return this.visitChildren(xmlOption, node.children);
    };

    WorkflowXmlConverter.prototype.visitLoop = function(node) {
      var xmlLoop, xmlLoopTask;
      xmlLoop = this.createActivityElement("loop", node);
      xmlLoopTask = this.createTag("loopTask", xmlLoop);
      this.addAttributesToNode(xmlLoopTask, node.data.act.loopTask.apiAttributes);
      return this.visitChildren(xmlLoop, node.children);
    };

    WorkflowXmlConverter.prototype.visitHumanTask = function(node) {
      return this.createActivityElement("task", node);
    };

    WorkflowXmlConverter.prototype.visitServiceTask = function(node) {
      return this.createActivityElement("serviceTask", node);
    };

    WorkflowXmlConverter.prototype.visitScript = function(node) {
      return this.createActivityElement("script", node);
    };

    WorkflowXmlConverter.prototype.visitExit = function(node) {
      return this.createActivityElement("exit", node);
    };

    WorkflowXmlConverter.prototype.visitSignal = function(node) {
      return this.createActivityElement("signal", node);
    };

    WorkflowXmlConverter.prototype.visitSubprocess = function(node) {
      return this.createActivityElement("subProcess", node);
    };

    WorkflowXmlConverter.prototype.createActivityElement = function(tag, treeNode) {
      var xml;
      xml = this.createTag(tag, this.parentXml);
      xml.attr("name", treeNode.data.act.name());
      this.addAttributesToNode(xml, treeNode.data.act.apiAttributes);
      this.createVariablesElement(xml, treeNode.data.act.variables);
      return xml;
    };

    WorkflowXmlConverter.prototype.createTextElement = function(parent, tag, content) {
      var xml;
      xml = this.createTag(tag, parent);
      xml.text(content);
      return xml;
    };

    WorkflowXmlConverter.prototype.createTag = function(name, parent) {
      var newTag;
      parent.append("<" + name + " class='hack'/>");
      newTag = parent.find(".hack");
      newTag.removeAttr("class");
      return newTag;
    };

    WorkflowXmlConverter.prototype.addAttributesToNode = function(xmlElement, attributes) {
      var attr, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = attributes.length; _i < _len; _i++) {
        attr = attributes[_i];
        if (attr.value != null) {
          if (attr.isXmlAttribute) {
            _results.push(xmlElement.attr(attr.key, attr.value));
          } else {
            _results.push(this.createTextElement(xmlElement, attr.key, attr.value));
          }
        }
      }
      return _results;
    };

    WorkflowXmlConverter.prototype.createVariablesElement = function(xmlElement, variables) {
      var attrName, varXml, variable, variablesXml, _i, _len, _results;
      variablesXml = this.createTag("variables", xmlElement);
      _results = [];
      for (_i = 0, _len = variables.length; _i < _len; _i++) {
        variable = variables[_i];
        varXml = this.createTag("variable", variablesXml);
        _results.push((function() {
          var _j, _len1, _ref, _results1;
          _ref = ["name", "value", "type", "required", "output"];
          _results1 = [];
          for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
            attrName = _ref[_j];
            _results1.push(varXml.attr(attrName, variable[attrName]));
          }
          return _results1;
        })());
      }
      return _results;
    };

    return WorkflowXmlConverter;

  })();

}).call(this);

//# sourceMappingURL=activity-types-lib.map
