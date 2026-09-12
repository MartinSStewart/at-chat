module ExportComparisonTests exposing (tests)

import ChannelExport
import DmChannel exposing (BackendDmChannel)
import Expect
import ExportComparison exposing (Difference(..))
import Id
import IdArray
import Message exposing (Message(..))
import SeqDict
import Test exposing (Test)
import Thread
import Time


{-| Everything is compared against this cutoff, so "old" means before it and
"recent" means after it.
-}
cutoff : Time.Posix
cutoff =
    Time.millisToPosix 1000000000000


old : String
old =
    "999999999999"


recent : String
recent =
    "1000000000001"


quote : String -> String
quote text =
    "\"" ++ text ++ "\""


{-| The parts of a channel export that the comparison looks at.
-}
export : List String -> String
export messages =
    exportWithThreads messages []


exportWithThreads : List String -> List ( String, List String ) -> String
exportWithThreads messages threads =
    "{"
        ++ quote "tag"
        ++ ":"
        ++ quote "DmChannelExport"
        ++ ","
        ++ quote "args"
        ++ ":[{"
        ++ quote "messages"
        ++ ":["
        ++ String.join "," messages
        ++ "],"
        ++ quote "threads"
        ++ ":["
        ++ String.join ","
            (List.map
                (\( key, threadMessages ) ->
                    "{"
                        ++ quote "k"
                        ++ ":"
                        ++ key
                        ++ ","
                        ++ quote "v"
                        ++ ":{"
                        ++ quote "messages"
                        ++ ":["
                        ++ String.join "," threadMessages
                        ++ "]}}"
                )
                threads
            )
        ++ "]}]}"


message : String -> String -> String
message createdAt content =
    "{"
        ++ quote "tag"
        ++ ":"
        ++ quote "UserTextMessage"
        ++ ","
        ++ quote "args"
        ++ ":[{"
        ++ quote "createdAt"
        ++ ":"
        ++ createdAt
        ++ ","
        ++ quote "content"
        ++ ":"
        ++ quote content
        ++ "}]}"


{-| Someone joining is dated by a timestamp that sits in the message directly rather than
in a record inside it, which is the other shape the comparison has to be able to read.
-}
joinedMessage : String -> String -> String
joinedMessage joinedAt reaction =
    "{"
        ++ quote "tag"
        ++ ":"
        ++ quote "UserJoinedMessage"
        ++ ","
        ++ quote "args"
        ++ ":["
        ++ joinedAt
        ++ ",0,"
        ++ quote reaction
        ++ ",null]}"


{-| A real export, built by the code behind the "Export channel" button, so that
the comparison is held to the shape of the exports it actually reads rather than
to the hand written ones above. Every message here is older than the cutoff, so
all of them are checked.
-}
channelExport : String
channelExport =
    ChannelExport.dmChannel
        { backendInit
            | messages = IdArray.fromList [ DeletedMessage (Time.millisToPosix 1), DeletedMessage (Time.millisToPosix 2) ]
            , threads =
                SeqDict.singleton
                    (Id.fromInt 0)
                    { threadInit | messages = IdArray.fromList [ DeletedMessage (Time.millisToPosix 3) ] }
        }


backendInit : BackendDmChannel
backendInit =
    DmChannel.backendInit


threadInit : Thread.BackendThread
threadInit =
    Thread.backendInit


compare : String -> String -> Result String (List Difference)
compare reference new =
    ExportComparison.compareExports cutoff reference new


