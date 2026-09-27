// The homepage previews a call, but nobody in it has a camera. Elm sends the id of each
// video node along with an image to show in its place, and this draws the image into
// that node whenever one turns up inside the preview. Only nodes inside the preview are
// touched, since the preview's own video has the same id as the real one.
exports.init = async function init(app) {
    // A WeakSet rather than a flag on the element, so that the preview being drawn again
    // (after logging out, say) with new elements under the same ids gets the images too.
    const drawn = new WeakSet();
    let preview = null;

    function draw() {
        if (!preview) return;
        const container = document.getElementById(preview.containerId);
        if (!container) return;
        for (const { htmlId, image } of preview.images) {
            if (!image.complete || image.naturalWidth === 0) continue;
            const element = container.querySelector("#" + CSS.escape(htmlId));
            if (!element || drawn.has(element)) continue;
            if (element instanceof HTMLCanvasElement) {
                element.width = image.naturalWidth;
                element.height = image.naturalHeight;
                element.getContext("2d").drawImage(image, 0, 0);
            } else if (element instanceof HTMLVideoElement) {
                element.poster = image.src;
                element.style.objectFit = "cover";
            } else {
                continue;
            }
            drawn.add(element);
        }
    }

    new MutationObserver(draw).observe(document.documentElement, { childList: true, subtree: true });

    app.ports.call_preview_images_to_js.subscribe(function (data) {
        preview = {
            containerId: data.containerId,
            images: data.images.map(function ({ htmlId, url }) {
                const image = new Image();
                image.onload = draw;
                image.src = url;
                return { htmlId, image };
            }),
        };
        draw();
    });
};
