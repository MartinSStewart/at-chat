module DiscordPermissionTests exposing (decodePermissionHelperTests)

import Discord
import Expect
import Test exposing (Test, describe, test)


decodePermissionHelperTests : Test
decodePermissionHelperTests =
    describe "decodePermissionHelper"
        [ test "converts small decimal number to binary correctly" <|
            \_ ->
                Discord.stringToBinary "5"
                    |> Expect.equal [ True, False, True ]
        , test "converts zero to Binary module format" <|
            \_ ->
                Discord.stringToBinary "0"
                    |> Expect.equal [ False ]
        , test "converts single digit to correct binary" <|
            \_ ->
                Discord.stringToBinary "1"
                    |> Expect.equal [ True ]
        , test "converts power of 2 correctly" <|
            \_ ->
                Discord.stringToBinary "8"
                    |> Expect.equal [ False, False, False, True ]
        , test "converts medium number correctly" <|
            \_ ->
                Discord.stringToBinary "255"
                    |> Expect.equal [ True, True, True, True, True, True, True, True ]
        , test "handles large number that fits in Int" <|
            \_ ->
                Discord.stringToBinary "1024"
                    |> Expect.equal [ False, False, False, False, False, False, False, False, False, False, True ]
        , test "handles edge case of largest safe integer" <|
            \_ ->
                Discord.stringToBinary "863286312958"
                    |> Expect.equal (helper "1100100011111111110111111011111111111110")
        ]


helper : String -> List Bool
helper text =
    String.toList text
        |> List.map
            (\char ->
                if char == '0' then
                    False

                else
                    True
            )
        |> List.reverse
