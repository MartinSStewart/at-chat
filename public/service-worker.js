console.log("service-worker");
// Register event listener for the 'push' event.
self.addEventListener('push', function(event) {
    try
    {
        const data = event.data.json().notification;

        self.registration.showNotification(
            data.title,
            { body: data.body
            , icon: data.icon
            });
    }
    catch(error)
    {
        self.registration.showNotification("error", { body : error });
    }
});