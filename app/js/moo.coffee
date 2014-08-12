## Directives ##
angular.module "moo.directives", []

.directive "mooNavMenu", [
    "$route", "Areas"
    ($route, Areas) ->
        restrict: "E"
        templateUrl: "partials/nav-menu.html"
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
    "Workflows"
    (Workflows) ->
        restrict: "E"
        templateUrl: "partials/workflow-tree.html"
        scope:
            wflowName: "=?"
            editable: "="
            showFields: "=?"
            treeId: "=?"
        link: ($scope) ->
            givenId = $scope.treeId
            # treeId to passed in, so that a single page can have multiple trees with different ids
            $scope.treeId ?= if $scope.wflowName? then $scope.wflowName + "-tree" else "tree"
            $scope.showFields ?= true

            treeSelector = "#" + $scope.treeId

            # Since treeId is configured here we need to wait until after initialization to access the tree div
            $scope.$watch (-> $scope.treeId), ->
                afterLoad = (workflow) ->
                    $scope.$emit("workflow.tree.loaded." + givenId)
                    $scope.workflow = workflow

#                    $scope.$watch (-> $scope.workflow.name()), (newVal) ->
#                        $scope.wflowName = newVal
                    # When a user clicks on a workflow element, change the form that is displayed
                    workflow.selectedActivityChanged ->
                        $scope.$apply()

                onNoExistingWorkflow = ->
                    if $scope.editable
                        afterLoad(ACT_FACTORY.createEmptyWorkflow(treeSelector, $scope.editable, $scope.wflowName))
                    else
                        errorMsg = "If workflow is not editable, then workflow must already exist,
                                    but workflow: #{$scope.wflowName} doesn't exist."
                        alert(errorMsg)
                        console.error(errorMsg)

                if $scope.wflowName?
                    onSuccess = (wflowData) ->
                        afterLoad(ACT_FACTORY.createWorkflow(wflowData, treeSelector, $scope.editable))
                    Workflows.get($scope.wflowName, onSuccess, onNoExistingWorkflow)
                else
                    onNoExistingWorkflow()


            return unless $scope.editable
            # Below is only necessary if the tree is editable


            $scope.workflowComponents = ACT_FACTORY.draggableActivities()
            # Configure trash droppable
            $(".trash").droppable
                drop: (event, ui) ->
                    sourceNode = $(ui.helper).data("ftSourceNode")
                    sourceNode.remove()





            $scope.save = ->
                xml = $scope.workflow.toXml()
                console.log(xml)
                onSuccess = -> alert("Workflow saved")
                onFail = (data) ->
                    console.log("Error: %o", data)
                    unless data.status is 409 # Conflict
                        alert("Error see console")
                    $scope.$emit("moo.workflow.save.error.#{data.status}",
                            { name: $scope.workflow.name(), instances: data.data, retry: $scope.save} )

                Workflows.update($scope.workflow.name(), xml, onSuccess, onFail)
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

