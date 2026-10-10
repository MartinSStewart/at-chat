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
import GuildColumn
import GuildName
import Html
import Html.Attributes
import Html.Events
import Icons
import Id exposing (ChannelMessageId, Id, UserId)
import Json.Decode
import LinkedAndOtherDiscordUsers
import LocalState exposing (DiscordFrontendGuild, FrontendGuild, LocalState)
import Message exposing (Message)
import MessageArray exposing (MessageArray)
import MyUi
import NonemptyDict
import PersonName
import Route exposing (ChannelRoute(..), ChannelsVisibleOnMobile(..), DiscordChannelRoute(..), Route(..), ShowChannelSettings(..), ThreadRouteWithFriends(..))
import SeqDict
import Time
import Types exposing (FrontendMsg_(..))
import Ui exposing (Element)
import Ui.Anim
import Ui.Events
import Ui.Font
import Ui.Input
import User


type alias SearchResult =
    { name : String
    , location : String
    , icon : ResultIcon
    , isDiscord : Bool
    , route : Route
    , lastActivity : Int
    }


type ResultIcon
    = ChannelIcon
    | ThreadIcon
    | PersonIcon


inputId : HtmlId
inputId =
    Dom.id "searchOverlay_input"


resultsContainerId : HtmlId
resultsContainerId =
    Dom.id "searchOverlay_results"


rowHeight : number
rowHeight =
    44


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


threadName :
    Id ChannelMessageId
    -> (Message ChannelMessageId userId channelId -> String)
    -> MessageArray ChannelMessageId userId channelId
    -> String
threadName threadId messageToString messages =
    case MessageArray.get threadId messages of
        Just message ->
            messageToString message

        Nothing ->
            "Thread not found"


