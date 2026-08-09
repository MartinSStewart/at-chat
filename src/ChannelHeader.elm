module ChannelHeader exposing
    ( channel
    , channelHeader
    , chattingWithYourself
    , discordChannel
    , discordThread
    , drawingCanUndoOrRedo
    , headerBackButton
    , thread
    )

import Call exposing (CallId(..))
import ChannelDescription
import ChannelName exposing (ChannelName)
import DmChannel
import DmChannelId
import Drawing exposing (Model(..))
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Game
import GuildIcon
import Html.Attributes
import Icons
import Id exposing (AnyGuildOrDmId(..), ChannelMessageId, DiscordGuildOrDmId(..), DiscordGuildOrDmId_DmData, GuildOrDmId(..), Id, ThreadRoute(..), ThreadRouteWithMessage(..), UserId)
import LinkedAndOtherDiscordUsers
import LocalState exposing (LocalState)
import Message exposing (Message)
import MessageArray exposing (MessageArray)
import MyUi
import NonemptyDict
import OneOrGreater exposing (OneOrGreater)
import PersonName
import Route exposing (ChannelRoute(..), DiscordChannelRoute(..), Route(..), ShowMembersTab(..))
import SeqDict exposing (SeqDict)
import SeqDictHelper
import Thread
import Touch
import Types exposing (Drag(..), FrontendMsg_(..), LoadedFrontend, LoggedIn2)
import Ui exposing (Element)
import Ui.Anim
import Ui.Font
import Ui.Lazy
import User exposing (LocalUser)
import UserSession exposing (ChannelHeaderTab(..))


channel : Bool -> String -> GuildOrDmId -> LocalState -> LoggedIn2 -> LoadedFrontend -> Element FrontendMsg_
channel isMobile name guildOrDmIdNoThread local loggedIn model =
    let
        currentChannelHeaderTab =
            Route.toChannelHeaderTab model.route
    in
    channelHeader
        isMobile
        (case guildOrDmIdNoThread of
            GuildOrDmId_Dm otherUserId ->
                if otherUserId == local.localUser.session.userId then
                    privateChatWithYourself isMobile model.route currentChannelHeaderTab local

                else
                    privateChatWith isMobile model.route currentChannelHeaderTab otherUserId local name

            GuildOrDmId_Guild _ _ ->
                Ui.row
                    [ Ui.spacing 2, Ui.clipWithEllipsis, Ui.height Ui.fill ]
                    [ channelHeaderTabRow
                        isMobile
                        (Dom.id "guild_openChannelDescription")
                        ChannelHeaderTab_ChannelDescription
                        currentChannelHeaderTab
                        [ Ui.el [ MyUi.noShrinking, Ui.width Ui.shrink ] (Ui.html Icons.hashtag)
                        , Ui.text name
                        ]
                    , Ui.row
                        [ Ui.width Ui.shrink, Ui.alignRight, Ui.height Ui.fill ]
                        [ Ui.Lazy.lazy2 gameButton isMobile currentChannelHeaderTab
                        , drawingTab isMobile currentChannelHeaderTab
                        , showFilesButton
                        , channelSettingsTab isMobile (Route.toShowMembersTab model.route |> Just)
                        ]
                    ]
        )
        (tabBodyView isMobile local loggedIn model)


thread : Bool -> String -> String -> GuildOrDmId -> LocalState -> LoggedIn2 -> LoadedFrontend -> Element FrontendMsg_
thread isMobile name threadName guildOrDmIdNoThread local loggedIn model =
    channelHeader
        isMobile
        (case guildOrDmIdNoThread of
            GuildOrDmId_Dm otherUserId ->
                if otherUserId == local.localUser.session.userId then
                    privateChatWithYourselfInThread isMobile model.route (Route.toChannelHeaderTab model.route) local threadName

                else
                    privateChatWithInThread
                        isMobile
                        model.route
                        (Route.toChannelHeaderTab model.route)
                        otherUserId
                        local
                        name
                        threadName

            GuildOrDmId_Guild _ _ ->
                Ui.row
                    [ Ui.Font.color MyUi.font1, Ui.spacing 2, Ui.clipWithEllipsis, Ui.height Ui.fill ]
                    [ Ui.el [ MyUi.noShrinking, Ui.width Ui.shrink ] (Ui.html Icons.hashtag)
                    , Ui.text (name ++ " / " ++ threadName)
                    , Ui.row
                        [ MyUi.noShrinking, Ui.width Ui.shrink, Ui.alignRight, Ui.height Ui.fill ]
                        [ drawingTab isMobile (Route.toChannelHeaderTab model.route)
                        , showFilesButton
                        , channelSettingsTab isMobile (Route.toShowMembersTab model.route |> Just)
                        ]
                    ]
        )
        (tabBodyView isMobile local loggedIn model)


