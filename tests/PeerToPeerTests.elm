module PeerToPeerTests exposing (tests)

import Effect.Time as Time
import Expect
import FileName
import FileStatus
import Id
import PeerToPeer
import SecretId
import Test exposing (Test, describe, test)


tests : Test
tests =
    describe "Peer to peer files"
        [ -- rust-server/src/peer_to_peer.rs checks the same token in token_matches_elm.
          test "The transfer url is signed the way the Rust server checks it" <|
            \_ ->
                PeerToPeer.transferUrl
                    (Time.millisToPosix (2000 - 120000))
                    (SecretId.fromString "secret")
                    (SecretId.fromString "abc123")
                    { guildOrDmId = Id.GuildOrDmId_Dm { otherUserId = Id.fromInt 1 }
                    , fileName = FileName.fromString "big file.bin"
                    , fileSize = 1000
                    }
                    |> Expect.equal
                        (FileStatus.domain
                            ++ "/file/p2p/abc123?size=1000&expires=2000"
                            ++ "&token=9d7e112068d366c09bfe692ab8e4ce3b34144552c1dc31a47b1874c4f4108513"
                            ++ "&name=big%20file.bin"
                        )
        ]
