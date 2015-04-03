var pagerApp = angular.module('pagerApp', ['angular-websocket']);

pagerApp.config(function(WebSocketProvider){
    WebSocketProvider
    .prefix('')
    .uri('ws://localhost:8081/ws');
});

pagerApp.controller('PagerController', function
    ($scope, WebSocket) {
        $scope.events = [];
        $scope.groups = [];

        WebSocket.onopen(function() {
            console.log('Connection');
        });

        WebSocket.onmessage(function(event) {
            console.log('message: ', event.data);
            msg = JSON.parse(event.data)
            if (msg['type'] == 'event') {
                $scope.events.unshift(msg);
            } else if (msg['type'] == 'groups') {
                $scope.groups = msg['data'];
            }
        });

        $scope.sync_pipe = function() {
            console.log($scope.groups);
            WebSocket.send(JSON.stringify({
                "type": "groups",
                "data": $scope.groups
            }));
        }
});
