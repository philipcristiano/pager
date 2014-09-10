var pagerApp = angular.module('pagerApp', []);

pagerApp.controller('PagerController', function
    ($scope) {
        $scope.events = [
            {'pipe': 'the pipe', 'time': 1},
            {'pipe': 'the second pipe', 'time': 2}
        ];
});
