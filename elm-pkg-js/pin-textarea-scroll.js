// The message input renders a formatted-text overlay on top of an invisible
// textarea, and the two only stay visually aligned if the textarea's internal
// scroll position stays at 0 (the overlay is a plain div and can't scroll).
// Browsers sometimes scroll a textarea anyway even though it has
// overflow:hidden, e.g. mobile browsers scrolling the caret into view when
// backspacing near an edge, or focus()/setSelectionRange() calls. Scroll
// events don't bubble but they do reach the document in the capture phase, so
// one listener covers every textarea marked with data-pin-scroll, including
// ones added later.

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
}
