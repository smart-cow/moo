## Directives ##

angular.module "moo.directives", []

.directive "mooNavMenu",  ->
    restrict: "E"
    scope: {}
    controller: [
        "$scope", "$route", "areas"
        ($scope, $route, areas) ->
            $scope.$on "$routeChangeStart", (evt, newRoute) ->
                for tab in $scope.tabs
                    tab.selected = tab.title is newRoute.provide.area

            $scope.tabs = for area in areas
                title: area.name
                url: "#" + area.defaultRoute.url
                selected: area.name is $route.current.provide.area
    ]
    templateUrl: "partials/nav-menu.html"

