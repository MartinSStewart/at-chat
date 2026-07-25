module ExportComparisonTests exposing (tests)

import Expect
import ExportComparison exposing (Difference(..))
import Test exposing (Test)
import Time


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


message : Int -> String -> String -> String
message index createdAt content =
    "{"
        ++ quote "index"
        ++ ":"
        ++ String.fromInt index
        ++ ","
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


deletedMessage : Int -> String -> String -> String
deletedMessage index deletedAt leftBehind =
    "{"
        ++ quote "index"
        ++ ":"
        ++ String.fromInt index
        ++ ","
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


compare : String -> String -> Result String (List Difference)
compare reference new =
    ExportComparison.compareExports cutoff reference new


tests : Test
tests =
    Test.describe "ExportComparison"
        [ Test.test "Identical exports match" <|
            \_ ->
                compare
                    (export [ message 0 old "hi", message 1 recent "there" ])
                    (export [ message 0 old "hi", message 1 recent "there" ])
                    |> Expect.equal (Ok [])
        , Test.test "A message older than the cutoff changing is a failure" <|
            \_ ->
                compare
                    (export [ message 0 old "hi" ])
                    (export [ message 0 old "changed" ])
                    |> Result.map (List.map describe)
                    |> Expect.equal (Ok [ "changed message 0" ])
        , Test.test "A message newer than the cutoff is allowed to change" <|
            \_ ->
                compare
                    (export [ message 0 recent "hi" ])
                    (export [ message 0 recent "edited, reacted to, whatever" ])
                    |> Expect.equal (Ok [])
        , Test.test "Messages the backup gained are ignored" <|
            \_ ->
                compare
                    (export [ message 0 old "hi" ])
                    (export [ message 0 old "hi", message 1 recent "new message" ])
                    |> Expect.equal (Ok [])
        , Test.test "An old message missing from the backup is a failure" <|
            \_ ->
                compare
                    (export [ message 0 old "hi", message 1 old "there" ])
                    (export [ message 0 old "hi" ])
                    |> Result.map (List.map describe)
                    |> Expect.equal (Ok [ "missing message 1" ])
        , Test.test "A recent message missing from the backup is ignored" <|
            \_ ->
                compare
                    (export [ message 0 old "hi", message 1 recent "there" ])
                    (export [ message 0 old "hi" ])
                    |> Expect.equal (Ok [])
        , Test.test "Message order doesn't matter, the index does" <|
            \_ ->
                compare
                    (export [ message 0 old "hi", message 1 old "there" ])
                    (export [ message 1 old "there", message 0 old "hi" ])
                    |> Expect.equal (Ok [])
        , Test.test "A new reply to an old message doesn't count as the old message changing" <|
            \_ ->
                compare
                    (export [ withThread (message 0 old "hi") [] ])
                    (export [ withThread (message 0 old "hi") [ message 0 recent "a reply" ] ])
                    |> Expect.equal (Ok [])
        , Test.test "An old thread message changing is a failure" <|
            \_ ->
                compare
                    (export [ withThread (message 0 old "hi") [ message 0 old "a reply" ] ])
                    (export [ withThread (message 0 old "hi") [ message 0 old "a different reply" ] ])
                    |> Result.map (List.map describe)
                    |> Expect.equal (Ok [ "changed message 0 thread message 0" ])
        , Test.test "An old thread message under a recent message is still checked" <|
            \_ ->
                compare
                    (export [ withThread (message 0 recent "hi") [ message 0 old "a reply" ] ])
                    (export [ withThread (message 0 recent "edited") [ message 0 old "changed" ] ])
                    |> Result.map (List.map describe)
                    |> Expect.equal (Ok [ "changed message 0 thread message 0" ])
        , Test.test "A recent message that took an old thread with it is a failure" <|
            \_ ->
                compare
                    (export [ withThread (message 0 recent "hi") [ message 0 old "a reply" ] ])
                    (export [])
                    |> Result.map (List.map describe)
                    |> Expect.equal (Ok [ "missing message 0" ])
        , Test.test "A message with no readable timestamp is checked rather than skipped" <|
            \_ ->
                compare
                    (export [ "{" ++ quote "index" ++ ":0," ++ quote "content" ++ ":" ++ quote "hi" ++ "}" ])
                    (export [ "{" ++ quote "index" ++ ":0," ++ quote "content" ++ ":" ++ quote "changed" ++ "}" ])
                    |> Result.map (List.map describe)
                    |> Expect.equal (Ok [ "changed message 0" ])
        , Test.test "A deleted message is dated by deletedAt, so a recent deletion is allowed to change" <|
            \_ ->
                compare
                    (export [ deletedMessage 0 recent "hi" ])
                    (export [ deletedMessage 0 recent "changed" ])
                    |> Expect.equal (Ok [])
        , Test.test "A deleted message is dated by deletedAt, so an old deletion is not allowed to change" <|
            \_ ->
                compare
                    (export [ deletedMessage 0 old "hi" ])
                    (export [ deletedMessage 0 old "changed" ])
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
