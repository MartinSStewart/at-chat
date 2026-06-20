module DuplicateMessageTest exposing (tests)

{-| Regression tests for new messages showing up twice for users who recently
(re)connected (for example a user that just joined a guild).

The frontend stores each channel's messages in an append-only array where the array index
_is_ the message id (see `DmChannel`/`LocalState`). A `Server_SendMessage` (a message from
someone else) or a `LocalChangeResponse` (a message we sent ourselves) is applied by
appending the new message to the end of that array via
`LocalState.createChannelMessageFrontend`.

The whole sync model assumes every backend change reaches the frontend exactly once. Around
a disconnect/reconnect that assumption can break: Lamdera can redeliver a `ToFrontend`
message that the reconnect reload (`ReloadDataResponse`) already folded into the snapshot. If
that happens the message gets appended a second time and shows up as a duplicate that only
goes away once the page is reloaded again.

These tests pin down that the append is idempotent: re-applying the same message is a no-op,
while genuinely different messages are still appended.

-}

import Array
import DmChannel
import Expect
import Id exposing (Id, UserId)
import LocalState
import Message exposing (Message)
import RichText
import SeqDict
import String.Nonempty exposing (NonemptyString(..))
import Test exposing (Test)
import Time


message : Int -> Message id (Id UserId)
message createdAtMillis =
    messageWith createdAtMillis "hello world"


messageWith : Int -> String -> Message id (Id UserId)
messageWith createdAtMillis text =
    Message.userTextMessageFrontend
        (Time.millisToPosix createdAtMillis)
        (Id.fromInt 5)
        (RichText.fromNonemptyString SeqDict.empty (NonemptyString (String.uncons text |> Maybe.map Tuple.first |> Maybe.withDefault ' ') (String.uncons text |> Maybe.map Tuple.second |> Maybe.withDefault "")))
        Nothing
        SeqDict.empty


tests : Test
tests =
    Test.describe "Duplicate message handling"
        [ Test.test "Receiving the same message twice only adds it once" <|
            \_ ->
                let
                    afterFirst =
                        LocalState.createChannelMessageFrontend (message 1000) DmChannel.frontendInit

                    -- Simulates the same server change being delivered a second time, which
                    -- is what happens when Lamdera redelivers a ToFrontend message after a
                    -- reconnect reload has already applied it.
                    afterDuplicate =
                        LocalState.createChannelMessageFrontend (message 1000) afterFirst
                in
                Expect.equal 1 (Array.length afterDuplicate.messages)
        , Test.test "Distinct messages are still appended" <|
            \_ ->
                let
                    afterFirst =
                        LocalState.createChannelMessageFrontend (message 1000) DmChannel.frontendInit

                    afterSecond =
                        LocalState.createChannelMessageFrontend (message 2000) afterFirst
                in
                Expect.equal 2 (Array.length afterSecond.messages)
        , Test.test "Different messages that share a timestamp are both kept" <|
            \_ ->
                let
                    -- Two genuinely different messages can share an author and timestamp
                    -- (e.g. Discord messages with a coarse timestamp); both must be kept.
                    afterFirst =
                        LocalState.createChannelMessageFrontend (messageWith 1000 "first message") DmChannel.frontendInit

                    afterSecond =
                        LocalState.createChannelMessageFrontend (messageWith 1000 "second message") afterFirst
                in
                Expect.equal 2 (Array.length afterSecond.messages)
        ]
