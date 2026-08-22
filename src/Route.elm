module Route exposing
    ( ChannelRoute(..)
    , ChannelSidebarMode(..)
    , ChannelsVisibleOnMobile(..)
    , DiscordChannelRoute(..)
    , DiscordDmRouteData
    , DiscordGuildRouteData
    , DmRouteData
    , LinkDiscordError(..)
    , Route(..)
    , ShowChannelSettings(..)
    , ThreadRouteWithFriends(..)
    , decode
    , encode
    , linkDiscordPath
    , linkDiscordQueryParam
    , requiresLogin
    , routeChangeCountsAsMessageView
    , sameChannelHeaderTab
    , sameThread
    , setChannelHeaderTab
    , setChannelsVisible
    , setShowMembers
    , toChannelHeaderTab
    , toGuildOrDmId
    , toShowMembersTab
    , toShowMembersTabVisible
    )

import AppUrl exposing (AppUrl)
import Codec
import Dict
import Discord
import DmChannelId exposing (DmChannelId)
import Effect.Time as Time
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), GamePublicId, GuildId, GuildOrDmId(..), Id, InviteLinkId, ThreadMessageId, ThreadRoute(..), UserId)
import Pagination
import SecretId exposing (SecretId)
import SessionIdHash exposing (SessionIdHash)
import Slack
import Url exposing (Url)
import Url.Builder
import User
import UserSession exposing (ChannelHeaderTab(..))


