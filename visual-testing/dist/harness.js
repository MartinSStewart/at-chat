
const Elm = require('./snapshot-harnessed-app').Elm

document.addEventListener("DOMContentLoaded", function() {

  var currentApp = Elm.SnapshotHarness.init();

  window.advanceSnapshotRequested = function(callback) {
    window.readyForSnapshotCallback = callback;
    currentApp.ports.advanceSnapshotRequested.send(null);
  }

  currentApp.ports.respondReadyForSnapshot.subscribe((snapshot) => {
    window.readyForSnapshotCallback(snapshot);
  });

});
