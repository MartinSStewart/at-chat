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

import Array exposing (Array)
import Call exposing (CallId(..))
import ChannelDescription
import ChannelName exposing (ChannelName)
import DmChannel
import Drawing exposing (Model(..))
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Game exposing (MatchData)
import Go
import GuildIcon
import Html.Attributes
import Icons
import Id exposing (AnyGuildOrDmId(..), ChannelMessageId, DiscordGuildOrDmId(..), DiscordGuildOrDmId_DmData, GuildOrDmId(..), Id, ThreadRoute(..), ThreadRouteWithMessage(..), UserId)
import LinkedAndOtherDiscordUsers
import LocalState exposing (LocalState)
import Message exposing (MessageState(..))
import MyUi
import NonemptyDict
import OneOrGreater exposing (OneOrGreater)
import PersonName
import Route exposing (ChannelRoute(..), DiscordChannelRoute(..), DmChannelHeaderTab(..), Route(..))
import SeqDict exposing (SeqDict)
import SeqDictHelper
import SeqSet
import Thread
import Types exposing (FrontendMsg(..), LoadedFrontend, LoggedIn2)
import Ui exposing (Element)
import Ui.Accessibility
import Ui.Anim
import Ui.Font
import Ui.Lazy
import User exposing (LocalUser)


channel : Bool -> String -> GuildOrDmId -> LocalState -> LoggedIn2 -> LoadedFrontend -> Element FrontendMsg
channel isMobile name guildOrDmIdNoThread local loggedIn model =
    let
        currentChannelHeaderTab =
            Route.toChannelHeaderTab model.route
    in
    channelHeader
        isMobile
        True
        (case guildOrDmIdNoThread of
            GuildOrDmId_Dm otherUserId ->
                Ui.row
                    [ Ui.height Ui.fill ]
                    [ if otherUserId == local.localUser.session.userId then
                        privateChatWithYourself isMobile currentChannelHeaderTab local

                      else
                        privateChatWith isMobile currentChannelHeaderTab otherUserId local name
                    , drawButton isMobile currentChannelHeaderTab
                    ]

            GuildOrDmId_Guild _ _ ->
                Ui.row
                    [ Ui.spacing 2, Ui.clipWithEllipsis, Ui.height Ui.fill ]
                    [ channelHeaderTabRow
                        isMobile
                        (Dom.id "guild_openChannelDescription")
                        DmChannelHeaderTab_ChannelDescription
                        currentChannelHeaderTab
                        [ Ui.el [ MyUi.noShrinking, Ui.width Ui.shrink ] (Ui.html Icons.hashtag)
                        , Ui.text name
                        ]
                    , Ui.row
                        [ Ui.width Ui.shrink, Ui.alignRight, Ui.height Ui.fill ]
                        [ drawButton isMobile currentChannelHeaderTab
                        , showFilesButton
                        ]
                    ]
        )
        (tabBodyView local loggedIn model)


thread : Bool -> String -> GuildOrDmId -> LocalState -> LoggedIn2 -> LoadedFrontend -> Element FrontendMsg
thread isMobile name guildOrDmIdNoThread local loggedIn model =
    channelHeader
        isMobile
        True
        (case guildOrDmIdNoThread of
            GuildOrDmId_Dm otherUserId ->
                Ui.row
                    [ Ui.height Ui.fill ]
                    [ if otherUserId == local.localUser.session.userId then
                        privateChatWithYourself isMobile (Route.toChannelHeaderTab model.route) local

                      else
                        privateChatWith isMobile (Route.toChannelHeaderTab model.route) otherUserId local name
                    , drawButton isMobile (Route.toChannelHeaderTab model.route)
                    ]

            GuildOrDmId_Guild _ _ ->
                Ui.row
                    [ Ui.Font.color MyUi.font1, Ui.spacing 2, Ui.clipWithEllipsis, Ui.height Ui.fill ]
                    [ Ui.el [ MyUi.noShrinking, Ui.width Ui.shrink ] (Ui.html Icons.hashtag)
                    , Ui.text name
                    , Ui.row
                        [ Ui.width Ui.shrink, Ui.alignRight, Ui.height Ui.fill ]
                        [ drawButton isMobile (Route.toChannelHeaderTab model.route)
                        , showFilesButton
                        ]
                    ]
        )
        (tabBodyView local loggedIn model)


