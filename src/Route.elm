module Route exposing
    ( ChannelRoute(..)
    , Route(..)
    , decode
    , encode
    )

import AppUrl
import Dict
import Effect.Lamdera as Lamdera exposing (SessionId)
import Id exposing (ChannelId, GuildId, Id, InviteLinkId, ThreadRouteWithMaybeMessage(..), UserId)
import SecretId exposing (SecretId)
import Slack
import Url exposing (Url)
import Url.Builder


type Route
    = HomePageRoute
    | AdminRoute { highlightLog : Maybe Int }
    | GuildRoute (Id GuildId) ChannelRoute
    | DmRoute (Id UserId) ThreadRouteWithMaybeMessage
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Slack.OAuthCode, SessionId ))
    | ChessRoute


type ChannelRoute
    = ChannelRoute (Id ChannelId) ThreadRouteWithMaybeMessage
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
                                            (stringToThread threadMessageIndex messageIndex)
                                        )

                                ( Just channelId2, [ "t", threadMessageIndex ] ) ->
                                    GuildRoute
                                        guildId2
                                        (ChannelRoute
                                            channelId2
                                            (stringToThread threadMessageIndex "")
                                        )

                                ( Just channelId2, [ "m", messageIndex ] ) ->
                                    GuildRoute
                                        guildId2
                                        (ChannelRoute channelId2 (NoThreadWithMaybeMessage (Id.fromString messageIndex)))

                                ( Just channelId2, [] ) ->
                                    GuildRoute guildId2 (ChannelRoute channelId2 (NoThreadWithMaybeMessage Nothing))

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
                            DmRoute userId2 (stringToThread threadMessageIndex messageIndex)

                        [ "t", threadMessageIndex ] ->
                            DmRoute userId2 (stringToThread threadMessageIndex "")

                        [ "m", messageIndex ] ->
                            DmRoute userId2 (NoThreadWithMaybeMessage (Id.fromString messageIndex))

                        _ ->
                            DmRoute userId2 (NoThreadWithMaybeMessage Nothing)

                Nothing ->
                    HomePageRoute

        [ "slack-oauth" ] ->
            case ( Dict.get "code" url2.queryParameters, Dict.get "state" url2.queryParameters ) of
                ( Just [ code ], Just [ state ] ) ->
                    SlackOAuthRedirect (Ok ( Slack.OAuthCode code, Lamdera.sessionIdFromString state ))

                _ ->
                    SlackOAuthRedirect (Err ())

        [ "chess" ] ->
            ChessRoute

        _ ->
            HomePageRoute


stringToThread : String -> String -> ThreadRouteWithMaybeMessage
stringToThread text maybeMessageIndex =
    case Id.fromString text of
        Just messageIndex ->
            ViewThreadWithMaybeMessage messageIndex (Id.fromString maybeMessageIndex)

        Nothing ->
            NoThreadWithMaybeMessage (Id.fromString maybeMessageIndex)


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
                                ChannelRoute channelId thread ->
                                    [ "c", Id.toString channelId ]
                                        ++ (case thread of
                                                ViewThreadWithMaybeMessage threadMessageIndex maybeMessageId ->
                                                    [ "t", Id.toString threadMessageIndex ]
                                                        ++ maybeMessageIdToString maybeMessageId

                                                NoThreadWithMaybeMessage maybeMessageId ->
                                                    maybeMessageIdToString maybeMessageId
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

                DmRoute userId thread ->
                    ( [ "d", Id.toString userId ]
                        ++ (case thread of
                                ViewThreadWithMaybeMessage threadMessageIndex maybeMessageId ->
                                    [ "t", Id.toString threadMessageIndex ]
                                        ++ maybeMessageIdToString maybeMessageId

                                NoThreadWithMaybeMessage maybeMessageId ->
                                    maybeMessageIdToString maybeMessageId
                           )
                    , []
                    )

                SlackOAuthRedirect _ ->
                    ( [ "slack-oauth" ]
                    , []
                    )

                ChessRoute ->
                    ( [ "chess" ]
                    , []
                    )
    in
    Url.Builder.absolute path query


maybeMessageIdToString : Maybe (Id a) -> List String
maybeMessageIdToString maybeMessageIndex =
    case maybeMessageIndex of
        Just messageIndex ->
            [ "m", Id.toString messageIndex ]

        Nothing ->
            []
