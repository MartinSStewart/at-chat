module SearchOverlay exposing
    ( ResultIcon
    , SearchResult
    , inputId
    , resultsContainerId
    , rowHeight
    , search
    , view
    )

{-| The overlay Ctrl+K (Cmd+K on macOS) opens for jumping to any channel, thread or DM, including
Discord ones.
-}

import ChannelName
import Discord
import DmChannel exposing (DiscordFrontendDmChannel, FrontendDmChannel)
import DmChannelId
import Effect.Browser.Dom as Dom exposing (HtmlId)
import FileStatus exposing (FileHash)
import GuildColumn
import GuildName
import Html.Attributes
import Html.Events
import Icons
import Id exposing (ChannelId, ChannelMessageId, Id, UserId)
import Json.Decode
import LocalState exposing (DiscordFrontendGuild, FrontendGuild, LocalState)
import Message
import MessageArray exposing (MessageArray)
import MyUi
import NonemptyDict
import PersonName
import Route exposing (ChannelRoute(..), ChannelsVisibleOnMobile(..), DiscordChannelRoute(..), Route(..), ShowChannelSettings(..), ThreadRouteWithFriends(..))
import SeqDict exposing (SeqDict)
import Time
import Types exposing (FrontendMsg_(..))
import Ui exposing (Element)
import Ui.Anim
import Ui.Events
import Ui.Font
import Ui.Input
import User exposing (FrontendUser)
import UserSession exposing (DiscordFrontendUser)


type alias SearchResult =
    { name : String
    , location : Maybe String
    , icon : ResultIcon
    , isDiscord : Bool
    , route : Route
    , lastActivity : Int
    }


type ResultIcon
    = ChannelIcon
    | UserIcon (Maybe FrontendUser)
    | DiscordUserIcon (Discord.Id Discord.UserId) (Maybe FileHash)


inputId : HtmlId
inputId =
    Dom.id "searchOverlay_input"


resultsContainerId : HtmlId
resultsContainerId =
    Dom.id "searchOverlay_results"


rowHeight : Bool -> number
rowHeight isMobile =
    if isMobile then
        50

    else
        30


maxResults : Int
maxResults =
    50


{-| Results whose name starts with the query come before ones that only contain it, and within
each of those the most recently active come first, so an empty query lists recent conversations.
-}
search : String -> LocalState -> List SearchResult
search query local =
    let
        query2 : String
        query2 =
            String.trim query |> String.toLower
    in
    List.filterMap
        (\result ->
            let
                name : String
                name =
                    String.toLower result.name
            in
            if String.startsWith query2 name then
                Just ( 0, negate result.lastActivity, result )

            else if String.contains query2 name then
                Just ( 1, negate result.lastActivity, result )

            else
                Nothing
        )
        (allResults local)
        |> List.sortBy (\( rank, negatedLastActivity, _ ) -> ( rank, negatedLastActivity ))
        |> List.take maxResults
        |> List.map (\( _, _, result ) -> result)


allResults : LocalState -> List SearchResult
allResults local =
    SeqDict.foldl (\guildId guild list -> guildResults local guildId guild ++ list) [] local.guilds
        ++ SeqDict.foldl (\guildId guild list -> discordGuildResults local guildId guild ++ list) [] local.discordGuilds
        ++ SeqDict.foldl (\otherUserId dmChannel list -> dmResults local otherUserId dmChannel ++ list) [] local.dmChannels
        ++ SeqDict.foldl
            (\channelId dmChannel list ->
                case discordDmResult local channelId dmChannel of
                    Just result ->
                        result :: list

                    Nothing ->
                        list
            )
            []
            local.discordDmChannels


lastActivity : { a | messages : MessageArray messageId userId channelId } -> Int
lastActivity channel =
    case MessageArray.last channel.messages of
        Just message ->
            Message.createdAt message |> Time.posixToMillis

        Nothing ->
            0


mentionName : channelId -> Id ChannelMessageId -> SeqDict ( channelId, Maybe (Id ChannelMessageId) ) { name : String } -> String
mentionName channelId threadId channelMentions =
    case SeqDict.get ( channelId, Just threadId ) channelMentions of
        Just mention ->
            mention.name

        Nothing ->
            "<missing>"


