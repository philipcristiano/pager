var socket = new WebSocket('ws://localhost:8080/ws');

socket.onopen = function(event) {
  console.log("Open!");
  socket.send("Hello WS World");
};

// Handle messages sent by the server.
socket.onmessage = function(event) {
  var message = event.data;
  console.log(message);
};

