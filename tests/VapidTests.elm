module VapidTests exposing (..)

import Expect
import Test exposing (Test)
import Unsafe
import Vapid


test : Test
test =
    Test.only <|
        Test.test "Vapid test" <|
            \_ ->
                Vapid.generateRequestDetails (Unsafe.url "https://at-chat.app")
                    |> Expect.equal "eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzI1NiJ9"
