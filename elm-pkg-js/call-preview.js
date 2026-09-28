// The homepage previews a call, but nobody in it has a camera. Elm sends the id of each
// video node along with an image to show in its place, each time the preview is shown. Only
// nodes inside the preview are touched, since the preview's own video has the same id as the
// real one.
exports.init = async function init(app) {
    app.ports.call_preview_images_to_js.subscribe(function (data) {
        for (const { htmlId, url } of data.images) {
            const image = new Image();
            // Elm hasn't drawn the preview yet when the port message arrives. Its next render is
            // already queued for the coming frame, so waiting for that frame puts us after it.
            image.onload = () => requestAnimationFrame(() => draw(data.containerId, htmlId, image));
            image.src = url;
        }
    });
};

function draw(containerId, htmlId, image) {
    const element = document.getElementById(containerId)?.querySelector("#" + CSS.escape(htmlId));
    if (element instanceof HTMLCanvasElement) {
        element.width = image.naturalWidth;
        element.height = image.naturalHeight;
        element.getContext("2d").drawImage(image, 0, 0);
    } else if (element instanceof HTMLVideoElement) {
        element.poster = image.src;
        element.style.objectFit = "cover";
    }
}
