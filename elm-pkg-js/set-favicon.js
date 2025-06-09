exports.init = async function(app) {
  app.ports.martinsstewart_set_favicon_to_js.subscribe(function(data) {
    // Original code found here: https://stackoverflow.com/a/260876
    var link = document.querySelector("link[rel~='icon']");
    if (!link) {
        link = document.createElement('link');
        link.rel = 'icon';
        document.getElementsByTagName('head')[0].appendChild(link);
    }
    link.href = data;
  })
}