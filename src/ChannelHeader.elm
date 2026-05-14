module ChannelHeader exposing (channelHeader, chattingWithYourself, conversationChannelHeader, discordChannelHeader, discordThreadChannelHeader, headerBackButton, threadChannelHeader)

import ChannelDescription exposing (ChannelDescription(..))
import ChannelName exposing (ChannelName)
import DmChannel
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Lamdera exposing (ClientId)
import Go
import GuildIcon
import Icons
import Id exposing (DiscordGuildOrDmId(..), DiscordGuildOrDmId_DmData, GuildOrDmId(..), Id, UserId)
import LocalState exposing (LocalState)
import MyUi
import NonemptyDict
import NonemptySet exposing (NonemptySet)
import OneOrGreater
import PersonName
import Route exposing (ChannelRoute(..), DmChannelHeaderTab(..), Route(..))
import SeqDict exposing (SeqDict)
import Types exposing (FrontendMsg(..), LoadedFrontend, LoggedIn2)
import Ui exposing (Element)
import Ui.Anim
import Ui.Font
import User exposing (LocalUser)
import VoiceChat exposing (RoomId(..))


conversationChannelHeader :
    Bool
    -> String
    -> GuildOrDmId
    -> LocalState
    -> LoggedIn2
    -> LoadedFrontend
    -> Element FrontendMsg
conversationChannelHeader isMobile name guildOrDmIdNoThread local loggedIn model =
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
                    [ Ui.Font.color MyUi.font1, Ui.spacing 6, Ui.height Ui.fill ]
                    (if otherUserId == local.localUser.session.userId then
                        privateChatWithYourself isMobile currentChannelHeaderTab local

                     else
                        privateChatWith isMobile currentChannelHeaderTab otherUserId local name
                    )

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
        (channelHeaderTabView local loggedIn model)


threadChannelHeader :
    Bool
    -> String
    -> GuildOrDmId
    -> LocalState
    -> LoggedIn2
    -> LoadedFrontend
    -> Element FrontendMsg
threadChannelHeader isMobile name guildOrDmIdNoThread local loggedIn model =
    channelHeader
        isMobile
        True
        (case guildOrDmIdNoThread of
            GuildOrDmId_Dm otherUserId ->
                Ui.row
                    [ Ui.Font.color MyUi.font1, Ui.spacing 6, Ui.height Ui.fill ]
                    (if otherUserId == local.localUser.session.userId then
                        privateChatWithYourself isMobile (Route.toChannelHeaderTab model.route) local

                     else
                        privateChatWith isMobile (Route.toChannelHeaderTab model.route) otherUserId local name
                    )

            GuildOrDmId_Guild _ _ ->
                Ui.row
                    [ Ui.Font.color MyUi.font1, Ui.spacing 2, Ui.clipWithEllipsis ]
                    [ Ui.el [ MyUi.noShrinking, Ui.width Ui.shrink ] (Ui.html Icons.hashtag)
                    , Ui.text name
                    , showFilesButton
                    ]
        )
        (channelHeaderTabView local loggedIn model)


discordChannelHeader : Bool -> String -> DiscordGuildOrDmId -> LocalState -> Element FrontendMsg
discordChannelHeader isMobile name guildOrDmIdNoThread local =
    channelHeader
        isMobile
        True
        (case guildOrDmIdNoThread of
            DiscordGuildOrDmId_Dm data ->
                Ui.row
                    [ Ui.Font.color MyUi.font1, Ui.spacing 6, Ui.height Ui.fill ]
                    (if chattingWithYourself data local then
                        privateChatWithYourself isMobile Nothing local

                     else
                        discordPrivateChatWith name
                    )

            DiscordGuildOrDmId_Guild _ _ _ ->
                Ui.row
                    [ Ui.Font.color MyUi.font1, Ui.spacing 2, Ui.clipWithEllipsis ]
                    [ Ui.el [ MyUi.noShrinking, Ui.width Ui.shrink ] (Ui.html Icons.hashtag)
                    , Ui.text name
                    , showFilesButton
                    ]
        )
        Nothing