guildResults : LocalState -> Id Id.GuildId -> FrontendGuild -> List SearchResult
guildResults local guildId guild =
    let
        guildName : String
        guildName =
            GuildName.toString guild.name

        channelMentions : SeqDict ( Id ChannelId, Maybe (Id ChannelMessageId) ) { name : String }
        channelMentions =
            LocalState.guildChannelMentions local.localUser guild.channels
    in
    SeqDict.foldl
        (\channelId channel list ->
            let
                route : ThreadRouteWithFriends -> Route
                route threadRoute =
                    GuildRoute guildId (ChannelRoute channelId threadRoute Nothing) ChannelsHiddenOnMobile Nothing
            in
            { name = ChannelName.toString channel.name
            , location = Just guildName
            , icon = ChannelIcon
            , isDiscord = False
            , route = route (NoThreadWithFriends Nothing HideChannelSettings)
            , lastActivity = lastActivity channel
            }
                :: SeqDict.foldl
                    (\threadId thread list2 ->
                        { name = mentionName channelId threadId channelMentions
                        , location = Just guildName
                        , icon = ChannelIcon
                        , isDiscord = False
                        , route = route (ViewThreadWithFriends threadId Nothing HideChannelSettings)
                        , lastActivity = lastActivity thread
                        }
                            :: list2
                    )
                    list
                    channel.threads
        )
        []
        guild.channels


discordGuildResults : LocalState -> Discord.Id Discord.GuildId -> DiscordFrontendGuild -> List SearchResult
discordGuildResults local guildId guild =
    case GuildColumn.discordGuildCurrentUserId local.localUser guild of
        Just currentUserId ->
            let
                guildName : String
                guildName =
                    GuildName.toString guild.name

                channelMentions : SeqDict ( Discord.Id Discord.ChannelId, Maybe (Id ChannelMessageId) ) { name : String }
                channelMentions =
                    LocalState.discordGuildChannelMentions local.localUser guild.channels
            in
            SeqDict.foldl
                (\channelId channel list ->
                    let
                        route : ThreadRouteWithFriends -> Route
                        route threadRoute =
                            DiscordGuildRoute
                                { currentDiscordUserId = currentUserId
                                , guildId = guildId
                                , channelRoute = DiscordChannel_ChannelRoute channelId threadRoute Nothing
                                , channelsVisible = ChannelsHiddenOnMobile
                                , overlay = Nothing
                                }
                    in
                    { name = ChannelName.toString channel.name
                    , location = Just guildName
                    , icon = ChannelIcon
                    , isDiscord = True
                    , route = route (NoThreadWithFriends Nothing HideChannelSettings)
                    , lastActivity = lastActivity channel
                    }
                        :: SeqDict.foldl
                            (\threadId thread list2 ->
                                { name = mentionName channelId threadId channelMentions
                                , location = Just guildName
                                , icon = ChannelIcon
                                , isDiscord = True
                                , route = route (ViewThreadWithFriends threadId Nothing HideChannelSettings)
                                , lastActivity = lastActivity thread
                                }
                                    :: list2
                            )
                            list
                            channel.threads
                )
                []
                guild.channels

        Nothing ->
            []


dmResults : LocalState -> Id UserId -> FrontendDmChannel -> List SearchResult
dmResults local otherUserId dmChannel =
    let
        otherUserName : String
        otherUserName =
            User.toStringAlt otherUserId local.localUser

        route : ThreadRouteWithFriends -> Route
        route threadRoute =
            DmRoute
                { channelId = DmChannelId.fromUserIds local.localUser.session.userId otherUserId
                , threadRoute = threadRoute
                , tab = Nothing
                , channelsVisible = ChannelsHiddenOnMobile
                , overlay = Nothing
                }
    in
    { name = otherUserName
    , location = Nothing
    , icon = UserIcon (User.getUser otherUserId local.localUser)
    , isDiscord = False
    , route = route (NoThreadWithFriends Nothing HideChannelSettings)
    , lastActivity = lastActivity dmChannel
    }
        :: SeqDict.foldl
            (\threadId thread list ->
                { name =
                    otherUserName
                        ++ "/"
                        ++ (case MessageArray.get threadId dmChannel.messages of
                                Just message ->
                                    LocalState.messageToString
                                        local.localUser.timezone
                                        (User.allUsers local.localUser)
                                        SeqDict.empty
                                        local.localUser.decryptedMessages
                                        message
                                        |> String.left 50

                                Nothing ->
                                    "<missing>"
                           )
                , location = Nothing
                , icon = UserIcon (User.getUser otherUserId local.localUser)
                , isDiscord = False
                , route = route (ViewThreadWithFriends threadId Nothing HideChannelSettings)
                , lastActivity = lastActivity thread
                }
                    :: list
            )
            []
            dmChannel.threads


