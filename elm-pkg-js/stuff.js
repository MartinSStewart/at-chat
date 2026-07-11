// Encode an ArrayBuffer (such as a push subscription's applicationServerKey)
// as an unpadded base64url string so it can be compared against the VAPID
// public key string we get from the server.
function arrayBufferToBase64Url(buffer) {
    if (!buffer) { return null; }
    const bytes = new Uint8Array(buffer);
    let binary = "";
    for (let i = 0; i < bytes.byteLength; i++) {
        binary += String.fromCharCode(bytes[i]);
    }
    return btoa(binary)
        .replace(/\+/g, "-")
        .replace(/\//g, "_")
        .replace(/=+$/, "");
}

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
    // Original code found here https://medium.com/@joelmalone/prevent-edge-swipe-gestures-in-your-html-game-but-only-in-safari-fba815a529a2
    function preventBrowserHistorySwipeGestures() {
      function touchStart(ev) {
        if (ev.touches.length === 1) {
          const touch = ev.touches[0];
          if (
            //touch.clientX < window.innerWidth * 0.1 ||
            // We only want to prevent forward navigation here.
            // Backward navigation would mean also blocking the guild column vertical scroll.
            // We instead prevent backward navigation by making sure we are always on the first navigation history item.
            touch.clientX > window.innerWidth * 0.9
          ) {
            ev.preventDefault();
          }
        }
      }

      // Safari defaults to passive: true for the touchstart event, so we need  to explicitly specify false
      // See https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/addEventListener
      const options= { passive: false };

      window.addEventListener("touchstart", touchStart, options);

      return () => window.removeEventListener("touchstart", touchStart, options);
    }

    preventBrowserHistorySwipeGestures();

    // Register a Service Worker.
    let activeNotifications = [];

    const serviceWorkerJs = '/service-worker.js';

    app.ports.register_service_worker_to_js.subscribe(() => {
        if (navigator.serviceWorker) {
            navigator.serviceWorker.register(serviceWorkerJs);
            navigator.serviceWorker.addEventListener("message", (event) => {
                console.log(event);
                app.ports.service_worker_message_from_js.send(event.data);
            });
        }
    });

    app.ports.unregister_service_worker_to_js.subscribe(() => {
        if (navigator.serviceWorker) {
            navigator.serviceWorker.getRegistrations().then(function (registrations) {
              for (let registration of registrations) {
                registration.unregister().then(function () {
                  console.log("Service Worker Unregistered:", registration.scope)
                })
              }
            });
            location.reload();
        }
    });

    app.ports.load_service_worker_data_to_js.subscribe(async () => {
        try {
            if (!navigator.serviceWorker) {
                app.ports.load_service_worker_data_from_js.send("navigator.serviceWorker is not supported in this browser");
                return;
            }

            const describeWorker = (worker) => {
                if (!worker) { return null; }
                return { scriptURL: worker.scriptURL, state: worker.state };
            };

            const describeRegistration = (registration) => {
                if (!registration) { return null; }
                return {
                    scope: registration.scope,
                    updateViaCache: registration.updateViaCache,
                    active: describeWorker(registration.active),
                    installing: describeWorker(registration.installing),
                    waiting: describeWorker(registration.waiting),
                };
            };

            const result = {};

            result.controller = describeWorker(navigator.serviceWorker.controller);

            // The service worker records its install time in Cache Storage on
            // the 'install' event (see public/service-worker.js). Read it back
            // here so we can show when the worker was last installed/updated on
            // this device.
            try {
                const cache = await caches.open('service_worker_installed_at');
                const installedAtResponse = await cache.matchAll();
                if (installedAtResponse[0]) {
                    result.installedAt = await installedAtResponse[0].text();
                } else {
                    result.installedAt = "Unknown (install time not recorded yet)";
                }
            } catch (e) {
                result.installedAt = "Error: " + e.toString();
            }

            // The service worker writes its log entries to IndexedDB (see
            // log() in public/service-worker.js) because that's the only
            // persistent storage both the worker and the page can read.
            try {
                result.serviceWorkerLogs = await new Promise((resolve, reject) => {
                    const openRequest = indexedDB.open("at-chat-db", 1);
                    openRequest.onerror = () => reject(openRequest.error);
                    openRequest.onupgradeneeded = (event) => {
                        // Same schema as the service worker's log() creates, in
                        // case the page opens the database before the worker has
                        // logged anything.
                        event.target.result.createObjectStore("at-chat-object-store", { keyPath: "id" });
                    };
                    openRequest.onsuccess = (event) => {
                        const db = event.target.result;
                        let getAllRequest;
                        try {
                            getAllRequest = db
                                .transaction("at-chat-object-store", "readonly")
                                .objectStore("at-chat-object-store")
                                .getAll();
                        } catch (e) {
                            db.close();
                            reject(e);
                            return;
                        }
                        getAllRequest.onerror = () => { db.close(); reject(getAllRequest.error); };
                        getAllRequest.onsuccess = () => {
                            db.close();
                            // Ids are "<Date.now()>_<random>" (older entries are
                            // just "<Date.now()>").
                            const entries = getAllRequest.result.map((entry) => {
                                const time = Number(String(entry.id).split("_")[0]);
                                return {
                                    time: time,
                                    text: (isNaN(time) ? String(entry.id) : new Date(time).toISOString()) + " " + entry.name
                                };
                            });
                            entries.sort((a, b) => a.time - b.time);
                            resolve(entries.map((entry) => entry.text));
                        };
                    };
                });
            } catch (e) {
                result.serviceWorkerLogs = "Error: " + e.toString();
            }

            const registration = await navigator.serviceWorker.getRegistration(serviceWorkerJs);
            result.registration = describeRegistration(registration);

            const registrations = await navigator.serviceWorker.getRegistrations();
            result.registrations = registrations.map(describeRegistration);

            if (registration) {
                try {
                    const notifications = await registration.getNotifications();
                    result.notifications = notifications.map((n) => ({ title: n.title, body: n.body, tag: n.tag }));
                } catch (e) {
                    result.notifications = "Error: " + e.toString();
                }

                if (registration.pushManager) {
                    try {
                        const subscription = await registration.pushManager.getSubscription();
                        result.pushSubscription = subscription ? subscription.toJSON() : null;
                    } catch (e) {
                        result.pushSubscription = "Error: " + e.toString();
                    }

                    try {
                        result.pushPermissionState = await registration.pushManager.permissionState({ userVisibleOnly: true });
                    } catch (e) {
                        result.pushPermissionState = "Error: " + e.toString();
                    }
                }
            }

            if ("Notification" in window) {
                result.notificationPermission = Notification.permission;
            }

            app.ports.load_service_worker_data_from_js.send(JSON.stringify(result, null, 2));
        } catch (e) {
            app.ports.load_service_worker_data_from_js.send("Error loading service worker data: " + e.toString());
        }
    });

    class LottiePlayer extends HTMLElement {
      static get observedAttributes() { return ['src', 'start-playing']; }
      constructor() { super(); this._animation = null; this._playIndex = 0; }
      connectedCallback() { this._loadAnimation(); }
      disconnectedCallback() { this._destroyAnimation(); }
      attributeChangedCallback(name, oldValue, newValue) {
        if (name === 'src' && oldValue !== newValue && this.isConnected) {
          this._loadAnimation();
        }
        if (name === 'start-playing' && this._animation) {
            switch(newValue) {
                case '0': break;
                case '1': {
                    this._animation.play();
                    this._animation.setLoop(true);
                    this._playIndex += 1;
                    const currentPlayIndex = this._playIndex;
                    setTimeout(() => { if (currentPlayIndex == this._playIndex) { this._animation.setLoop(false); } }, 4000);
                    break;
                }
                case '2': {
                    this._animation.play();
                    this._animation.setLoop(true);
                    this._playIndex += 1;
                    break;
                }
            }
        }
      }
      _destroyAnimation() {
        if (this._animation) {
          this._animation.destroy();
          this._animation = null;
        }
      }
      _loadAnimation() {
        this._destroyAnimation();
        let src = this.getAttribute('src');
        if (!src) return;
        if (typeof bodymovin !== 'undefined') {
            this._animation = bodymovin.loadAnimation({
              container: this,
              renderer: 'canvas',
              loop: true,
              autoplay: true,
              path: src,
              rendererSettings: { runExpressions: false }
            });

            this._playIndex += 1;
            const currentPlayIndex = this._playIndex;
            switch(this.getAttribute('start-playing')) {
                case '0': {
                    setTimeout(() => { if (currentPlayIndex == this._playIndex) { this._animation.setLoop(false); } }, 4000);
                    break;
                }
                case '1': {
                    setTimeout(() => { if (currentPlayIndex == this._playIndex) { this._animation.setLoop(false); } }, 4000);
                    break;
                }
                case '2': {
                    break;
                }
            }
        }
        else {
            setTimeout(() => { this._loadAnimation(this); }, 1000);
        }
      }
    }

    if (!customElements.get('lottie-player')) {
        customElements.define('lottie-player', LottiePlayer);
    }

    class AnimatedImagePlayer extends HTMLElement {
      static get observedAttributes() { return ['src', 'start-playing']; }
      constructor() {
        super();
        this._canvas = document.createElement('canvas');
        this._img = document.createElement('img');
        this._playIndex = 0;
        this._loaded = false;
      }
      connectedCallback() { this._loadGif(); }
      disconnectedCallback() {
        this._canvas.remove();
        this._img.remove();
        this._loaded = false;
      }
      attributeChangedCallback(name, oldValue, newValue) {
        if (name === 'src' && oldValue !== newValue && this.isConnected) {
          this._loadGif();
        }
        if (name === 'start-playing' && this._loaded) {
            switch(newValue) {
                case '0': break;
                case '1': { this._play(false); break; }
                case '2': { this._play(true); break; }
            }

        }
      }
      _play(loopForever) {
        // Show the animated img, hide the canvas
        this._canvas.style.display = 'none';
        this._img.src = this.getAttribute('src');
        this._img.style.display = 'block';
        this._playIndex += 1;
        if (!loopForever) {
            const currentPlayIndex = this._playIndex;
            setTimeout(() => {
              if (currentPlayIndex === this._playIndex) {
                this._img.style.display = 'none';
                this._canvas.style.display = 'block';
              }
            }, 5000);
        }
      }
      _loadGif() {
        this._loaded = false;
        this.innerHTML = '';
        const src = this.getAttribute('src');
        if (!src) return;

        this._canvas.style.display = 'block';
        this._img.style.display = 'none';
        this._img.style.width = '100%';
        this._img.style.height = '100%';
        this.appendChild(this._canvas);
        this.appendChild(this._img);

        // Load the image to capture the first frame onto the canvas
        const tempImg = new Image();
        tempImg.crossOrigin = 'anonymous';
        tempImg.onload = () => {
          this._canvas.width = tempImg.naturalWidth;
          this._canvas.height = tempImg.naturalHeight;
          const ctx = this._canvas.getContext('2d');
          ctx.drawImage(tempImg, 0, 0);
          this._canvas.style.width = '100%';
          this._canvas.style.height = '100%';
          this._loaded = true;

          this._play(this.getAttribute('start-playing') === '2');
        };
        tempImg.src = src;
      }
    }

    if (!customElements.get('animated-image-player')) {
        customElements.define('animated-image-player', AnimatedImagePlayer);
    }

    document.addEventListener('focusout', (event) => {
        app.ports.focus_changed_from_js.send({ id : null });
    });

    document.addEventListener('focusin', (event) => {
        app.ports.focus_changed_from_js.send(event.target);
    });

    document.addEventListener('selectionchange', (event) => {
        const node = document.activeElement;
        if (node) {
            app.ports.selection_changed_from_js.send(node);
        }
    });

    app.ports.exec_command_to_js.subscribe((data) => {
        var textarea = document.getElementById(data.htmlId);
        textarea.focus();
        data.commands.forEach((item) => {
            console.log(item.args[0]);
            switch (item.tag) {
                case 'undo': {
                    document.execCommand(item.tag, false, null);
                    break;
                }
                case 'insertText': {
                    textarea.setSelectionRange(item.args[1].start, item.args[1].end);
                    document.execCommand(item.tag, false, item.args[0]);
                    break;
                }
                case 'selectRange': {
                    textarea.setSelectionRange(item.args[0].start, item.args[0].end, item.args[1]);
                    break;
                }
            }

        });
    });

    app.ports.fix_cursor_position_to_js.subscribe((htmlId) => {
        var a = document.getElementById(htmlId);

        requestAnimationFrame(() =>
        {
            if (a) {
                a.value = a.value + " ";
            }
        });

    });

    app.ports.close_notifications_to_js.subscribe(() => {
        if (navigator.serviceWorker) {
            // Original code found here https://stackoverflow.com/a/64686549
            navigator.serviceWorker.ready.then(reg => {
              reg.getNotifications().then(notifications => {
                for (let i = 0; i < notifications.length; i += 1) {
                  notifications[i].close();
                }
              });
            });

            activeNotifications.forEach((notification) => { try { notification.close(); } catch(error) {} });
            activeNotifications = [];
        }
    });

    app.ports.register_push_subscription_to_js.subscribe((publicKey) => {
        if (navigator.serviceWorker) {
            try {
                navigator.serviceWorker.ready
                .then(function(registration) {

                    // Use the PushManager to get the user's subscription to the push service.
                    return registration.pushManager.getSubscription()
                    .then(async function(subscription)
                    {
                        // If a subscription was found, reuse it only when it was created with the
                        // same VAPID public key the server is currently signing with. If the keys
                        // were rotated or regenerated, the stale subscription's applicationServerKey
                        // no longer matches the private key used to sign, so the push service rejects
                        // it with "VAPID public key mismatch". In that case drop it and resubscribe.
                        if (subscription) {
                            const existingKey = arrayBufferToBase64Url(subscription.options.applicationServerKey);
                            if (existingKey === publicKey) {
                                return subscription;
                            }
                            await subscription.unsubscribe();
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
                  app.ports.register_push_subscription_from_js.send({ tag: "GotSubscribeData", args: [ subscription.toJSON() ]});
                }).catch((e) =>
                    app.ports.register_push_subscription_from_js.send({ tag: "SubscribeJsException", args: [ e.toString() ]})
                );
            }
            catch (e) {
                app.ports.register_push_subscription_from_js.send({ tag: "SubscribeJsException", args: [ e.toString() ]});
            }

        } else {
            app.ports.register_push_subscription_from_js.send({ tag: "SubscribeJsException", args: [ "navigator.serviceWorker is missing" ]});
        }
    });

    function sendStartupData() {
        // original code found here https://stackoverflow.com/a/13382873
        // Creating invisible container
        const outer = document.createElement('div');
        outer.style.visibility = 'hidden';
        outer.style.overflow = 'scroll'; // forcing scrollbar to appear
        outer.style.msOverflowStyle = 'scrollbar'; // needed for WinJS apps
        document.body.appendChild(outer);

        // Creating inner element and placing it in the container
        const inner = document.createElement('div');
        outer.appendChild(inner);

        // Calculating difference between container's full width and the child width
        const scrollbarWidth = (outer.offsetWidth - inner.offsetWidth);

        // Removing temporary elements from the DOM
        outer.parentNode.removeChild(outer);

        // Check if the app is running as an installed PWA
        const isPwa = window.matchMedia('(display-mode: standalone)').matches ||
            window.navigator.standalone === true ||
            document.referrer.includes('android-app://');

        // The safe-area inset at the top of the screen (e.g. the notch on a phone), in pixels.
        // Touch events report positions relative to the viewport top (behind the inset), but the UI
        // is laid out below it, so the game board needs this to line drops up with the finger.
        const insetProbe = document.createElement('div');
        insetProbe.style.position = 'fixed';
        insetProbe.style.top = '0';
        insetProbe.style.left = '0';
        insetProbe.style.width = '0';
        insetProbe.style.height = 'env(safe-area-inset-top)';
        insetProbe.style.visibility = 'hidden';
        insetProbe.style.pointerEvents = 'none';
        document.body.appendChild(insetProbe);
        const safeAreaInsetTop = insetProbe.getBoundingClientRect().height;
        insetProbe.parentNode.removeChild(insetProbe);

        app.ports.load_startup_data_from_js.send({
            // Event timeStamps are milliseconds since timeOrigin (the monotonic performance clock),
            // not since the unix epoch. We convert them to a wall-clock Time.Posix by adding
            // timeOrigin. `performance.timeOrigin` is fixed at page load, but the monotonic clock
            // that event timeStamps use pauses/diverges from wall time while the tab is backgrounded
            // or the machine sleeps, so a fixed origin makes touch times drift (off by a second, then
            // by far more after a long sleep). Instead we compute the origin as
            // `Date.now() - performance.now()`, and re-send it whenever the page becomes visible/
            // focused again (see the listeners below) so it re-anchors to the current wall clock.
            timeOrigin: Date.now() - performance.now(),
            userAgent: window.navigator.userAgent,
            scrollbarWidth: scrollbarWidth,
            isPwa: isPwa,
            notificationPermission: ("Notification" in window) ? Notification.permission : "unsupported",
            safeAreaInsetTop: safeAreaInsetTop
        });
    }

    app.ports.load_startup_data_to_js.subscribe((a) => {
        sendStartupData();
    });

    // Re-anchor timeOrigin after the tab was backgrounded or the machine slept, since the monotonic
    // clock behind event timeStamps drifts from wall time during those periods.
    document.addEventListener('visibilitychange', () => {
        if (document.visibilityState === 'visible') sendStartupData();
    });
    window.addEventListener('focus', sendStartupData);
    window.addEventListener('pageshow', sendStartupData);

    app.ports.shift_scroll_by_element_delta_to_js.subscribe((data) => {
        const element = document.getElementById(data.elementId);
        const container = document.getElementById(data.containerId);
        if (!element || !container) return;
        const oldY = element.getBoundingClientRect().top;
        requestAnimationFrame(() => {
            const newY = element.getBoundingClientRect().top;
            container.scrollTop += (newY - oldY);
        });
    });

    app.ports.smooth_scroll_by_to_js.subscribe((data) => {
        const container = document.getElementById(data.containerId);
        if (!container) return;
        const duration = 250;
        const startTime = performance.now();
        const total = data.scrollY;
        let traveled = 0;
        function easeInOutQuart(t) {
            return t < 0.5 ? 8 * t * t * t * t : 1 - Math.pow(-2 * t + 2, 4) / 2;
        }
        function step(now) {
            const t = Math.min((now - startTime) / duration, 1);
            const desired = total * easeInOutQuart(t);
            // Apply the delta on top of the current scrollTop so that any
            // shift caused by content being prepended above (e.g. older
            // messages loading in) is preserved instead of fighting the
            // animation.
            container.scrollTop += desired - traveled;
            traveled = desired;
            if (t < 1) requestAnimationFrame(step);
        }
        requestAnimationFrame(step);
    });

    app.ports.set_cursor_position_to_js.subscribe((data) => {
        requestAnimationFrame(() =>
            {
                const element = document.getElementById(data.htmlId);
                if (element.setSelectionRange) {
                    element.focus();
                    element.setSelectionRange(data.start, data.end);
                    //element.setSelectionRange(0, 5);
                }
            });
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

    window.visualViewport.addEventListener(
        "resize",
        () => {
            app.ports.visual_viewport_resized_from_js.send(window.visualViewport.height);
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

    app.ports.show_notification.subscribe((a) => {
        if ("Notification" in window) {
            const notification = new Notification(a.title, { body: a.body });
            activeNotifications.push(notification);
        }
    });

    app.ports.copy_to_clipboard_to_js.subscribe(text => copyTextToClipboard(text));

    app.ports.copy_image_to_clipboard_to_js.subscribe(imageUrl => copyImageToClipboard(imageUrl));

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

    window.addEventListener('focus', () => { app.ports.window_has_focus_from_js.send(true); });
    window.addEventListener('blur', () => { app.ports.window_has_focus_from_js.send(false); });

    function copyImageToClipboard(imageUrl) {
        if (!navigator.clipboard || typeof ClipboardItem === "undefined") {
            // Fall back to copying the link when writing image data isn't supported.
            copyTextToClipboard(imageUrl);
            return;
        }
        fetch(imageUrl)
            .then(function (response) { return response.blob(); })
            .then(function (blob) {
                // The clipboard only accepts a handful of image types (png is the safest).
                // Re-encode anything else to png via a canvas before writing it.
                if (blob.type === "image/png") {
                    return navigator.clipboard.write([new ClipboardItem({ "image/png": blob })]);
                }
                return createImageBitmap(blob).then(function (bitmap) {
                    var canvas = document.createElement("canvas");
                    canvas.width = bitmap.width;
                    canvas.height = bitmap.height;
                    canvas.getContext("2d").drawImage(bitmap, 0, 0);
                    return new Promise(function (resolve) {
                        canvas.toBlob(function (pngBlob) {
                            resolve(navigator.clipboard.write([new ClipboardItem({ "image/png": pngBlob })]));
                        }, "image/png");
                    });
                });
            })
            .catch(function (err) {
                console.error('Error: Could not copy image: ', err);
                copyTextToClipboard(imageUrl);
            });
    }

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