discordThreadChannelHeader : Bool -> String -> DiscordGuildOrDmId -> LocalState -> Element FrontendMsg
discordThreadChannelHeader isMobile name guildOrDmIdNoThread local =
    channelHeader
        isMobile
        True
        (case guildOrDmIdNoThread of
            DiscordGuildOrDmId_Dm data ->
                Ui.row
                    [ Ui.Font.color MyUi.font1, Ui.spacing 6, Ui.height Ui.fill ]
                    (if chattingWithYourself data local then
                        privateChatWithYourself isMobile Nothing local

                     else
                        discordPrivateChatWith name
                    )

            DiscordGuildOrDmId_Guild _ _ _ ->
                Ui.row
                    [ Ui.Font.color MyUi.font1, Ui.spacing 2, Ui.clipWithEllipsis ]
                    [ Ui.el [ MyUi.noShrinking, Ui.width Ui.shrink ] (Ui.html Icons.hashtag)
                    , Ui.text name
                    , showFilesButton
                    ]
        )
        Nothing


chattingWithYourself : DiscordGuildOrDmId_DmData -> LocalState -> Bool
chattingWithYourself data local =
    case SeqDict.get data.channelId local.discordDmChannels of
        Just channel ->
            NonemptyDict.all (\userId _ -> SeqDict.member userId local.localUser.linkedDiscordUsers) channel.members

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
                , content
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
                [ Ui.el [ Ui.paddingWith { left = 16, right = 8, top = 0, bottom = 0 }, Ui.height Ui.fill ] content ]
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
    , Ui.attrIf isSelected (Ui.background MyUi.background1)
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


privateChatWithYourself : Bool -> Maybe DmChannelHeaderTab -> LocalState -> List (Element FrontendMsg)
privateChatWithYourself isMobile currentTab local =
    [ channelHeaderTab
        isMobile
        (Dom.id "guild_openDescription")
        DmChannelHeaderTab_ChannelDescription
        currentTab
        (Ui.text "Private chat with yourself")
    , Ui.row
        [ Ui.width Ui.shrink, Ui.alignRight, Ui.height Ui.fill ]
        [ voiceChatButton isMobile currentTab local.localUser.session.userId local.localUser local.calls
        , goGameButton isMobile currentTab
        ]
    ]


privateChatWith : Bool -> Maybe DmChannelHeaderTab -> Id UserId -> LocalState -> String -> List (Element FrontendMsg)
privateChatWith isMobile currentTab otherUserId local name =
    [ channelHeaderTab
        isMobile
        (Dom.id "guild_openDescription")
        DmChannelHeaderTab_ChannelDescription
        currentTab
        (Ui.text "Private chat with ")
    , Ui.text name
    , Ui.row
        [ Ui.width Ui.shrink, Ui.alignRight, Ui.height Ui.fill ]
        [ voiceChatButton isMobile currentTab otherUserId local.localUser local.calls
        , goGameButton isMobile currentTab
        ]
    ]


goGameButton : Bool -> Maybe DmChannelHeaderTab -> Element FrontendMsg
goGameButton isMobile currentTab =
    channelHeaderTab
        isMobile
        (Dom.id "guild_openGoMatch")
        (DmChannelHeaderTab_Go Nothing)
        currentTab
        (Ui.el [ Ui.width Ui.shrink, Ui.Font.bold ] (Ui.html Icons.go))