discordChannel : Bool -> String -> DiscordGuildOrDmId -> LocalState -> LoggedIn2 -> LoadedFrontend -> Element FrontendMsg_
discordChannel isMobile name guildOrDmIdNoThread local loggedIn model =
    let
        currentChannelHeaderTab =
            Route.toChannelHeaderTab model.route
    in
    channelHeader
        isMobile
        (case guildOrDmIdNoThread of
            DiscordGuildOrDmId_Dm data ->
                Ui.row
                    [ Ui.height Ui.fill ]
                    [ if chattingWithYourself data local then
                        privateChatWithYourself isMobile model.route currentChannelHeaderTab local

                      else
                        discordPrivateChatWith isMobile model.route currentChannelHeaderTab name
                    ]

            DiscordGuildOrDmId_Guild _ _ _ ->
                Ui.row
                    [ Ui.Font.color MyUi.font1, Ui.spacing 2, Ui.clipWithEllipsis, Ui.height Ui.fill ]
                    [ channelHeaderTabRow
                        isMobile
                        (Dom.id "guild_openChannelDescription")
                        ChannelHeaderTab_ChannelDescription
                        currentChannelHeaderTab
                        [ Ui.el [ MyUi.noShrinking, Ui.width Ui.shrink ] (Ui.html Icons.hashtag)
                        , Ui.text name
                        ]
                    , Ui.row
                        [ MyUi.noShrinking, Ui.width Ui.shrink, Ui.alignRight, Ui.height Ui.fill ]
                        [ drawingTab isMobile currentChannelHeaderTab
                        , showFilesButton
                        , channelSettingsTab isMobile (Route.toShowMembersTab model.route |> Just)
                        ]
                    ]
        )
        (tabBodyView isMobile local loggedIn model)


discordThread : Bool -> String -> DiscordGuildOrDmId -> LocalState -> LoggedIn2 -> LoadedFrontend -> Element FrontendMsg_
discordThread isMobile name guildOrDmIdNoThread local loggedIn model =
    channelHeader
        isMobile
        (case guildOrDmIdNoThread of
            DiscordGuildOrDmId_Dm data ->
                if chattingWithYourself data local then
                    privateChatWithYourself isMobile model.route (Route.toChannelHeaderTab model.route) local

                else
                    discordPrivateChatWith isMobile model.route (Route.toChannelHeaderTab model.route) name

            DiscordGuildOrDmId_Guild _ _ _ ->
                Ui.row
                    [ Ui.Font.color MyUi.font1, Ui.spacing 2, Ui.clipWithEllipsis, Ui.contentCenterY, Ui.height Ui.fill ]
                    [ Ui.el [ MyUi.noShrinking, Ui.width Ui.shrink ] (Ui.html Icons.hashtag)
                    , Ui.text name
                    , Ui.row
                        [ MyUi.noShrinking, Ui.width Ui.shrink, Ui.alignRight, Ui.height Ui.fill ]
                        [ drawingTab isMobile (Route.toChannelHeaderTab model.route)
                        , showFilesButton
                        , channelSettingsTab isMobile (Route.toShowMembersTab model.route |> Just)
                        ]
                    ]
        )
        (tabBodyView isMobile local loggedIn model)


chattingWithYourself : DiscordGuildOrDmId_DmData -> LocalState -> Bool
chattingWithYourself data local =
    case SeqDict.get data.channelId local.discordDmChannels of
        Just channel2 ->
            NonemptyDict.all
                (\userId _ -> LinkedAndOtherDiscordUsers.isLinkedUser userId local.localUser.discordUsers)
                channel2.members

        Nothing ->
            False


{-| Toggles a mode where the user can draw freehand on top of messages, with a
mouse, a finger or a pen.
-}
drawingTab : Bool -> Maybe ChannelHeaderTab -> Element FrontendMsg_
drawingTab isMobile currentTab =
    channelHeaderIconTab
        isMobile
        (Dom.id "channelHeader_drawOnMessages")
        ChannelHeaderTab_Draw
        currentTab
        (Ui.el
            [ Ui.width (Ui.px 24)
            , MyUi.hoverText "Draw on top of messages"
            ]
            (Ui.html Icons.paintbrush)
        )


