exports.init = async function init(app)
{
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