// Experiment: probe whether WebTransport (HTTP/3 over QUIC) works for this app.
// Waits 5 seconds after load, opens a WebTransport connection to the rust-server,
// sends "Hello" over a bidirectional stream and logs the server's reply.
//
// Only runs against the local dev rust-server (localhost), so it never affects
// production visitors.

exports.init = function init(app) {
  const isLocal =
    location.hostname === "localhost" || location.hostname === "127.0.0.1";

  if (!isLocal) {
    return;
  }

  setTimeout(runWebTransportTest, 5000);
};

async function runWebTransportTest() {
  if (typeof WebTransport === "undefined") {
    console.error("[WebTransport test] WebTransport is not supported in this browser");
    return;
  }

  const httpBase = "http://localhost:3000";
  const webTransportUrl = "https://localhost:3001/";

  try {
    // The rust-server generates a fresh self-signed cert on each start, so fetch
    // its SHA-256 hash and pass it via serverCertificateHashes to let the browser
    // trust it without manual cert installation.
    const hashText = await (await fetch(httpBase + "/webtransport-cert-hash")).text();
    const certHash = Uint8Array.from(
      hashText.trim().split(":").map((byte) => parseInt(byte, 16))
    );

    const transport = new WebTransport(webTransportUrl, {
      serverCertificateHashes: [{ algorithm: "sha-256", value: certHash }],
    });

    await transport.ready;
    console.log("[WebTransport test] connection established");

    const stream = await transport.createBidirectionalStream();

    const writer = stream.writable.getWriter();
    await writer.write(new TextEncoder().encode("Hello"));
    await writer.close();

    const reader = stream.readable.getReader();
    const decoder = new TextDecoder();
    let received = "";
    while (true) {
      const { value, done } = await reader.read();
      if (done) {
        break;
      }
      received += decoder.decode(value, { stream: true });
    }
    received += decoder.decode();

    console.log("[WebTransport test] server replied:", received);
  } catch (error) {
    console.error("[WebTransport test] failed:", error);
  }
}