showFilesButton : Element FrontendMsg_
showFilesButton =
    MyUi.elButton
        (Dom.id "guild_showFiles")
        (PressedLink Route.TextEditorRoute)
        [ Ui.alignRight
        , Ui.width (Ui.px 48)
        , Ui.paddingXY 12 0
        , Ui.height Ui.fill
        , Ui.contentCenterY
        , Ui.Font.color MyUi.font3
        , MyUi.hoverText "Show files"
        ]
        (Ui.html Icons.document)


{-| `showMembers` is `Nothing` on the routes that have no member column to open,
so those never get a "Show members" button. When the column is already open the
button is left out too, since the column carries its own close button.
-}
channelHeader :
    Bool
    -> Element FrontendMsg_
    -> Maybe (Element FrontendMsg_)
    -> Element FrontendMsg_
channelHeader isMobile content tabContent =
    Ui.column
        [ Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
        , Ui.borderColor MyUi.border2
        , Ui.background MyUi.background3
        , case tabContent of
            Just tabContent2 ->
                -- Drawn over the conversation view rather than pushing it down.
                -- Ui.below is avoided here since Chrome and Firefox disagree on
                -- how to position its height:0 wrapper. The z-index keeps the tab
                -- body above positioned elements inside the conversation view.
                Ui.inFront
                    (Ui.el
                        [ Ui.move { x = 0, y = MyUi.channelHeaderHeight + 1, z = 0 }
                        , tabBodyZIndex
                        ]
                        tabContent2
                    )

            Nothing ->
                Ui.noAttr
        ]
        [ Ui.row
            [ Ui.contentCenterY
            , Ui.height (Ui.px MyUi.channelHeaderHeight)
            , MyUi.noShrinking
            ]
            (if isMobile then
                [ headerBackButton (Dom.id "guild_headerBackButton") PressedChannelHeaderBackButton
                , Ui.el [ Ui.height Ui.fill, Ui.contentCenterY ] content
                ]

             else
                [ Ui.el
                    [ Ui.paddingWith { left = 16, right = 0, top = 0, bottom = 0 }
                    , Ui.contentCenterY
                    , Ui.height Ui.fill
                    ]
                    content
                ]
            )
        ]


tabBodyZIndex : Ui.Attribute msg
tabBodyZIndex =
    MyUi.htmlStyle "z-index" "20"


channelSettingsTab : Bool -> Maybe ( ShowMembersTab, Bool ) -> Element FrontendMsg_
channelSettingsTab isMobile showMembers =
    case showMembers of
        Just ( HideMembersTab, isThread ) ->
            MyUi.elButton
                (Dom.id "guild_showMembers")
                PressedShowMembers
                [ Ui.width (Ui.px (24 + 24))
                , Ui.height Ui.fill
                , Ui.paddingXY 12 0
                , Ui.contentCenterY
                , Ui.Font.color MyUi.font3
                , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
                , MyUi.hoverText
                    (if isThread then
                        "Thread settings"

                     else
                        "Channel settings"
                    )
                ]
                (Ui.html Icons.gear)

        Just ( ShowMembersTab, _ ) ->
            Ui.none

        Nothing ->
            Ui.none


headerBackButton : HtmlId -> msg -> Element msg
headerBackButton htmlId onPress =
    MyUi.elButton
        htmlId
        onPress
        [ Ui.width Ui.shrink
        , Ui.height Ui.fill
        , Ui.Font.color MyUi.font3
        , Ui.contentCenterY
        , Ui.contentCenterX
        , Ui.paddingWith { left = 12, top = 8, bottom = 8, right = 8 }
        , MyUi.hoverText "Back"
        ]
        (Ui.html (Icons.arrowLeft 16))


channelHeaderTabRow :
    Bool
    -> HtmlId
    -> ChannelHeaderTab
    -> Maybe ChannelHeaderTab
    -> List (Element FrontendMsg_)
    -> Element FrontendMsg_
channelHeaderTabRow isMobile htmlId tab currentTab content =
    MyUi.rowButton
        htmlId
        (PressedChannelHeaderTab tab)
        (Ui.spacing 2 :: MyUi.prewrap :: channelHeaderTabAttributes 4 8 isMobile tab currentTab)
        content


