// For playtesting Tetromino Fort with a script in the browser. Only set up when the page's URL has
// "bot" in its query string (https://…/?bot), so nobody else's match ever leaves Elm. The script
// calls window.tetrominoBot: getState() resolves with the open match as this user sees it (or null
// when no match is open), and join/move/drop send the same inputs clicking would.
exports.init = async function init(app) {
    // The app tidies the URL before this runs, so look at the one the page was loaded from.
    const loadedFrom = performance.getEntriesByType("navigation")[0]?.name ?? window.location.href;
    if (!new URL(loadedFrom).searchParams.has("bot")) {
        return;
    }
    let nextId = 0;
    const waiting = new Map();
    app.ports.tetromino_bot_to_js.subscribe((response) => {
        if (response.type === "error") {
            console.warn("tetromino bot request failed:", response.message);
            return;
        }
        const resolve = waiting.get(response.id);
        waiting.delete(response.id);
        if (resolve) {
            resolve(response.type === "state" ? response : null);
        }
    });
    const send = (request) => app.ports.tetromino_bot_from_js.send(request);
    window.tetrominoBot = {
        getState: () =>
            new Promise((resolve) => {
                const id = nextId++;
                waiting.set(id, resolve);
                send({ type: "getState", id });
            }),
        join: () => send({ type: "join" }),
        move: (x, y) => send({ type: "move", x, y }),
        drop: (x, y, quarterTurns, upright) => send({ type: "drop", x, y, quarterTurns, upright }),
    };
};
