exports.init = async function (app) {
  app.ports.martinsstewart_crop_image_to_js.subscribe(function (data) {
    setImage(app, data);
  })
}

function setImage(app, data) {
  var canvas = document.createElement('canvas');
  canvas.width = data.cropWidth;
  canvas.height = data.cropHeight;
  canvas.style.display = "none";
  document.body.appendChild(canvas);
  var ctx = canvas.getContext('2d');

  var img = new Image();

  img.onload = function () {
    ctx.imageSmoothingEnabled = true;
    ctx.imageSmoothingQuality = "high";

    ctx.drawImage(img, data.cropX, data.cropY, data.width, data.height, 0, 0, data.cropWidth, data.cropHeight);
    var croppedImageUrl = canvas.toDataURL();
    document.body.removeChild(canvas);
    app.ports.martinsstewart_crop_image_from_js.send({ requestId: data.requestId, croppedImageUrl: croppedImageUrl });
  }

  img.src = data.imageUrl;
}