discordChannel : Bool -> String -> DiscordGuildOrDmId -> LocalState -> LoggedIn2 -> LoadedFrontend -> Element FrontendMsg
discordChannel isMobile name guildOrDmIdNoThread local loggedIn model =
    let
        currentChannelHeaderTab =
            Route.toChannelHeaderTab model.route
    in
    channelHeader
        isMobile
        True
        (case guildOrDmIdNoThread of
            DiscordGuildOrDmId_Dm data ->
                Ui.row
                    [ Ui.height Ui.fill ]
                    [ if chattingWithYourself data local then
                        privateChatWithYourself isMobile currentChannelHeaderTab local

                      else
                        discordPrivateChatWith isMobile currentChannelHeaderTab name
                    , drawButton isMobile currentChannelHeaderTab
                    ]

            DiscordGuildOrDmId_Guild _ _ _ ->
                Ui.row
                    [ Ui.Font.color MyUi.font1, Ui.spacing 2, Ui.clipWithEllipsis, Ui.height Ui.fill ]
                    [ channelHeaderTabRow
                        isMobile
                        (Dom.id "guild_openChannelDescription")
                        DmChannelHeaderTab_ChannelDescription
                        currentChannelHeaderTab
                        [ Ui.el [ MyUi.noShrinking, Ui.width Ui.shrink ] (Ui.html Icons.hashtag)
                        , Ui.text name
                        ]
                    , Ui.row
                        [ Ui.width Ui.shrink, Ui.alignRight, Ui.height Ui.fill ]
                        [ drawButton isMobile currentChannelHeaderTab
                        , showFilesButton
                        ]
                    ]
        )
        (tabBodyView local loggedIn model)


discordThread : Bool -> String -> DiscordGuildOrDmId -> LocalState -> LoggedIn2 -> LoadedFrontend -> Element FrontendMsg
discordThread isMobile name guildOrDmIdNoThread local loggedIn model =
    channelHeader
        isMobile
        True
        (case guildOrDmIdNoThread of
            DiscordGuildOrDmId_Dm data ->
                if chattingWithYourself data local then
                    privateChatWithYourself isMobile (Route.toChannelHeaderTab model.route) local

                else
                    discordPrivateChatWith isMobile (Route.toChannelHeaderTab model.route) name

            DiscordGuildOrDmId_Guild _ _ _ ->
                Ui.row
                    [ Ui.Font.color MyUi.font1, Ui.spacing 2, Ui.clipWithEllipsis, Ui.contentCenterY, Ui.height Ui.fill ]
                    [ Ui.el [ MyUi.noShrinking, Ui.width Ui.shrink ] (Ui.html Icons.hashtag)
                    , Ui.text name
                    , Ui.row
                        [ Ui.width Ui.shrink, Ui.alignRight, Ui.height Ui.fill ]
                        [ drawButton isMobile (Route.toChannelHeaderTab model.route)
                        , showFilesButton
                        ]
                    ]
        )
        (tabBodyView local loggedIn model)


chattingWithYourself : DiscordGuildOrDmId_DmData -> LocalState -> Bool
chattingWithYourself data local =
    case SeqDict.get data.channelId local.discordDmChannels of
        Just channel2 ->
            NonemptyDict.all
                (\userId _ -> LinkedAndOtherDiscordUsers.isLinkedUser userId local.localUser.discordUsers)
                channel2.members

        Nothing ->
            False


{-| Toggles a mode where the user can draw freehand on top of messages.
Only available on non-mobile since it requires a mouse.
-}
drawButton : Bool -> Maybe DmChannelHeaderTab -> Element FrontendMsg
drawButton isMobile currentTab =
    if isMobile then
        Ui.none

    else
        channelHeaderTab
            isMobile
            (Dom.id "channelHeader_drawOnMessages")
            DmChannelHeaderTab_Draw
            currentTab
            (Ui.el
                [ Ui.width (Ui.px 24), Ui.Accessibility.description "Draw on top of messages" ]
                (Ui.html Icons.paintbrush)
            )


showFilesButton : Element FrontendMsg
showFilesButton =
    MyUi.elButton
        (Dom.id "guild_showFiles")
        (PressedLink Route.TextEditorRoute)
        [ Ui.alignRight
        , Ui.width (Ui.px 32)
        , Ui.paddingXY 4 0
        , Ui.height Ui.fill
        , Ui.contentCenterY
        , Ui.Font.color MyUi.font3
        ]
        (Ui.html Icons.document)


