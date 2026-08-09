// Proof of concept for using WebTransport to talk to the Rust server. Opens a
// connection, sends "Hello world!" on a bidirectional stream, and reports back
// whatever the server echoes.
//
// The Rust server generates a self-signed certificate when it starts, so the browser
// has to be told which certificate to trust via serverCertificateHashes. The hash and
// the port to connect to come from /file/webtransport-info on the file API.

exports.init = async function init(app) {
    app.ports.webtransport_to_js.subscribe(async function (data) {
        if (data.tag === "SendHelloWorld") {
            try {
                await sendHelloWorld(data.args[0]);
            } catch (error) {
                app.ports.webtransport_from_js.send({ tag: "Failed", args: [ String(error) ] });
            }
        }
    });



    let transport = null;
    let stream = null;
    let reader = null;
    let writer = null;

    async function sendHelloWorld(serverUrl) {
        if (typeof WebTransport === "undefined") {
            throw new Error("This browser doesn't support WebTransport");
        }


        if (transport) {
        }
        else
        {
            const response = await fetch(serverUrl + "/file/webtransport-info");

            if (!response.ok) {
                throw new Error("Couldn't load the WebTransport server info: " + response.status);
            }

            const info = await response.json();
            transport = new WebTransport(
                "https://" + new URL(serverUrl).hostname + ":" + info.port + "/",
                { serverCertificateHashes: [{ algorithm: "sha-256", value: new Uint8Array(info.certificateHash) }] }
            );
            await transport.ready;

            stream = await transport.createBidirectionalStream();
            reader = stream.readable.getReader();
            writer = stream.writable.getWriter();
            readAll(reader);
        }

        await writer.write(new TextEncoder().encode("Hello world!"));

    }

    async function readAll(reader) {
        while (true) {
            const { value, done } = await reader.read();

            if (done) {
                return;
            }

            const data = new TextDecoder().decode(value);
            app.ports.webtransport_from_js.send({ tag : "GotServerData", args: [ data ] });
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

}
