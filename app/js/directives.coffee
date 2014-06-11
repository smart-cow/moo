## Directives ##

angular.module "moo.directives", []

.directive "mooNavMenu",  ->
    restrict: "E"
    scope: {}
    controller: [
        "$scope", "$route", "areas"
        ($scope, $route, areas) ->
            $scope.$on "$routeChangeStart", (evt, newRoute) ->
                console.log("route change")
                console.log(newRoute)
                for tab in $scope.tabs
                    tab.selected = tab.title is newRoute.provide.area



            $scope.tabs = for areaName, area of areas
                    title: areaName
                    url: "#" + area.defaultRoute.url
                    selected: areaName is $route.current.provide.area

    ]
    templateUrl: "partials/nav-menu.html"

