## Directives ##






angular.module "moo.directives", []


.directive "mooNavMenu", [
    "$route", "Areas"
    ($route, Areas) ->
        restrict: "E"
        templateUrl: "partials/nav-menu.html"
        scope: { }
        link: ($scope) ->
            $scope.tabs = for area in Areas
                title: area.name
                url: "#" + area.defaultRoute.url
                selected: area.name is $route.current.provide.area

            # Keep selected tab in sync with current page
            $scope.$on "$routeChangeSuccess", (evt, newRoute) ->
                for tab in $scope.tabs
                    tab.selected = tab.title is newRoute.provide.area
]


.directive "mooSearchField", [
    ->
        restrict: "E"
        templateUrl: "partials/search-field.html"
        scope:
            searchText: "="
]

.directive "mooAjaxSpinner", [
    "$http"
    ($http) ->
        restrict: "E"
        templateUrl: "partials/ajax-spinner.html"
        scope: { }
        link: ($scope, $element) ->
            $scope.isLoading = ->
                $http.pendingRequests.length > 0

            spinner = $element.find("#spinner")

            $scope.$watch $scope.isLoading, (v) ->
                if v then spinner.show() else spinner.hide()
]



.directive "mooEditableVariables", [
    ->
        restrict: "E"
        templateUrl: "partials/editable-variables.html"
        scope:
            variables: "="
        link: ($scope, element) ->

            # Prevent enter key from deleting variables
            element.on "keypress", (evt) ->
                evt.which isnt 13


            $scope.addVariable = ->
                $scope.variables.push
                    name: ""
                    value: ""

            $scope.removeVariable = (variableToRemove) ->
               $scope.variables.m$removeFirst (v) ->
                   variableToRemove.name is v.name and variableToRemove.value is v.value


]

.directive "mooReadOnlyVariables", [
    ->
        restrict: "E"
        templateUrl: "partials/read-only-variables.html"
        scope:
            variables: "="
]
.directive "mooWorkflowTree", [
    ->
        restrict: "E"
        templateUrl: "partials/workflow-tree.html"
        scope:
            wflowName: "=?"
            editable: "="
            showFields: "=?"
            treeId: "=?"
        controller: WorkflowTreeCtrl
        controllerAs: "treeCtrl"
]



.directive "mooWorkflowComponent", [
    ->
        restrict: "E"
        templateUrl: "partials/workflow-component.html"
        scope:
            component: "="
        link: ($scope, element) ->
            element.find("div").draggable
                helper: "clone"
                cursorAt: {top: -5, left: -5}
                connectToFancytree: true

]

.directive "mooWorkflowChooser", [
    "$compile", "Workflows"
    ($compile, Workflows) ->
        restrict: "E"
        templateUrl: "partials/workflow-chooser.html"
        scope:
            mainBtnText: "=?"
            workflows: "=?"
        controller: ($scope, $element) ->
            $scope.workflows ?= Workflows.query()
            $scope.mainBtnText ?= "Select"

            $scope.selectWorkflow = (wf) ->
                $scope.$emit("moo.workflow.selected", wf)

            loadedWorkflows = { }
            $scope.loadWorkflowTree = (wfName) ->
                return true if loadedWorkflows[wfName]?
                $scope.wfName = wfName
                newTree = $compile("<moo-workflow-tree wflow-name='wfName' editable='false'></moo-workflow-tree>")($scope)
                $element.find("#hidden-row-" + wfName).append(newTree)
                return true
]



.directive "mooGreeter", [
    ->
        restrict: "E"
        template: 'Name: {{greeter.customer.name}} | Address: {{greeter.customer.address}} | Message: {{greeter.greet()}}  '
        scope:
            name: "=?"
        controller: "GreeterCtrl2"
        controllerAs: "greeter"
]

.directive "mooModal", [
    ->
        restrict: "E"
        templateUrl: "partials/modal.html"
        transclude: true
        scope:
            title: '@'
            modalId: '@'
        controller: ($scope) ->
            $scope.clickedAccept = ->
                $scope.$emit("modal.clicked.accept")

            $scope.clickedClose = ->
                $scope.$emit("modal.clicked.close")
]