type Route
    = HomePageRoute
    | AdminRoute { highlightLog : Maybe (Id Pagination.ItemId) }
    | NewGuildRoute
    | GuildRoute (Id GuildId) ChannelRoute ChannelsVisibleOnMobile
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Slack.OAuthCode, SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Discord.UserAuth)
    | PublicGoMatchRoute (SecretId GamePublicId)


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type alias DiscordDmRouteData =
    { currentDiscordUserId : Discord.Id Discord.UserId
    , channelId : Discord.Id Discord.PrivateChannelId
    , viewingMessage : Maybe (Id ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DmRouteData =
    { channelId : DmChannelId, threadRoute : ThreadRouteWithFriends, tab : Maybe ChannelHeaderTab, channelsVisible : ChannelsVisibleOnMobile }


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Discord.Id Discord.UserId
    , guildId : Discord.Id Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    }


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type ChannelRoute
    = ChannelRoute (Id ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (SecretId InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Discord.Id Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Id ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Id ChannelMessageId) (Maybe (Id ThreadMessageId)) ShowChannelSettings


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


showMembersParam : String
showMembersParam =
    "show-members"


guildChannelsVisibleParam : String
guildChannelsVisibleParam =
    "show-channels"


decode : Url -> Route
decode url =
    let
        url2 =
            AppUrl.fromUrl url

        showMembers : ShowChannelSettings
        showMembers =
            case Dict.get showMembersParam url2.queryParameters of
                Just [ "True" ] ->
                    ShowChannelSettings

                _ ->
                    HideChannelSettings

        channelsVisible : ChannelsVisibleOnMobile
        channelsVisible =
            case Dict.get guildChannelsVisibleParam url2.queryParameters of
                Just [ "True" ] ->
                    ChannelsVisibleOnMobile

                _ ->
                    ChannelsHiddenOnMobile
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

        [ "new-guild" ] ->
            NewGuildRoute

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
                                            (decodeChannelHeaderTab url2)
                                        )
                                        channelsVisible

                                ( Just channelId2, [ "t", threadMessageIndex ] ) ->
                                    GuildRoute
                                        guildId2
                                        (ChannelRoute
                                            channelId2
                                            (stringToThread showMembers threadMessageIndex "")
                                            (decodeChannelHeaderTab url2)
                                        )
                                        channelsVisible

                                ( Just channelId2, [ "m", messageIndex ] ) ->
                                    GuildRoute
                                        guildId2
                                        (ChannelRoute
                                            channelId2
                                            (NoThreadWithFriends (Id.fromString messageIndex) showMembers)
                                            (decodeChannelHeaderTab url2)
                                        )
                                        channelsVisible

                                ( Just channelId2, [] ) ->
                                    GuildRoute
                                        guildId2
                                        (ChannelRoute
                                            channelId2
                                            (NoThreadWithFriends Nothing showMembers)
                                            (decodeChannelHeaderTab url2)
                                        )
                                        channelsVisible

                                _ ->
                                    HomePageRoute

                        [ "new" ] ->
                            GuildRoute guildId2 NewChannelRoute channelsVisible

                        [ "settings" ] ->
                            GuildRoute guildId2 GuildSettingsRoute channelsVisible

                        [ "join", inviteLinkId ] ->
                            GuildRoute guildId2 (JoinRoute (SecretId.fromString inviteLinkId)) channelsVisible

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
                                            (decodeChannelHeaderTab url2)
                                        )
                                        channelsVisible
                                        |> DiscordGuildRoute

                                ( Just channelId2, [ "t", threadMessageIndex ] ) ->
                                    DiscordGuildRouteData
                                        userId2
                                        guildId2
                                        (DiscordChannel_ChannelRoute
                                            channelId2
                                            (stringToThread showMembers threadMessageIndex "")
                                            (decodeChannelHeaderTab url2)
                                        )
                                        channelsVisible
                                        |> DiscordGuildRoute

                                ( Just channelId2, [ "m", messageIndex ] ) ->
                                    DiscordGuildRouteData
                                        userId2
                                        guildId2
                                        (DiscordChannel_ChannelRoute
                                            channelId2
                                            (NoThreadWithFriends (Id.fromString messageIndex) showMembers)
                                            (decodeChannelHeaderTab url2)
                                        )
                                        channelsVisible
                                        |> DiscordGuildRoute

                                ( Just channelId2, [] ) ->
                                    DiscordGuildRouteData
                                        userId2
                                        guildId2
                                        (DiscordChannel_ChannelRoute
                                            channelId2
                                            (NoThreadWithFriends Nothing showMembers)
                                            (decodeChannelHeaderTab url2)
                                        )
                                        channelsVisible
                                        |> DiscordGuildRoute

                                _ ->
                                    HomePageRoute

                        [ "new" ] ->
                            DiscordGuildRouteData userId2 guildId2 DiscordChannel_NewChannelRoute channelsVisible
                                |> DiscordGuildRoute

                        [ "settings" ] ->
                            DiscordGuildRouteData userId2 guildId2 DiscordChannel_GuildSettingsRoute channelsVisible
                                |> DiscordGuildRoute

                        _ ->
                            HomePageRoute

                _ ->
                    HomePageRoute

        "d" :: channelId :: rest ->
            case DmChannelId.fromString channelId of
                Ok channelId2 ->
                    (case rest of
                        [ "t", threadMessageIndex, "m", messageIndex ] ->
                            { channelId = channelId2
                            , threadRoute = stringToThread showMembers threadMessageIndex messageIndex
                            , tab = decodeChannelHeaderTab url2
                            , channelsVisible = channelsVisible
                            }

                        [ "t", threadMessageIndex ] ->
                            { channelId = channelId2
                            , threadRoute = stringToThread showMembers threadMessageIndex ""
                            , tab = decodeChannelHeaderTab url2
                            , channelsVisible = channelsVisible
                            }

                        [ "m", messageIndex ] ->
                            { channelId = channelId2
                            , threadRoute = NoThreadWithFriends (Id.fromString messageIndex) showMembers
                            , tab = decodeChannelHeaderTab url2
                            , channelsVisible = channelsVisible
                            }

                        _ ->
                            { channelId = channelId2
                            , threadRoute = NoThreadWithFriends Nothing showMembers
                            , tab = decodeChannelHeaderTab url2
                            , channelsVisible = channelsVisible
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
                        , tab = decodeChannelHeaderTab url2
                        , channelsVisible = channelsVisible
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

        [ "go-match", goMatchPublicId ] ->
            PublicGoMatchRoute (SecretId.fromString goMatchPublicId)

        _ ->
            HomePageRoute


decodeChannelHeaderTab : AppUrl -> Maybe ChannelHeaderTab
decodeChannelHeaderTab url2 =
    let
        goMatchId : Maybe (Id ChannelMessageId)
        goMatchId =
            case Dict.get goMatchParam url2.queryParameters of
                Just [ goMatchId2 ] ->
                    Id.fromString goMatchId2

                _ ->
                    Nothing
    in
    case Dict.get tabParam url2.queryParameters of
        Just [ tab2 ] ->
            case tab2 of
                "description" ->
                    ChannelHeaderTab_ChannelDescription |> Just

                "game" ->
                    ChannelHeaderTab_Games goMatchId |> Just

                "call" ->
                    ChannelHeaderTab_VoiceChat |> Just

                "draw" ->
                    ChannelHeaderTab_Draw |> Just

                _ ->
                    Nothing

        _ ->
            Nothing


toChannelHeaderTab : Route -> Maybe ChannelHeaderTab
toChannelHeaderTab route =
    case route of
        DmRoute dmRoute ->
            dmRoute.tab

        HomePageRoute ->
            Nothing

        AdminRoute _ ->
            Nothing

        NewGuildRoute ->
            Nothing

        GuildRoute _ channelRoute _ ->
            case channelRoute of
                ChannelRoute _ _ maybeTab ->
                    maybeTab

                NewChannelRoute ->
                    Nothing

                GuildSettingsRoute ->
                    Nothing

                JoinRoute _ ->
                    Nothing

        DiscordGuildRoute routeData ->
            case routeData.channelRoute of
                DiscordChannel_ChannelRoute _ _ maybeTab ->
                    maybeTab

                DiscordChannel_NewChannelRoute ->
                    Nothing

                DiscordChannel_GuildSettingsRoute ->
                    Nothing

        DiscordDmRoute routeData ->
            routeData.tab

        AiChatRoute ->
            Nothing

        SlackOAuthRedirect _ ->
            Nothing

        TextEditorRoute ->
            Nothing

        LinkDiscord _ ->
            Nothing

        PublicGoMatchRoute _ ->
            Nothing


type ChannelSidebarMode
    = ChannelSidebarNotDragging { offset : Float }
    | ChannelSidebarDragging { offset : Float, previousOffset : Float, time : Time.Posix }


toShowMembersTabVisible : { a | sidebarMode : ChannelSidebarMode } -> Route -> ( ShowChannelSettings, Bool )
toShowMembersTabVisible { sidebarMode } route =
    let
        helper : ShowChannelSettings -> ShowChannelSettings
        helper showChannelSettings =
            case sidebarMode of
                ChannelSidebarNotDragging { offset } ->
                    case showChannelSettings of
                        ShowChannelSettings ->
                            ShowChannelSettings

                        HideChannelSettings ->
                            if offset < 1 then
                                ShowChannelSettings

                            else
                                HideChannelSettings

                ChannelSidebarDragging { offset } ->
                    case showChannelSettings of
                        ShowChannelSettings ->
                            ShowChannelSettings

                        HideChannelSettings ->
                            if offset < 1 then
                                ShowChannelSettings

                            else
                                HideChannelSettings
    in
    case route of
        DmRoute dmRoute ->
            threadRouteToShowMembersTab dmRoute.threadRoute |> Tuple.mapFirst helper

        HomePageRoute ->
            ( HideChannelSettings, False )

        AdminRoute _ ->
            ( HideChannelSettings, False )

        NewGuildRoute ->
            ( HideChannelSettings, False )

        GuildRoute _ channelRoute _ ->
            case channelRoute of
                ChannelRoute _ threadRoute _ ->
                    threadRouteToShowMembersTab threadRoute |> Tuple.mapFirst helper

                NewChannelRoute ->
                    ( HideChannelSettings, False )

                GuildSettingsRoute ->
                    ( HideChannelSettings, False )

                JoinRoute _ ->
                    ( HideChannelSettings, False )

        DiscordGuildRoute routeData ->
            case routeData.channelRoute of
                DiscordChannel_ChannelRoute _ threadRoute _ ->
                    threadRouteToShowMembersTab threadRoute |> Tuple.mapFirst helper

                DiscordChannel_NewChannelRoute ->
                    ( HideChannelSettings, False )

                DiscordChannel_GuildSettingsRoute ->
                    ( HideChannelSettings, False )

        DiscordDmRoute routeData ->
            ( routeData.showMembersTab, False )

        AiChatRoute ->
            ( HideChannelSettings, False )

        SlackOAuthRedirect _ ->
            ( HideChannelSettings, False )

        TextEditorRoute ->
            ( HideChannelSettings, False )

        LinkDiscord _ ->
            ( HideChannelSettings, False )

        PublicGoMatchRoute _ ->
            ( HideChannelSettings, False )


{-| Whether the member column is open. Routes that have no member column to
open are treated as having it closed.
-}
toShowMembersTab : Route -> ( ShowChannelSettings, Bool )
toShowMembersTab route =
    case route of
        DmRoute dmRoute ->
            threadRouteToShowMembersTab dmRoute.threadRoute

        HomePageRoute ->
            ( HideChannelSettings, False )

        AdminRoute _ ->
            ( HideChannelSettings, False )

        NewGuildRoute ->
            ( HideChannelSettings, False )

        GuildRoute _ channelRoute _ ->
            case channelRoute of
                ChannelRoute _ threadRoute _ ->
                    threadRouteToShowMembersTab threadRoute

                NewChannelRoute ->
                    ( HideChannelSettings, False )

                GuildSettingsRoute ->
                    ( HideChannelSettings, False )

                JoinRoute _ ->
                    ( HideChannelSettings, False )

        DiscordGuildRoute routeData ->
            case routeData.channelRoute of
                DiscordChannel_ChannelRoute _ threadRoute _ ->
                    threadRouteToShowMembersTab threadRoute

                DiscordChannel_NewChannelRoute ->
                    ( HideChannelSettings, False )

                DiscordChannel_GuildSettingsRoute ->
                    ( HideChannelSettings, False )

        DiscordDmRoute routeData ->
            ( routeData.showMembersTab, False )

        AiChatRoute ->
            ( HideChannelSettings, False )

        SlackOAuthRedirect _ ->
            ( HideChannelSettings, False )

        TextEditorRoute ->
            ( HideChannelSettings, False )

        LinkDiscord _ ->
            ( HideChannelSettings, False )

        PublicGoMatchRoute _ ->
            ( HideChannelSettings, False )


threadRouteToShowMembersTab : ThreadRouteWithFriends -> ( ShowChannelSettings, Bool )
threadRouteToShowMembersTab threadRoute =
    case threadRoute of
        ViewThreadWithFriends _ _ showMembers ->
            ( showMembers, True )

        NoThreadWithFriends _ showMembers ->
            ( showMembers, False )


{-| Replaces the channel header tab for routes that can have one, leaves other routes unchanged.
-}
setChannelHeaderTab : Maybe ChannelHeaderTab -> Route -> Route
setChannelHeaderTab tab route =
    case route of
        DmRoute dmRoute ->
            DmRoute { dmRoute | tab = tab }

        GuildRoute guildId (ChannelRoute channelId threadRoute _) channelsVisible ->
            GuildRoute guildId (ChannelRoute channelId threadRoute tab) channelsVisible

        DiscordGuildRoute routeData ->
            case routeData.channelRoute of
                DiscordChannel_ChannelRoute channelId threadRoute _ ->
                    DiscordGuildRoute
                        { routeData | channelRoute = DiscordChannel_ChannelRoute channelId threadRoute tab }

                _ ->
                    route

        DiscordDmRoute routeData ->
            DiscordDmRoute { routeData | tab = tab }

        _ ->
            route


setShowMembers : ShowChannelSettings -> Route -> Route
setShowMembers showMembers route =
    case route of
        GuildRoute guildId (ChannelRoute channelId threadRoute tab) channelsVisible ->
            GuildRoute
                guildId
                (ChannelRoute channelId (threadRouteWithShowMembers showMembers threadRoute) tab)
                channelsVisible

        DiscordGuildRoute ({ channelRoute } as routeData) ->
            case channelRoute of
                DiscordChannel_ChannelRoute channelId threadRoute tab ->
                    DiscordGuildRoute
                        { routeData
                            | channelRoute =
                                DiscordChannel_ChannelRoute
                                    channelId
                                    (threadRouteWithShowMembers showMembers threadRoute)
                                    tab
                        }

                _ ->
                    route

        DmRoute routeData ->
            DmRoute { routeData | threadRoute = threadRouteWithShowMembers showMembers routeData.threadRoute }

        DiscordDmRoute routeData ->
            DiscordDmRoute { routeData | showMembersTab = showMembers }

        _ ->
            route


threadRouteWithShowMembers : ShowChannelSettings -> ThreadRouteWithFriends -> ThreadRouteWithFriends
threadRouteWithShowMembers showMembers threadRoute =
    case threadRoute of
        NoThreadWithFriends a _ ->
            NoThreadWithFriends a showMembers

        ViewThreadWithFriends threadId a _ ->
            ViewThreadWithFriends threadId a showMembers


setChannelsVisible : ChannelsVisibleOnMobile -> Route -> Route
setChannelsVisible channelsVisible route =
    case route of
        GuildRoute guildId channelRoute _ ->
            GuildRoute guildId channelRoute channelsVisible

        DiscordGuildRoute routeData ->
            DiscordGuildRoute { routeData | channelsVisible = channelsVisible }

        HomePageRoute ->
            route

        AdminRoute _ ->
            route

        NewGuildRoute ->
            route

        DmRoute dmRouteData ->
            DmRoute { dmRouteData | channelsVisible = channelsVisible }

        DiscordDmRoute routeData ->
            DiscordDmRoute { routeData | channelsVisible = channelsVisible }

        AiChatRoute ->
            route

        SlackOAuthRedirect _ ->
            route

        TextEditorRoute ->
            route

        LinkDiscord _ ->
            route

        PublicGoMatchRoute _ ->
            route


sameChannelHeaderTab : ChannelHeaderTab -> ChannelHeaderTab -> Bool
sameChannelHeaderTab tabA tabB =
    case tabA of
        ChannelHeaderTab_VoiceChat ->
            tabB == ChannelHeaderTab_VoiceChat

        ChannelHeaderTab_Games _ ->
            case tabB of
                ChannelHeaderTab_Games _ ->
                    True

                _ ->
                    False

        ChannelHeaderTab_ChannelDescription ->
            tabB == ChannelHeaderTab_ChannelDescription

        ChannelHeaderTab_Draw ->
            tabB == ChannelHeaderTab_Draw


goMatchParam : String
goMatchParam =
    "match"


tabParam : String
tabParam =
    "tab"


stringToThread : ShowChannelSettings -> String -> String -> ThreadRouteWithFriends
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

                NewGuildRoute ->
                    ( [ "new-guild" ], [] )

                AiChatRoute ->
                    ( [ "ai-chat" ], [] )

                GuildRoute guildId maybeChannelId channelsVisible ->
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
                                        ++ encodeChannelHeaderTab tab
                                        ++ encodeChannelsVisible channelsVisible
                                    )

                                NoThreadWithFriends maybeMessageId showMembers ->
                                    ( [ "g", Id.toString guildId, "c", Id.toString channelId ]
                                        ++ maybeMessageIdToString maybeMessageId
                                    , encodeShowMembers showMembers
                                        ++ encodeChannelHeaderTab tab
                                        ++ encodeChannelsVisible channelsVisible
                                    )

                        NewChannelRoute ->
                            ( [ "g", Id.toString guildId, "new" ], encodeChannelsVisible channelsVisible )

                        GuildSettingsRoute ->
                            ( [ "g", Id.toString guildId, "settings" ], encodeChannelsVisible channelsVisible )

                        JoinRoute inviteLinkId ->
                            ( [ "g", Id.toString guildId, "join", SecretId.toString inviteLinkId ]
                            , encodeChannelsVisible channelsVisible
                            )

                DiscordGuildRoute { currentDiscordUserId, guildId, channelRoute, channelsVisible } ->
                    case channelRoute of
                        DiscordChannel_ChannelRoute channelId thread tab ->
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
                                        ++ encodeChannelHeaderTab tab
                                        ++ encodeChannelsVisible channelsVisible
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
                                        ++ encodeChannelHeaderTab tab
                                        ++ encodeChannelsVisible channelsVisible
                                    )

                        DiscordChannel_NewChannelRoute ->
                            ( [ "dg", Discord.idToString currentDiscordUserId, Discord.idToString guildId, "new" ]
                            , encodeChannelsVisible channelsVisible
                            )

                        DiscordChannel_GuildSettingsRoute ->
                            ( [ "dg", Discord.idToString currentDiscordUserId, Discord.idToString guildId, "settings" ]
                            , encodeChannelsVisible channelsVisible
                            )

                DmRoute { channelId, threadRoute, tab, channelsVisible } ->
                    case threadRoute of
                        ViewThreadWithFriends threadMessageIndex maybeMessageId showMembers ->
                            ( [ "d", DmChannelId.toString channelId, "t", Id.toString threadMessageIndex ]
                                ++ maybeMessageIdToString maybeMessageId
                            , encodeShowMembers showMembers ++ encodeChannelHeaderTab tab ++ encodeChannelsVisible channelsVisible
                            )

                        NoThreadWithFriends maybeMessageId showMembers ->
                            ( [ "d", DmChannelId.toString channelId ] ++ maybeMessageIdToString maybeMessageId
                            , encodeShowMembers showMembers ++ encodeChannelHeaderTab tab ++ encodeChannelsVisible channelsVisible
                            )

                DiscordDmRoute { currentDiscordUserId, channelId, viewingMessage, showMembersTab, tab, channelsVisible } ->
                    ( [ "dd"
                      , Discord.idToString currentDiscordUserId
                      , Discord.idToString channelId
                      ]
                        ++ maybeMessageIdToString viewingMessage
                    , encodeShowMembers showMembersTab ++ encodeChannelHeaderTab tab ++ encodeChannelsVisible channelsVisible
                    )

                SlackOAuthRedirect _ ->
                    ( [ "slack-oauth" ]
                    , []
                    )

                TextEditorRoute ->
                    ( [ "text-editor" ], [] )

                LinkDiscord _ ->
                    ( [ linkDiscordPath ], [] )

                PublicGoMatchRoute goMatchPublicId ->
                    ( [ "go-match", SecretId.toString goMatchPublicId ], [] )
    in
    Url.Builder.absolute path query