channelHeader : Bool -> Bool -> Element FrontendMsg -> Maybe (Element FrontendMsg) -> Element FrontendMsg
channelHeader isMobile2 includeShowMembers content tabContent =
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
                        , MyUi.htmlStyle "z-index" "20"
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
            (if isMobile2 then
                [ headerBackButton (Dom.id "guild_headerBackButton") PressedChannelHeaderBackButton
                , Ui.el [ Ui.height Ui.fill, Ui.contentCenterY ] content
                , if includeShowMembers then
                    MyUi.elButton
                        (Dom.id "guild_showMembers")
                        PressedShowMembers
                        [ Ui.alignRight
                        , Ui.width (Ui.px (24 + 24))
                        , Ui.height Ui.fill
                        , Ui.paddingXY 12 0
                        , Ui.contentCenterY
                        ]
                        (Ui.html Icons.users)

                  else
                    Ui.none
                ]

             else
                [ Ui.el
                    [ Ui.paddingWith { left = 16, right = 8, top = 0, bottom = 0 }
                    , Ui.contentCenterY
                    , Ui.height Ui.fill
                    ]
                    content
                ]
            )
        ]


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
        ]
        (Ui.html (Icons.arrowLeft 16))


channelHeaderTabRow :
    Bool
    -> HtmlId
    -> DmChannelHeaderTab
    -> Maybe DmChannelHeaderTab
    -> List (Element FrontendMsg)
    -> Element FrontendMsg
channelHeaderTabRow isMobile htmlId tab currentTab content =
    MyUi.rowButton
        htmlId
        (PressedChannelHeaderTab tab)
        (Ui.spacing 2 :: MyUi.prewrap :: channelHeaderTabAttributes 4 8 isMobile tab currentTab)
        content


channelHeaderTabAttributes : Int -> Int -> Bool -> DmChannelHeaderTab -> Maybe DmChannelHeaderTab -> List (Ui.Attribute msg)
channelHeaderTabAttributes paddingLeft paddingRight isMobile tab currentTab =
    let
        isSelected =
            case currentTab of
                Just currentTab2 ->
                    Route.sameChannelHeaderTab tab currentTab2

                Nothing ->
                    False
    in
    [ Ui.width Ui.shrink
    , Ui.height Ui.fill
    , Ui.paddingWith { left = paddingLeft, right = paddingRight, top = 4, bottom = 4 }
    , Ui.roundedWith { topLeft = 8, topRight = 8, bottomLeft = 0, bottomRight = 0 }
    , Ui.attrIf isSelected (Ui.background MyUi.tabBackground)
    , Ui.attrIf isSelected (MyUi.outwardBottomCorner 8 True MyUi.tabBackground)
    , Ui.attrIf isSelected (MyUi.outwardBottomCorner 8 False MyUi.tabBackground)
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
    -> DmChannelHeaderTab
    -> Maybe DmChannelHeaderTab
    -> Element FrontendMsg
    -> Element FrontendMsg
channelHeaderTab isMobile htmlId tab currentTab content =
    MyUi.elButton htmlId (PressedChannelHeaderTab tab) (channelHeaderTabAttributes 16 16 isMobile tab currentTab) content


privateChatWithYourself : Bool -> Maybe DmChannelHeaderTab -> LocalState -> Element FrontendMsg
privateChatWithYourself isMobile currentTab local =
    Ui.row
        [ Ui.Font.color MyUi.font1, Ui.spacing 6, Ui.height Ui.fill ]
        [ channelHeaderTab
            isMobile
            (Dom.id "guild_openDescription")
            DmChannelHeaderTab_ChannelDescription
            currentTab
            (Ui.text "Chat with yourself")
        , Ui.row
            [ Ui.width Ui.shrink, Ui.alignRight, Ui.height Ui.fill ]
            [ Ui.Lazy.lazy5 voiceChatButton isMobile currentTab local.localUser.session.userId local.localUser local.calls
            , Ui.Lazy.lazy4 gameButton isMobile currentTab local.localUser.session.userId SeqDict.empty
            ]
        ]


privateChatWith : Bool -> Maybe DmChannelHeaderTab -> Id UserId -> LocalState -> String -> Element FrontendMsg
privateChatWith isMobile currentTab otherUserId local name =
    Ui.row
        [ Ui.Font.color MyUi.font1, Ui.spacing 6, Ui.height Ui.fill ]
        [ channelHeaderTab
            isMobile
            (Dom.id "guild_openDescription")
            DmChannelHeaderTab_ChannelDescription
            currentTab
            (Ui.row [ Ui.Font.exactWhitespace ] [ Ui.text "Chat with ", Ui.el [ Ui.Font.color MyUi.font1 ] (Ui.text name) ])
        , Ui.row
            [ Ui.width Ui.shrink, Ui.alignRight, Ui.height Ui.fill ]
            [ Ui.Lazy.lazy5 voiceChatButton isMobile currentTab otherUserId local.localUser local.calls
            , SeqDict.get otherUserId local.dmChannels
                |> Maybe.map .games
                |> Maybe.withDefault SeqDict.empty
                |> Ui.Lazy.lazy4 gameButton isMobile currentTab local.localUser.session.userId
            ]
        ]


gameButton :
    Bool
    -> Maybe DmChannelHeaderTab
    -> Id UserId
    -> SeqDict (Id ChannelMessageId) Game.MatchData
    -> Element FrontendMsg
gameButton isMobile currentTab userId goMatches =
    let
        viewingGo : Bool
        viewingGo =
            case currentTab of
                Just (DmChannelHeaderTab_Games _) ->
                    True

                _ ->
                    False

        hasPendingTurn =
            Game.hasPendingTurn userId goMatches
    in
    channelHeaderTab
        isMobile
        (Dom.id "guild_openGamesTab")
        (SeqSet.toList hasPendingTurn |> List.reverse |> List.head |> DmChannelHeaderTab_Games)
        currentTab
        (Ui.el
            [ Ui.width Ui.shrink
            , Ui.Font.bold
            , case ( viewingGo, SeqSet.isEmpty hasPendingTurn ) of
                ( False, False ) ->
                    Ui.el
                        [ Ui.width (Ui.px 10)
                        , Ui.height (Ui.px 10)
                        , Ui.background MyUi.alertColor
                        , Ui.rounded 5
                        , Ui.border 2
                        , Ui.borderColor MyUi.background1
                        , Ui.move { x = -3, y = 3, z = 0 }
                        , Ui.alignRight
                        , Ui.Accessibility.description "Your turn"
                        , Ui.htmlAttribute (Dom.idToAttribute (Dom.id "guild_goMatchTurnDot"))
                        ]
                        Ui.none
                        |> Ui.inFront

                _ ->
                    Ui.noAttr
            ]
            (Ui.html Icons.go)
        )


voiceChatButton : Bool -> Maybe DmChannelHeaderTab -> Id UserId -> LocalUser -> Call.Local -> Element FrontendMsg
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
        , channelHeaderTab
            isMobile
            (Dom.id "guild_voiceChat")
            DmChannelHeaderTab_VoiceChat
            currentTab
            (Ui.html Icons.phone)
        ]


