module ChannelHeader exposing
    ( channel
    , channelHeader
    , chattingWithYourself
    , discordChannel
    , discordThread
    , headerBackButton
    , thread
    )

import Array exposing (Array)
import Call exposing (RoomId(..))
import ChannelDescription
import ChannelName exposing (ChannelName)
import DmChannel
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Go
import GuildIcon
import Html.Attributes
import Icons
import Id exposing (ChannelMessageId, DiscordGuildOrDmId(..), DiscordGuildOrDmId_DmData, GuildOrDmId(..), Id, UserId)
import LocalState exposing (LocalState)
import MyUi
import NonemptyDict
import NonemptySet
import OneOrGreater exposing (OneOrGreater)
import PersonName
import Route exposing (ChannelRoute(..), DiscordChannelRoute(..), DmChannelHeaderTab(..), Route(..))
import SeqDict exposing (SeqDict)
import SeqDictHelper
import SeqSet
import Svg
import Svg.Attributes
import Types exposing (FrontendMsg(..), LoadedFrontend, LoggedIn2)
import Ui exposing (Element)
import Ui.Accessibility
import Ui.Anim
import Ui.Font
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
                if otherUserId == local.localUser.session.userId then
                    privateChatWithYourself isMobile currentChannelHeaderTab local

                else
                    privateChatWith isMobile currentChannelHeaderTab otherUserId local name

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
                    , showFilesButton
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
                if otherUserId == local.localUser.session.userId then
                    privateChatWithYourself isMobile (Route.toChannelHeaderTab model.route) local

                else
                    privateChatWith isMobile (Route.toChannelHeaderTab model.route) otherUserId local name

            GuildOrDmId_Guild _ _ ->
                Ui.row
                    [ Ui.Font.color MyUi.font1, Ui.spacing 2, Ui.clipWithEllipsis ]
                    [ Ui.el [ MyUi.noShrinking, Ui.width Ui.shrink ] (Ui.html Icons.hashtag)
                    , Ui.text name
                    , showFilesButton
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
                if chattingWithYourself data local then
                    privateChatWithYourself isMobile Nothing local

                else
                    discordPrivateChatWith name

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
                    , showFilesButton
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
                    privateChatWithYourself isMobile Nothing local

                else
                    discordPrivateChatWith name

            DiscordGuildOrDmId_Guild _ _ _ ->
                Ui.row
                    [ Ui.Font.color MyUi.font1, Ui.spacing 2, Ui.clipWithEllipsis, Ui.contentCenterY, Ui.height Ui.fill ]
                    [ Ui.el [ MyUi.noShrinking, Ui.width Ui.shrink ] (Ui.html Icons.hashtag)
                    , Ui.text name
                    , showFilesButton
                    ]
        )
        (tabBodyView local loggedIn model)


chattingWithYourself : DiscordGuildOrDmId_DmData -> LocalState -> Bool
chattingWithYourself data local =
    case SeqDict.get data.channelId local.discordDmChannels of
        Just channel2 ->
            NonemptyDict.all (\userId _ -> SeqDict.member userId local.localUser.linkedDiscordUsers) channel2.members

        Nothing ->
            False


showFilesButton : Element FrontendMsg
showFilesButton =
    MyUi.elButton
        (Dom.id "guild_showFiles")
        (PressedLink Route.TextEditorRoute)
        [ Ui.alignRight
        , Ui.width (Ui.px 32)
        , Ui.paddingXY 4 0
        , Ui.height Ui.fill
        ]
        (Ui.html Icons.document)


channelHeader : Bool -> Bool -> Element FrontendMsg -> Maybe (Element FrontendMsg) -> Element FrontendMsg
channelHeader isMobile2 includeShowMembers content tabContent =
    Ui.column
        [ Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
        , Ui.borderColor MyUi.border2
        , Ui.background MyUi.background3
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
        , case tabContent of
            Just tabContent2 ->
                tabContent2

            Nothing ->
                Ui.none
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
    , Ui.attrIf isSelected (outwardBottomCorner 8 True)
    , Ui.attrIf isSelected (outwardBottomCorner 8 False)
    , Ui.contentCenterY
    , Ui.Font.color
        (if isSelected then
            MyUi.font1

         else
            MyUi.font3
        )
    , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
    ]