linkDiscordPath : String
linkDiscordPath =
    "link-discord"


linkDiscordQueryParam : String
linkDiscordQueryParam =
    "data"


encodeShowMembers : ShowChannelSettings -> List Url.Builder.QueryParameter
encodeShowMembers showMembers =
    case showMembers of
        ShowChannelSettings ->
            [ Url.Builder.string showMembersParam "True" ]

        HideChannelSettings ->
            []


encodeChannelsVisible : ChannelsVisibleOnMobile -> List Url.Builder.QueryParameter
encodeChannelsVisible channelsVisible =
    case channelsVisible of
        ChannelsVisibleOnMobile ->
            [ Url.Builder.string guildChannelsVisibleParam "True" ]

        ChannelsHiddenOnMobile ->
            []


encodeChannelHeaderTab : Maybe ChannelHeaderTab -> List Url.Builder.QueryParameter
encodeChannelHeaderTab tab =
    case tab of
        Just ChannelHeaderTab_VoiceChat ->
            [ Url.Builder.string tabParam "call" ]

        Just (ChannelHeaderTab_Games maybeMatchId) ->
            Url.Builder.string tabParam "game"
                :: (case maybeMatchId of
                        Just matchId ->
                            [ Url.Builder.int goMatchParam (Id.toInt matchId) ]

                        Nothing ->
                            []
                   )

        Just ChannelHeaderTab_ChannelDescription ->
            [ Url.Builder.string tabParam "description" ]

        Just ChannelHeaderTab_Draw ->
            [ Url.Builder.string tabParam "draw" ]

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

        NewGuildRoute ->
            True

        AiChatRoute ->
            False

        GuildRoute _ _ _ ->
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

        PublicGoMatchRoute _ ->
            False