discordPrivateChatWith : Bool -> Maybe DmChannelHeaderTab -> String -> Element FrontendMsg
discordPrivateChatWith isMobile currentTab name =
    Ui.row
        [ Ui.Font.color MyUi.font1, Ui.spacing 6, Ui.height Ui.fill ]
        [ channelHeaderTab
            isMobile
            (Dom.id "guild_openDescription")
            DmChannelHeaderTab_ChannelDescription
            currentTab
            (Ui.row [ Ui.Font.exactWhitespace ] [ Ui.text "Chat with ", Ui.el [ Ui.Font.color MyUi.font1 ] (Ui.text name) ])
        ]


tabBodyView : LocalState -> LoggedIn2 -> LoadedFrontend -> Maybe (Element FrontendMsg)
tabBodyView local loggedIn model =
    case model.route of
        GuildRoute guildId channelRoute ->
            case channelRoute of
                ChannelRoute channelId _ (Just tab) ->
                    case tab of
                        DmChannelHeaderTab_ChannelDescription ->
                            case LocalState.getGuildAndChannel guildId channelId local of
                                Just ( _, channel2 ) ->
                                    Just (channelDescriptionView (Just channel2.name) (ChannelDescription.toString channel2.description))

                                Nothing ->
                                    Nothing

                        DmChannelHeaderTab_VoiceChat ->
                            Nothing

                        DmChannelHeaderTab_Games _ ->
                            Nothing

                        DmChannelHeaderTab_Draw ->
                            drawingTabView loggedIn.drawingMode local |> Just

                ChannelRoute _ _ _ ->
                    Nothing

                NewChannelRoute ->
                    Nothing

                EditChannelRoute _ ->
                    Nothing

                GuildSettingsRoute ->
                    Nothing

                JoinRoute _ ->
                    Nothing

        DmRoute dmRoute ->
            case DmChannel.otherUserId local.localUser.session.userId dmRoute.channelId of
                Just otherUserId ->
                    case dmRoute.tab of
                        Just (DmChannelHeaderTab_Games maybeMatchId) ->
                            Game.view
                                model.time
                                model.windowSize
                                model.lastCopied
                                local.localUser
                                otherUserId
                                maybeMatchId
                                (SeqDict.get otherUserId local.dmChannels |> Maybe.withDefault DmChannel.frontendInit |> .games)
                                (SeqDict.get ( otherUserId, maybeMatchId ) loggedIn.currentDmGame)
                                |> Ui.map GameMsg
                                |> Just

                        Just DmChannelHeaderTab_VoiceChat ->
                            Call.view model.windowSize (DmRoomId otherUserId) local.calls loggedIn.voiceChat
                                |> Ui.map VoiceChatMsg
                                |> Just

                        Just DmChannelHeaderTab_ChannelDescription ->
                            channelDescriptionView
                                Nothing
                                (if otherUserId == local.localUser.session.userId then
                                    "A channel where you can write things down you want to remember."

                                 else
                                    "A private channel for just you and "
                                        ++ User.toString otherUserId local.localUser.otherUsers
                                )
                                |> Just

                        Just DmChannelHeaderTab_Draw ->
                            drawingTabView loggedIn.drawingMode local |> Just

                        Nothing ->
                            Nothing

                Nothing ->
                    Nothing

        HomePageRoute ->
            Nothing

        AdminRoute _ ->
            Nothing

        DiscordGuildRoute routeData ->
            case routeData.channelRoute of
                DiscordChannel_ChannelRoute channelId _ (Just tab) ->
                    case tab of
                        DmChannelHeaderTab_ChannelDescription ->
                            case LocalState.getDiscordGuildAndChannel routeData.guildId channelId local of
                                Just ( _, channel2 ) ->
                                    Just (channelDescriptionView (Just channel2.name) (ChannelDescription.toString channel2.description))

                                Nothing ->
                                    Nothing

                        DmChannelHeaderTab_VoiceChat ->
                            Nothing

                        DmChannelHeaderTab_Games _ ->
                            Nothing

                        DmChannelHeaderTab_Draw ->
                            drawingTabView loggedIn.drawingMode local |> Just

                DiscordChannel_ChannelRoute _ _ _ ->
                    Nothing

                DiscordChannel_NewChannelRoute ->
                    Nothing

                DiscordChannel_EditChannelRoute _ ->
                    Nothing

                DiscordChannel_GuildSettingsRoute ->
                    Nothing

        DiscordDmRoute routeData ->
            case routeData.tab of
                Just DmChannelHeaderTab_ChannelDescription ->
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

                Just DmChannelHeaderTab_Draw ->
                    drawingTabView loggedIn.drawingMode local |> Just

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


