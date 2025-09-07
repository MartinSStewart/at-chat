module VisibleMessagesTests exposing (test)

import Array
import DmChannel
import Effect.Time as Time
import Expect
import Id
import Message exposing (Message(..), MessageState(..))
import SeqDict
import Test exposing (Test)
import VisibleMessages


test : Test
test =
    Test.test "load messages correct number" <|
        \_ ->
            let
                message : Int -> Message messageId
                message index =
                    UserJoinedMessage (Time.millisToPosix index) (Id.fromInt 0) SeqDict.empty

                extraMessages : number
                extraMessages =
                    20
            in
            DmChannel.loadMessages
                True
                (Array.initialize (VisibleMessages.pageSize + extraMessages) message)
                |> Expect.equal
                    (Array.append
                        (Array.repeat extraMessages MessageUnloaded)
                        (Array.initialize
                            VisibleMessages.pageSize
                            (\index -> message (extraMessages + index) |> MessageLoaded)
                        )
                    )
