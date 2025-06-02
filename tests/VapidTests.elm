module VapidTests exposing (..)

import Array exposing (Array)
import Bytes exposing (Bytes)
import Bytes.Encode
import Expect
import Hex
import List.Extra
import Test exposing (Test)
import Vapid


input : Bytes
input =
    String.toList "304502206591431e2e2c6645d6b75784f4429da8bd943bc6cbc1d1a2c76e74068d3be6c7022100f95b6ba3093f9cb37820873982425e78f3f15fcfa5db279cbe3b44ab07dd63f8"
        |> List.Extra.greedyGroupsOf 2
        |> List.filterMap (\chars -> String.fromList chars |> Hex.fromString |> Result.toMaybe)
        |> Vapid.encodeHex
        |> Bytes.Encode.encode


expected : Array Int
expected =
    String.toList "6591431e2e2c6645d6b75784f4429da8bd943bc6cbc1d1a2c76e74068d3be6c7f95b6ba3093f9cb37820873982425e78f3f15fcfa5db279cbe3b44ab07dd63f8"
        |> List.Extra.greedyGroupsOf 2
        |> List.filterMap (\chars -> String.fromList chars |> Hex.fromString |> Result.toMaybe)
        |> Array.fromList


test : Test
test =
    Test.only <|
        Test.test "derToJose" <|
            \_ ->
                Vapid.derToJose input
                    |> Vapid.bytesToHex
                    |> Expect.equal expected



--Test.test "Vapid test" <|
--    \_ ->
--        Vapid.generateRequestDetails (Time.millisToPosix 0) (Unsafe.url "https://at-chat.app")
--            |> Expect.equal "eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzI1NiJ9"
