module ExportComparisonTests exposing (tests)

import ChannelExport
import DmChannel exposing (DmChannel)
import Expect
import ExportComparison exposing (Difference(..))
import Id
import IdArray
import Message exposing (Message(..))
import NonemptyDict
import SeqDict
import Test exposing (Test)
import Thread
import Time
import Unsafe
import User


{-| Everything is compared against this cutoff, so "old" means before it and
"recent" means after it.
-}
cutoff : Time.Posix
cutoff =
    Time.millisToPosix 1000000000000


old : String
old =
    "2001-09-09T01:00:00.000Z"


recent : String
recent =
    "2001-09-09T02:00:00.000Z"


quote : String -> String
quote text =
    "\"" ++ text ++ "\""


{-| The parts of a channel export that the comparison looks at.
-}
export : List String -> String
export messages =
    "{" ++ quote "channel" ++ ":{}," ++ quote "messages" ++ ":[" ++ String.join "," messages ++ "]}"


message : String -> String -> String
message createdAt content =
    "{"
        ++ quote "type"
        ++ ":"
        ++ quote "userTextMessage"
        ++ ","
        ++ quote "createdAt"
        ++ ":"
        ++ quote createdAt
        ++ ","
        ++ quote "content"
        ++ ":"
        ++ quote content
        ++ "}"


deletedMessage : String -> String -> String
deletedMessage deletedAt leftBehind =
    "{"
        ++ quote "type"
        ++ ":"
        ++ quote "deleted"
        ++ ","
        ++ quote "deletedAt"
        ++ ":"
        ++ quote deletedAt
        ++ ","
        ++ quote "content"
        ++ ":"
        ++ quote leftBehind
        ++ "}"


withThread : String -> List String -> String
withThread parent threadMessages =
    String.dropRight 1 parent
        ++ ","
        ++ quote "threadMessages"
        ++ ":["
        ++ String.join "," threadMessages
        ++ "]}"


{-| A real export, built by the code behind the "Export channel" button, so that
the comparison is held to the shape of the exports it actually reads rather than
to the hand written ones above. Every message here is older than the cutoff, so
all of them are checked.
-}
channelExport : String
channelExport =
    ChannelExport.dmChannel
        (NonemptyDict.singleton
            (Id.fromInt 1)
            (User.init (Time.millisToPosix 0) (Unsafe.personName "Sven") (Unsafe.emailAddress "sven@example.com") False)
        )
        (Id.fromInt 1)
        (Id.fromInt 2)
        { backendInit
            | messages = IdArray.fromList [ DeletedMessage (Time.millisToPosix 1), DeletedMessage (Time.millisToPosix 2) ]
            , threads =
                SeqDict.singleton
                    (Id.fromInt 0)
                    { threadInit | messages = IdArray.fromList [ DeletedMessage (Time.millisToPosix 3) ] }
        }


backendInit : DmChannel
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
                    (export [ withThread (message old "hi") [] ])
                    (export [ withThread (message old "hi") [ message recent "a reply" ] ])
                    |> Expect.equal (Ok [])
        , Test.test "An old thread message changing is a failure" <|
            \_ ->
                compare
                    (export [ withThread (message old "hi") [ message old "a reply" ] ])
                    (export [ withThread (message old "hi") [ message old "a different reply" ] ])
                    |> Result.map (List.map describe)
                    |> Expect.equal (Ok [ "changed message 0 thread message 0" ])
        , Test.test "An old thread message under a recent message is still checked" <|
            \_ ->
                compare
                    (export [ withThread (message recent "hi") [ message old "a reply" ] ])
                    (export [ withThread (message recent "edited") [ message old "changed" ] ])
                    |> Result.map (List.map describe)
                    |> Expect.equal (Ok [ "changed message 0 thread message 0" ])
        , Test.test "A recent message that took an old thread with it is a failure" <|
            \_ ->
                compare
                    (export [ withThread (message recent "hi") [ message old "a reply" ] ])
                    (export [])
                    |> Result.map (List.map describe)
                    |> Expect.equal (Ok [ "missing message 0" ])
        , Test.test "A message with no readable timestamp is checked rather than skipped" <|
            \_ ->
                compare
                    (export [ "{" ++ quote "content" ++ ":" ++ quote "hi" ++ "}" ])
                    (export [ "{" ++ quote "content" ++ ":" ++ quote "changed" ++ "}" ])
                    |> Result.map (List.map describe)
                    |> Expect.equal (Ok [ "changed message 0" ])
        , Test.test "A deleted message is dated by deletedAt, so a recent deletion is allowed to change" <|
            \_ ->
                compare
                    (export [ deletedMessage recent "hi" ])
                    (export [ deletedMessage recent "changed" ])
                    |> Expect.equal (Ok [])
        , Test.test "A deleted message is dated by deletedAt, so an old deletion is not allowed to change" <|
            \_ ->
                compare
                    (export [ deletedMessage old "hi" ])
                    (export [ deletedMessage old "changed" ])
                    |> Result.map (List.map describe)
                    |> Expect.equal (Ok [ "changed message 0" ])
        , Test.test "A reference export that isn't JSON is reported as an error" <|
            \_ ->
                compare "not json" (export [])
                    |> Result.mapError (String.left 38)
                    |> Expect.equal (Err "The reference export is not valid JSON")
        , Test.test "An export without a messages array is reported as an error" <|
            \_ ->
                compare ("{" ++ quote "channel" ++ ":{}}") (export [])
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
