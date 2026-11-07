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
        [ -- rust-server/src/peer_to_peer.rs checks the same tokens in token_matches_elm.
          test "The transfer url is signed the way the Rust server checks it" <|
            \_ ->
                transferUrl "big file.bin"
                    |> Expect.equal
                        (FileStatus.domain
                            ++ "/file/p2p/abc123?size=1000&expires=2000"
                            ++ "&token=727a34277bfdc8eb734227ac0351af4d0c56bf2d4db4b63412cc9174957f0702"
                            ++ "&name=big%20file.bin"
                        )
        , test "A name outside ASCII is signed as UTF-8" <|
            \_ ->
                transferUrl "häst 🐴.bin"
                    |> Expect.equal
                        (FileStatus.domain
                            ++ "/file/p2p/abc123?size=1000&expires=2000"
                            ++ "&token=abd6d05d564e7168eb1ced7346ab83eb1bea3b7602db6f2f8af6e78d1d21cc6b"
                            ++ "&name=h%C3%A4st%20%F0%9F%90%B4.bin"
                        )
        ]


transferUrl : String -> String
transferUrl name =
    PeerToPeer.transferUrl
        (Time.millisToPosix (2000 - 120000))
        (SecretId.fromString "secret")
        (SecretId.fromString "abc123")
        { guildOrDmId = Id.GuildOrDmId_Dm { otherUserId = Id.fromInt 1 }
        , fileName = FileName.fromString name
        , fileSize = 1000
        }
