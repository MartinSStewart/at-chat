module Route exposing
    ( ChannelRoute(..)
    , DiscordChannelRoute(..)
    , DiscordDmRouteData
    , DiscordGuildRouteData
    , Route(..)
    , ShowMembersTab(..)
    , ThreadRouteWithFriends(..)
    , decode
    , encode
    )

import AppUrl
import Dict
import Discord.Id
import Id exposing (ChannelId, ChannelMessageId, GuildId, Id, InviteLinkId, ThreadMessageId, UserId)
import SecretId exposing (SecretId)
import SessionIdHash exposing (SessionIdHash)
import Slack
import UInt64 exposing (UInt64)
import Url exposing (Url)
import Url.Builder


type Route
    = HomePageRoute
    | AdminRoute { highlightLog : Maybe Int }
    | GuildRoute (Id GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Id UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Slack.OAuthCode, SessionIdHash ))
    | TextEditorRoute


type alias DiscordDmRouteData =
    { currentDiscordUserId : Discord.Id.Id Discord.Id.UserId
    , channelId : Discord.Id.Id Discord.Id.PrivateChannelId
    , viewingMessage : Maybe (Id ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Discord.Id.Id Discord.Id.UserId
    , guildId : Discord.Id.Id Discord.Id.GuildId
    , channelRoute : DiscordChannelRoute
    }


type ChannelRoute
    = ChannelRoute (Id ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Id ChannelId)
    | GuildSettingsRoute
    | JoinRoute (SecretId InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Discord.Id.Id Discord.Id.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Discord.Id.Id Discord.Id.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Id ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Id ChannelMessageId) (Maybe (Id ThreadMessageId)) ShowMembersTab


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


showMembersParam : String
showMembersParam =
    "show-members"


decode : Url -> Route
decode url =
    let
        url2 =
            AppUrl.fromUrl url

        showMembers : ShowMembersTab
        showMembers =
            case Dict.get showMembersParam url2.queryParameters of
                Just [ "True" ] ->
                    ShowMembersTab

                _ ->
                    HideMembersTab
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
                                            (stringToThread showMembers threadMessageIndex messageIndex)
                                        )

                                ( Just channelId2, [ "t", threadMessageIndex ] ) ->
                                    GuildRoute
                                        guildId2
                                        (ChannelRoute
                                            channelId2
                                            (stringToThread showMembers threadMessageIndex "")
                                        )

                                ( Just channelId2, [ "m", messageIndex ] ) ->
                                    GuildRoute
                                        guildId2
                                        (ChannelRoute
                                            channelId2
                                            (NoThreadWithFriends (Id.fromString messageIndex) showMembers)
                                        )

                                ( Just channelId2, [] ) ->
                                    GuildRoute
                                        guildId2
                                        (ChannelRoute
                                            channelId2
                                            (NoThreadWithFriends Nothing showMembers)
                                        )

                                ( Just channelId2, [ "edit" ] ) ->
                                    GuildRoute guildId2 (EditChannelRoute channelId2)

                                _ ->
                                    HomePageRoute

                        [ "new" ] ->
                            GuildRoute guildId2 NewChannelRoute

                        [ "settings" ] ->
                            GuildRoute guildId2 GuildSettingsRoute

                        [ "join", inviteLinkId ] ->
                            GuildRoute guildId2 (JoinRoute (SecretId.fromString inviteLinkId))

                        _ ->
                            HomePageRoute

                Nothing ->
                    HomePageRoute

        "dg" :: userId :: guildId :: rest ->
            case ( Discord.Id.fromString userId, Discord.Id.fromString guildId ) of
                ( Just userId2, Just guildId2 ) ->
                    case rest of
                        "c" :: channelId :: rest2 ->
                            case ( Discord.Id.fromString channelId, rest2 ) of
                                ( Just channelId2, [ "t", threadMessageIndex, "m", messageIndex ] ) ->
                                    DiscordGuildRouteData
                                        userId2
                                        guildId2
                                        (DiscordChannel_ChannelRoute
                                            channelId2
                                            (stringToThread showMembers threadMessageIndex messageIndex)
                                        )
                                        |> DiscordGuildRoute

                                ( Just channelId2, [ "t", threadMessageIndex ] ) ->
                                    DiscordGuildRouteData
                                        userId2
                                        guildId2
                                        (DiscordChannel_ChannelRoute
                                            channelId2
                                            (stringToThread showMembers threadMessageIndex "")
                                        )
                                        |> DiscordGuildRoute

                                ( Just channelId2, [ "m", messageIndex ] ) ->
                                    DiscordGuildRouteData
                                        userId2
                                        guildId2
                                        (DiscordChannel_ChannelRoute
                                            channelId2
                                            (NoThreadWithFriends (Id.fromString messageIndex) showMembers)
                                        )
                                        |> DiscordGuildRoute

                                ( Just channelId2, [] ) ->
                                    DiscordGuildRouteData
                                        userId2
                                        guildId2
                                        (DiscordChannel_ChannelRoute
                                            channelId2
                                            (NoThreadWithFriends Nothing showMembers)
                                        )
                                        |> DiscordGuildRoute

                                ( Just channelId2, [ "edit" ] ) ->
                                    DiscordGuildRouteData userId2 guildId2 (DiscordChannel_EditChannelRoute channelId2)
                                        |> DiscordGuildRoute

                                _ ->
                                    HomePageRoute

                        [ "new" ] ->
                            DiscordGuildRouteData userId2 guildId2 DiscordChannel_NewChannelRoute |> DiscordGuildRoute

                        [ "settings" ] ->
                            DiscordGuildRouteData userId2 guildId2 DiscordChannel_GuildSettingsRoute |> DiscordGuildRoute

                        _ ->
                            HomePageRoute

                _ ->
                    HomePageRoute

        "d" :: userId :: rest ->
            case Id.fromString userId of
                Just userId2 ->
                    case rest of
                        [ "t", threadMessageIndex, "m", messageIndex ] ->
                            DmRoute userId2 (stringToThread showMembers threadMessageIndex messageIndex)

                        [ "t", threadMessageIndex ] ->
                            DmRoute userId2 (stringToThread showMembers threadMessageIndex "")

                        [ "m", messageIndex ] ->
                            DmRoute userId2 (NoThreadWithFriends (Id.fromString messageIndex) showMembers)

                        _ ->
                            DmRoute userId2 (NoThreadWithFriends Nothing showMembers)

                Nothing ->
                    HomePageRoute

        "dd" :: userId :: otherUserId :: rest ->
            case ( Discord.Id.fromString userId, Discord.Id.fromString otherUserId ) of
                ( Just userId2, Just otherUserId2 ) ->
                    DiscordDmRoute
                        { currentDiscordUserId = userId2
                        , channelId = otherUserId2
                        , viewingMessage =
                            case rest of
                                [ "m", messageIndex ] ->
                                    Id.fromString messageIndex

                                _ ->
                                    Nothing
                        , showMembersTab = showMembers
                        }

                _ ->
                    HomePageRoute

        [ "slack-oauth" ] ->
            case ( Dict.get "code" url2.queryParameters, Dict.get "state" url2.queryParameters ) of
                ( Just [ code ], Just [ state ] ) ->
                    SlackOAuthRedirect (Ok ( Slack.OAuthCode code, SessionIdHash.fromString state ))

                _ ->
                    SlackOAuthRedirect (Err ())

        [ "text-editor" ] ->
            TextEditorRoute

        _ ->
            HomePageRoute