channelHeaderTabAttributes : Int -> Int -> Bool -> ChannelHeaderTab -> Maybe ChannelHeaderTab -> List (Ui.Attribute msg)
channelHeaderTabAttributes paddingLeft paddingRight isMobile tab currentTab =
    let
        isSelected =
            case currentTab of
                Just currentTab2 ->
                    Route.sameChannelHeaderTab tab currentTab2

                Nothing ->
                    False

        borderHalfRadius =
            4
    in
    [ Ui.width Ui.shrink
    , Ui.height Ui.fill
    , Ui.paddingWith { left = paddingLeft, right = paddingRight, top = borderHalfRadius, bottom = borderHalfRadius }
    , -- The rounded top corners are part of the side edges, which are painted outside
      -- the tab, so the tab itself is a plain rectangle
      Ui.attrIf
        isSelected
        (Ui.behindContent
            (Ui.el
                [ Ui.height Ui.fill, Ui.paddingXY 4 0 ]
                (Ui.el [ Ui.background MyUi.tabBackground, Ui.height Ui.fill ] Ui.none)
            )
        )
    , Ui.attrIf isSelected (MyUi.tabSideEdge (borderHalfRadius * 2) MyUi.channelHeaderHeight True MyUi.tabBackground)
    , Ui.attrIf isSelected (MyUi.tabSideEdge (borderHalfRadius * 2) MyUi.channelHeaderHeight False MyUi.tabBackground)
    , Ui.contentCenterY
    , Ui.Font.color
        (if isSelected then
            MyUi.font1

         else
            MyUi.font3
        )
    , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
    ]


channelHeaderTab :
    Bool
    -> HtmlId
    -> ChannelHeaderTab
    -> Maybe ChannelHeaderTab
    -> Element FrontendMsg_
    -> Element FrontendMsg_
channelHeaderTab isMobile htmlId tab currentTab content =
    MyUi.elButton htmlId (PressedChannelHeaderTab tab) (channelHeaderTabAttributes 16 16 isMobile tab currentTab) content


{-| A tab holding nothing but a 24px icon. The 12px of padding on either side make it
48px wide, the same as the plain icon buttons it sits next to in the header.
-}
channelHeaderIconTab :
    Bool
    -> HtmlId
    -> ChannelHeaderTab
    -> Maybe ChannelHeaderTab
    -> Element FrontendMsg_
    -> Element FrontendMsg_
channelHeaderIconTab isMobile htmlId tab currentTab content =
    MyUi.elButton htmlId (PressedChannelHeaderTab tab) (channelHeaderTabAttributes 12 12 isMobile tab currentTab) content


privateChatWithYourself : Bool -> Route -> Maybe ChannelHeaderTab -> LocalState -> Element FrontendMsg_
privateChatWithYourself isMobile route currentTab local =
    Ui.row
        [ Ui.Font.color MyUi.font1, Ui.spacing 6, Ui.height Ui.fill ]
        [ channelHeaderTab
            isMobile
            (Dom.id "guild_openDescription")
            ChannelHeaderTab_ChannelDescription
            currentTab
            (Ui.text "Solo chat")
        , dmHeaderButtons isMobile route currentTab local.localUser.session.userId local
        ]


privateChatWith : Bool -> Route -> Maybe ChannelHeaderTab -> Id UserId -> LocalState -> String -> Element FrontendMsg_
privateChatWith isMobile route currentTab otherUserId local name =
    Ui.row
        [ Ui.Font.color MyUi.font1, Ui.spacing 6, Ui.clipWithEllipsis, Ui.height Ui.fill ]
        [ channelHeaderTab
            isMobile
            (Dom.id "guild_openDescription")
            ChannelHeaderTab_ChannelDescription
            currentTab
            (if isMobile then
                Ui.el [ Ui.Font.color MyUi.font1 ] (Ui.text name)

             else
                Ui.row
                    [ Ui.Font.exactWhitespace ]
                    [ Ui.text "Chat with ", Ui.el [ Ui.Font.color MyUi.font1 ] (Ui.text name) ]
            )
        , dmHeaderButtons isMobile route currentTab otherUserId local
        ]


{-| A thread is named after the message it started from, which can be arbitrarily long, so
the thread name is what gets cut short when the header runs out of room.
-}
privateChatWithYourselfInThread : Bool -> Route -> Maybe ChannelHeaderTab -> LocalState -> String -> Element FrontendMsg_
privateChatWithYourselfInThread isMobile route currentTab local threadName =
    Ui.row
        [ Ui.Font.color MyUi.font1, Ui.spacing 6, Ui.clipWithEllipsis, Ui.height Ui.fill ]
        [ channelHeaderTab
            isMobile
            (Dom.id "guild_openDescription")
            ChannelHeaderTab_ChannelDescription
            currentTab
            (Ui.text ("Solo chat / " ++ threadName))
        , dmHeaderButtons isMobile route currentTab local.localUser.session.userId local
        ]


