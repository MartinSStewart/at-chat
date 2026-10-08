// The tetromino game's canvas is drawn at the screen's own resolution and dithers see-through
// things one pixel at a time, which only looks right if each pixel of the canvas lands on exactly
// one pixel of the screen. Elm sizes the canvas in whole device pixels, but can't tell where on the
// screen it ends up: centring it, or a device pixel ratio like 1.25, can leave it part way across a
// pixel, and then the browser blends neighbouring pixels together. <pixel-snapped> shifts its
// first child by under a pixel each frame so it lines up again.
exports.init = async function init(app) {
    if (customElements.get("pixel-snapped")) {
        return;
    }
    customElements.define(
        "pixel-snapped",
        class extends HTMLElement {
            connectedCallback() {
                const step = () => {
                    snap(this);
                    this._frame = requestAnimationFrame(step);
                };
                this._frame = requestAnimationFrame(step);
            }

            disconnectedCallback() {
                cancelAnimationFrame(this._frame);
            }
        }
    );
};

function snap(element) {
    const child = element.firstElementChild;
    if (!(child instanceof HTMLElement)) {
        return;
    }
    const ratio = window.devicePixelRatio || 1;
    // The element itself isn't moved, so this is where the child would be without the shift.
    const rect = element.getBoundingClientRect();
    const shift = (position) => (Math.round(position * ratio) - position * ratio) / ratio;
    const transform = `translate(${shift(rect.left)}px, ${shift(rect.top)}px)`;
    if (child.style.transform !== transform) {
        child.style.transform = transform;
    }
}