outwardBottomCorner : Int -> Bool -> Ui.Attribute msg
outwardBottomCorner radius isLeft =
    let
        overlap : Int
        overlap =
            1

        r : String
        r =
            String.fromInt radius

        w : String
        w =
            String.fromInt (radius + overlap)

        path : String
        path =
            if isLeft then
                "M " ++ w ++ ",0 L " ++ r ++ ",0 A " ++ r ++ " " ++ r ++ " 0 0 1 0," ++ r ++ " L " ++ w ++ "," ++ r ++ " Z"

            else
                "M 0,0 L " ++ String.fromInt overlap ++ ",0 A " ++ r ++ " " ++ r ++ " 0 0 0 " ++ w ++ "," ++ r ++ " L 0," ++ r ++ " Z"

        translate : String
        translate =
            if isLeft then
                "translate(-" ++ r ++ "px, 0)"

            else
                "translate(" ++ r ++ "px, 0)"
    in
    Ui.inFront
        (Ui.el
            [ Ui.alignBottom
            , if isLeft then
                Ui.alignLeft

              else
                Ui.alignRight
            , Ui.move { x = 0, y = 1, z = 0 }
            , Ui.width (Ui.px (radius + overlap))
            , Ui.height (Ui.px radius)
            , Ui.Font.color MyUi.tabBackground
            , MyUi.htmlStyle "transform" translate
            , MyUi.htmlStyle "pointer-events" "none"
            ]
            (Svg.svg
                [ Svg.Attributes.width w
                , Svg.Attributes.height r
                , Svg.Attributes.viewBox ("0 0 " ++ w ++ " " ++ r)
                , Svg.Attributes.style "display:block"
                ]
                [ Svg.path
                    [ Svg.Attributes.d path
                    , Svg.Attributes.fill "currentColor"
                    ]
                    []
                ]
                |> Ui.html
            )
        )


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
            [ voiceChatButton isMobile currentTab local.localUser.session.userId local.localUser local.calls
            , goGameButton isMobile currentTab local.localUser.session.userId SeqDict.empty
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
            [ voiceChatButton isMobile currentTab otherUserId local.localUser local.calls
            , SeqDict.get otherUserId local.dmChannels
                |> Maybe.map .goMatches
                |> Maybe.withDefault SeqDict.empty
                |> goGameButton isMobile currentTab local.localUser.session.userId
            ]
        ]


goGameButton :
    Bool
    -> Maybe DmChannelHeaderTab
    -> Id UserId
    -> SeqDict (Id ChannelMessageId) ( Go.ValidatedSetup, Array Go.ActionWithTime )
    -> Element FrontendMsg
goGameButton isMobile currentTab userId goMatches =
    let
        viewingGo : Bool
        viewingGo =
            case currentTab of
                Just (DmChannelHeaderTab_Go _) ->
                    True

                _ ->
                    False

        hasPendingTurn =
            Go.hasPendingTurn userId goMatches
    in
    channelHeaderTab
        isMobile
        (Dom.id "guild_openGoMatch")
        (SeqSet.toList hasPendingTurn |> List.reverse |> List.head |> DmChannelHeaderTab_Go)
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
                    NonemptySet.foldl
                        (\( userId, _ ) dict -> SeqDictHelper.increment userId dict)
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


discordPrivateChatWith : String -> Element FrontendMsg
discordPrivateChatWith name =
    Ui.row
        [ Ui.Font.color MyUi.font1, Ui.spacing 6, Ui.height Ui.fill ]
        [ Ui.el
            [ Ui.Font.color MyUi.font3
            , Ui.width Ui.shrink
            , Ui.Font.exactWhitespace
            , Ui.clipWithEllipsis
            ]
            (Ui.text "Chat with ")
        , Ui.text name
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

                        DmChannelHeaderTab_Go _ ->
                            Nothing

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
                        Just (DmChannelHeaderTab_Go maybeMatchId) ->
                            Go.view
                                model.windowSize
                                local.localUser
                                otherUserId
                                maybeMatchId
                                (SeqDict.get otherUserId local.dmChannels |> Maybe.withDefault DmChannel.frontendInit |> .goMatches)
                                (SeqDict.get ( otherUserId, maybeMatchId ) loggedIn.currentDmGoMatch)
                                |> Ui.map GoMsg
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

                        DmChannelHeaderTab_Go _ ->
                            Nothing

                DiscordChannel_ChannelRoute _ _ _ ->
                    Nothing

                DiscordChannel_NewChannelRoute ->
                    Nothing

                DiscordChannel_EditChannelRoute _ ->
                    Nothing

                DiscordChannel_GuildSettingsRoute ->
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


channelDescriptionView : Maybe ChannelName -> String -> Element FrontendMsg
channelDescriptionView channelName description =
    Ui.column
        [ Ui.paddingXY 16 12
        , Ui.background MyUi.tabBackground
        , Ui.Font.color MyUi.font2
        , Ui.spacing 8
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
