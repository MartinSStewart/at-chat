module Route exposing
    ( ChannelRoute(..)
    , DiscordChannelRoute(..)
    , DiscordDmRouteData
    , DiscordGuildRouteData
    , DmChannelHeaderTab(..)
    , DmRouteData
    , LinkDiscordError(..)
    , Route(..)
    , ShowMembersTab(..)
    , ThreadRouteWithFriends(..)
    , decode
    , encode
    , linkDiscordPath
    , linkDiscordQueryParam
    , requiresLogin
    , sameChannelHeaderTab
    , toChannelHeaderTab
    , toGuildOrDmId
    )

import AppUrl
import Codec
import Dict
import Discord
import DmChannel exposing (DmChannelId)
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, InviteLinkId, ThreadMessageId, ThreadRoute(..), UserId)
import Pagination
import SecretId exposing (SecretId)
import SessionIdHash exposing (SessionIdHash)
import Slack
import Url exposing (Url)
import Url.Builder
import User


type Route
    = HomePageRoute
    | AdminRoute { highlightLog : Maybe (Id Pagination.ItemId) }
    | GuildRoute (Id GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Slack.OAuthCode, SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Discord.UserAuth)


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type alias DiscordDmRouteData =
    { currentDiscordUserId : Discord.Id Discord.UserId
    , channelId : Discord.Id Discord.PrivateChannelId
    , viewingMessage : Maybe (Id ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type alias DmRouteData =
    { channelId : DmChannelId, threadRoute : ThreadRouteWithFriends, tab : Maybe DmChannelHeaderTab }


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Id ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Discord.Id Discord.UserId
    , guildId : Discord.Id Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type ChannelRoute
    = ChannelRoute (Id ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Id ChannelId)
    | GuildSettingsRoute
    | JoinRoute (SecretId InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Discord.Id Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Discord.Id Discord.ChannelId)
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
                            String.toInt a |> Maybe.map Id.fromInt

                        _ ->
                            Nothing
                }

        [ "ai-chat" ] ->
            AiChatRoute

        "g" :: guildId :: rest ->
            let
                guildTab : Maybe DmChannelHeaderTab
                guildTab =
                    case Dict.get tabParam url2.queryParameters of
                        Just [ "description" ] ->
                            Just DmChannelHeaderTab_ChannelDescription

                        _ ->
                            Nothing
            in
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
                                            Nothing
                                        )

                                ( Just channelId2, [ "t", threadMessageIndex ] ) ->
                                    GuildRoute
                                        guildId2
                                        (ChannelRoute
                                            channelId2
                                            (stringToThread showMembers threadMessageIndex "")
                                            Nothing
                                        )

                                ( Just channelId2, [ "m", messageIndex ] ) ->
                                    GuildRoute
                                        guildId2
                                        (ChannelRoute
                                            channelId2
                                            (NoThreadWithFriends (Id.fromString messageIndex) showMembers)
                                            guildTab
                                        )

                                ( Just channelId2, [] ) ->
                                    GuildRoute
                                        guildId2
                                        (ChannelRoute
                                            channelId2
                                            (NoThreadWithFriends Nothing showMembers)
                                            guildTab
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
            case ( Discord.idFromString userId, Discord.idFromString guildId ) of
                ( Just userId2, Just guildId2 ) ->
                    case rest of
                        "c" :: channelId :: rest2 ->
                            case ( Discord.idFromString channelId, rest2 ) of
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

        "d" :: channelId :: rest ->
            case DmChannel.channelIdFromString channelId of
                Ok channelId2 ->
                    let
                        goMatchId : Maybe (Id ChannelMessageId)
                        goMatchId =
                            case Dict.get goMatchParam url2.queryParameters of
                                Just [ goMatchId2 ] ->
                                    Id.fromString goMatchId2

                                _ ->
                                    Nothing

                        tab : Maybe DmChannelHeaderTab
                        tab =
                            case Dict.get tabParam url2.queryParameters of
                                Just [ tab2 ] ->
                                    case tab2 of
                                        "go" ->
                                            DmChannelHeaderTab_Go goMatchId |> Just

                                        "call" ->
                                            DmChannelHeaderTab_VoiceChat |> Just

                                        _ ->
                                            Nothing

                                _ ->
                                    Nothing
                    in
                    (case rest of
                        [ "t", threadMessageIndex, "m", messageIndex ] ->
                            { channelId = channelId2
                            , threadRoute = stringToThread showMembers threadMessageIndex messageIndex
                            , tab = tab
                            }

                        [ "t", threadMessageIndex ] ->
                            { channelId = channelId2
                            , threadRoute = stringToThread showMembers threadMessageIndex ""
                            , tab = tab
                            }

                        [ "m", messageIndex ] ->
                            { channelId = channelId2
                            , threadRoute = NoThreadWithFriends (Id.fromString messageIndex) showMembers
                            , tab = tab
                            }

                        _ ->
                            { channelId = channelId2
                            , threadRoute = NoThreadWithFriends Nothing showMembers
                            , tab = tab
                            }
                    )
                        |> DmRoute

                Err () ->
                    HomePageRoute

        "dd" :: userId :: otherUserId :: rest ->
            case ( Discord.idFromString userId, Discord.idFromString otherUserId ) of
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

        [ "link-discord" ] ->
            case Dict.get linkDiscordQueryParam url2.queryParameters of
                Just [ data ] ->
                    Codec.decodeString User.linkDiscordDataCodec data
                        |> Result.mapError (\_ -> LinkDiscordInvalidData)
                        |> LinkDiscord

                _ ->
                    LinkDiscord (Err LinkDiscordExpired)

        _ ->
            HomePageRoute


toChannelHeaderTab : Route -> Maybe DmChannelHeaderTab
toChannelHeaderTab route =
    case route of
        DmRoute dmRoute ->
            dmRoute.tab

        HomePageRoute ->
            Nothing

        AdminRoute _ ->
            Nothing

        GuildRoute _ channelRoute ->
            case channelRoute of
                ChannelRoute _ _ maybeTab ->
                    maybeTab

                NewChannelRoute ->
                    Nothing

                EditChannelRoute id ->
                    Nothing

                GuildSettingsRoute ->
                    Nothing

                JoinRoute secretId ->
                    Nothing

        DiscordGuildRoute _ ->
            Nothing

        DiscordDmRoute _ ->
            Nothing

        AiChatRoute ->
            Nothing

        SlackOAuthRedirect _ ->
            Nothing

        TextEditorRoute ->
            Nothing

        LinkDiscord _ ->
            Nothing


sameChannelHeaderTab : DmChannelHeaderTab -> DmChannelHeaderTab -> Bool
sameChannelHeaderTab tabA tabB =
    case tabA of
        DmChannelHeaderTab_VoiceChat ->
            case tabB of
                DmChannelHeaderTab_VoiceChat ->
                    True

                _ ->
                    False

        DmChannelHeaderTab_Go maybeId ->
            case tabB of
                DmChannelHeaderTab_Go _ ->
                    True

                _ ->
                    False

        DmChannelHeaderTab_ChannelDescription ->
            case tabB of
                DmChannelHeaderTab_ChannelDescription ->
                    True

                _ ->
                    False


goMatchParam : String
goMatchParam =
    "match"


tabParam : String
tabParam =
    "tab"


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
                            [ Url.Builder.int "highlight-log" (Id.toInt a) ]

                        Nothing ->
                            []
                    )

                AiChatRoute ->
                    ( [ "ai-chat" ], [] )

                GuildRoute guildId maybeChannelId ->
                    case maybeChannelId of
                        ChannelRoute channelId thread tab ->
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
                                    , encodeShowMembers showMembers ++ encodeTab tab
                                    )

                        EditChannelRoute channelId ->
                            ( [ "g", Id.toString guildId, "c", Id.toString channelId, "edit" ], [] )

                        NewChannelRoute ->
                            ( [ "g", Id.toString guildId, "new" ], [] )

                        GuildSettingsRoute ->
                            ( [ "g", Id.toString guildId, "settings" ], [] )

                        JoinRoute inviteLinkId ->
                            ( [ "g", Id.toString guildId, "join", SecretId.toString inviteLinkId ], [] )

                DiscordGuildRoute { currentDiscordUserId, guildId, channelRoute } ->
                    case channelRoute of
                        DiscordChannel_ChannelRoute channelId thread ->
                            case thread of
                                ViewThreadWithFriends threadMessageIndex maybeMessageId showMembers ->
                                    ( [ "dg"
                                      , Discord.idToString currentDiscordUserId
                                      , Discord.idToString guildId
                                      , "c"
                                      , Discord.idToString channelId
                                      , "t"
                                      , Id.toString threadMessageIndex
                                      ]
                                        ++ maybeMessageIdToString maybeMessageId
                                    , encodeShowMembers showMembers
                                    )

                                NoThreadWithFriends maybeMessageId showMembers ->
                                    ( [ "dg"
                                      , Discord.idToString currentDiscordUserId
                                      , Discord.idToString guildId
                                      , "c"
                                      , Discord.idToString channelId
                                      ]
                                        ++ maybeMessageIdToString maybeMessageId
                                    , encodeShowMembers showMembers
                                    )

                        DiscordChannel_EditChannelRoute channelId ->
                            ( [ "dg"
                              , Discord.idToString currentDiscordUserId
                              , Discord.idToString guildId
                              , "c"
                              , Discord.idToString channelId
                              , "edit"
                              ]
                            , []
                            )

                        DiscordChannel_NewChannelRoute ->
                            ( [ "dg", Discord.idToString currentDiscordUserId, Discord.idToString guildId, "new" ]
                            , []
                            )

                        DiscordChannel_GuildSettingsRoute ->
                            ( [ "dg", Discord.idToString currentDiscordUserId, Discord.idToString guildId, "settings" ]
                            , []
                            )

                DmRoute { channelId, threadRoute, tab } ->
                    case threadRoute of
                        ViewThreadWithFriends threadMessageIndex maybeMessageId showMembers ->
                            ( [ "d", DmChannel.channelIdToString channelId, "t", Id.toString threadMessageIndex ]
                                ++ maybeMessageIdToString maybeMessageId
                            , encodeShowMembers showMembers ++ encodeTab tab
                            )

                        NoThreadWithFriends maybeMessageId showMembers ->
                            ( [ "d", DmChannel.channelIdToString channelId ] ++ maybeMessageIdToString maybeMessageId
                            , encodeShowMembers showMembers ++ encodeTab tab
                            )

                DiscordDmRoute { currentDiscordUserId, channelId, viewingMessage, showMembersTab } ->
                    ( [ "dd"
                      , Discord.idToString currentDiscordUserId
                      , Discord.idToString channelId
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

                LinkDiscord _ ->
                    ( [ linkDiscordPath ], [] )
    in
    Url.Builder.absolute path query


linkDiscordPath : String
linkDiscordPath =
    "link-discord"


linkDiscordQueryParam : String
linkDiscordQueryParam =
    "data"


encodeShowMembers : ShowMembersTab -> List Url.Builder.QueryParameter
encodeShowMembers showMembers =
    case showMembers of
        ShowMembersTab ->
            [ Url.Builder.string showMembersParam "True" ]

        HideMembersTab ->
            []


encodeTab : Maybe DmChannelHeaderTab -> List Url.Builder.QueryParameter
encodeTab tab =
    case tab of
        Just DmChannelHeaderTab_VoiceChat ->
            [ Url.Builder.string tabParam "call" ]

        Just (DmChannelHeaderTab_Go maybeMatchId) ->
            Url.Builder.string tabParam "go"
                :: (case maybeMatchId of
                        Just matchId ->
                            [ Url.Builder.int goMatchParam (Id.toInt matchId) ]

                        Nothing ->
                            []
                   )

        Just DmChannelHeaderTab_ChannelDescription ->
            [ Url.Builder.string tabParam "description" ]

        Nothing ->
            []


maybeMessageIdToString : Maybe (Id a) -> List String
maybeMessageIdToString maybeMessageIndex =
    case maybeMessageIndex of
        Just messageIndex ->
            [ "m", Id.toString messageIndex ]

        Nothing ->
            []


requiresLogin : Route -> Bool
requiresLogin route =
    case route of
        HomePageRoute ->
            False

        AdminRoute _ ->
            True

        AiChatRoute ->
            False

        GuildRoute _ _ ->
            True

        DiscordGuildRoute _ ->
            True

        DmRoute _ ->
            True

        SlackOAuthRedirect _ ->
            False

        TextEditorRoute ->
            False

        DiscordDmRoute _ ->
            True

        LinkDiscord _ ->
            False


toGuildOrDmId : Id UserId -> Route -> Maybe ( AnyGuildOrDmId, ThreadRoute )
toGuildOrDmId userId route =
    case route of
        GuildRoute guildId (ChannelRoute channelId threadRoute _) ->
            ( GuildOrDmId_Guild guildId channelId |> GuildOrDmId
            , case threadRoute of
                ViewThreadWithFriends threadMessageId _ _ ->
                    ViewThread threadMessageId

                NoThreadWithFriends _ _ ->
                    NoThread
            )
                |> Just

        DmRoute { channelId, threadRoute } ->
            case DmChannel.otherUserId userId channelId of
                Just otherUserId ->
                    ( GuildOrDmId_Dm otherUserId |> GuildOrDmId
                    , case threadRoute of
                        ViewThreadWithFriends threadMessageId _ _ ->
                            ViewThread threadMessageId

                        NoThreadWithFriends _ _ ->
                            NoThread
                    )
                        |> Just

                Nothing ->
                    Nothing

        DiscordGuildRoute data ->
            case data.channelRoute of
                DiscordChannel_ChannelRoute channelId threadRoute ->
                    ( DiscordGuildOrDmId_Guild data.currentDiscordUserId data.guildId channelId |> DiscordGuildOrDmId
                    , case threadRoute of
                        ViewThreadWithFriends threadMessageId _ _ ->
                            ViewThread threadMessageId

                        NoThreadWithFriends _ _ ->
                            NoThread
                    )
                        |> Just

                _ ->
                    Nothing

        DiscordDmRoute data ->
            ( DiscordGuildOrDmId_Dm { currentUserId = data.currentDiscordUserId, channelId = data.channelId }
                |> DiscordGuildOrDmId
            , NoThread
            )
                |> Just

        _ ->
            Nothing
