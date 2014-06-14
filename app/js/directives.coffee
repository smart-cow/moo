## Directives ##

angular.module "moo.directives", []

.directive "mooNavMenu", [
    "$route", "areas"
    ($route, areas) ->
        restrict: "E"
        templateUrl: "partials/nav-menu.html"
        link: ($scope) ->
            $scope.tabs = for area in areas
                title: area.name
                url: "#" + area.defaultRoute.url
                selected: area.name is $route.current.provide.area

            $scope.$on "$routeChangeSuccess", (evt, newRoute) ->
                for tab in $scope.tabs
                    tab.selected = tab.title is newRoute.provide.area
]