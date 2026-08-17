module RoutingTests exposing (roundtrip)

import DmChannelId
import Expect
import Fuzz exposing (Fuzzer)
import Id exposing (Id)
import Route exposing (ChannelRoute(..), ChannelsVisibleOnMobile(..), Route(..), ShowChannelSettings(..), ThreadRouteWithFriends(..))
import SecretId exposing (SecretId)
import Test exposing (Test)
import Url
import UserSession exposing (ChannelHeaderTab(..))


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
                        Expect.equal route actual


routeFuzzer : Fuzzer Route
routeFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant HomePageRoute
        , Fuzz.map AdminRoute (Fuzz.map (\highlightLog -> { highlightLog = highlightLog }) (Fuzz.maybe idFuzzer))
        , Fuzz.constant NewGuildRoute
        , Fuzz.constant AiChatRoute
        , Fuzz.map3 GuildRoute idFuzzer channelRouteFuzzer channelsVisibleFuzzer
        , Fuzz.map5
            (\userId otherUserId threadRoute tab channelsVisible ->
                DmRoute
                    { channelId = DmChannelId.fromUserIds userId otherUserId
                    , threadRoute = threadRoute
                    , tab = tab
                    , channelsVisible = channelsVisible
                    }
            )
            idFuzzer
            idFuzzer
            threadRouteFuzzer
            (Fuzz.maybe tabFuzzer)
            channelsVisibleFuzzer
        , Fuzz.map PublicGoMatchRoute secretIdFuzzer
        ]


tabFuzzer : Fuzzer ChannelHeaderTab
tabFuzzer =
    Fuzz.oneOfValues
        [ ChannelHeaderTab_VoiceChat
        , ChannelHeaderTab_Games Nothing
        , ChannelHeaderTab_Games (Just (Id.fromInt 123))
        , ChannelHeaderTab_Draw
        ]


idFuzzer : Fuzzer (Id a)
idFuzzer =
    Fuzz.map Id.fromInt (Fuzz.intRange 0 9999)


secretIdFuzzer : Fuzzer (SecretId a)
secretIdFuzzer =
    Fuzz.map
        (\a -> String.fromList a |> SecretId.fromString)
        (Fuzz.listOfLength
            16
            (Fuzz.oneOf
                (List.map Fuzz.constant (String.toList "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"))
            )
        )


threadRouteFuzzer : Fuzzer ThreadRouteWithFriends
threadRouteFuzzer =
    Fuzz.oneOf
        [ Fuzz.map2 NoThreadWithFriends (Fuzz.maybe idFuzzer) showMemberTabFuzzer
        , Fuzz.map3 ViewThreadWithFriends idFuzzer (Fuzz.maybe idFuzzer) showMemberTabFuzzer
        ]


channelRouteFuzzer : Fuzzer ChannelRoute
channelRouteFuzzer =
    Fuzz.oneOf
        [ Fuzz.map3 ChannelRoute idFuzzer threadRouteFuzzer (Fuzz.maybe tabFuzzer)
        , Fuzz.constant NewChannelRoute
        , Fuzz.constant GuildSettingsRoute
        , Fuzz.map JoinRoute secretIdFuzzer
        ]


channelsVisibleFuzzer : Fuzzer ChannelsVisibleOnMobile
channelsVisibleFuzzer =
    Fuzz.oneOfValues
        [ ChannelsVisibleOnMobile
        , ChannelsHiddenOnMobile
        ]


showMemberTabFuzzer : Fuzzer ShowChannelSettings
showMemberTabFuzzer =
    Fuzz.oneOfValues
        [ ShowChannelSettings
        , HideChannelSettings
        ]