guildResults : LocalState -> Id Id.GuildId -> FrontendGuild -> List SearchResult
guildResults local guildId guild =
    let
        guildName : String
        guildName =
            GuildName.toString guild.name

        channelMentions =
            LocalState.guildChannelMentions local.localUser guild.channels
    in
    SeqDict.foldl
        (\channelId channel list ->
            let
                channelName : String
                channelName =
                    ChannelName.toString channel.name

                route : ThreadRouteWithFriends -> Route
                route threadRoute =
                    GuildRoute guildId (ChannelRoute channelId threadRoute Nothing) ChannelsHiddenOnMobile Nothing
            in
            { name = channelName
            , location = guildName
            , icon = ChannelIcon
            , isDiscord = False
            , route = route (NoThreadWithFriends Nothing HideChannelSettings)
            , lastActivity = lastActivity channel
            }
                :: SeqDict.foldl
                    (\threadId thread list2 ->
                        { name =
                            threadName
                                threadId
                                (LocalState.messageToString
                                    local.localUser.timezone
                                    (User.allUsers local.localUser)
                                    channelMentions
                                    local.localUser.decryptedMessages
                                )
                                channel.messages
                        , location = guildName ++ " / #" ++ channelName
                        , icon = ThreadIcon
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

                channelMentions =
                    LocalState.discordGuildChannelMentions local.localUser guild.channels
            in
            SeqDict.foldl
                (\channelId channel list ->
                    let
                        channelName : String
                        channelName =
                            ChannelName.toString channel.name

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
                    { name = channelName
                    , location = guildName
                    , icon = ChannelIcon
                    , isDiscord = True
                    , route = route (NoThreadWithFriends Nothing HideChannelSettings)
                    , lastActivity = lastActivity channel
                    }
                        :: SeqDict.foldl
                            (\threadId thread list2 ->
                                { name =
                                    threadName
                                        threadId
                                        (LocalState.messageToString
                                            local.localUser.timezone
                                            (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                                            channelMentions
                                            SeqDict.empty
                                        )
                                        channel.messages
                                , location = guildName ++ " / #" ++ channelName
                                , icon = ThreadIcon
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
    , location = "Direct message"
    , icon = PersonIcon
    , isDiscord = False
    , route = route (NoThreadWithFriends Nothing HideChannelSettings)
    , lastActivity = lastActivity dmChannel
    }
        :: SeqDict.foldl
            (\threadId thread list ->
                { name =
                    threadName
                        threadId
                        (LocalState.messageToString
                            local.localUser.timezone
                            (User.allUsers local.localUser)
                            SeqDict.empty
                            local.localUser.decryptedMessages
                        )
                        dmChannel.messages
                , location = "Direct message / " ++ otherUserName
                , icon = ThreadIcon
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

                names : List String
                names =
                    List.filterMap
                        (\userId -> User.getDiscordUser userId local.localUser |> Maybe.map (\user -> PersonName.toString user.name))
                        (case otherMembers of
                            [] ->
                                [ currentUserId ]

                            _ ->
                                otherMembers
                        )
            in
            { name = String.join ", " names
            , location = "Direct message"
            , icon = PersonIcon
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
            , Ui.background MyUi.background3
            , Ui.rounded 16
            , Ui.border 1
            , Ui.borderColor MyUi.border1
            , Ui.clip
            ]
            [ Ui.row
                [ Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
                , Ui.borderColor MyUi.border1
                , Ui.paddingWith { left = 16, right = 0, top = 0, bottom = 0 }
                , Ui.contentCenterY
                , MyUi.noShrinking
                ]
                [ Ui.el [ Ui.Font.color MyUi.font3, Ui.width Ui.shrink ] (Ui.html Icons.magnifyingGlass)
                , Ui.Input.text
                    [ Ui.id (Dom.idToString inputId)
                    , Ui.background (Ui.rgba 0 0 0 0)
                    , Ui.border 0
                    , Ui.padding 16
                    , Ui.Font.color MyUi.font1
                    , Ui.Font.size 18
                    , Html.Events.preventDefaultOn "keydown" decodeKeyDown |> Ui.htmlAttribute
                    , Html.Attributes.attribute "autocomplete" "off" |> Ui.htmlAttribute
                    ]
                    { onChange = TypedSearchOverlay
                    , text = query
                    , placeholder = Just "Search channels, threads and DMs"
                    , label = Ui.Input.labelHidden (Dom.idToString inputId)
                    }
                ]
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
                        , Ui.paddingXY 8 8
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
        [ Ui.height (Ui.px rowHeight)
        , MyUi.noShrinking
        , Ui.spacing 8
        , Ui.paddingXY 8 0
        , Ui.rounded 8
        , Ui.contentCenterY
        , if isSelected then
            Ui.Font.color MyUi.font1

          else
            Ui.Font.color MyUi.font2
        , Ui.attrIf isSelected (Ui.background MyUi.selectedHighlight)
        , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
        ]
        [ Ui.el
            [ Ui.width (Ui.px 20), Ui.Font.color MyUi.font3, MyUi.noShrinking ]
            (Ui.html (resultIcon result.icon))
        , Ui.el [ Ui.clipWithEllipsis, MyUi.hoverText result.name ] (Ui.text result.name)
        , Ui.row
            [ Ui.width Ui.shrink
            , Ui.widthMax 240
            , Ui.spacing 4
            , Ui.alignRight
            , Ui.Font.size 14
            , Ui.Font.color MyUi.font3
            , Ui.contentCenterY
            ]
            [ Ui.el [ Ui.clipWithEllipsis ] (Ui.text result.location)
            , if result.isDiscord then
                Ui.el [ Ui.width Ui.shrink, MyUi.noShrinking, MyUi.hoverText "Discord" ] (Ui.html Icons.discord)

              else
                Ui.none
            ]
        ]


resultIcon : ResultIcon -> Html.Html msg
resultIcon icon =
    case icon of
        ChannelIcon ->
            Icons.hashtag

        ThreadIcon ->
            Html.div
                [ Html.Attributes.style "height" "20px", Html.Attributes.style "overflow" "hidden" ]
                [ Icons.threadSingleSegment ]

        PersonIcon ->
            Html.div [ Html.Attributes.style "width" "20px", Html.Attributes.style "height" "20px" ] [ Icons.person ]
