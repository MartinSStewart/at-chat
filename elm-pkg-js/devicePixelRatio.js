async function loadAudio(url, context, sounds) {
    try {
        const response = await fetch("/" + url + ".mp3");
        const responseBuffer = await response.arrayBuffer();
        sounds[url] = await context.decodeAudioData(responseBuffer);
    } catch (error) {
        console.log(error);
        sounds[url] = null;
    }
}

exports.init = async function init(app)
{
    // Register a Service Worker.

    const serviceWorkerJs = '/service-worker.js';

    app.ports.register_push_subscription_to_js.subscribe((publicKey) => {

        navigator.serviceWorker.register(serviceWorkerJs);

        navigator.serviceWorker.ready
        .then(function(registration) {

            // Use the PushManager to get the user's subscription to the push service.
            return registration.pushManager.getSubscription()
            .then(async function(subscription)
            {
                // If a subscription was found, return it.
                if (subscription) {
                    return subscription;
                }


                // Otherwise, subscribe the user (userVisibleOnly allows to specify that we don't plan to
                // send notifications that don't have a visible effect for the user).
                return registration.pushManager.subscribe({
                    userVisibleOnly: true,
                    applicationServerKey: publicKey
                });
            });
        }).then(function(subscription) {
          // Send the subscription details to the server using the Fetch API.
          app.ports.register_push_subscription_from_js.send(subscription.toJSON());
        });
    });

    app.ports.is_push_subscription_registered_to_js.subscribe((a) => {
        navigator.serviceWorker.getRegistration(serviceWorkerJs).then((registration) => {
            if (registration) {
                app.ports.is_push_subscription_registered_from_js.send(true);
            } else {
                app.ports.is_push_subscription_registered_from_js.send(false);
            }
        });
    });

    app.ports.unregister_push_subscription_to_js.subscribe((a) => {
        navigator.serviceWorker.getRegistration(serviceWorkerJs).then((registration) => {
            if (registration) {
                registration
                    .unregister()
                    .then((isSuccessful) => { });
            }
        });
    });


    let context = null;
    let sounds = {};
    app.ports.load_sounds_to_js.subscribe((a) => {
        context = new AudioContext();
        loadAudio("pop", context, sounds);
        //app.ports.load_sounds_from_js.send(null);
    });
    app.ports.play_sound.subscribe((a) => {
        const source = context.createBufferSource();
        if (sounds[a]) {
            source.buffer = sounds[a];
            source.connect(context.destination);
            source.start(0);
        }
    });

    app.ports.haptic_feedback.subscribe((a) => {
        try {
            const label = document.createElement("label");
            label.ariaHidden = "true";
            label.style.display = "none";

            const input = document.createElement("input");
            input.type = "checkbox";
            input.setAttribute("switch", "");
            label.appendChild(input);

            document.head.appendChild(label);
            label.click();
            document.head.removeChild(label);
        } catch {
            // do nothing
        }

    });

    app.ports.request_notification_permission.subscribe((a) => {
        if ("Notification" in window) {
            Notification.requestPermission().then((permission) => {
                if (permission === "granted") {
                    const notification = new Notification("Notifications enabled");
                }
                app.ports.check_notification_permission_from_js.send(permission);
            });
        } else {
            app.ports.check_notification_permission_from_js.send("unsupported");
        }
    })

    app.ports.check_notification_permission_to_js.subscribe((a) => {
        if ("Notification" in window) {
            app.ports.check_notification_permission_from_js.send(Notification.permission);
        } else {
            app.ports.check_notification_permission_from_js.send("unsupported");
        }
    });

    app.ports.show_notification.subscribe((a) => {
        if ("Notification" in window) {
            const notification = new Notification(a.title, { body: a.body });
        }
    });

    app.ports.check_pwa_status_to_js.subscribe((a) => {
        // Check if the app is running as an installed PWA
        const isPwa = window.matchMedia('(display-mode: standalone)').matches ||
            window.navigator.standalone === true ||
            document.referrer.includes('android-app://');

        app.ports.check_pwa_status_from_js.send(isPwa);
    });

    app.ports.copy_to_clipboard_to_js.subscribe(text => copyTextToClipboard(text));

    app.ports.text_input_select_all_to_js.subscribe(htmlId => {
        var a = document.getElementById(htmlId);
        if (a) {
            a.select();
        }
    });

    app.ports.save_user_settings_to_js.subscribe(function (data) {
        window.localStorage.setItem("ai-chat-settings", data);
    });

    app.ports.load_user_settings_to_js.subscribe(function (data) {
        let localStorageValue = window.localStorage.getItem("ai-chat-settings");
        if (localStorageValue !== null) {
          app.ports.load_user_settings_from_js.send(localStorageValue);
        }
        else {
          app.ports.load_user_settings_from_js.send("");
        }
    });

    function copyTextToClipboard(text) {
        if (!navigator.clipboard) {
            fallbackCopyTextToClipboard(text);
            return;
        }
        navigator.clipboard.writeText(text).then(function () {
        }, function (err) {
            console.error('Error: Could not copy text: ', err);
        });
    }

    function fallbackCopyTextToClipboard(text) {
        var textArea = document.createElement("textarea");
        textArea.value = text;

        // Avoid scrolling to bottom
        textArea.style.top = "0";
        textArea.style.left = "0";
        textArea.style.position = "fixed";

        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();

        try {
            var successful = document.execCommand('copy');
            if (successful !== true) {
                console.log('Error: Copying text command was unsuccessful');
            }
        } catch (err) {
            console.error('Error: Oops, unable to copy', err);
        }

        document.body.removeChild(textArea);
    }
}