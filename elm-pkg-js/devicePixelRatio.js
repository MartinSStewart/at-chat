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

    app.ports.request_notification_permission.subscribe((a) => {
        console.log("request");
        if ("Notification" in window) {
            Notification.requestPermission().then((permission) => {
                console.log(permission);
              if (permission === "granted") {
                console.log("granted");
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
            console.log(notification);
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

    app.ports.text_input_select_all_to_js.subscribe(htmlId =>
        {
            var a = document.getElementById(htmlId);
            if (a) {
                a.select();
            }
        });

    function copyTextToClipboard(text) {
      if (!navigator.clipboard) {
        fallbackCopyTextToClipboard(text);
        return;
      }
      navigator.clipboard.writeText(text).then(function() {
      }, function(err) {
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