privateChatWithInThread :
    Bool
    -> Route
    -> Maybe ChannelHeaderTab
    -> Id UserId
    -> LocalState
    -> String
    -> String
    -> Element FrontendMsg_
privateChatWithInThread isMobile route currentTab otherUserId local name threadName =
    Ui.row
        [ Ui.Font.color MyUi.font1, Ui.spacing 6, Ui.clipWithEllipsis, Ui.height Ui.fill ]
        [ channelHeaderTab
            isMobile
            (Dom.id "guild_openDescription")
            ChannelHeaderTab_ChannelDescription
            currentTab
            (if isMobile then
                Ui.el [ Ui.Font.color MyUi.font1 ] (Ui.text (name ++ " / " ++ threadName))

             else
                Ui.row
                    -- For whatever reason, Ui.Font.exactWhitespace doesn't work here. So Ui.spacing is used instead
                    [ Ui.spacing 5 ]
                    [ Ui.text "Chat with "
                    , Ui.el [ Ui.Font.color MyUi.font1 ] (Ui.text (name ++ " / " ++ threadName))
                    ]
            )
        , dmHeaderButtons isMobile route currentTab otherUserId local
        ]


{-| The buttons on the right hand side of a DM's header.
-}
dmHeaderButtons : Bool -> Route -> Maybe ChannelHeaderTab -> Id UserId -> LocalState -> Element FrontendMsg_
dmHeaderButtons isMobile route currentTab otherUserId local =
    Ui.row
        [ MyUi.noShrinking, Ui.width Ui.shrink, Ui.alignRight, Ui.height Ui.fill ]
        [ Ui.Lazy.lazy5 voiceChatButton isMobile currentTab otherUserId local.localUser local.calls
        , Ui.Lazy.lazy2 gameButton isMobile currentTab
        , drawingTab isMobile currentTab
        , channelSettingsTab isMobile (Route.toShowMembersTab route |> Just)
        ]


gameButton : Bool -> Maybe ChannelHeaderTab -> Element FrontendMsg_
gameButton isMobile currentTab =
    channelHeaderIconTab
        isMobile
        (Dom.id "guild_openGamesTab")
        (ChannelHeaderTab_Games Nothing)
        currentTab
        (Ui.el [ MyUi.hoverText "Games" ] (Ui.html Icons.go))


voiceChatButton : Bool -> Maybe ChannelHeaderTab -> Id UserId -> LocalUser -> Call.Local -> Element FrontendMsg_
voiceChatButton isMobile currentTab otherUserId localUser calls =
    let
        joinedUsers : SeqDict (Id UserId) OneOrGreater
        joinedUsers =
            case SeqDict.get (DmRoomId otherUserId) calls.voiceChats of
                Just voiceChat ->
                    NonemptyDict.foldl
                        (\( userId, _ ) _ dict -> SeqDictHelper.increment userId dict)
                        SeqDict.empty
                        voiceChat

                Nothing ->
                    SeqDict.empty

        joinedUsers2 =
            if calls.currentRoom == Just (DmRoomId otherUserId) then
                SeqDictHelper.increment localUser.session.userId joinedUsers

            else
                joinedUsers

        joined : Element msg
        joined =
            SeqDict.toList joinedUsers2
                |> List.map
                    (\( userId, count ) ->
                        case User.getUser userId localUser of
                            Just user ->
                                Ui.el
                                    [ if OneOrGreater.toInt count > 1 then
                                        GuildIcon.notificationHelper
                                            MyUi.background1
                                            MyUi.white
                                            MyUi.border1
                                            2
                                            -2
                                            count

                                      else
                                        Ui.noAttr
                                    , Html.Attributes.attribute "aria-label" (PersonName.toString user.name ++ " is in a call")
                                        |> Ui.htmlAttribute
                                    ]
                                    (User.profileImage userId user.icon)

                            Nothing ->
                                Ui.none
                    )
                |> Ui.row [ Ui.width Ui.shrink, Ui.spacing 4 ]
    in
    Ui.row
        [ Ui.width Ui.shrink, Ui.spacing 8, Ui.height Ui.fill, Ui.contentCenterY ]
        [ joined
        , channelHeaderIconTab
            isMobile
            (Dom.id "guild_voiceChat")
            ChannelHeaderTab_VoiceChat
            currentTab
            (Ui.el [ MyUi.hoverText "Voice chat" ] (Ui.html Icons.phone))
        ]


