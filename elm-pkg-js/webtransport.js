// Proof of concept for using WebTransport to talk to the Rust server. Opens a
// connection, sends "Hello world!" on a bidirectional stream, and reports back
// whatever the server echoes.
//
// The Rust server generates a self-signed certificate when it starts, so the browser
// has to be told which certificate to trust via serverCertificateHashes. The hash and
// the port to connect to come from /file/webtransport-info on the file API.

exports.init = async function init(app) {
    app.ports.webtransport_to_js.subscribe(async function (data) {
        try {
            const echo = await sendHelloWorld(data.serverUrl);
            app.ports.webtransport_from_js.send({ tag: "echoed", message: echo });
        } catch (error) {
            app.ports.webtransport_from_js.send({ tag: "failed", message: String(error) });
        }
    });
}

async function sendHelloWorld(serverUrl) {
    if (typeof WebTransport === "undefined") {
        throw new Error("This browser doesn't support WebTransport");
    }

    const response = await fetch(serverUrl + "/file/webtransport-info");

    if (!response.ok) {
        throw new Error("Couldn't load the WebTransport server info: " + response.status);
    }

    const info = await response.json();

    const transport = new WebTransport(
        "https://" + new URL(serverUrl).hostname + ":" + info.port + "/",
        { serverCertificateHashes: [{ algorithm: "sha-256", value: new Uint8Array(info.certificateHash) }] }
    );

    try {
        await transport.ready;

        const stream = await transport.createBidirectionalStream();

        const writer = stream.writable.getWriter();
        await writer.write(new TextEncoder().encode("Hello world!"));
        // Closing the write side tells the server we're done, which makes it finish its
        // side of the stream so the read below terminates.
        await writer.close();

        return await readAll(stream.readable);
    } finally {
        transport.close();
    }
}

async function readAll(readable) {
    const reader = readable.getReader();
    const chunks = [];

    while (true) {
        const { value, done } = await reader.read();

        if (done) {
            return new TextDecoder().decode(concat(chunks));
        }

        chunks.push(value);
    }
}

function concat(chunks) {
    const result = new Uint8Array(chunks.reduce((total, chunk) => total + chunk.length, 0));
    let offset = 0;

    chunks.forEach(function (chunk) {
        result.set(chunk, offset);
        offset += chunk.length;
    });

    return result;
}