{-| A Discord DM is named after the people in it besides the linked account we're in it as, or
after that account when it's a DM with ourselves.
-}
discordDmResult : LocalState -> Discord.Id Discord.PrivateChannelId -> DiscordFrontendDmChannel -> Maybe SearchResult
discordDmResult local channelId dmChannel =
    case GuildColumn.discordDmCurrentUserId local.localUser dmChannel of
        Just currentUserId ->
            let
                otherMembers : List (Discord.Id Discord.UserId)
                otherMembers =
                    NonemptyDict.remove currentUserId dmChannel.members |> SeqDict.keys

                members : List ( Discord.Id Discord.UserId, DiscordFrontendUser )
                members =
                    List.filterMap
                        (\userId -> User.getDiscordUser userId local.localUser |> Maybe.map (Tuple.pair userId))
                        (case otherMembers of
                            [] ->
                                [ currentUserId ]

                            _ ->
                                otherMembers
                        )
            in
            { name = List.map (\( _, user ) -> PersonName.toString user.name) members |> String.join ", "
            , location = Nothing
            , icon =
                case members of
                    ( userId, user ) :: _ ->
                        DiscordUserIcon userId user.icon

                    [] ->
                        DiscordUserIcon currentUserId Nothing
            , isDiscord = True
            , route =
                DiscordDmRoute
                    { currentDiscordUserId = currentUserId
                    , channelId = channelId
                    , viewingMessage = Nothing
                    , showMembersTab = HideChannelSettings
                    , tab = Nothing
                    , channelsVisible = ChannelsHiddenOnMobile
                    , overlay = Nothing
                    }
            , lastActivity = lastActivity dmChannel
            }
                |> Just

        Nothing ->
            Nothing


view : Bool -> String -> Int -> List SearchResult -> Element FrontendMsg_
view isMobile query selection results =
    Ui.el
        [ Ui.behindContent
            (Ui.el
                [ Ui.background MyUi.scrim
                , Ui.height Ui.fill
                , Ui.Events.onClick PressedCloseOverlay
                ]
                Ui.none
            )
        , Ui.height Ui.fill
        , Ui.paddingXY 16 16
        ]
        (Ui.column
            [ Ui.centerX
            , Ui.centerY
            , Ui.widthMax 600
            , Ui.height Ui.fill
            , Ui.heightMax 480
            , Ui.heightMin 0
            , Ui.background MyUi.background2
            , Ui.Font.color MyUi.font2
            , Ui.rounded 16
            , Ui.border 1
            , Ui.borderColor MyUi.buttonBorder
            ]
            [ Ui.el
                [ Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
                , Ui.borderColor MyUi.buttonBorder
                , MyUi.noShrinking
                , Ui.el
                    [ Ui.Font.color MyUi.font3
                    , Ui.width Ui.shrink
                    , Ui.height Ui.fill
                    , Ui.contentCenterY
                    , Ui.paddingXY 16 0
                    , MyUi.noPointerEvents
                    ]
                    (Ui.html Icons.magnifyingGlass)
                    |> Ui.inFront
                ]
                (Ui.Input.text
                    [ Ui.id (Dom.idToString inputId)
                    , Ui.background (Ui.rgba 0 0 0 0)
                    , Ui.border 0
                    , -- The modal's border is 1px wide inside its 16px corners
                      Ui.roundedWith { topLeft = 15, topRight = 15, bottomLeft = 0, bottomRight = 0 }
                    , Ui.paddingWith { left = 44, right = 16, top = 16, bottom = 16 }
                    , Ui.Font.color MyUi.font1
                    , Ui.Font.size 18
                    , Html.Events.preventDefaultOn "keydown" decodeKeyDown |> Ui.htmlAttribute
                    , Html.Attributes.attribute "autocomplete" "off" |> Ui.htmlAttribute
                    , MyUi.htmlStyle "outline-offset" "-1px"
                    ]
                    { onChange = TypedSearchOverlay
                    , text = query
                    , placeholder = Just "Search channels, threads and DMs"
                    , label = Ui.Input.labelHidden (Dom.idToString inputId)
                    }
                )
            , case results of
                [] ->
                    Ui.el
                        [ Ui.Font.color MyUi.font3, Ui.Font.italic, Ui.padding 16 ]
                        (Ui.text "No results found")

                _ ->
                    Ui.column
                        [ Ui.id (Dom.idToString resultsContainerId)
                        , Ui.scrollable
                        , Ui.heightMin 0
                        , Ui.height Ui.fill
                        ]
                        (List.indexedMap (\index result -> resultView isMobile (index == selection) index result) results)
            ]
        )


