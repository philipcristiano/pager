var pagerApp = angular.module('pagerApp', ['angular-websocket']);

pagerApp.config(function(WebSocketProvider){
    WebSocketProvider
    .prefix('')
    .uri('ws://localhost:8080/ws');
});

pagerApp.controller('PagerController', function
    ($scope, WebSocket) {
        $scope.events = [];

        WebSocket.onopen(function() {
            console.log('Connection');
        });

        WebSocket.onmessage(function(event) {
            $scope.events.push(JSON.parse(event.data));
            console.log('message: ', event.data);
        });
});