{-| Whether moving between these two routes leaves the reader looking at a conversation they
weren't already looking at, which is what counts as having seen the messages waiting in it.

The rest of a route names the conversation it was already naming: opening a tab, jumping to
a message or showing the channel settings isn't arriving anywhere. Coming back out of the
channel list on mobile is, since that was covering the conversation.

Nothing is being marked as read on a route with no messages in it, so the answer for those
doesn't mean anything.

-}
routeChangeCountsAsMessageView : Route -> Route -> Bool
routeChangeCountsAsMessageView old new =
    not (sameConversation old new)


sameConversation : Route -> Route -> Bool
sameConversation old new =
    case ( old, new ) of
        ( GuildRoute oldGuildId (ChannelRoute oldChannelId oldThreadRoute _) oldChannelsVisible, GuildRoute newGuildId (ChannelRoute newChannelId newThreadRoute _) newChannelsVisible ) ->
            (oldGuildId == newGuildId)
                && (oldChannelId == newChannelId)
                && sameThread oldThreadRoute newThreadRoute
                && (oldChannelsVisible == newChannelsVisible)

        ( DiscordGuildRoute oldData, DiscordGuildRoute newData ) ->
            case ( oldData.channelRoute, newData.channelRoute ) of
                ( DiscordChannel_ChannelRoute oldChannelId oldThreadRoute _, DiscordChannel_ChannelRoute newChannelId newThreadRoute _ ) ->
                    (oldData.currentDiscordUserId == newData.currentDiscordUserId)
                        && (oldData.guildId == newData.guildId)
                        && (oldChannelId == newChannelId)
                        && sameThread oldThreadRoute newThreadRoute
                        && (oldData.channelsVisible == newData.channelsVisible)

                _ ->
                    False

        ( DmRoute oldData, DmRoute newData ) ->
            (oldData.channelId == newData.channelId)
                && sameThread oldData.threadRoute newData.threadRoute
                && (oldData.channelsVisible == newData.channelsVisible)

        ( DiscordDmRoute oldData, DiscordDmRoute newData ) ->
            (oldData.currentDiscordUserId == newData.currentDiscordUserId)
                && (oldData.channelId == newData.channelId)
                && (oldData.channelsVisible == newData.channelsVisible)

        _ ->
            False