decodeKeyDown : Json.Decode.Decoder ( FrontendMsg_, Bool )
decodeKeyDown =
    Json.Decode.field "key" Json.Decode.string
        |> Json.Decode.andThen
            (\key ->
                case key of
                    "ArrowDown" ->
                        Json.Decode.succeed ( PressedSearchOverlayArrowKey 1, True )

                    "ArrowUp" ->
                        Json.Decode.succeed ( PressedSearchOverlayArrowKey -1, True )

                    "Enter" ->
                        Json.Decode.succeed ( PressedSearchOverlayEnter, True )

                    _ ->
                        Json.Decode.fail ""
            )


resultView : Bool -> Bool -> Int -> SearchResult -> Element FrontendMsg_
resultView isMobile isSelected index result =
    MyUi.rowButton
        (Dom.id ("searchOverlay_result_" ++ String.fromInt index))
        (PressedSearchOverlayResult result.route)
        [ Ui.height (Ui.px (rowHeight isMobile))
        , MyUi.noShrinking
        , Ui.spacing 8
        , Ui.paddingXY 8 0
        , Ui.contentCenterY
        , MyUi.hover isMobile [ Ui.Anim.backgroundColor MyUi.hoverHighlight ]
        , Ui.attrIf isSelected (Ui.background MyUi.background3)
        ]
        [ Ui.row
            [ Ui.height Ui.fill, Ui.clipWithEllipsis, MyUi.hoverText result.name ]
            [ case result.icon of
                ChannelIcon ->
                    Ui.el [ Ui.width Ui.shrink, MyUi.noShrinking, Ui.centerY, Ui.Font.color MyUi.font3 ] (Ui.html Icons.hashtag)

                UserIcon user ->
                    Ui.el [ Ui.width Ui.shrink, MyUi.noShrinking, Ui.centerY, Ui.paddingWith { left = 0, right = 8, top = 0, bottom = 0 } ] (User.smallProfileImage False user)

                DiscordUserIcon userId icon ->
                    Ui.el
                        [ Ui.width Ui.shrink, MyUi.noShrinking, Ui.centerY, Ui.paddingWith { left = 0, right = 8, top = 0, bottom = 0 } ]
                        (User.smallDiscordProfileImage userId icon)
            , Ui.text result.name
            ]
        , Ui.row
            [ Ui.width Ui.shrink
            , Ui.widthMax 240
            , Ui.spacing 4
            , Ui.alignRight
            , Ui.Font.size 14
            , Ui.Font.color MyUi.font3
            , Ui.contentCenterY
            ]
            [ case result.location of
                Just location ->
                    Ui.el [ Ui.clipWithEllipsis ] (Ui.text location)

                Nothing ->
                    Ui.none
            , if result.isDiscord then
                Ui.el [ Ui.width Ui.shrink, MyUi.noShrinking, MyUi.hoverText "Discord" ] (Ui.html Icons.discord)

              else
                Ui.none
            ]
        ]
