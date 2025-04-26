(function() {
  Image = (function() {
    class Image {
      constructor() {
        this.width = 128;
        this.height = 128;
      }

      set src(url) {
        setTimeout(() => {this.onload();}, 10);
      }
    }
    return Image;
  }).call(this);

  module.exports = Image;
  Image.Image = Image;
}).call(this);