discordPrivateChatWith : Bool -> Route -> Maybe ChannelHeaderTab -> String -> Element FrontendMsg_
discordPrivateChatWith isMobile route currentTab name =
    Ui.row
        [ Ui.Font.color MyUi.font1, Ui.spacing 6, Ui.height Ui.fill ]
        [ channelHeaderTab
            isMobile
            (Dom.id "guild_openDescription")
            ChannelHeaderTab_ChannelDescription
            currentTab
            (if isMobile then
                Ui.el [ Ui.Font.color MyUi.font1 ] (Ui.text name)

             else
                Ui.row
                    [ Ui.Font.exactWhitespace ]
                    [ Ui.text "Chat with ", Ui.el [ Ui.Font.color MyUi.font1 ] (Ui.text name) ]
            )
        , Ui.row
            [ Ui.alignRight, Ui.height Ui.fill ]
            [ drawingTab isMobile currentTab
            , channelSettingsTab isMobile (Route.toShowMembersTab route |> Just)
            ]
        ]


tabBodyView : Bool -> LocalState -> LoggedIn2 -> LoadedFrontend -> Maybe (Element FrontendMsg_)
tabBodyView isMobile local loggedIn model =
    case model.route of
        GuildRoute guildId channelRoute ->
            case channelRoute of
                ChannelRoute channelId _ (Just tab) ->
                    case tab of
                        ChannelHeaderTab_ChannelDescription ->
                            case LocalState.getGuildAndChannel guildId channelId local of
                                Just ( _, channel2 ) ->
                                    Just (channelDescriptionView (Just channel2.name) (ChannelDescription.toString channel2.description))

                                Nothing ->
                                    Nothing

                        ChannelHeaderTab_VoiceChat ->
                            Nothing

                        ChannelHeaderTab_Games maybeMatchId ->
                            case LocalState.getGuildAndChannel guildId channelId local of
                                Just ( _, channel2 ) ->
                                    gameTabBody
                                        (GuildOrDmId_Guild guildId channelId)
                                        maybeMatchId
                                        local
                                        loggedIn
                                        channel2.games
                                        model

                                Nothing ->
                                    Nothing

                        ChannelHeaderTab_Draw ->
                            drawingTabView isMobile loggedIn.drawingMode local |> Just

                ChannelRoute _ _ _ ->
                    Nothing

                NewChannelRoute ->
                    Nothing

                GuildSettingsRoute ->
                    Nothing

                JoinRoute _ ->
                    Nothing

        DmRoute dmRoute ->
            case DmChannelId.otherUserId local.localUser.session.userId dmRoute.channelId of
                Just otherUserId ->
                    case dmRoute.tab of
                        Just (ChannelHeaderTab_Games maybeMatchId) ->
                            gameTabBody
                                (GuildOrDmId_Dm otherUserId)
                                maybeMatchId
                                local
                                loggedIn
                                (SeqDict.get otherUserId local.dmChannels |> Maybe.withDefault DmChannel.frontendInit |> .games)
                                model

                        Just ChannelHeaderTab_VoiceChat ->
                            Call.view model.windowSize (DmRoomId otherUserId) local.calls loggedIn.voiceChat
                                |> Ui.map VoiceChatMsg
                                |> Just

                        Just ChannelHeaderTab_ChannelDescription ->
                            channelDescriptionView
                                Nothing
                                (if otherUserId == local.localUser.session.userId then
                                    "A channel where you can write things down you want to remember."

                                 else
                                    "A private channel for just you and "
                                        ++ User.toString otherUserId local.localUser.otherUsers
                                )
                                |> Just

                        Just ChannelHeaderTab_Draw ->
                            drawingTabView isMobile loggedIn.drawingMode local |> Just

                        Nothing ->
                            Nothing

                Nothing ->
                    Nothing

        HomePageRoute ->
            Nothing

        AdminRoute _ ->
            Nothing

        NewGuildRoute ->
            Nothing

        DiscordGuildRoute routeData ->
            case routeData.channelRoute of
                DiscordChannel_ChannelRoute channelId _ (Just tab) ->
                    case tab of
                        ChannelHeaderTab_ChannelDescription ->
                            case LocalState.getDiscordGuildAndChannel routeData.guildId channelId local of
                                Just ( _, channel2 ) ->
                                    Just (channelDescriptionView (Just channel2.name) (ChannelDescription.toString channel2.description))

                                Nothing ->
                                    Nothing

                        ChannelHeaderTab_VoiceChat ->
                            Nothing

                        ChannelHeaderTab_Games _ ->
                            Nothing

                        ChannelHeaderTab_Draw ->
                            drawingTabView isMobile loggedIn.drawingMode local |> Just

                DiscordChannel_ChannelRoute _ _ _ ->
                    Nothing

                DiscordChannel_NewChannelRoute ->
                    Nothing

                DiscordChannel_GuildSettingsRoute ->
                    Nothing

        DiscordDmRoute routeData ->
            case routeData.tab of
                Just ChannelHeaderTab_ChannelDescription ->
                    channelDescriptionView
                        Nothing
                        (if
                            chattingWithYourself
                                { currentUserId = routeData.currentDiscordUserId, channelId = routeData.channelId }
                                local
                         then
                            "A channel where you can write things down you want to remember."

                         else
                            case SeqDict.get routeData.channelId local.discordDmChannels of
                                Just channel2 ->
                                    case
                                        NonemptyDict.toSeqDict channel2.members
                                            |> SeqDict.remove routeData.currentDiscordUserId
                                            |> SeqDict.toList
                                    of
                                        [ ( single, _ ) ] ->
                                            "A Discord DM channel for you and "
                                                ++ (case User.getDiscordUser single local.localUser of
                                                        Just user ->
                                                            PersonName.toString user.name

                                                        Nothing ->
                                                            "<missing>"
                                                   )

                                        many ->
                                            "A Discord group channel for "
                                                ++ String.join ", "
                                                    (List.map
                                                        (\( userId, _ ) ->
                                                            case User.getDiscordUser userId local.localUser of
                                                                Just user ->
                                                                    PersonName.toString user.name

                                                                Nothing ->
                                                                    "<missing>"
                                                        )
                                                        many
                                                    )
                                                ++ " and you."

                                Nothing ->
                                    ""
                        )
                        |> Just

                Just ChannelHeaderTab_Draw ->
                    drawingTabView isMobile loggedIn.drawingMode local |> Just

                _ ->
                    Nothing

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


