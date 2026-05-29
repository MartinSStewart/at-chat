
function mtime() {
  const hrTime = process.hrtime();
  return Math.floor(hrTime[0] * 1000000 + hrTime[1] / 1000);
}

global.markTimer = mtime();

module.exports.markTime = function(label) {
  const duration = mtime() - global.markTimer;
  console.log("⏱  ", label, ":", Math.floor(duration / 1000), "ms")
  global.markTimer = mtime();
}
