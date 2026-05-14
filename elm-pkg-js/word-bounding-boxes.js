exports.init = async function (app) {
  app.ports.word_bounding_boxes_to_js.subscribe(function (data) {
    var requestId = data.requestId;
    var element = document.getElementById(data.htmlId);
    if (!element) {
      app.ports.word_bounding_boxes_from_js.send({ requestId: requestId, boxes: [] });
      return;
    }
    app.ports.word_bounding_boxes_from_js.send({
      requestId: requestId,
      boxes: getWordBoundingBoxes(element)
    });
  });
};

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
          height: r.height
        });
      }
    }
  }
  return boxes;
}