gameTabBody :
    GuildOrDmId
    -> Maybe (Id ChannelMessageId)
    -> LocalState
    -> LoggedIn2
    -> SeqDict (Id ChannelMessageId) Game.MatchData
    -> LoadedFrontend
    -> Maybe (Element FrontendMsg_)
gameTabBody guildOrDmId maybeMatchId local loggedIn matchData model =
    Game.view
        model.time
        model.windowSize
        (case Route.toShowMembersTab model.route of
            ( ShowMembersTab, _ ) ->
                True

            ( HideMembersTab, _ ) ->
                False
        )
        -- Touches are reported from the viewport top (behind the safe-area
        -- inset); shift them to match the board laid out below the inset.
        ((case model.drag of
            NoDrag ->
                Nothing

            DragStart _ dragging ->
                Just dragging

            Dragging dragging ->
                Just dragging.touches
         )
            |> Maybe.map (Touch.removeSafeAreaTopInset model.startupData.safeAreaInsetTop)
        )
        model.lastCopied
        local.localUser
        guildOrDmId
        maybeMatchId
        matchData
        (SeqDict.get guildOrDmId loggedIn.games |> Maybe.withDefault Game.initModel)
        |> Ui.map GameMsg
        |> Just


drawingCanUndoOrRedo : AnyGuildOrDmId -> Drawing.AnchorType -> LocalState -> ( Bool, Bool )
drawingCanUndoOrRedo guildOrDmId anchor local =
    let
        noThreadHelper : userId -> Drawing.MessageAnchor -> Id messageId -> { a | messages : MessageArray messageId (Message messageId userId) } -> ( Bool, Bool )
        noThreadHelper userId anchor2 messageId channel2 =
            case MessageArray.get messageId channel2.messages of
                Just message ->
                    let
                        drawing : Drawing.Drawing userId
                        drawing =
                            Message.drawing anchor2 message
                    in
                    ( Drawing.canUndo userId drawing, Drawing.canRedo userId drawing )

                _ ->
                    ( False, False )

        helper userId channel2 =
            case anchor of
                Drawing.MessageAnchor threadRoute anchor2 ->
                    case threadRoute of
                        NoThreadWithMessage messageId ->
                            noThreadHelper userId anchor2 messageId channel2

                        ViewThreadWithMessage threadId messageId ->
                            SeqDict.get threadId channel2.threads
                                |> Maybe.withDefault Thread.frontendInit
                                |> noThreadHelper userId anchor2 messageId

                Drawing.DateDividerAnchor threadRoute date ->
                    case threadRoute of
                        NoThread ->
                            case SeqDict.get date channel2.dateDividerDrawings of
                                Just drawing ->
                                    ( Drawing.canUndo userId drawing, Drawing.canRedo userId drawing )

                                Nothing ->
                                    ( False, False )

                        ViewThread threadId ->
                            case
                                SeqDict.get threadId channel2.threads
                                    |> Maybe.withDefault Thread.frontendInit
                                    |> .dateDividerDrawings
                                    |> SeqDict.get date
                            of
                                Just drawing ->
                                    ( Drawing.canUndo userId drawing, Drawing.canRedo userId drawing )

                                Nothing ->
                                    ( False, False )
    in
    case guildOrDmId of
        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
            case LocalState.getGuildAndChannel guildId channelId local of
                Just ( _, channel2 ) ->
                    helper local.localUser.session.userId channel2

                Nothing ->
                    ( False, False )

        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
            case SeqDict.get otherUserId local.dmChannels of
                Just channel2 ->
                    helper local.localUser.session.userId channel2

                Nothing ->
                    ( False, False )

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentUserId guildId channelId) ->
            case LocalState.getDiscordGuildAndChannel guildId channelId local of
                Just ( _, channel2 ) ->
                    helper currentUserId channel2

                Nothing ->
                    ( False, False )

        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data) ->
            case SeqDict.get data.channelId local.discordDmChannels of
                Just channel2 ->
                    case anchor of
                        Drawing.MessageAnchor (NoThreadWithMessage messageId) anchor2 ->
                            noThreadHelper data.currentUserId anchor2 messageId channel2

                        Drawing.DateDividerAnchor NoThread date ->
                            case SeqDict.get date channel2.dateDividerDrawings of
                                Just drawing ->
                                    ( Drawing.canUndo data.currentUserId drawing, Drawing.canRedo data.currentUserId drawing )

                                Nothing ->
                                    ( False, False )

                        _ ->
                            ( False, False )

                Nothing ->
                    ( False, False )