voiceChatButton : Bool -> Maybe DmChannelHeaderTab -> Id UserId -> LocalUser -> VoiceChat.Local -> Element FrontendMsg
voiceChatButton isMobile currentTab otherUserId localUser calls =
    let
        joinedUsers : SeqDict (Id UserId) (NonemptySet ClientId)
        joinedUsers =
            case SeqDict.get (DmRoomId otherUserId) calls.voiceChats of
                Just voiceChat ->
                    NonemptySet.foldl
                        (\( userId, clientId ) dict ->
                            SeqDict.update
                                userId
                                (\maybe ->
                                    case maybe of
                                        Just nonempty ->
                                            NonemptySet.insert clientId nonempty |> Just

                                        Nothing ->
                                            NonemptySet.singleton clientId |> Just
                                )
                                dict
                        )
                        SeqDict.empty
                        voiceChat

                Nothing ->
                    SeqDict.empty

        joined : Element msg
        joined =
            joinedUsers
                |> SeqDict.toList
                |> List.map
                    (\( userId, clientIds ) ->
                        let
                            count =
                                NonemptySet.size clientIds
                        in
                        Ui.el
                            [ case ( count > 1, OneOrGreater.fromInt count ) of
                                ( True, Just count2 ) ->
                                    GuildIcon.notificationHelper
                                        MyUi.background1
                                        MyUi.white
                                        MyUi.border1
                                        2
                                        -2
                                        count2

                                _ ->
                                    Ui.noAttr
                            ]
                            (case User.getUser userId localUser of
                                Just user ->
                                    User.profileImage user.icon

                                Nothing ->
                                    User.profileImage Nothing
                            )
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
            (Ui.row
                [ Ui.spacing 2, Ui.width Ui.shrink, Ui.contentCenterY ]
                [ Ui.el [ Ui.width (Ui.px 20) ] (Ui.html Icons.phone)
                , if VoiceChat.hasJoined (DmRoomId otherUserId) calls then
                    Ui.el
                        [ Ui.width (Ui.px 8)
                        , Ui.height (Ui.px 8)
                        , Ui.background (Ui.rgb 40 190 80)
                        , Ui.rounded 4
                        ]
                        Ui.none

                  else
                    Ui.none
                ]
            )
        ]


discordPrivateChatWith : String -> List (Element FrontendMsg)
discordPrivateChatWith name =
    [ Ui.el
        [ Ui.Font.color MyUi.font3
        , Ui.width Ui.shrink
        , MyUi.prewrap
        , Ui.clipWithEllipsis
        ]
        (Ui.text "Private chat with ")
    , Ui.text name
    ]


channelHeaderTabView : LocalState -> LoggedIn2 -> LoadedFrontend -> Maybe (Element FrontendMsg)
channelHeaderTabView local loggedIn model =
    case model.route of
        GuildRoute guildId channelRoute ->
            case channelRoute of
                ChannelRoute channelId _ (Just tab) ->
                    case tab of
                        DmChannelHeaderTab_ChannelDescription ->
                            case LocalState.getGuildAndChannel guildId channelId local of
                                Just ( _, channel ) ->
                                    Just (channelDescriptionView (Just channel.name) (ChannelDescription.toString channel.description))

                                Nothing ->
                                    Nothing

                        DmChannelHeaderTab_VoiceChat ->
                            Nothing

                        DmChannelHeaderTab_Go maybeId ->
                            Nothing

                ChannelRoute channelId _ _ ->
                    Nothing

                NewChannelRoute ->
                    Nothing

                EditChannelRoute id ->
                    Nothing

                GuildSettingsRoute ->
                    Nothing

                JoinRoute secretId ->
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
                            VoiceChat.view model.windowSize (DmRoomId otherUserId) local.calls loggedIn.voiceChat
                                |> Ui.map VoiceChatMsg
                                |> Just

                        Just DmChannelHeaderTab_ChannelDescription ->
                            (if otherUserId == local.localUser.session.userId then
                                Ui.text "This is a channel all to yourself where you can write things down you want to remember."

                             else
                                "This is a private channel for just you and "
                                    ++ User.toString otherUserId local.localUser.otherUsers
                                    |> Ui.text
                            )
                                |> Just

                        Nothing ->
                            Nothing

                Nothing ->
                    Nothing

        HomePageRoute ->
            Nothing

        AdminRoute record ->
            Nothing

        DiscordGuildRoute discordGuildRouteData ->
            Nothing

        DiscordDmRoute dmRoute ->
            Nothing

        AiChatRoute ->
            Nothing

        SlackOAuthRedirect result ->
            Nothing

        TextEditorRoute ->
            Nothing

        LinkDiscord result ->
            Nothing


channelDescriptionView : Maybe ChannelName -> String -> Element FrontendMsg
channelDescriptionView channelName description =
    Ui.column
        [ Ui.paddingXY 16 12
        , Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
        , Ui.borderColor MyUi.border2
        , Ui.background MyUi.background1
        , Ui.Font.color MyUi.font2
        ]
        [ case channelName of
            Just channelName2 ->
                Ui.el [ Ui.Font.bold ] (Ui.text (ChannelName.toString channelName2))

            Nothing ->
                Ui.none
        , if String.isEmpty description then
            Ui.el [ Ui.Font.italic ] (Ui.text "No channel description")

          else
            Ui.text description
        ]