tests : Test
tests =
    Test.describe "ExportComparison"
        [ Test.test "Identical exports match" <|
            \_ ->
                compare
                    (export [ message old "hi", message recent "there" ])
                    (export [ message old "hi", message recent "there" ])
                    |> Expect.equal (Ok [])
        , Test.test "An export produced by ChannelExport matches itself" <|
            \_ ->
                compare channelExport channelExport
                    |> Expect.equal (Ok [])
        , Test.test "A message older than the cutoff changing is a failure" <|
            \_ ->
                compare
                    (export [ message old "hi" ])
                    (export [ message old "changed" ])
                    |> Result.map (List.map describe)
                    |> Expect.equal (Ok [ "changed message 0" ])
        , Test.test "A message newer than the cutoff is allowed to change" <|
            \_ ->
                compare
                    (export [ message recent "hi" ])
                    (export [ message recent "edited, reacted to, whatever" ])
                    |> Expect.equal (Ok [])
        , Test.test "Messages the backup gained are ignored" <|
            \_ ->
                compare
                    (export [ message old "hi" ])
                    (export [ message old "hi", message recent "new message" ])
                    |> Expect.equal (Ok [])
        , Test.test "An old message missing from the backup is a failure" <|
            \_ ->
                compare
                    (export [ message old "hi", message old "there" ])
                    (export [ message old "hi" ])
                    |> Result.map (List.map describe)
                    |> Expect.equal (Ok [ "missing message 1" ])
        , Test.test "A recent message missing from the backup is ignored" <|
            \_ ->
                compare
                    (export [ message old "hi", message recent "there" ])
                    (export [ message old "hi" ])
                    |> Expect.equal (Ok [])
        , Test.test "Messages are matched up by their position, since the export gives them no id" <|
            \_ ->
                compare
                    (export [ message old "hi", message old "there" ])
                    (export [ message old "there", message old "hi" ])
                    |> Result.map (List.map describe)
                    |> Expect.equal (Ok [ "changed message 0", "changed message 1" ])
        , Test.test "A new reply to an old message doesn't count as the old message changing" <|
            \_ ->
                compare
                    (exportWithThreads [ message old "hi" ] [ ( "0", [] ) ])
                    (exportWithThreads [ message old "hi" ] [ ( "0", [ message recent "a reply" ] ) ])
                    |> Expect.equal (Ok [])
        , Test.test "An old thread message changing is a failure" <|
            \_ ->
                compare
                    (exportWithThreads [ message old "hi" ] [ ( "0", [ message old "a reply" ] ) ])
                    (exportWithThreads [ message old "hi" ] [ ( "0", [ message old "a different reply" ] ) ])
                    |> Result.map (List.map describe)
                    |> Expect.equal (Ok [ "changed thread 0 message 0" ])
        , Test.test "An old thread message under a recent message is still checked" <|
            \_ ->
                compare
                    (exportWithThreads [ message recent "hi" ] [ ( "0", [ message old "a reply" ] ) ])
                    (exportWithThreads [ message recent "edited" ] [ ( "0", [ message old "changed" ] ) ])
                    |> Result.map (List.map describe)
                    |> Expect.equal (Ok [ "changed thread 0 message 0" ])
        , Test.test "An old thread the backup lost entirely is a failure" <|
            \_ ->
                compare
                    (exportWithThreads [ message recent "hi" ] [ ( "0", [ message old "a reply" ] ) ])
                    (export [ message recent "hi" ])
                    |> Result.map (List.map describe)
                    |> Expect.equal (Ok [ "missing thread 0 message 0" ])
        , Test.test "A message with no readable timestamp is checked rather than skipped" <|
            \_ ->
                compare
                    (export [ "{" ++ quote "content" ++ ":" ++ quote "hi" ++ "}" ])
                    (export [ "{" ++ quote "content" ++ ":" ++ quote "changed" ++ "}" ])
                    |> Result.map (List.map describe)
                    |> Expect.equal (Ok [ "changed message 0" ])
        , Test.test "A message dated by a bare timestamp is read, so a recent one is allowed to change" <|
            \_ ->
                compare
                    (export [ joinedMessage recent "hi" ])
                    (export [ joinedMessage recent "changed" ])
                    |> Expect.equal (Ok [])
        , Test.test "A message dated by a bare timestamp is read, so an old one is not allowed to change" <|
            \_ ->
                compare
                    (export [ joinedMessage old "hi" ])
                    (export [ joinedMessage old "changed" ])
                    |> Result.map (List.map describe)
                    |> Expect.equal (Ok [ "changed message 0" ])
        , Test.test "A reference export that isn't JSON is reported as an error" <|
            \_ ->
                compare "not json" (export [])
                    |> Result.mapError (String.left 38)
                    |> Expect.equal (Err "The reference export is not valid JSON")
        , Test.test "Something that isn't a channel export at all is reported as an error" <|
            \_ ->
                compare ("{" ++ quote "channel" ++ ":{}}") (export [])
                    |> Expect.equal (Err "The reference export isn't a channel export")
        , Test.test "An export without a messages array is reported as an error" <|
            \_ ->
                compare
                    ("{" ++ quote "tag" ++ ":" ++ quote "DmChannelExport" ++ "," ++ quote "args" ++ ":[{}]}")
                    (export [])
                    |> Expect.equal (Err "The reference export has no \"messages\" array")
        ]


{-| Boils a difference down to something short enough to assert on.
-}
describe : Difference -> String
describe difference =
    case difference of
        MessageMissing path ->
            "missing " ++ path

        MessageChanged path _ _ ->
            "changed " ++ path
