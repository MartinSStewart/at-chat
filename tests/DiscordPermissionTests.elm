module DiscordPermissionTests exposing (decodePermissionHelperTests)

import Array exposing (Array)
import Discord
import Expect
import Test exposing (Test, describe, test)


decodePermissionHelperTests : Test
decodePermissionHelperTests =
    describe "decodePermissionHelper"
        [ test "converts small decimal number to binary correctly" <|
            \_ ->
                Discord.stringToBinary "5"
                    |> Expect.equal (Array.fromList [ True, False, True ])
        , test "converts zero to Binary module format" <|
            \_ ->
                Discord.stringToBinary "0"
                    |> Expect.equal Array.empty
        , test "converts single digit to correct binary" <|
            \_ ->
                Discord.stringToBinary "1"
                    |> Expect.equal (Array.fromList [ True ])
        , test "converts power of 2 correctly" <|
            \_ ->
                Discord.stringToBinary "8"
                    |> Expect.equal (Array.fromList [ False, False, False, True ])
        , test "converts medium number correctly" <|
            \_ ->
                Discord.stringToBinary "255"
                    |> Expect.equal (Array.fromList [ True, True, True, True, True, True, True, True ])
        , test "handles large number that fits in Int" <|
            \_ ->
                Discord.stringToBinary "1024"
                    |> Expect.equal (Array.fromList [ False, False, False, False, False, False, False, False, False, False, True ])
        , test "handles edge case of largest safe integer" <|
            \_ ->
                Discord.stringToBinary "863286312958"
                    |> Expect.equal (helper "1100100011111111110111111011111111111110")
        ]


helper : String -> Array Bool
helper text =
    String.toList text
        |> List.map
            (\char ->
                char /= '0'
            )
        |> List.reverse
        |> Array.fromList