drawingCanUndoOrRedo : AnyGuildOrDmId -> Drawing.AnchorType -> LocalState -> ( Bool, Bool )
drawingCanUndoOrRedo guildOrDmId anchor local =
    let
        noThreadHelper : userId -> Drawing.MessageAnchor -> Id messageId -> { a | messages : Array (MessageState messageId userId) } -> ( Bool, Bool )
        noThreadHelper userId anchor2 messageId channel2 =
            case DmChannel.getArray messageId channel2.messages of
                Just (MessageLoaded message) ->
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
drawingTabView : Model -> LocalState -> Element FrontendMsg
drawingTabView model local =
    Ui.row
        [ Ui.paddingXY 16 12
        , Ui.background MyUi.tabBackground
        , Ui.Font.color MyUi.font2
        , Ui.spacing 16
        , Ui.height (Ui.px 80)
        , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
        , Ui.borderColor MyUi.border2
        ]
        (case model of
            NoSelectedAnchor ->
                [ Ui.text "Click on a profile image, timestamp, or attachment to anchor your drawing to it." ]

            SelectedAnchor selected ->
                let
                    ( canUndo, canRedo ) =
                        drawingCanUndoOrRedo selected.guildOrDmId selected.anchorType local
                in
                [ Ui.text "Draw with the mouse. Press Escape or the pencil tab when you're done."
                , Drawing.undoRedoButton Drawing.undoButtonId Drawing.PressedUndo "Undo" canUndo
                , Drawing.undoRedoButton Drawing.redoButtonId Drawing.PressedRedo "Redo" canRedo
                , Drawing.undoRedoButton
                    Drawing.zoomButtonId
                    Drawing.PressedZoom
                    (if selected.zoom == 1 then
                        "Zoom in"

                     else
                        "Zoom out"
                    )
                    True
                ]
        )
        |> Ui.map DrawingMsg


channelDescriptionView : Maybe ChannelName -> String -> Element FrontendMsg
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