## Filters ##
angular.module "moo.filters", []

.filter "escapeDot", [
    ->
        (text) ->
            text.replace(".", "_")
]

.filter "wflowIdToName", [
    ->
        (text) -> text.m$leftOf(".")
]

.filter "filterKey", [
    "$filter"
    ($filter) ->
        return (items, query) ->
            list = (k for own k  of items)
            filtered = $filter("filter")(list, query)
            result = { }
            for k in filtered
                result[k] = items[k]
            return result
]



class GreeterCtrl extends BaseCtrl
    @register(angular.module("moo.directives"))
    @inject("$scope", "Tasks")

    init: (arg) =>
        @customer =
            name: arg?.name ? "Naomi"
            address: "1600 ARoad"


class GreeterCtrl2 extends BaseCtrl
    @register(angular.module("moo.directives"))
    @inject("$scope", "Tasks")

    constructor: ($scope, MyTasks) ->
        @customer =
            name: $scope?.name ? "Naomi"
            address: "1600 ARoad"
        m$log("init tasks", MyTasks)

    greet: => "Hello #{@customer.name}!"



window.Greeter = GreeterCtrl2

class WorkflowTreeCtrl extends BaseCtrl
    @register(angular.module("moo.directives"))
    @inject("$scope", "Workflows", "$element")

    constructor: (@$scope, @Workflows, $element) ->
        @givenId = $scope.treeId
        @editable = $scope.editable
        @showFields = $scope.showFields ? true
        @workflowComponents = if @editable then ACT_FACTORY.draggableActivities() else []

        wfName = $scope.wflowName
        @treeId = if wfName? then wfName + "-tree" else "tree"
        @treeSelector = "#" + @treeId
        if @editable
            @_configureTrash($element)
        window.ctrl = @

        $scope.$on "moo.tree.change", (evt, wfName) =>
            @setWorkflow(wfName)

        $scope.$on "moo.tree.copy", (evt, data) =>
            console.log(data)
            @setWorkflow(data.wfName)
            @workflow.name(data.newName)


        @setWorkflow(wfName)


    setWorkflow: (wfName = null) =>
        if wfName
            onSuccess = (wflowData) =>
                @_afterLoad(ACT_FACTORY.createWorkflow(wflowData, @treeSelector, @editable))
            @Workflows.get(wfName, onSuccess, @_onNoExistingWorkflow)
        else
            @_onNoExistingWorkflow()



    save: =>
        unless @editable
            console.log("Can't save when in read only mode")
            return
        xml = @workflow.toXml()
        console.log(xml)
        onSuccess = -> alert("Workflow save")
        onFail = (data) =>
            console.log("Error: %o", data)
            unless data.status is 409 # Conflict
                alert("Error see console")
            @$scope.$emit("moo.workflow.save.error.#{data.status}",
                { name: @workflow.name(), instances: data.data, retry: @save} )

        @Workflows.update(@workflow.name(), xml, onSuccess, onFail)



    _onNoExistingWorkflow: () =>
        if @editable
            @_afterLoad(ACT_FACTORY.createEmptyWorkflow(@treeSelector, @editable, "NewWorkflow"))
        else
            errorMsg = "If workflow is not editable, then workflow must already exist"
            alert(errorMsg)
            console.log(errorMsg)


    _afterLoad: (workflow) =>
        @$scope.$emit("workflow.tree.loaded." + @givenId)
        @workflow = workflow
        @workflow.selectedActivityChanged =>
            @$scope.$apply()

    _configureTrash: ($element) =>
        @$scope.$watchCollection (-> $element.find(".trash")), ->
            console.log("watch")
            $element.find(".trash").droppable
                drop: (event, ui) ->
                    sourceNode = $(ui.helper).data("ftSourceNode")
                    sourceNode.remove()



