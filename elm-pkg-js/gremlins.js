// Gremlin overlay: when enabled, draw a looping outline-guy-sit
// animation perched on a word inside each visible text message.

const FRAME_URLS = [
  "/gremlins/outline-guy-sit-frame-1.png",
  "/gremlins/outline-guy-sit-frame-2.png",
  "/gremlins/outline-guy-sit-frame-3.png",
];

const GREMLIN_HEIGHT = 28; // px, on-screen size of the gremlin
const GREMLIN_WIDTH = Math.round(GREMLIN_HEIGHT * (112 / 150));
const FRAME_INTERVAL_MS = 250;
const RESCAN_INTERVAL_MS = 1000;
const MESSAGE_ID_PREFIXES = ["guild_message_", "thread_message_"];
const MARKER_ATTR = "data-gremlin-spot";

let enabled = false;
let frameIndex = 0;
let frameTimer = null;
let rescanTimer = null;

function getWordBoundingBoxes(element) {
  var containerRect = element.getBoundingClientRect();
  var boxes = [];
  var walker = document.createTreeWalker(element, NodeFilter.SHOW_TEXT, null);
  var node;
  while ((node = walker.nextNode())) {
    var text = node.nodeValue;
    var wordRegex = /\S+/g;
    var match;
    while ((match = wordRegex.exec(text)) !== null) {
      var range = document.createRange();
      range.setStart(node, match.index);
      range.setEnd(node, match.index + match[0].length);
      var rects = range.getClientRects();
      for (var i = 0; i < rects.length; i++) {
        var r = rects[i];
        if (r.width === 0 && r.height === 0) continue;
        boxes.push({
          word: match[0],
          x: r.left - containerRect.left,
          y: r.top - containerRect.top,
          width: r.width,
          height: r.height,
        });
      }
    }
  }
  return boxes;
}

function pickSpot(boxes) {
  if (boxes.length === 0) return null;
  // Pick a stable-ish word: prefer the longest word so the gremlin has
  // somewhere wide to sit on. Tie-break by leftmost position.
  var best = boxes[0];
  for (var i = 1; i < boxes.length; i++) {
    var b = boxes[i];
    if (
      b.width > best.width ||
      (b.width === best.width && b.x < best.x)
    ) {
      best = b;
    }
  }
  return best;
}

function ensureGremlin(messageEl) {
  if (messageEl.getAttribute(MARKER_ATTR) === "done") return;
  var boxes = getWordBoundingBoxes(messageEl);
  if (boxes.length === 0) return; // no text yet (e.g. images only) - try again later
  var spot = pickSpot(boxes);
  if (!spot) return;

  // Make sure the message can host an absolutely-positioned child.
  var prevPosition = window.getComputedStyle(messageEl).position;
  if (prevPosition === "static" || !prevPosition) {
    messageEl.style.position = "relative";
  }

  var img = document.createElement("img");
  img.className = "gremlin-overlay";
  img.alt = "";
  img.src = FRAME_URLS[frameIndex];
  img.style.position = "absolute";
  img.style.pointerEvents = "none";
  img.style.imageRendering = "pixelated";
  img.style.width = GREMLIN_WIDTH + "px";
  img.style.height = GREMLIN_HEIGHT + "px";
  img.style.zIndex = "5";
  // Sit on top of the chosen word: bottom of the sprite aligns with the
  // top of the word, horizontally near its right edge.
  var left = Math.max(0, spot.x + spot.width - GREMLIN_WIDTH);
  var top = Math.max(0, spot.y - GREMLIN_HEIGHT + 2);
  img.style.left = left + "px";
  img.style.top = top + "px";

  messageEl.appendChild(img);
  messageEl.setAttribute(MARKER_ATTR, "done");
}

function scanMessages() {
  if (!enabled) return;
  var selector = MESSAGE_ID_PREFIXES.map(function (p) {
    return '[id^="' + p + '"]';
  }).join(",");
  var els = document.querySelectorAll(selector);
  for (var i = 0; i < els.length; i++) {
    ensureGremlin(els[i]);
  }
}

function clearAllGremlins() {
  var imgs = document.querySelectorAll("img.gremlin-overlay");
  for (var i = 0; i < imgs.length; i++) {
    imgs[i].parentNode && imgs[i].parentNode.removeChild(imgs[i]);
  }
  var marked = document.querySelectorAll("[" + MARKER_ATTR + "]");
  for (var j = 0; j < marked.length; j++) {
    marked[j].removeAttribute(MARKER_ATTR);
  }
}

function tickFrame() {
  frameIndex = (frameIndex + 1) % FRAME_URLS.length;
  var src = FRAME_URLS[frameIndex];
  var imgs = document.querySelectorAll("img.gremlin-overlay");
  for (var i = 0; i < imgs.length; i++) {
    imgs[i].src = src;
  }
}

function start() {
  if (frameTimer == null) frameTimer = setInterval(tickFrame, FRAME_INTERVAL_MS);
  if (rescanTimer == null) rescanTimer = setInterval(scanMessages, RESCAN_INTERVAL_MS);
  scanMessages();
}

function stop() {
  if (frameTimer != null) {
    clearInterval(frameTimer);
    frameTimer = null;
  }
  if (rescanTimer != null) {
    clearInterval(rescanTimer);
    rescanTimer = null;
  }
  clearAllGremlins();
}

exports.init = async function (app) {
  app.ports.gremlins_to_js.subscribe(function (data) {
    var nextEnabled = !!(data && data.enabled);
    if (nextEnabled === enabled) return;
    enabled = nextEnabled;
    if (enabled) start();
    else stop();
  });
};
