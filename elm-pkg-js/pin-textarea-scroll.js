// The message input renders a formatted-text overlay on top of an invisible
// textarea, and the two only stay visually aligned if the textarea's internal
// scroll position stays at 0 (the overlay is a plain div and can't scroll)
// and both layers break lines at the same points.
//
// Browsers sometimes scroll a textarea anyway even though it has
// overflow:hidden, e.g. mobile browsers scrolling the caret into view when
// typing near an edge, or focus()/setSelectionRange() calls. iOS Safari has
// also been seen keeping a stale line layout / scroll offset after a
// deletion re-joins a word onto the previous line (the overlay re-wraps but
// the textarea doesn't). Two defenses, both scoped to textareas marked with
// data-pin-scroll:
//
// 1. Scroll events don't bubble but they do reach the document in the
//    capture phase, so one listener resets any internal scroll immediately.
// 2. After each input event, once Elm has re-rendered the overlay (double
//    requestAnimationFrame), force the textarea to rebuild its line layout
//    by toggling a layout-affecting style inside the frame (no paint happens
//    in between, so nothing flickers) and re-clamp the scroll position.

exports.init = async function init(app) {
    document.addEventListener(
        "scroll",
        (event) => {
            const target = event.target;
            if (
                target instanceof HTMLTextAreaElement
                && target.hasAttribute("data-pin-scroll")
                && (target.scrollTop !== 0 || target.scrollLeft !== 0)
            ) {
                target.scrollTop = 0;
                target.scrollLeft = 0;
            }
        },
        { capture: true, passive: true }
    );

    document.addEventListener(
        "input",
        (event) => {
            const target = event.target;
            if (
                target instanceof HTMLTextAreaElement
                && target.hasAttribute("data-pin-scroll")
            ) {
                requestAnimationFrame(() => {
                    requestAnimationFrame(() => {
                        const previous = target.style.letterSpacing;
                        target.style.letterSpacing = "0.001px";
                        void target.offsetHeight;
                        target.style.letterSpacing = previous;
                        void target.offsetHeight;
                        if (target.scrollTop !== 0 || target.scrollLeft !== 0) {
                            target.scrollTop = 0;
                            target.scrollLeft = 0;
                        }
                    });
                });
            }
        },
        { capture: true, passive: true }
    );
}
