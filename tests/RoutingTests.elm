module RoutingTests exposing (roundtrip)

import Expect
import Fuzz exposing (Fuzzer)
import Id exposing (ChannelId, ChannelMessageId, GuildId, Id, InviteLinkId, ThreadRoute(..), UserId)
import Route exposing (ChannelRoute(..), Route(..))
import SecretId exposing (SecretId)
import Test exposing (Test)
import Url


roundtrip : Test
roundtrip =
    Test.fuzz routeFuzzer "Route toString/decode roundtrips" <|
        \route ->
            let
                encoded : String
                encoded =
                    Route.encode route
            in
            case Url.fromString ("http://fake" ++ encoded) of
                Nothing ->
                    Expect.fail ("Could not parse  URL: " ++ encoded)

                Just url ->
                    let
                        actual =
                            Route.decode url
                    in
                    if actual == route then
                        Expect.pass

                    else
                        let
                            _ =
                                Debug.log "Failed to roundtrip, URL was " encoded
                        in
                        actual
                            |> Expect.equal route


routeFuzzer : Fuzzer Route
routeFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant HomePageRoute
        , Fuzz.map AdminRoute (Fuzz.map (\highlightLog -> { highlightLog = highlightLog }) (Fuzz.maybe Fuzz.int))
        , Fuzz.constant AiChatRoute
        , Fuzz.map2 GuildRoute idFuzzer channelRouteFuzzer
        , Fuzz.map3 DmRoute idFuzzer threadRouteFuzzer (Fuzz.maybe idFuzzer)
        ]


idFuzzer : Fuzzer (Id a)
idFuzzer =
    Fuzz.map Id.fromInt (Fuzz.intRange 0 9999)


secretIdFuzzer : Fuzzer (SecretId a)
secretIdFuzzer =
    Fuzz.map SecretId.fromString (Fuzz.map String.fromList (Fuzz.listOfLength 16 (Fuzz.oneOf (List.map Fuzz.constant (String.toList "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")))))


threadRouteFuzzer : Fuzzer ThreadRoute
threadRouteFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant NoThread
        , Fuzz.map ViewThread idFuzzer
        ]


channelRouteFuzzer : Fuzzer ChannelRoute
channelRouteFuzzer =
    Fuzz.oneOf
        [ Fuzz.map3 ChannelRoute idFuzzer threadRouteFuzzer (Fuzz.maybe idFuzzer)
        , Fuzz.constant NewChannelRoute
        , Fuzz.map EditChannelRoute idFuzzer
        , Fuzz.constant InviteLinkCreatorRoute
        , Fuzz.map JoinRoute secretIdFuzzer
        ]
