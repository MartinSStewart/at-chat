module Route exposing
    ( ChannelRoute(..)
    , Route(..)
    , decode
    , encode
    )

import AppUrl
import Dict
import Id exposing (ChannelId, GuildId, Id, InviteLinkId, UserId)
import SecretId exposing (SecretId)
import Url exposing (Url)
import Url.Builder


type Route
    = HomePageRoute
    | AdminRoute { highlightLog : Maybe Int }
    | GuildRoute (Id GuildId) ChannelRoute
    | DmRoute (Id UserId) (Maybe Int)
    | AiChatRoute


type ChannelRoute
    = ChannelRoute (Id ChannelId) (Maybe Int)
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
                        [ "c", channelId, "m", messageIndex ] ->
                            case Id.fromString channelId of
                                Just channelId2 ->
                                    GuildRoute
                                        guildId2
                                        (ChannelRoute channelId2 (String.toInt messageIndex))

                                Nothing ->
                                    HomePageRoute

                        [ "c", channelId ] ->
                            case Id.fromString channelId of
                                Just channelId2 ->
                                    GuildRoute guildId2 (ChannelRoute channelId2 Nothing)

                                Nothing ->
                                    HomePageRoute

                        [ "c", channelId, "edit" ] ->
                            case Id.fromString channelId of
                                Just channelId2 ->
                                    GuildRoute guildId2 (EditChannelRoute channelId2)

                                Nothing ->
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
                        [ "m", messageIndex ] ->
                            DmRoute userId2 (String.toInt messageIndex)

                        _ ->
                            DmRoute userId2 Nothing

                Nothing ->
                    HomePageRoute

        _ ->
            HomePageRoute


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
                                ChannelRoute channelId maybeMessageIndex ->
                                    [ "c", Id.toString channelId ]
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

                DmRoute userId ->
                    ( [ "d", Id.toString userId ], [] )
    in
    Url.Builder.absolute path query