{-| Shown in the channel header below the tab buttons while the drawing tab is selected.
-}
drawingTabView : Bool -> Model -> LocalState -> Element FrontendMsg_
drawingTabView isMobile model local =
    Ui.el
        [ Ui.paddingXY 16 0
        , Ui.background MyUi.tabBackground
        , Ui.contentCenterY
        , Ui.height (Ui.px 80)
        , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
        , Ui.borderColor MyUi.border2
        ]
        (case model of
            NoSelectedAnchor ->
                Ui.text "Click on a profile image, timestamp, or attachment to anchor your drawing to it."

            SelectedAnchor selected ->
                let
                    ( canUndo, canRedo ) =
                        drawingCanUndoOrRedo selected.guildOrDmId selected.anchorType local
                in
                Ui.column
                    [ Ui.spacing 8 ]
                    [ Ui.text "Start drawing!"
                    , Ui.row
                        [ if isMobile then
                            Ui.spacing 8

                          else
                            Ui.spacing 16
                        ]
                        [ Drawing.button (Dom.id "drawing_done") Drawing.PressedDone "Done" True
                        , Drawing.button Drawing.undoButtonId Drawing.PressedUndo "Undo" canUndo
                        , Drawing.button Drawing.redoButtonId Drawing.PressedRedo "Redo" canRedo
                        , Drawing.button
                            Drawing.zoomButtonId
                            Drawing.PressedZoom
                            (if selected.zoom == 1 then
                                "Zoom in"

                             else
                                "Zoom out"
                            )
                            True
                        ]
                    ]
        )
        |> Ui.map DrawingMsg


channelDescriptionView : Maybe ChannelName -> String -> Element FrontendMsg_
channelDescriptionView channelName description =
    Ui.column
        [ Ui.paddingXY 16 12
        , Ui.background MyUi.tabBackground
        , Ui.Font.color MyUi.font2
        , Ui.spacing 8
        , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
        , Ui.borderColor MyUi.border2
        ]
        [ case channelName of
            Just channelName2 ->
                Ui.el
                    [ Ui.Font.bold, MyUi.htmlStyle "overflow-wrap" "break-word" ]
                    (Ui.text (ChannelName.toString channelName2))

            Nothing ->
                Ui.none
        , if String.isEmpty description then
            Ui.el [ Ui.Font.italic ] (Ui.text "No channel description")

          else
            Ui.text description
        ]