stringToThread : ShowMembersTab -> String -> String -> ThreadRouteWithFriends
stringToThread showMembers text maybeMessageIndex =
    case Id.fromString text of
        Just messageIndex ->
            ViewThreadWithFriends messageIndex (Id.fromString maybeMessageIndex) showMembers

        Nothing ->
            NoThreadWithFriends (Id.fromString maybeMessageIndex) showMembers


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
                    case maybeChannelId of
                        ChannelRoute channelId thread ->
                            case thread of
                                ViewThreadWithFriends threadMessageIndex maybeMessageId showMembers ->
                                    ( [ "g"
                                      , Id.toString guildId
                                      , "c"
                                      , Id.toString channelId
                                      , "t"
                                      , Id.toString threadMessageIndex
                                      ]
                                        ++ maybeMessageIdToString maybeMessageId
                                    , encodeShowMembers showMembers
                                    )

                                NoThreadWithFriends maybeMessageId showMembers ->
                                    ( [ "g", Id.toString guildId, "c", Id.toString channelId ]
                                        ++ maybeMessageIdToString maybeMessageId
                                    , encodeShowMembers showMembers
                                    )

                        EditChannelRoute channelId ->
                            ( [ "g", Id.toString guildId, "c", Id.toString channelId, "edit" ], [] )

                        NewChannelRoute ->
                            ( [ "g", Id.toString guildId, "new" ], [] )

                        GuildSettingsRoute ->
                            ( [ "g", Id.toString guildId, "invite" ], [] )

                        JoinRoute inviteLinkId ->
                            ( [ "g", Id.toString guildId, "join", SecretId.toString inviteLinkId ], [] )

                DiscordGuildRoute { currentDiscordUserId, guildId, channelRoute } ->
                    case channelRoute of
                        DiscordChannel_ChannelRoute channelId thread ->
                            case thread of
                                ViewThreadWithFriends threadMessageIndex maybeMessageId showMembers ->
                                    ( [ "dg"
                                      , Discord.Id.toString currentDiscordUserId
                                      , Discord.Id.toString guildId
                                      , "c"
                                      , Discord.Id.toString channelId
                                      , "t"
                                      , Id.toString threadMessageIndex
                                      ]
                                        ++ maybeMessageIdToString maybeMessageId
                                    , encodeShowMembers showMembers
                                    )

                                NoThreadWithFriends maybeMessageId showMembers ->
                                    ( [ "dg"
                                      , Discord.Id.toString currentDiscordUserId
                                      , Discord.Id.toString guildId
                                      , "c"
                                      , Discord.Id.toString channelId
                                      ]
                                        ++ maybeMessageIdToString maybeMessageId
                                    , encodeShowMembers showMembers
                                    )

                        DiscordChannel_EditChannelRoute channelId ->
                            ( [ "dg"
                              , Discord.Id.toString currentDiscordUserId
                              , Discord.Id.toString guildId
                              , "c"
                              , Discord.Id.toString channelId
                              , "edit"
                              ]
                            , []
                            )

                        DiscordChannel_NewChannelRoute ->
                            ( [ "dg", Discord.Id.toString currentDiscordUserId, Discord.Id.toString guildId, "new" ]
                            , []
                            )

                        DiscordChannel_GuildSettingsRoute ->
                            ( [ "dg", Discord.Id.toString currentDiscordUserId, Discord.Id.toString guildId, "invite" ]
                            , []
                            )

                DmRoute userId thread ->
                    case thread of
                        ViewThreadWithFriends threadMessageIndex maybeMessageId showMembers ->
                            ( [ "d", Id.toString userId, "t", Id.toString threadMessageIndex ]
                                ++ maybeMessageIdToString maybeMessageId
                            , encodeShowMembers showMembers
                            )

                        NoThreadWithFriends maybeMessageId showMembers ->
                            ( [ "d", Id.toString userId ] ++ maybeMessageIdToString maybeMessageId
                            , encodeShowMembers showMembers
                            )

                DiscordDmRoute { currentDiscordUserId, channelId, viewingMessage, showMembersTab } ->
                    ( [ "dd"
                      , Discord.Id.toString currentDiscordUserId
                      , Discord.Id.toString channelId
                      ]
                        ++ maybeMessageIdToString viewingMessage
                    , encodeShowMembers showMembersTab
                    )

                SlackOAuthRedirect _ ->
                    ( [ "slack-oauth" ]
                    , []
                    )

                TextEditorRoute ->
                    ( [ "text-editor" ], [] )
    in
    Url.Builder.absolute path query


encodeShowMembers : ShowMembersTab -> List Url.Builder.QueryParameter
encodeShowMembers showMembers =
    case showMembers of
        ShowMembersTab ->
            [ Url.Builder.string showMembersParam "True" ]

        HideMembersTab ->
            []


maybeMessageIdToString : Maybe (Id a) -> List String
maybeMessageIdToString maybeMessageIndex =
    case maybeMessageIndex of
        Just messageIndex ->
            [ "m", Id.toString messageIndex ]

        Nothing ->
            []