sameThread : ThreadRouteWithFriends -> ThreadRouteWithFriends -> Bool
sameThread threadRoute previousThreadRoute =
    case ( threadRoute, previousThreadRoute ) of
        ( NoThreadWithFriends _ _, NoThreadWithFriends _ _ ) ->
            True

        ( ViewThreadWithFriends threadId _ _, ViewThreadWithFriends previousThreadId _ _ ) ->
            threadId == previousThreadId

        _ ->
            False


toGuildOrDmId : Id UserId -> Route -> Maybe ( AnyGuildOrDmId, ThreadRoute )
toGuildOrDmId userId route =
    case route of
        GuildRoute guildId (ChannelRoute channelId threadRoute _) _ ->
            ( GuildOrDmId_Guild { guildId = guildId, channelId = channelId } |> GuildOrDmId
            , case threadRoute of
                ViewThreadWithFriends threadMessageId _ _ ->
                    ViewThread threadMessageId

                NoThreadWithFriends _ _ ->
                    NoThread
            )
                |> Just

        DmRoute { channelId, threadRoute } ->
            case DmChannelId.otherUserId userId channelId of
                Just otherUserId ->
                    ( GuildOrDmId_Dm { otherUserId = otherUserId } |> GuildOrDmId
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
                DiscordChannel_ChannelRoute channelId threadRoute _ ->
                    ( DiscordGuildOrDmId_Guild
                        { currentUserId = data.currentDiscordUserId
                        , guildId = data.guildId
                        , channelId = channelId
                        }
                        |> DiscordGuildOrDmId
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
