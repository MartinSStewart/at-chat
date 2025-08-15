module Route exposing
    ( ChannelRoute(..)
    , Route(..)
    , decode
    , encode
    )

import AppUrl
import Dict
import Id exposing (ChannelId, GuildId, Id, InviteLinkId, ThreadRoute(..), UserId)
import SecretId exposing (SecretId)
import Url exposing (Url)
import Url.Builder


type Route
    = HomePageRoute
    | AdminRoute { highlightLog : Maybe Int }
    | GuildRoute (Id GuildId) ChannelRoute
    | DmRoute (Id UserId) ThreadRoute (Maybe Int)
    | AiChatRoute


type ChannelRoute
    = ChannelRoute (Id ChannelId) ThreadRoute (Maybe Int)
    | NewChannelRoute
    | EditChannelRoute (Id ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (SecretId InviteLinkId)


decode : Url -> Route
decode url =
    let
        url2 =
            AppUrl.fromUrl url
    in
    case url2.path of
        [ "admin" ] ->
            AdminRoute
                { highlightLog =
                    case Dict.get "highlight-log" url2.queryParameters of
                        Just [ a ] ->
                            String.toInt a

                        _ ->
                            Nothing
                }

        [ "ai-chat" ] ->
            AiChatRoute

        "g" :: guildId :: rest ->
            case Id.fromString guildId of
                Just guildId2 ->
                    case rest of
                        "c" :: channelId :: rest2 ->
                            case ( Id.fromString channelId, rest2 ) of
                                ( Just channelId2, [ "t", threadMessageIndex, "m", messageIndex ] ) ->
                                    GuildRoute
                                        guildId2
                                        (ChannelRoute
                                            channelId2
                                            (stringToThread threadMessageIndex)
                                            (String.toInt messageIndex)
                                        )

                                ( Just channelId2, [ "t", threadMessageIndex ] ) ->
                                    GuildRoute
                                        guildId2
                                        (ChannelRoute
                                            channelId2
                                            (stringToThread threadMessageIndex)
                                            Nothing
                                        )

                                ( Just channelId2, [ "m", messageIndex ] ) ->
                                    GuildRoute
                                        guildId2
                                        (ChannelRoute channelId2 NoThread (String.toInt messageIndex))

                                ( Just channelId2, [] ) ->
                                    GuildRoute guildId2 (ChannelRoute channelId2 NoThread Nothing)

                                ( Just channelId2, [ "edit" ] ) ->
                                    GuildRoute guildId2 (EditChannelRoute channelId2)

                                _ ->
                                    HomePageRoute

                        [ "new" ] ->
                            GuildRoute guildId2 NewChannelRoute

                        [ "invite" ] ->
                            GuildRoute guildId2 InviteLinkCreatorRoute

                        [ "join", inviteLinkId ] ->
                            GuildRoute guildId2 (JoinRoute (SecretId.fromString inviteLinkId))

                        _ ->
                            HomePageRoute

                Nothing ->
                    HomePageRoute

        "d" :: userId :: rest ->
            case Id.fromString userId of
                Just userId2 ->
                    case rest of
                        [ "t", threadMessageIndex, "m", messageIndex ] ->
                            DmRoute userId2 (stringToThread threadMessageIndex) (String.toInt messageIndex)

                        [ "m", messageIndex ] ->
                            DmRoute userId2 NoThread (String.toInt messageIndex)

                        _ ->
                            DmRoute userId2 NoThread Nothing

                Nothing ->
                    HomePageRoute

        _ ->
            HomePageRoute


stringToThread : String -> ThreadRoute
stringToThread text =
    case String.toInt text of
        Just messageIndex ->
            ViewThread messageIndex

        Nothing ->
            NoThread


encode : Route -> String
encode route =
    let
        ( path, query ) =
            case route of
                HomePageRoute ->
                    ( [], [] )

                AdminRoute params ->
                    ( [ "admin" ]
                    , case params.highlightLog of
                        Just a ->
                            [ Url.Builder.int "highlight-log" a ]

                        Nothing ->
                            []
                    )

                AiChatRoute ->
                    ( [ "ai-chat" ], [] )

                GuildRoute guildId maybeChannelId ->
                    ( [ "g", Id.toString guildId ]
                        ++ (case maybeChannelId of
                                ChannelRoute channelId thread maybeMessageIndex ->
                                    [ "c", Id.toString channelId ]
                                        ++ (case thread of
                                                ViewThread threadMessageIndex ->
                                                    [ "t", String.fromInt threadMessageIndex ]

                                                NoThread ->
                                                    []
                                           )
                                        ++ (case maybeMessageIndex of
                                                Just messageIndex ->
                                                    [ "m", String.fromInt messageIndex ]

                                                Nothing ->
                                                    []
                                           )

                                EditChannelRoute channelId ->
                                    [ "c", Id.toString channelId, "edit" ]

                                NewChannelRoute ->
                                    [ "new" ]

                                InviteLinkCreatorRoute ->
                                    [ "invite" ]

                                JoinRoute inviteLinkId ->
                                    [ "join", SecretId.toString inviteLinkId ]
                           )
                    , []
                    )

                DmRoute userId thread maybeMessageIndex ->
                    ( [ "d", Id.toString userId ]
                        ++ (case thread of
                                ViewThread threadMessageIndex ->
                                    [ "t", String.fromInt threadMessageIndex ]

                                NoThread ->
                                    []
                           )
                        ++ (case maybeMessageIndex of
                                Just messageIndex ->
                                    [ "m", String.fromInt messageIndex ]

                                Nothing ->
                                    []
                           )
                    , []
                    )
    in
    Url.Builder.absolute path query
