module Pages.Guild exposing
    ( HighlightMessage(..)
    , IsHovered(..)
    , channelHeaderHeight
    , channelMessageHtmlId
    , channelTextInputId
    , conversationContainerId
    , dropdownButtonId
    , guildView
    , homePageLoggedInView
    , messageInputConfig
    , messageViewDecode
    , messageViewEncode
    , newGuildFormInit
    , repliedToUserId
    , threadMessageHtmlId
    )

import Array exposing (Array)
import Array.Extra
import Bitwise
import ChannelName
import Coord
import DmChannel exposing (DmChannel, LastTypedAt, Thread)
import Duration
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Emoji exposing (Emoji)
import Env
import FileStatus
import GuildIcon exposing (NotificationType(..))
import GuildName
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Icons
import Id exposing (ChannelId, ChannelMessageId, GuildId, GuildOrDmId(..), GuildOrDmIdNoThread(..), GuildOrDmIdWithMaybeMessage(..), Id, ThreadMessageId, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), UserId)
import Json.Decode
import List.Extra
import LocalState exposing (FrontendChannel, FrontendGuild, LocalState, LocalUser)
import Maybe.Extra
import Message exposing (Message(..), UserTextMessageData)
import MessageInput exposing (MentionUserDropdown, MsgConfig)
import MessageMenu
import MessageView exposing (MessageViewMsg(..))
import MyUi
import NonemptyDict
import NonemptySet exposing (NonemptySet)
import PersonName
import Quantity
import RichText
import Route exposing (ChannelRoute(..), Route(..))
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import String.Nonempty
import Time
import Touch
import Types exposing (Drag(..), EditMessage, EmojiSelector(..), FrontendMsg(..), LoadedFrontend, LoggedIn2, MessageHover(..), NewChannelForm, NewGuildForm)
import Ui exposing (Element)
import Ui.Anim
import Ui.Events
import Ui.Font
import Ui.Gradient
import Ui.Input
import Ui.Lazy
import Ui.Prose
import User exposing (BackendUser, FrontendUser)


repliedToUserId : Maybe (Id messageId) -> { a | messages : Array Message } -> Maybe (Id UserId)
repliedToUserId maybeRepliedTo channel =
    case maybeRepliedTo of
        Just repliedTo ->
            case LocalState.getArray repliedTo channel.messages of
                Just (UserTextMessage repliedToData) ->
                    Just repliedToData.createdBy

                Just (UserJoinedMessage _ joinedUser _) ->
                    Just joinedUser

                Just (DeletedMessage _) ->
                    Nothing

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


channelOrThreadHasNotifications :
    Id UserId
    -> Id messageId
    -> { a | messages : Array Message }
    -> NotificationType
channelOrThreadHasNotifications currentUserId lastViewed channel =
    Array.slice (Id.toInt lastViewed) (Array.length channel.messages) channel.messages
        |> Array.toList
        |> List.foldl
            (\message state ->
                case state of
                    NewMessageForUser ->
                        state

                    _ ->
                        case message of
                            UserTextMessage data ->
                                if data.createdBy == currentUserId then
                                    state

                                else if
                                    (repliedToUserId data.repliedTo channel == Just currentUserId)
                                        || RichText.mentionsUser currentUserId data.content
                                then
                                    NewMessageForUser

                                else
                                    NewMessage

                            UserJoinedMessage _ _ _ ->
                                NewMessage

                            DeletedMessage _ ->
                                state
            )
            NoNotification


guildHasNotifications : Id UserId -> BackendUser -> Id GuildId -> FrontendGuild -> NotificationType
guildHasNotifications currentUserId currentUser guildId guild =
    SeqDict.foldl
        (\channelId channel state ->
            case state of
                NewMessageForUser ->
                    state

                _ ->
                    let
                        state3 =
                            SeqDict.foldl
                                (\threadMessageIndex thread state2 ->
                                    case state2 of
                                        NewMessageForUser ->
                                            state2

                                        _ ->
                                            let
                                                lastViewed2 : Id ThreadMessageId
                                                lastViewed2 =
                                                    case SeqDict.get ( GuildOrDmId_Guild_NoThread guildId channelId, threadMessageIndex ) currentUser.lastViewedThreads of
                                                        Just id ->
                                                            Id.increment id

                                                        Nothing ->
                                                            Id.fromInt 0
                                            in
                                            case
                                                channelOrThreadHasNotifications currentUserId lastViewed2 thread
                                            of
                                                NoNotification ->
                                                    state2

                                                notification ->
                                                    notification
                                )
                                state
                                channel.threads

                        lastViewed : Id ChannelMessageId
                        lastViewed =
                            case SeqDict.get (GuildOrDmId_Guild_NoThread guildId channelId) currentUser.lastViewed of
                                Just id ->
                                    Id.increment id

                                Nothing ->
                                    Id.fromInt 0
                    in
                    case channelOrThreadHasNotifications currentUserId lastViewed channel of
                        NoNotification ->
                            state3

                        notification ->
                            notification
        )
        NoNotification
        guild.channels


canScroll : LoadedFrontend -> Bool
canScroll model =
    case model.drag of
        Dragging dragging ->
            not dragging.horizontalStart

        _ ->
            True


guildColumn :
    Bool
    -> Route
    -> Id UserId
    -> BackendUser
    -> SeqDict (Id GuildId) FrontendGuild
    -> Bool
    -> Element FrontendMsg
guildColumn isMobile route currentUserId currentUser guilds canScroll2 =
    Ui.el
        [ Ui.inFront
            (Ui.el
                [ Ui.backgroundGradient
                    [ Ui.Gradient.linear
                        (Ui.radians 0)
                        [ Ui.Gradient.percent 0 (Ui.rgba 0 0 0 0)
                        , Ui.Gradient.percent 100 MyUi.background1
                        ]
                    ]
                , MyUi.htmlStyle "height" ("calc(max(6px, " ++ MyUi.insetTop ++ "))")
                ]
                Ui.none
            )
        , Ui.width Ui.shrink
        , Ui.height Ui.fill
        ]
        (Ui.column
            [ Ui.spacing 4
            , Ui.width (Ui.px GuildIcon.fullWidth)
            , Ui.height Ui.fill
            , Ui.background MyUi.background1
            , scrollable canScroll2
            , Ui.htmlAttribute (Html.Attributes.class "disable-scrollbars")
            , MyUi.htmlStyle "padding" ("calc(max(6px, " ++ MyUi.insetTop ++ ")) 0 4px 0")
            , bounceScroll isMobile
            ]
            (GuildIcon.showFriendsButton (route == HomePageRoute) (PressedLink HomePageRoute)
                :: List.map
                    (\( guildId, guild ) ->
                        elLinkButton
                            (GuildRoute
                                guildId
                                (ChannelRoute
                                    (SeqDict.get guildId currentUser.lastChannelViewed
                                        |> Maybe.withDefault (LocalState.announcementChannel guild)
                                    )
                                    (NoThreadWithMaybeMessage Nothing)
                                )
                            )
                            []
                            (GuildIcon.view
                                (case route of
                                    GuildRoute a _ ->
                                        if a == guildId then
                                            GuildIcon.IsSelected

                                        else
                                            guildHasNotifications currentUserId currentUser guildId guild
                                                |> GuildIcon.Normal

                                    _ ->
                                        guildHasNotifications currentUserId currentUser guildId guild |> GuildIcon.Normal
                                )
                                guild
                            )
                    )
                    (SeqDict.toList guilds)
                ++ [ GuildIcon.addGuildButton (Dom.id "guild_createGuild") False PressedCreateGuild ]
            )
        )


elLinkButton : Route -> List (Ui.Attribute FrontendMsg) -> Element FrontendMsg -> Element FrontendMsg
elLinkButton route attributes content =
    MyUi.elButton
        (Route.encode route |> Dom.id)
        (PressedLink route)
        attributes
        content


rowLinkButton : Route -> List (Ui.Attribute FrontendMsg) -> List (Element FrontendMsg) -> Element FrontendMsg
rowLinkButton route attributes content =
    MyUi.rowButton
        (Route.encode route |> Dom.id)
        (PressedLink route)
        attributes
        content


loggedInAsView : LocalState -> Element FrontendMsg
loggedInAsView local =
    Ui.row
        [ Ui.Font.color MyUi.font2
        , Ui.borderColor MyUi.border1
        , Ui.borderWith { left = 0, bottom = 0, top = 1, right = 0 }
        , Ui.background MyUi.background1
        , MyUi.htmlStyle "padding" ("4px 4px calc(" ++ MyUi.insetBottom ++ " + 4px) 4px")
        ]
        [ Ui.text (PersonName.toString local.localUser.user.name)
        , MyUi.elButton
            (Dom.id "guild_showUserOptions")
            PressedShowUserOption
            [ Ui.width (Ui.px 30)
            , Ui.paddingXY 4 0
            , Ui.alignRight
            ]
            (Ui.html Icons.gear)
        ]


homePageLoggedInView :
    Maybe ( Id UserId, ThreadRouteWithMaybeMessage )
    -> LoadedFrontend
    -> LoggedIn2
    -> LocalState
    -> Element FrontendMsg
homePageLoggedInView maybeOtherUserId model loggedIn local =
    case loggedIn.newGuildForm of
        Just form ->
            newGuildFormView form

        Nothing ->
            if MyUi.isMobile model then
                Ui.row
                    [ Ui.height Ui.fill
                    , Ui.background MyUi.background1
                    ]
                    [ Ui.column
                        [ Ui.height Ui.fill
                        , case maybeOtherUserId of
                            Just ( otherUserId, threadRoute ) ->
                                dmChannelView otherUserId threadRoute loggedIn local model
                                    |> Ui.el
                                        [ Ui.height Ui.fill
                                        , Ui.background MyUi.background3
                                        , MyUi.htmlStyle "padding" (MyUi.insetTop ++ " 0 0 0")
                                        , sidebarOffsetAttr loggedIn model
                                        , Ui.heightMin 0
                                        , Ui.borderColor MyUi.border1
                                        , Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
                                        ]
                                    |> Ui.inFront

                            Nothing ->
                                Ui.noAttr
                        ]
                        [ Ui.row
                            [ Ui.height Ui.fill, Ui.heightMin 0 ]
                            [ Ui.Lazy.lazy6
                                guildColumn
                                True
                                model.route
                                local.localUser.userId
                                local.localUser.user
                                local.guilds
                                (canScroll model)
                            , friendsColumn True maybeOtherUserId local
                            ]
                        , loggedInAsView local
                        ]
                    ]

            else
                Ui.row
                    [ Ui.height Ui.fill
                    , Ui.background MyUi.background1
                    ]
                    [ Ui.column
                        [ Ui.height Ui.fill, Ui.width (Ui.px 300) ]
                        [ Ui.row
                            [ Ui.height Ui.fill, Ui.heightMin 0 ]
                            [ Ui.Lazy.lazy6
                                guildColumn
                                False
                                model.route
                                local.localUser.userId
                                local.localUser.user
                                local.guilds
                                (canScroll model)
                            , friendsColumn False maybeOtherUserId local
                            ]
                        , loggedInAsView local
                        ]
                    , case maybeOtherUserId of
                        Just ( otherUserId, threadRoute ) ->
                            dmChannelView otherUserId threadRoute loggedIn local model
                                |> Ui.el
                                    [ Ui.height Ui.fill
                                    , Ui.background MyUi.background3
                                    , Ui.heightMin 0
                                    , Ui.borderColor MyUi.border1
                                    , Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
                                    ]
                                |> Ui.el
                                    [ Ui.height Ui.fill
                                    , MyUi.htmlStyle "padding-top" MyUi.insetTop
                                    ]

                        Nothing ->
                            Ui.el [ Ui.Font.color MyUi.font1, Ui.contentCenterX ] Ui.none
                    ]


dmChannelView : Id UserId -> ThreadRouteWithMaybeMessage -> LoggedIn2 -> LocalState -> LoadedFrontend -> Element FrontendMsg
dmChannelView otherUserId threadRoute loggedIn local model =
    case LocalState.getUser otherUserId local.localUser of
        Just otherUser ->
            let
                dmChannel : DmChannel
                dmChannel =
                    SeqDict.get otherUserId local.dmChannels
                        |> Maybe.withDefault DmChannel.init
            in
            case threadRoute of
                ViewThreadWithMaybeMessage threadMessageIndex _ ->
                    SeqDict.get threadMessageIndex dmChannel.threads
                        |> Maybe.withDefault DmChannel.threadInit
                        |> conversationView
                            (SeqDict.get
                                ( GuildOrDmId_Dm_NoThread otherUserId, threadMessageIndex )
                                local.localUser.user.lastViewedThreads
                                |> Maybe.withDefault (Id.fromInt -1)
                                |> Id.changeType
                            )
                            (GuildOrDmId_Dm_WithMaybeMessage otherUserId threadRoute)
                            loggedIn
                            model
                            local
                            (PersonName.toString otherUser.name)
                            SeqDict.empty

                NoThreadWithMaybeMessage _ ->
                    conversationView
                        (SeqDict.get
                            (GuildOrDmId_Dm_NoThread otherUserId)
                            local.localUser.user.lastViewed
                            |> Maybe.withDefault (Id.fromInt -1)
                        )
                        (GuildOrDmId_Dm_WithMaybeMessage otherUserId threadRoute)
                        loggedIn
                        model
                        local
                        (PersonName.toString otherUser.name)
                        dmChannel.threads
                        dmChannel

        Nothing ->
            Ui.el
                [ Ui.centerY
                , Ui.Font.center
                , Ui.Font.color MyUi.font1
                , Ui.Font.size 20
                ]
                (Ui.text "User not found")


conversationWidth : LoadedFrontend -> Int
conversationWidth model =
    if MyUi.isMobile model then
        Coord.xRaw model.windowSize
            - (User.profileImageSize
                + (messagePaddingX * 2)
                + profileImagePaddingRight
              )

    else
        Coord.xRaw model.windowSize
            - ((GuildIcon.fullWidth + 1)
                + channelColumnWidth
                + memberColumnWidth
                + User.profileImageSize
                + (messagePaddingX * 2)
                + profileImagePaddingRight
              )


channelColumnWidth : number
channelColumnWidth =
    241


guildView : LoadedFrontend -> Id GuildId -> ChannelRoute -> LoggedIn2 -> LocalState -> Element FrontendMsg
guildView model guildId channelRoute loggedIn local =
    case loggedIn.newGuildForm of
        Just form ->
            newGuildFormView form

        Nothing ->
            case SeqDict.get guildId local.guilds of
                Just guild ->
                    if MyUi.isMobile model then
                        let
                            canScroll2 =
                                canScroll model
                        in
                        Ui.column
                            [ Ui.height Ui.fill
                            , Ui.background MyUi.background1
                            , Ui.heightMin 0
                            , Ui.clip
                            , channelView channelRoute guildId guild loggedIn local model
                                |> Ui.el
                                    [ Ui.height Ui.fill
                                    , Ui.background MyUi.background3
                                    , MyUi.htmlStyle "padding" (MyUi.insetTop ++ " 0 0 0")
                                    , sidebarOffsetAttr loggedIn model
                                    ]
                                |> Ui.inFront
                            ]
                            [ Ui.row
                                [ Ui.height Ui.fill, Ui.heightMin 0 ]
                                [ Ui.Lazy.lazy6
                                    guildColumn
                                    True
                                    model.route
                                    local.localUser.userId
                                    local.localUser.user
                                    local.guilds
                                    canScroll2
                                , Ui.Lazy.lazy5
                                    (if canScroll2 then
                                        channelColumnCanScrollMobile

                                     else
                                        channelColumnCannotScrollMobile
                                    )
                                    local.localUser
                                    guildId
                                    guild
                                    channelRoute
                                    loggedIn.channelNameHover
                                ]
                            , loggedInAsView local
                            ]

                    else
                        Ui.row
                            [ Ui.height Ui.fill, Ui.background MyUi.background1 ]
                            [ Ui.column
                                [ Ui.height Ui.fill
                                , Ui.width (Ui.px 300)
                                ]
                                [ Ui.row
                                    [ Ui.height Ui.fill, Ui.heightMin 0 ]
                                    [ Ui.Lazy.lazy6
                                        guildColumn
                                        False
                                        model.route
                                        local.localUser.userId
                                        local.localUser.user
                                        local.guilds
                                        True
                                    , Ui.Lazy.lazy5
                                        channelColumnNotMobile
                                        local.localUser
                                        guildId
                                        guild
                                        channelRoute
                                        loggedIn.channelNameHover
                                    ]
                                , loggedInAsView local
                                ]
                            , channelView channelRoute guildId guild loggedIn local model
                                |> Ui.el
                                    [ Ui.height Ui.fill
                                    , Ui.background MyUi.background3
                                    , Ui.heightMin 0
                                    , Ui.borderColor MyUi.border1
                                    , Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
                                    ]
                                |> Ui.el
                                    [ Ui.height Ui.fill
                                    , MyUi.htmlStyle "padding-top" MyUi.insetTop
                                    ]
                            , Ui.Lazy.lazy4 memberColumn False local.localUser guild.owner guild.members
                                |> Ui.el
                                    [ Ui.width Ui.shrink
                                    , Ui.height Ui.fill
                                    , MyUi.htmlStyle "padding-top" MyUi.insetTop
                                    ]
                            ]

                Nothing ->
                    homePageLoggedInView Nothing model loggedIn local


memberColumnWidth : number
memberColumnWidth =
    200


memberColumn : Bool -> LocalUser -> Id UserId -> SeqDict (Id UserId) { joinedAt : Time.Posix } -> Element FrontendMsg
memberColumn isMobile localUser guildOwner guildMembers =
    let
        _ =
            Debug.log "rerendered memberColumn" ()
    in
    Ui.column
        [ Ui.height Ui.fill
        , Ui.alignRight
        , Ui.background MyUi.background2
        , Ui.Font.color MyUi.font1
        , Ui.width (Ui.px memberColumnWidth)
        , Ui.scrollable
        ]
        [ Ui.column
            [ Ui.paddingXY 4 4 ]
            [ Ui.text "Owner"
            , memberLabel isMobile localUser guildOwner
            ]
        , Ui.column
            [ Ui.paddingXY 4 4 ]
            [ Ui.text ("Members (" ++ String.fromInt (SeqDict.size guildMembers) ++ ")")
            , Ui.column
                [ Ui.height Ui.fill ]
                (SeqDict.foldr
                    (\userId _ list -> memberLabel isMobile localUser userId :: list)
                    []
                    guildMembers
                )
            ]
        ]


memberLabel : Bool -> LocalUser -> Id UserId -> Element FrontendMsg
memberLabel isMobile localUser userId =
    rowLinkButton
        (DmRoute userId (NoThreadWithMaybeMessage Nothing))
        [ Ui.spacing 8
        , Ui.paddingXY 4 4
        , MyUi.hover
            isMobile
            [ Ui.Anim.backgroundColor (Ui.rgba 255 255 255 0.1)
            , Ui.Anim.fontColor MyUi.font1
            ]
        , Ui.Font.color MyUi.font3
        , Ui.clipWithEllipsis
        ]
        (case LocalState.getUser userId localUser of
            Just user ->
                [ User.profileImage user.icon, Ui.text (PersonName.toString user.name) ]

            Nothing ->
                []
        )


sidebarOffsetAttr : LoggedIn2 -> LoadedFrontend -> Ui.Attribute msg
sidebarOffsetAttr loggedIn model =
    let
        width : Int
        width =
            Coord.xRaw model.windowSize

        offset : Float
        offset =
            (case loggedIn.sidebarMode of
                Types.ChannelSidebarClosed ->
                    1

                Types.ChannelSidebarOpened ->
                    0

                Types.ChannelSidebarClosing a ->
                    a.offset

                Types.ChannelSidebarOpening a ->
                    a.offset

                Types.ChannelSidebarDragging a ->
                    a.offset
            )
                * toFloat width
    in
    Ui.move
        { x =
            --if offset < 20 then
            --    0
            --
            --else if offset > toFloat width - 20 then
            --    width
            --
            --else
            round offset
        , y = 0
        , z = 0
        }


threadPreviewText : Id ChannelMessageId -> { a | messages : Array Message } -> LocalUser -> String
threadPreviewText threadMessageIndex channel localUser =
    case LocalState.getArray threadMessageIndex channel.messages of
        Just message ->
            let
                allUsers : SeqDict (Id UserId) FrontendUser
                allUsers =
                    LocalState.allUsers2 localUser
            in
            case message of
                UserTextMessage data ->
                    RichText.toString allUsers data.content

                UserJoinedMessage _ userId _ ->
                    User.toString userId allUsers ++ " joined!"

                DeletedMessage _ ->
                    "Deleted message"

        Nothing ->
            "Thread not found"


channelView : ChannelRoute -> Id GuildId -> FrontendGuild -> LoggedIn2 -> LocalState -> LoadedFrontend -> Element FrontendMsg
channelView channelRoute guildId guild loggedIn local model =
    case channelRoute of
        ChannelRoute channelId threadRoute ->
            case SeqDict.get channelId guild.channels of
                Just channel ->
                    case threadRoute of
                        ViewThreadWithMaybeMessage threadMessageIndex _ ->
                            SeqDict.get threadMessageIndex channel.threads
                                |> Maybe.withDefault DmChannel.threadInit
                                |> conversationView
                                    (SeqDict.get
                                        ( GuildOrDmId_Guild_NoThread guildId channelId, threadMessageIndex )
                                        local.localUser.user.lastViewedThreads
                                        |> Maybe.withDefault (Id.fromInt -1)
                                        |> Id.changeType
                                    )
                                    (GuildOrDmId_Guild_WithMaybeMessage guildId channelId threadRoute)
                                    loggedIn
                                    model
                                    local
                                    (ChannelName.toString channel.name
                                        ++ " / "
                                        ++ threadPreviewText threadMessageIndex channel local.localUser
                                    )
                                    SeqDict.empty

                        NoThreadWithMaybeMessage _ ->
                            conversationView
                                (SeqDict.get
                                    (GuildOrDmId_Guild_NoThread guildId channelId)
                                    local.localUser.user.lastViewed
                                    |> Maybe.withDefault (Id.fromInt -1)
                                )
                                (GuildOrDmId_Guild_WithMaybeMessage guildId channelId threadRoute)
                                loggedIn
                                model
                                local
                                (ChannelName.toString channel.name)
                                channel.threads
                                channel

                Nothing ->
                    Ui.el
                        [ Ui.centerY
                        , Ui.Font.center
                        , Ui.Font.color MyUi.font1
                        , Ui.Font.size 20
                        ]
                        (Ui.text "Channel does not exist")

        NewChannelRoute ->
            SeqDict.get guildId loggedIn.newChannelForm
                |> Maybe.withDefault newChannelFormInit
                |> newChannelFormView (MyUi.isMobile model) guildId

        EditChannelRoute channelId ->
            case SeqDict.get channelId guild.channels of
                Just channel ->
                    editChannelFormView
                        guildId
                        channelId
                        channel
                        (SeqDict.get ( guildId, channelId ) loggedIn.editChannelForm
                            |> Maybe.withDefault (editChannelFormInit channel)
                        )

                Nothing ->
                    Ui.el
                        [ Ui.centerY
                        , Ui.Font.center
                        , Ui.Font.color MyUi.font1
                        , Ui.Font.size 20
                        ]
                        (Ui.text "Channel does not exist")

        InviteLinkCreatorRoute ->
            inviteLinkCreatorForm model guildId guild

        JoinRoute _ ->
            Ui.none


inviteLinkCreatorForm : LoadedFrontend -> Id GuildId -> FrontendGuild -> Element FrontendMsg
inviteLinkCreatorForm model guildId guild =
    Ui.el
        [ Ui.height Ui.fill ]
        (Ui.column
            [ Ui.Font.color MyUi.font1
            , Ui.alignTop
            , Ui.spacing 16
            , scrollable (canScroll model)
            ]
            [ channelHeader (MyUi.isMobile model) (Ui.text "Invite member to guild")
            , Ui.el [ Ui.paddingXY 16 0 ] (submitButton (PressedCreateInviteLink guildId) "Create invite link")
            , if SeqDict.isEmpty guild.invites then
                Ui.none

              else
                Ui.el [ Ui.Font.bold, Ui.paddingXY 16 0 ] (Ui.text "Existing invites")
            , Ui.column
                [ Ui.spacing 8, Ui.paddingXY 16 0 ]
                (SeqDict.toList guild.invites
                    |> List.sortBy (\( _, data ) -> -(Time.posixToMillis data.createdAt))
                    |> List.map
                        (\( inviteId, data ) ->
                            let
                                url : String
                                url =
                                    Route.encode (GuildRoute guildId (JoinRoute inviteId))
                            in
                            Ui.row
                                [ Ui.spacing 16 ]
                                [ Ui.el [ Ui.widthMax 300 ] (copyableText (Env.domain ++ url) model)
                                , if Duration.from data.createdAt model.time |> Quantity.lessThan (Duration.minutes 5) then
                                    Ui.text "Created just now!"

                                  else
                                    Ui.none
                                ]
                        )
                )
            ]
        )


copyableText : String -> LoadedFrontend -> Element FrontendMsg
copyableText text model =
    let
        isCopied : Bool
        isCopied =
            case model.lastCopied of
                Just copied ->
                    (copied.copiedText == text)
                        && (Duration.from copied.copiedAt model.time
                                |> Quantity.lessThan (Duration.seconds 10)
                           )

                Nothing ->
                    False
    in
    Ui.row
        []
        [ Ui.Input.text
            [ Ui.roundedWith { topLeft = 4, bottomLeft = 4, topRight = 0, bottomRight = 0 }
            , Ui.border 1
            , Ui.borderColor MyUi.inputBorder
            , Ui.paddingXY 4 4
            , Ui.background MyUi.inputBackground
            ]
            { text = text
            , onChange = \_ -> FrontendNoOp
            , placeholder = Nothing
            , label = Ui.Input.labelHidden "Readonly text field"
            }
        , MyUi.elButton
            (Dom.id "guild_copyText")
            (PressedCopyText text)
            [ Ui.Font.color MyUi.font2
            , Ui.roundedWith { topRight = 4, bottomRight = 4, topLeft = 0, bottomLeft = 0 }
            , Ui.borderWith { left = 0, right = 1, top = 1, bottom = 1 }
            , Ui.borderColor MyUi.inputBorder
            , Ui.paddingXY 6 0
            , Ui.width Ui.shrink
            , Ui.height Ui.fill
            , Ui.contentCenterY
            , Ui.Font.size 14
            ]
            (if isCopied then
                Ui.text "Copied!"

             else
                Ui.el [ Ui.width (Ui.px 18) ] (Ui.html Icons.copyIcon)
            )
        ]


channelTextInputId : HtmlId
channelTextInputId =
    "channel_textinput" |> Dom.id


emojiSelector : Element FrontendMsg
emojiSelector =
    Ui.column
        [ Ui.width (Ui.px (8 * 32 + 21))
        , Ui.height (Ui.px 400)
        , Ui.scrollable
        , Ui.background MyUi.background1
        , Ui.border 1
        , Ui.borderColor MyUi.border1
        , Ui.Font.size 24
        , MyUi.blockClickPropagation PressedReactionEmojiContainer
        ]
        (List.map
            (\emojiRow ->
                Ui.row
                    [ Ui.height (Ui.px 34) ]
                    (List.map
                        (\emoji ->
                            Ui.el
                                [ Ui.width (Ui.px 32)
                                , Ui.contentCenterX
                                , Ui.Input.button (PressedEmojiSelectorEmoji emoji)
                                ]
                                (Ui.text (Emoji.toString emoji))
                        )
                        emojiRow
                    )
            )
            (List.Extra.greedyGroupsOf 8 Emoji.emojis)
        )
        |> Ui.el [ Ui.alignBottom, Ui.paddingXY 8 0, Ui.width Ui.shrink ]


messageHover : GuildOrDmId -> Id ChannelMessageId -> LoggedIn2 -> IsHovered
messageHover guildOrDmId messageIndex loggedIn =
    case loggedIn.messageHover of
        MessageMenu messageMenu ->
            if guildOrDmId == messageMenu.guildOrDmId then
                if messageMenu.messageIndex == messageIndex then
                    IsHoveredButNoMenu

                else
                    IsNotHovered

            else
                IsNotHovered

        MessageHover guildOrDmIdA messageIndexA ->
            if guildOrDmId == guildOrDmIdA then
                if messageIndexA == messageIndex then
                    IsHovered

                else
                    IsNotHovered

            else
                IsNotHovered

        _ ->
            IsNotHovered


conversationViewHelper :
    Id ChannelMessageId
    -> GuildOrDmIdWithMaybeMessage
    -> SeqDict (Id ChannelMessageId) Thread
    -> { a | lastTypedAt : SeqDict (Id UserId) (LastTypedAt messageId), messages : Array Message }
    -> LoggedIn2
    -> LocalState
    -> LoadedFrontend
    -> List (Element FrontendMsg)
conversationViewHelper lastViewedIndex guildOrDmIdWithMaybeMessage threads channel loggedIn local model =
    let
        guildOrDmId : GuildOrDmId
        guildOrDmId =
            Id.guildOrDmIdWithoutMaybeMessage guildOrDmIdWithMaybeMessage

        maybeEditing : Maybe EditMessage
        maybeEditing =
            SeqDict.get guildOrDmId loggedIn.editMessage

        othersEditing : SeqSet (Id messageId)
        othersEditing =
            SeqDict.remove local.localUser.userId channel.lastTypedAt
                |> SeqDict.values
                |> List.filterMap
                    (\a ->
                        if Duration.from a.time model.time |> Quantity.lessThan (Duration.seconds 3) then
                            a.messageIndex

                        else
                            Nothing
                    )
                |> SeqSet.fromList

        replyToIndex : Maybe (Id ChannelMessageId)
        replyToIndex =
            SeqDict.get guildOrDmId loggedIn.replyTo

        revealedSpoilers : SeqDict (Id ChannelMessageId) (NonemptySet Int)
        revealedSpoilers =
            case loggedIn.revealedSpoilers of
                Just revealed ->
                    if revealed.guildOrDmId == guildOrDmId then
                        revealed.messages

                    else
                        SeqDict.empty

                Nothing ->
                    SeqDict.empty

        containerWidth : Int
        containerWidth =
            conversationWidth model

        isMobile : Bool
        isMobile =
            MyUi.isMobile model
    in
    Array.foldr
        (\message ( index, list ) ->
            let
                messageId : Id ChannelMessageId
                messageId =
                    Id.fromInt index

                threadId : Id ChannelMessageId
                threadId =
                    Id.fromInt index

                messageHover2 : IsHovered
                messageHover2 =
                    messageHover guildOrDmId messageId loggedIn

                otherUserIsEditing : Bool
                otherUserIsEditing =
                    SeqSet.member (Id.changeType messageId) othersEditing

                isEditing : Maybe EditMessage
                isEditing =
                    case maybeEditing of
                        Just editing ->
                            if editing.messageIndex == messageId then
                                Just editing

                            else
                                Nothing

                        Nothing ->
                            Nothing

                isUrlHighlighted : Bool
                isUrlHighlighted =
                    case guildOrDmIdWithMaybeMessage of
                        GuildOrDmId_Guild_WithMaybeMessage _ _ (ViewThreadWithMaybeMessage _ (Just a)) ->
                            Id.toInt a == index

                        GuildOrDmId_Guild_WithMaybeMessage _ _ (NoThreadWithMaybeMessage (Just a)) ->
                            Id.toInt a == index

                        GuildOrDmId_Dm_WithMaybeMessage _ (ViewThreadWithMaybeMessage _ (Just a)) ->
                            Id.toInt a == index

                        GuildOrDmId_Dm_WithMaybeMessage _ (NoThreadWithMaybeMessage (Just a)) ->
                            Id.toInt a == index

                        _ ->
                            False

                highlight : HighlightMessage
                highlight =
                    if isUrlHighlighted then
                        UrlHighlight

                    else if replyToIndex == Just messageId then
                        ReplyToHighlight

                    else
                        NoHighlight

                newLine : List (Element msg)
                newLine =
                    if Id.increment lastViewedIndex == messageId then
                        [ Ui.el
                            [ Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
                            , Ui.borderColor MyUi.alertColor
                            , Ui.inFront
                                (Ui.el
                                    [ Ui.Font.color MyUi.font1
                                    , Ui.background MyUi.alertColor
                                    , Ui.width Ui.shrink
                                    , Ui.paddingXY 4 0
                                    , Ui.alignRight
                                    , Ui.Font.size 12
                                    , Ui.contentCenterY
                                    , Ui.Font.bold
                                    , Ui.height (Ui.px 15)
                                    , Ui.roundedWith
                                        { bottomLeft = 8, bottomRight = 0, topLeft = 8, topRight = 0 }
                                    , Ui.move { x = 0, y = -8, z = 0 }
                                    ]
                                    (Ui.text "New")
                                )
                            ]
                            Ui.none
                        ]

                    else
                        []

                maybeRepliedTo : Maybe ( Id ChannelMessageId, Message )
                maybeRepliedTo =
                    case message of
                        UserTextMessage data ->
                            case data.repliedTo of
                                Just repliedToIndex ->
                                    case LocalState.getArray repliedToIndex channel.messages of
                                        Just message2 ->
                                            Just ( repliedToIndex, message2 )

                                        Nothing ->
                                            Nothing

                                Nothing ->
                                    Nothing

                        UserJoinedMessage _ _ _ ->
                            Nothing

                        DeletedMessage _ ->
                            Nothing
            in
            ( index - 1
            , newLine
                ++ (case isEditing of
                        Just editing ->
                            if MyUi.isMobile model then
                                -- On mobile, we show the editor at the bottom instead
                                messageView
                                    isMobile
                                    containerWidth
                                    True
                                    revealedSpoilers
                                    highlight
                                    messageHover2
                                    otherUserIsEditing
                                    local.localUser
                                    maybeRepliedTo
                                    (SeqDict.get threadId threads)
                                    messageId
                                    message
                                    |> Ui.map (MessageViewMsg guildOrDmId)

                            else
                                messageEditingView
                                    isMobile
                                    guildOrDmId
                                    messageId
                                    message
                                    maybeRepliedTo
                                    (SeqDict.get threadId threads)
                                    revealedSpoilers
                                    editing
                                    loggedIn.pingUser
                                    local

                        Nothing ->
                            case SeqDict.get threadId threads of
                                Nothing ->
                                    case maybeRepliedTo of
                                        Just _ ->
                                            messageView
                                                isMobile
                                                containerWidth
                                                True
                                                revealedSpoilers
                                                highlight
                                                messageHover2
                                                otherUserIsEditing
                                                local.localUser
                                                maybeRepliedTo
                                                Nothing
                                                messageId
                                                message
                                                |> Ui.map (MessageViewMsg guildOrDmId)

                                        Nothing ->
                                            Ui.Lazy.lazy5
                                                messageViewNotThreadStarter
                                                (messageViewEncode isMobile messageHover2 containerWidth otherUserIsEditing highlight)
                                                SeqDict.empty
                                                --revealedSpoilers
                                                local.localUser
                                                index
                                                message
                                                |> Ui.map (MessageViewMsg guildOrDmId)

                                Just thread ->
                                    case maybeRepliedTo of
                                        Just _ ->
                                            messageView
                                                isMobile
                                                containerWidth
                                                True
                                                revealedSpoilers
                                                highlight
                                                messageHover2
                                                otherUserIsEditing
                                                local.localUser
                                                maybeRepliedTo
                                                (Just thread)
                                                messageId
                                                message
                                                |> Ui.map (MessageViewMsg guildOrDmId)

                                        Nothing ->
                                            Ui.Lazy.lazy6
                                                messageViewThreadStarter
                                                (messageViewEncode isMobile messageHover2 containerWidth otherUserIsEditing highlight)
                                                revealedSpoilers
                                                local.localUser
                                                index
                                                thread
                                                message
                                                |> Ui.map (MessageViewMsg guildOrDmId)
                   )
                :: list
            )
        )
        ( Array.length channel.messages - 1, [] )
        channel.messages
        |> Tuple.second


messageViewEncode : Bool -> IsHovered -> Int -> Bool -> HighlightMessage -> Int
messageViewEncode isMobile isHovered containerWidth otherUserIsEditing highlight =
    (if otherUserIsEditing then
        1

     else
        0
    )
        + Bitwise.shiftLeftBy
            1
            (case isHovered of
                IsNotHovered ->
                    0

                IsHovered ->
                    1

                IsHoveredButNoMenu ->
                    2
            )
        + Bitwise.shiftLeftBy
            3
            (case highlight of
                NoHighlight ->
                    0

                ReplyToHighlight ->
                    1

                MentionHighlight ->
                    2

                UrlHighlight ->
                    3
            )
        + Bitwise.shiftLeftBy
            5
            (if isMobile then
                1

             else
                0
            )
        + Bitwise.shiftLeftBy 6 containerWidth


messageViewDecode : Int -> { containerWidth : Int, isEditing : Bool, highlight : HighlightMessage, isHovered : IsHovered, isMobile : Bool }
messageViewDecode value =
    { isEditing = Bitwise.and 0x01 value == 1
    , isHovered =
        case Bitwise.shiftRightBy 1 value |> Bitwise.and 0x03 of
            1 ->
                IsHovered

            2 ->
                IsHoveredButNoMenu

            _ ->
                IsNotHovered
    , highlight =
        case Bitwise.shiftRightBy 3 value |> Bitwise.and 0x03 of
            1 ->
                ReplyToHighlight

            2 ->
                MentionHighlight

            3 ->
                UrlHighlight

            _ ->
                NoHighlight
    , isMobile = Bitwise.shiftRightBy 5 value |> Bitwise.and 0x01 |> (==) 1
    , containerWidth = Bitwise.shiftRightBy 6 value
    }


channelHeader : Bool -> Element FrontendMsg -> Element FrontendMsg
channelHeader isMobile2 content =
    Ui.row
        [ Ui.contentCenterY
        , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
        , Ui.borderColor MyUi.border2
        , Ui.background MyUi.background3
        , Ui.height (Ui.px channelHeaderHeight)
        , MyUi.noShrinking
        ]
        (if isMobile2 then
            [ Ui.el
                [ Ui.Input.button PressedChannelHeaderBackButton
                , Ui.width (Ui.px 36)
                , Ui.height Ui.fill
                , Ui.Font.color MyUi.font3
                , Ui.contentCenterY
                , Ui.contentCenterX
                , Ui.padding 8
                ]
                (Ui.html Icons.arrowLeft)
            , Ui.el [] content
            ]

         else
            [ Ui.el [ Ui.paddingXY 16 0 ] content ]
        )


channelHeaderHeight : number
channelHeaderHeight =
    38


scrollable : Bool -> Ui.Attribute msg
scrollable canScroll2 =
    if canScroll2 then
        Ui.scrollable

    else
        Ui.clip


conversationContainerId : HtmlId
conversationContainerId =
    Dom.id "conversationContainer"


messageInputConfig : GuildOrDmId -> MsgConfig FrontendMsg
messageInputConfig guildOrDmId =
    { gotPingUserPosition = GotPingUserPosition
    , textInputGotFocus = TextInputGotFocus
    , textInputLostFocus = TextInputLostFocus
    , pressedTextInput = PressedTextInput
    , typedMessage = TypedMessage guildOrDmId
    , pressedSendMessage =
        case guildOrDmId of
            GuildOrDmId_Guild guildId channelId threadRoute ->
                PressedSendMessage (GuildOrDmId_Guild_NoThread guildId channelId) threadRoute

            GuildOrDmId_Dm otherUserId threadRoute ->
                PressedSendMessage (GuildOrDmId_Dm_NoThread otherUserId) threadRoute
    , pressedArrowInDropdown = PressedArrowInDropdown guildOrDmId
    , pressedArrowUpInEmptyInput = PressedArrowUpInEmptyInput guildOrDmId
    , pressedPingUser = PressedPingUser guildOrDmId
    , pressedPingDropdownContainer = PressedPingDropdownContainer
    , pressedUploadFile = PressedAttachFiles guildOrDmId
    , target = MessageInput.NewMessage
    , onPasteFiles = PastedFiles guildOrDmId
    }


scrollToBottomDecoder : Bool -> Json.Decode.Decoder FrontendMsg
scrollToBottomDecoder isScrolledToBottomOfChannel =
    Json.Decode.map3
        (\scrollTop scrollHeight clientHeight ->
            scrollTop + clientHeight >= scrollHeight - 5
        )
        (Json.Decode.at [ "target", "scrollTop" ] Json.Decode.float)
        (Json.Decode.at [ "target", "scrollHeight" ] Json.Decode.float)
        (Json.Decode.at [ "target", "clientHeight" ] Json.Decode.float)
        |> Json.Decode.andThen
            (\isAtBottom ->
                if isAtBottom == isScrolledToBottomOfChannel then
                    Json.Decode.fail ""

                else
                    UserScrolled { scrolledToBottomOfChannel = isAtBottom } |> Json.Decode.succeed
            )


conversationView :
    Id ChannelMessageId
    -> GuildOrDmIdWithMaybeMessage
    -> LoggedIn2
    -> LoadedFrontend
    -> LocalState
    -> String
    -> SeqDict (Id ChannelMessageId) Thread
    -> { a | lastTypedAt : SeqDict (Id UserId) (LastTypedAt messageId), messages : Array Message }
    -> Element FrontendMsg
conversationView lastViewedIndex guildOrDmIdWithMaybeMessage loggedIn model local name threads channel =
    let
        guildOrDmId : GuildOrDmId
        guildOrDmId =
            Id.guildOrDmIdWithoutMaybeMessage guildOrDmIdWithMaybeMessage

        allUsers : SeqDict (Id UserId) FrontendUser
        allUsers =
            LocalState.allUsers local

        replyTo : Maybe (Id ChannelMessageId)
        replyTo =
            SeqDict.get guildOrDmId loggedIn.replyTo

        isMobile : Bool
        isMobile =
            MyUi.isMobile model
    in
    Ui.column
        [ Ui.height Ui.fill
        , Ui.heightMin 0
        ]
        [ channelHeader
            isMobile
            (case guildOrDmId of
                GuildOrDmId_Dm otherUserId _ ->
                    Ui.row
                        [ Ui.Font.color MyUi.font1 ]
                        (if otherUserId == local.localUser.userId then
                            [ Ui.el
                                [ Ui.Font.color MyUi.font3
                                , Ui.width Ui.shrink
                                , MyUi.prewrap
                                , Ui.clipWithEllipsis
                                ]
                                (Ui.text "Private chat with yourself")
                            ]

                         else
                            [ Ui.el
                                [ Ui.Font.color MyUi.font3
                                , Ui.width Ui.shrink
                                , MyUi.prewrap
                                , Ui.clipWithEllipsis
                                ]
                                (Ui.text "Private chat with ")
                            , Ui.text name
                            ]
                        )

                GuildOrDmId_Guild _ _ _ ->
                    Ui.row
                        [ Ui.Font.color MyUi.font1, Ui.spacing 2, Ui.clipWithEllipsis ]
                        [ Ui.html Icons.hashtag, Ui.text name ]
            )
        , Ui.el
            [ case loggedIn.showEmojiSelector of
                EmojiSelectorHidden ->
                    Ui.noAttr

                EmojiSelectorForReaction _ _ ->
                    Ui.inFront emojiSelector

                EmojiSelectorForMessage ->
                    Ui.inFront emojiSelector
            , Ui.heightMin 0
            , Ui.height Ui.fill
            ]
            (Ui.column
                [ Ui.height Ui.fill
                , Ui.paddingXY 0 16
                , scrollable (canScroll model)
                , MyUi.htmlStyle "overflow-wrap" "break-word"
                , Ui.id (Dom.idToString conversationContainerId)
                , Ui.Events.on "scroll" (scrollToBottomDecoder model.scrolledToBottomOfChannel)
                , Ui.heightMin 0
                , bounceScroll isMobile
                ]
                ((case guildOrDmId of
                    GuildOrDmId_Guild guildId channelId (ViewThread threadMessageIndex) ->
                        Ui.column
                            [ Ui.alignBottom ]
                            [ Ui.el
                                [ Ui.Font.color MyUi.font2, Ui.paddingXY 8 4, Ui.alignBottom, Ui.Font.size 20 ]
                                (Ui.text "Start of thread")
                            , case LocalState.getGuildAndChannel guildId channelId local of
                                Just ( _, channel2 ) ->
                                    threadStarterMessage
                                        isMobile
                                        (GuildOrDmId_Guild guildId channelId NoThread)
                                        threadMessageIndex
                                        channel2
                                        loggedIn
                                        local
                                        model

                                Nothing ->
                                    Ui.none
                            ]

                    GuildOrDmId_Guild _ _ NoThread ->
                        Ui.el
                            [ Ui.Font.color MyUi.font2, Ui.paddingXY 8 4, Ui.alignBottom, Ui.Font.size 20 ]
                            (Ui.text ("This is the start of #" ++ name))

                    GuildOrDmId_Dm otherUserId (ViewThread threadMessageIndex) ->
                        Ui.column
                            [ Ui.alignBottom ]
                            [ Ui.el
                                [ Ui.Font.color MyUi.font2, Ui.paddingXY 8 4, Ui.alignBottom, Ui.Font.size 20 ]
                                (Ui.text "Start of thread")
                            , case SeqDict.get otherUserId local.dmChannels of
                                Just dmChannel2 ->
                                    threadStarterMessage
                                        isMobile
                                        (GuildOrDmId_Dm otherUserId NoThread)
                                        threadMessageIndex
                                        dmChannel2
                                        loggedIn
                                        local
                                        model

                                Nothing ->
                                    Ui.none
                            ]

                    GuildOrDmId_Dm otherUserId NoThread ->
                        Ui.el
                            [ Ui.Font.color MyUi.font2, Ui.paddingXY 8 4, Ui.alignBottom, Ui.Font.size 20 ]
                            (Ui.text
                                (if otherUserId == local.localUser.userId then
                                    "This is the start of a conversation with yourself"

                                 else
                                    "This is the start of your conversation with " ++ name
                                )
                            )
                 )
                    :: conversationViewHelper
                        lastViewedIndex
                        guildOrDmIdWithMaybeMessage
                        threads
                        channel
                        loggedIn
                        local
                        model
                )
            )
        , Ui.column
            [ Ui.paddingXY 2 0
            , Ui.heightMin 0
            , MyUi.noShrinking
            , case SeqDict.get guildOrDmId loggedIn.filesToUpload of
                Just filesToUpload2 ->
                    FileStatus.fileUploadPreview (PressedDeleteAttachedFile guildOrDmId) filesToUpload2
                        |> Ui.inFront

                Nothing ->
                    Ui.noAttr
            ]
            [ case replyTo of
                Just messageIndex ->
                    case LocalState.getArray messageIndex channel.messages of
                        Just (UserTextMessage data) ->
                            replyToHeader (PressedCloseReplyTo guildOrDmId) data.createdBy local

                        Just (UserJoinedMessage _ userId _) ->
                            replyToHeader (PressedCloseReplyTo guildOrDmId) userId local

                        Just (DeletedMessage _) ->
                            Ui.none

                        Nothing ->
                            Ui.none

                Nothing ->
                    Ui.none
            , MessageInput.view
                (replyTo == Nothing)
                (MyUi.isMobile model)
                (messageInputConfig guildOrDmId)
                channelTextInputId
                (case guildOrDmId of
                    GuildOrDmId_Guild _ _ NoThread ->
                        "Write a message in #" ++ name

                    GuildOrDmId_Guild _ _ (ViewThread _) ->
                        "Write a message in this thread"

                    GuildOrDmId_Dm otherUserId NoThread ->
                        "Write a message to "
                            ++ (if otherUserId == local.localUser.userId then
                                    "yourself"

                                else
                                    name
                               )

                    GuildOrDmId_Dm _ (ViewThread _) ->
                        "Write a message in this thread"
                )
                (case SeqDict.get guildOrDmId loggedIn.drafts of
                    Just text ->
                        String.Nonempty.toString text

                    Nothing ->
                        ""
                )
                (case SeqDict.get guildOrDmId loggedIn.filesToUpload of
                    Just attachedFiles ->
                        NonemptyDict.toSeqDict attachedFiles

                    Nothing ->
                        SeqDict.empty
                )
                loggedIn.pingUser
                local
            , (case
                SeqDict.filter
                    (\_ a ->
                        (Duration.from a.time model.time |> Quantity.lessThan (Duration.seconds 3))
                            && (a.messageIndex == Nothing)
                    )
                    (SeqDict.remove local.localUser.userId channel.lastTypedAt)
                    |> SeqDict.keys
               of
                [] ->
                    " "

                [ single ] ->
                    User.toString single allUsers ++ " is typing..."

                [ one, two ] ->
                    User.toString one allUsers ++ " and " ++ User.toString two allUsers ++ " are typing..."

                [ one, two, three ] ->
                    User.toString one allUsers
                        ++ ", "
                        ++ User.toString two allUsers
                        ++ ", and "
                        ++ User.toString three allUsers
                        ++ " are typing..."

                _ :: _ :: _ :: _ ->
                    "Several people are typing..."
              )
                |> Ui.text
                |> Ui.el
                    [ Ui.Font.bold
                    , Ui.Font.size 13
                    , Ui.Font.color MyUi.font3
                    , MyUi.prewrap
                    , MyUi.noShrinking
                    , Ui.contentCenterY
                    , MyUi.htmlStyle
                        "padding"
                        ("0 calc(12px + "
                            ++ MyUi.insetBottom
                            ++ " * 0.5) "
                            ++ (if model.virtualKeyboardOpen then
                                    "calc(" ++ MyUi.insetBottom ++ " * 0.5)"

                                else
                                    MyUi.insetBottom
                               )
                            ++ " calc(12px + "
                            ++ MyUi.insetBottom
                            ++ " * 0.5)"
                        )
                    ]
            ]
        ]


threadStarterMessage :
    Bool
    -> GuildOrDmId
    -> Id ChannelMessageId
    ->
        { a
            | messages : Array Message
            , -- Isn't used but is here to indicate this is a Channel or DmChannel type
              threads : SeqDict (Id ChannelMessageId) Thread
        }
    -> LoggedIn2
    -> LocalState
    -> LoadedFrontend
    -> Element FrontendMsg
threadStarterMessage isMobile guildOrDmId2 threadMessageIndex channel loggedIn local model =
    case LocalState.getArray threadMessageIndex channel.messages of
        Just message ->
            case SeqDict.get guildOrDmId2 loggedIn.editMessage of
                Just editMessage ->
                    if editMessage.messageIndex == threadMessageIndex then
                        messageEditingView
                            isMobile
                            guildOrDmId2
                            threadMessageIndex
                            message
                            Nothing
                            Nothing
                            SeqDict.empty
                            editMessage
                            loggedIn.pingUser
                            local

                    else
                        messageView
                            isMobile
                            (conversationWidth model)
                            True
                            SeqDict.empty
                            NoHighlight
                            (messageHover guildOrDmId2 threadMessageIndex loggedIn)
                            False
                            local.localUser
                            Nothing
                            Nothing
                            threadMessageIndex
                            message
                            |> Ui.map (MessageViewMsg guildOrDmId2)

                Nothing ->
                    messageView
                        isMobile
                        (conversationWidth model)
                        True
                        SeqDict.empty
                        NoHighlight
                        (messageHover guildOrDmId2 threadMessageIndex loggedIn)
                        False
                        local.localUser
                        Nothing
                        Nothing
                        threadMessageIndex
                        message
                        |> Ui.map (MessageViewMsg guildOrDmId2)

        Nothing ->
            Ui.none


replyToHeader : msg -> Id UserId -> LocalState -> Element msg
replyToHeader onPress userId local =
    Ui.Prose.paragraph
        [ Ui.Font.color MyUi.font2
        , Ui.background MyUi.background2
        , Ui.paddingXY 32 10
        , Ui.roundedWith { topLeft = 8, topRight = 8, bottomLeft = 0, bottomRight = 0 }
        , Ui.borderWith { left = 1, right = 1, top = 1, bottom = 0 }
        , Ui.borderColor MyUi.border1
        , Ui.inFront
            (Ui.el
                [ Ui.Input.button onPress
                , Ui.width (Ui.px 32)
                , Ui.paddingWith { left = 4, right = 4, top = 4, bottom = 0 }
                , Ui.alignRight
                ]
                (Ui.html Icons.x)
            )
        , Ui.inFront
            (Ui.el [ Ui.width (Ui.px 18), Ui.move { x = 10, y = 8, z = 0 } ] (Ui.html Icons.reply))
        ]
        [ Ui.text "Reply to "
        , Ui.el [ Ui.Font.bold ] (Ui.text (User.toString userId (LocalState.allUsers local)))
        ]
        |> Ui.el [ Ui.paddingWith { left = 0, right = 36, top = 0, bottom = 0 }, Ui.move { x = 0, y = 1, z = 0 } ]


dropdownButtonId : Int -> HtmlId
dropdownButtonId index =
    Dom.id ("dropdown_button" ++ String.fromInt index)


reactionEmojiView : Id ChannelMessageId -> Id UserId -> SeqDict Emoji (NonemptySet (Id UserId)) -> Maybe (Element MessageViewMsg)
reactionEmojiView messageIndex currentUserId reactions =
    if SeqDict.isEmpty reactions then
        Nothing

    else
        Ui.row
            [ Ui.wrap
            , Ui.spacing 4
            ]
            (List.map
                (\( emoji, users ) ->
                    let
                        hasReactedTo : Bool
                        hasReactedTo =
                            NonemptySet.member currentUserId users
                    in
                    Ui.row
                        [ Ui.rounded 8
                        , Ui.spacing 2
                        , Ui.background MyUi.background1
                        , Ui.paddingXY 4 0
                        , Ui.borderColor
                            (if hasReactedTo then
                                MyUi.highlightedBorder

                             else
                                MyUi.border1
                            )
                        , Ui.Font.color
                            (if hasReactedTo then
                                MyUi.highlightedBorder

                             else
                                MyUi.font2
                            )
                        , Ui.border 1
                        , Ui.width Ui.shrink
                        , Ui.Font.bold
                        , Ui.Input.button
                            (if hasReactedTo then
                                MessageView_PressedReactionEmoji_Remove messageIndex emoji

                             else
                                MessageView_PressedReactionEmoji_Add messageIndex emoji
                            )
                        ]
                        [ Emoji.view emoji, Ui.text (String.fromInt (NonemptySet.size users)) ]
                )
                (SeqDict.toList reactions)
            )
            |> Just


messageEditingView :
    Bool
    -> GuildOrDmId
    -> Id ChannelMessageId
    -> Message
    -> Maybe ( Id ChannelMessageId, Message )
    -> Maybe Thread
    -> SeqDict (Id ChannelMessageId) (NonemptySet Int)
    -> EditMessage
    -> Maybe MentionUserDropdown
    -> LocalState
    -> Element FrontendMsg
messageEditingView isMobile guildOrDmId messageIndex message maybeRepliedTo maybeThread revealedSpoilers editing pingUser local =
    case message of
        UserTextMessage data ->
            let
                maybeReactions =
                    reactionEmojiView messageIndex local.localUser.userId data.reactions
            in
            Ui.column
                [ Ui.Font.color MyUi.font1
                , Ui.background MyUi.hoverHighlight
                , Ui.paddingWith
                    { left = 0
                    , right = 0
                    , top = 4
                    , bottom =
                        if maybeReactions == Nothing then
                            8

                        else
                            4
                    }
                , Ui.spacing 4
                , channelMessageHtmlId messageIndex |> Dom.idToString |> Ui.id
                ]
                [ repliedToMessage isMobile maybeRepliedTo revealedSpoilers (LocalState.allUsers local)
                    |> Ui.el [ Ui.paddingXY 8 0 ]
                    |> Ui.map (MessageViewMsg guildOrDmId)
                , User.toString data.createdBy (LocalState.allUsers local)
                    ++ " "
                    |> Ui.text
                    |> Ui.el [ Ui.Font.bold, Ui.paddingXY 8 0 ]
                , Ui.column
                    [ case NonemptyDict.fromSeqDict editing.attachedFiles of
                        Just filesToUpload ->
                            FileStatus.fileUploadPreview
                                (EditMessage_PressedDeleteAttachedFile guildOrDmId)
                                filesToUpload
                                |> Ui.inFront

                        Nothing ->
                            Ui.noAttr
                    ]
                    [ MessageInput.view
                        True
                        False
                        (MessageMenu.editMessageTextInputConfig guildOrDmId)
                        MessageMenu.editMessageTextInputId
                        ""
                        editing.text
                        editing.attachedFiles
                        pingUser
                        local
                        |> Ui.el [ Ui.paddingXY 5 0 ]
                    , Ui.row
                        [ Ui.Font.size 14
                        , Ui.Font.color MyUi.font3
                        , Ui.paddingXY 12 0
                        , MyUi.prewrap
                        ]
                        [ Ui.text "Press "
                        , Ui.el
                            [ Ui.Input.button (PressedCancelMessageEdit guildOrDmId)
                            , Ui.Font.color MyUi.font1
                            , Ui.width Ui.shrink
                            ]
                            (Ui.text "escape")
                        , Ui.text " to cancel edit"
                        ]
                    ]
                , case maybeReactions of
                    Just reactionView ->
                        Ui.el [ Ui.paddingXY 8 0 ] reactionView |> Ui.map (MessageViewMsg guildOrDmId)

                    Nothing ->
                        Ui.none
                , case maybeThread of
                    Just thread ->
                        threadStarterIndicator
                            local.localUser.timezone
                            (LocalState.allUsers local)
                            messageIndex
                            thread
                            |> Ui.el [ Ui.paddingXY 8 0 ]
                            |> Ui.map (MessageViewMsg guildOrDmId)

                    Nothing ->
                        Ui.none
                ]

        UserJoinedMessage _ _ _ ->
            Ui.none

        DeletedMessage _ ->
            Ui.none


type IsHovered
    = IsNotHovered
    | IsHovered
    | IsHoveredButNoMenu


messageViewNotThreadStarter :
    Int
    -> SeqDict (Id ChannelMessageId) (NonemptySet Int)
    -> LocalUser
    -> Int
    -> Message
    -> Element MessageViewMsg
messageViewNotThreadStarter data revealedSpoilers localUser messageIndex message =
    let
        { containerWidth, isEditing, highlight, isHovered, isMobile } =
            messageViewDecode data

        _ =
            Debug.log "rerender messageViewNotThreadStarter" ()
    in
    messageView
        isMobile
        containerWidth
        False
        revealedSpoilers
        highlight
        isHovered
        isEditing
        localUser
        Nothing
        Nothing
        (Id.fromInt messageIndex)
        message


messageViewThreadStarter :
    Int
    -> SeqDict (Id ChannelMessageId) (NonemptySet Int)
    -> LocalUser
    -> Int
    -> Thread
    -> Message
    -> Element MessageViewMsg
messageViewThreadStarter data revealedSpoilers localUser messageIndex thread message =
    let
        { containerWidth, isEditing, highlight, isHovered, isMobile } =
            messageViewDecode data

        _ =
            Debug.log "rerender messageViewThreadStarter" ()
    in
    messageView
        isMobile
        containerWidth
        False
        revealedSpoilers
        highlight
        isHovered
        isEditing
        localUser
        Nothing
        (Just thread)
        (Id.fromInt messageIndex)
        message


type HighlightMessage
    = NoHighlight
    | ReplyToHighlight
    | MentionHighlight
    | UrlHighlight


profileImagePaddingRight : number
profileImagePaddingRight =
    8


messageView :
    Bool
    -> Int
    -> Bool
    -> SeqDict (Id ChannelMessageId) (NonemptySet Int)
    -> HighlightMessage
    -> IsHovered
    -> Bool
    -> LocalUser
    -> Maybe ( Id ChannelMessageId, Message )
    -> Maybe Thread
    -> Id ChannelMessageId
    -> Message
    -> Element MessageViewMsg
messageView isMobile containerWidth isThreadStarter revealedSpoilers highlight isHovered isBeingEdited localUser maybeRepliedTo maybeThreadStarter messageIndex message =
    let
        --_ =
        --    Debug.log "changed" messageIndex
        allUsers : SeqDict (Id UserId) FrontendUser
        allUsers =
            LocalState.allUsers2 localUser
    in
    case message of
        UserTextMessage message2 ->
            messageContainer
                isThreadStarter
                localUser.timezone
                allUsers
                (case highlight of
                    NoHighlight ->
                        if RichText.mentionsUser localUser.userId message2.content then
                            MentionHighlight

                        else
                            highlight

                    _ ->
                        highlight
                )
                messageIndex
                (localUser.userId == message2.createdBy)
                localUser.userId
                message2.reactions
                maybeThreadStarter
                isHovered
                (Ui.row
                    []
                    [ Ui.el
                        [ Ui.paddingWith
                            { left = 0
                            , right = profileImagePaddingRight
                            , top =
                                case maybeRepliedTo of
                                    Just _ ->
                                        24

                                    Nothing ->
                                        2
                            , bottom = 0
                            }
                        , Ui.width Ui.shrink
                        , Ui.alignTop
                        ]
                        (case SeqDict.get message2.createdBy allUsers of
                            Just user ->
                                User.profileImage user.icon

                            Nothing ->
                                User.profileImage Nothing
                        )
                    , Ui.column
                        []
                        [ repliedToMessage isMobile maybeRepliedTo revealedSpoilers allUsers
                        , Ui.row
                            []
                            [ User.toString message2.createdBy allUsers
                                ++ " "
                                |> Ui.text
                                |> Ui.el [ Ui.Font.bold ]
                            , messageTimestamp message2.createdAt localUser.timezone |> Ui.html
                            ]
                        , Html.div
                            [ Html.Attributes.style "white-space" "pre-wrap" ]
                            (RichText.view
                                containerWidth
                                (MessageView_PressedSpoiler messageIndex)
                                (case SeqDict.get messageIndex revealedSpoilers of
                                    Just nonempty ->
                                        NonemptySet.toSeqSet nonempty

                                    Nothing ->
                                        SeqSet.empty
                                )
                                allUsers
                                message2.attachedFiles
                                message2.content
                                ++ (if isBeingEdited then
                                        [ Html.span
                                            [ Html.Attributes.style "color" "rgb(200,200,200)"
                                            , Html.Attributes.style "font-size" "12px"
                                            ]
                                            [ Html.text " (editing...)" ]
                                        ]

                                    else
                                        case message2.editedAt of
                                            Just editedAt ->
                                                [ Html.span
                                                    [ Html.Attributes.style "color" "rgb(200,200,200)"
                                                    , Html.Attributes.style "font-size" "12px"
                                                    , MyUi.datestamp editedAt |> Html.Attributes.title
                                                    ]
                                                    [ Html.text " (edited)" ]
                                                ]

                                            Nothing ->
                                                []
                                   )
                            )
                            |> Ui.html
                        ]
                    ]
                )

        UserJoinedMessage joinedAt userId reactions ->
            messageContainer
                isThreadStarter
                localUser.timezone
                allUsers
                highlight
                messageIndex
                False
                localUser.userId
                reactions
                maybeThreadStarter
                isHovered
                (Ui.row
                    []
                    [ userJoinedContent userId allUsers
                    , messageTimestamp joinedAt localUser.timezone |> Ui.html
                    ]
                )

        DeletedMessage createdAt ->
            messageContainer
                isThreadStarter
                localUser.timezone
                allUsers
                highlight
                messageIndex
                False
                localUser.userId
                SeqDict.empty
                maybeThreadStarter
                isHovered
                (Ui.row
                    [ Ui.paddingWith { left = 4, right = 0, top = 4, bottom = 0 } ]
                    [ Ui.el
                        [ Ui.Font.color MyUi.font3
                        , Ui.Font.italic
                        , Ui.Font.size 14
                        , channelMessageHtmlId messageIndex |> Dom.idToString |> Ui.id
                        , case highlight of
                            NoHighlight ->
                                Ui.noAttr

                            ReplyToHighlight ->
                                Ui.noAttr

                            MentionHighlight ->
                                Ui.noAttr

                            UrlHighlight ->
                                Ui.background MyUi.hoverAndReplyToColor
                        ]
                        (Ui.text "Message deleted")
                    , messageTimestamp createdAt localUser.timezone |> Ui.html
                    ]
                )


messageTimestamp : Time.Posix -> Time.Zone -> Html msg
messageTimestamp createdAt timezone =
    Html.span
        [ Html.Attributes.style "font-size" "14px"
        , Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font3)
        ]
        [ MyUi.timestamp createdAt timezone |> Html.text ]


repliedToMessage :
    Bool
    -> Maybe ( Id ChannelMessageId, Message )
    -> SeqDict (Id ChannelMessageId) (NonemptySet Int)
    -> SeqDict (Id UserId) FrontendUser
    -> Element MessageViewMsg
repliedToMessage isMobile maybeRepliedTo revealedSpoilers allUsers =
    case maybeRepliedTo of
        Just ( repliedToIndex, UserTextMessage repliedToData ) ->
            repliedToHeaderHelper
                isMobile
                repliedToIndex
                (userTextMessagePreview
                    allUsers
                    (case SeqDict.get repliedToIndex revealedSpoilers of
                        Just set ->
                            NonemptySet.toSeqSet set

                        Nothing ->
                            SeqSet.empty
                    )
                    repliedToData
                )

        Just ( repliedToIndex, UserJoinedMessage _ userId _ ) ->
            repliedToHeaderHelper isMobile repliedToIndex (userJoinedContent userId allUsers)

        Just ( repliedToIndex, DeletedMessage _ ) ->
            repliedToHeaderHelper
                isMobile
                repliedToIndex
                (Ui.el
                    [ Ui.Font.italic, Ui.Font.color MyUi.font3 ]
                    (Ui.text "Message deleted")
                )

        Nothing ->
            Ui.none


userTextMessagePreview : SeqDict (Id UserId) FrontendUser -> SeqSet Int -> UserTextMessageData -> Element MessageViewMsg
userTextMessagePreview allUsers revealedSpoilers message =
    Html.div
        [ Html.Attributes.style "white-space" "nowrap"
        , Html.Attributes.style "overflow" "hidden"
        , Html.Attributes.style "text-overflow" "ellipsis"
        ]
        (Html.span
            [ Html.Attributes.style "color" "rgb(200,200,200)"
            , Html.Attributes.style "padding" "0 6px 0 2px"
            ]
            [ Html.text (User.toString message.createdBy allUsers) ]
            :: RichText.preview
                (\_ -> MessageView_NoOp)
                revealedSpoilers
                allUsers
                message.attachedFiles
                message.content
        )
        |> Ui.html


channelMessageHtmlId : Id ChannelMessageId -> HtmlId
channelMessageHtmlId messageIndex =
    "guild_message_" ++ Id.toString messageIndex |> Dom.id


threadMessageHtmlId : Id ThreadMessageId -> HtmlId
threadMessageHtmlId messageIndex =
    "thread_message_" ++ Id.toString messageIndex |> Dom.id


repliedToHeaderHelper : Bool -> Id ChannelMessageId -> Element MessageViewMsg -> Element MessageViewMsg
repliedToHeaderHelper isMobile messageIndex content =
    Ui.row
        [ Ui.Font.color MyUi.font1
        , Ui.Font.size 14
        , Ui.paddingWith { left = 0, right = 8, top = 2, bottom = 0 }
        , Ui.Input.button (MessageView_PressedReplyLink messageIndex)
        , Ui.Font.color MyUi.font3
        , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
        ]
        [ Ui.el
            [ Ui.width (Ui.px 18)
            , Ui.move { x = 0, y = 3, z = 0 }
            ]
            (Ui.html Icons.reply)
        , content
        ]


userJoinedContent : Id UserId -> SeqDict (Id UserId) FrontendUser -> Element msg
userJoinedContent userId allUsers =
    Ui.Prose.paragraph
        [ Ui.paddingXY 0 4 ]
        [ User.toString userId allUsers
            |> Ui.text
            |> Ui.el [ Ui.Font.bold ]
        , Ui.el
            []
            (Ui.text " joined!")
        ]


messagePaddingX : number
messagePaddingX =
    8


messageContainer :
    Bool
    -> Time.Zone
    -> SeqDict (Id UserId) FrontendUser
    -> HighlightMessage
    -> Id ChannelMessageId
    -> Bool
    -> Id UserId
    -> SeqDict Emoji (NonemptySet (Id UserId))
    -> Maybe Thread
    -> IsHovered
    -> Element MessageViewMsg
    -> Element MessageViewMsg
messageContainer isThreadStarter timezone allUsers highlight messageIndex canEdit currentUserId reactions maybeThread isHovered messageContent =
    let
        maybeReactions : Maybe (Element MessageViewMsg)
        maybeReactions =
            reactionEmojiView messageIndex currentUserId reactions
    in
    Ui.column
        ([ Ui.Font.color MyUi.font1
         , Ui.Events.onMouseEnter (MessageView_MouseEnteredMessage messageIndex)
         , Ui.Events.onMouseLeave (MessageView_MouseExitedMessage messageIndex)
         , Ui.Events.on
            "touchstart"
            (Touch.touchEventDecoder
                (\time touches ->
                    MessageView_TouchStart
                        time
                        isThreadStarter
                        messageIndex
                        (NonemptyDict.map (\_ touch -> { touch | target = channelMessageHtmlId messageIndex }) touches)
                )
            )
         , Ui.Events.preventDefaultOn "contextmenu"
            (Json.Decode.map2
                (\x y ->
                    ( MessageView_AltPressedMessage isThreadStarter messageIndex (Coord.xy (round x) (round y))
                    , True
                    )
                )
                (Json.Decode.field "clientX" Json.Decode.float)
                (Json.Decode.field "clientY" Json.Decode.float)
            )
         , Ui.paddingWith
            { left = messagePaddingX
            , right = messagePaddingX
            , top = 4
            , bottom =
                if maybeReactions == Nothing then
                    8

                else
                    4
            }
         , Ui.spacing 4
         , channelMessageHtmlId messageIndex |> Dom.idToString |> Ui.id
         ]
            ++ (case isHovered of
                    IsNotHovered ->
                        case highlight of
                            NoHighlight ->
                                []

                            ReplyToHighlight ->
                                [ Ui.background MyUi.replyToColor ]

                            MentionHighlight ->
                                [ Ui.background MyUi.mentionColor ]

                            UrlHighlight ->
                                [ Ui.background MyUi.replyToColor ]

                    IsHovered ->
                        [ case highlight of
                            NoHighlight ->
                                Ui.background MyUi.hoverHighlight

                            ReplyToHighlight ->
                                Ui.background MyUi.hoverAndReplyToColor

                            MentionHighlight ->
                                Ui.background MyUi.hoverAndMentionColor

                            UrlHighlight ->
                                Ui.background MyUi.hoverAndReplyToColor
                        , MessageView.miniView
                            isThreadStarter
                            canEdit
                            messageIndex
                            |> Ui.inFront
                        ]

                    IsHoveredButNoMenu ->
                        case highlight of
                            NoHighlight ->
                                [ Ui.background MyUi.hoverHighlight ]

                            ReplyToHighlight ->
                                [ Ui.background MyUi.hoverAndReplyToColor ]

                            MentionHighlight ->
                                [ Ui.background MyUi.hoverAndMentionColor ]

                            UrlHighlight ->
                                [ Ui.background MyUi.hoverAndReplyToColor ]
               )
        )
        (messageContent
            :: Maybe.Extra.toList maybeReactions
            ++ (case maybeThread of
                    Just thread ->
                        [ threadStarterIndicator timezone allUsers messageIndex thread
                        ]

                    Nothing ->
                        []
               )
        )


threadStarterIndicator : Time.Zone -> SeqDict (Id UserId) FrontendUser -> Id ChannelMessageId -> Thread -> Element MessageViewMsg
threadStarterIndicator timezone allUsers messageIndex thread =
    let
        lastMessage =
            Array.Extra.last thread.messages
    in
    Html.div
        [ Html.Attributes.style "white-space" "nowrap"
        , Html.Attributes.style "text-overflow" "ellipsis"
        , Html.Attributes.style "overflow" "hidden"
        , Html.Attributes.style "background-color" (MyUi.colorToStyle MyUi.background1)
        , Html.Attributes.style "border" ("1px solid " ++ MyUi.colorToStyle MyUi.border1)
        , Html.Attributes.style "padding" "4px 8px 4px 8px"
        , Html.Attributes.style "width" "fit-content"
        , Html.Attributes.style "max-width" "calc(min(100% - 16px, 800px))"
        , Html.Attributes.style "min-width" "250px"
        , Html.Events.onClick (MessageView_PressedViewThreadLink messageIndex)
        , Html.Attributes.style "cursor" "pointer"
        ]
        (Html.div
            [ Html.Attributes.style "display" "flex"
            , Html.Attributes.style "align-content" "center"
            , Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font3)
            ]
            [ Icons.hashtag
            , case Array.length thread.messages of
                1 ->
                    Html.text "1 message"

                count ->
                    Html.text (String.fromInt count ++ " messages")
            , Html.div [ Html.Attributes.style "flex-grow" "1" ] []
            , case lastMessage of
                Just (UserTextMessage data) ->
                    messageTimestamp data.createdAt timezone

                Just (UserJoinedMessage joinedAt _ _) ->
                    messageTimestamp joinedAt timezone

                Just (DeletedMessage createdAt) ->
                    messageTimestamp createdAt timezone

                Nothing ->
                    Html.text ""
            ]
            :: (case lastMessage of
                    Just last ->
                        case last of
                            UserTextMessage data ->
                                Html.span
                                    [ Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font3)
                                    , Html.Attributes.style "padding" "0 6px 0 2px"
                                    ]
                                    [ Html.text (User.toString data.createdBy allUsers) ]
                                    :: RichText.preview
                                        (\_ -> MessageView_NoOp)
                                        SeqSet.empty
                                        allUsers
                                        data.attachedFiles
                                        data.content

                            UserJoinedMessage _ userId _ ->
                                [ Html.span
                                    []
                                    [ Html.b [] [ User.toString userId allUsers |> Html.text ]
                                    , Html.text " joined!"
                                    ]
                                ]

                            DeletedMessage _ ->
                                [ Html.i
                                    [ Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font3) ]
                                    [ Html.text "Message deleted" ]
                                ]

                    Nothing ->
                        []
               )
        )
        |> Ui.html


channelColumnNotMobile :
    LocalUser
    -> Id GuildId
    -> FrontendGuild
    -> ChannelRoute
    -> Maybe ( Id GuildId, Id ChannelId, ThreadRoute )
    -> Element FrontendMsg
channelColumnNotMobile localUser guildId guild channelRoute channelNameHover =
    channelColumn False localUser guildId guild channelRoute channelNameHover True


channelColumnCanScrollMobile :
    LocalUser
    -> Id GuildId
    -> FrontendGuild
    -> ChannelRoute
    -> Maybe ( Id GuildId, Id ChannelId, ThreadRoute )
    -> Element FrontendMsg
channelColumnCanScrollMobile localUser guildId guild channelRoute channelNameHover =
    channelColumn True localUser guildId guild channelRoute channelNameHover True


channelColumnCannotScrollMobile :
    LocalUser
    -> Id GuildId
    -> FrontendGuild
    -> ChannelRoute
    -> Maybe ( Id GuildId, Id ChannelId, ThreadRoute )
    -> Element FrontendMsg
channelColumnCannotScrollMobile localUser guildId guild channelRoute channelNameHover =
    channelColumn True localUser guildId guild channelRoute channelNameHover False


channelColumnContainer : List (Element msg) -> Element msg -> Element msg
channelColumnContainer header content =
    Ui.el
        [ Ui.height Ui.fill, MyUi.htmlStyle "padding-top" MyUi.insetTop ]
        (Ui.column
            [ Ui.height Ui.fill
            , Ui.background MyUi.background2
            , MyUi.htmlStyle "border-radius" ("calc(" ++ MyUi.insetTop ++ " * 0.5) 0 0 0")
            , Ui.borderWith { left = 1, right = 0, bottom = 0, top = 1 }
            , Ui.borderColor MyUi.border1
            ]
            [ Ui.row
                [ Ui.Font.bold
                , MyUi.htmlStyle "padding" ("0 4px 0 calc(max(" ++ MyUi.insetTop ++ " * 0.25, 8px))")
                , Ui.spacing 8
                , Ui.Font.color MyUi.font1
                , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
                , Ui.borderColor MyUi.border1
                , Ui.height (Ui.px channelHeaderHeight)
                , MyUi.noShrinking
                , Ui.clipWithEllipsis
                ]
                header
            , content
            ]
        )


bounceScroll : Bool -> Ui.Attribute msg
bounceScroll isMobile =
    Ui.attrIf
        isMobile
        (Ui.inFront (Ui.el [ Ui.height (Ui.px 1), Ui.alignBottom, Ui.move { x = 0, y = 1, z = 0 } ] Ui.none))


channelColumn :
    Bool
    -> LocalUser
    -> Id GuildId
    -> FrontendGuild
    -> ChannelRoute
    -> Maybe ( Id GuildId, Id ChannelId, ThreadRoute )
    -> Bool
    -> Element FrontendMsg
channelColumn isMobile localUser guildId guild channelRoute channelNameHover canScroll2 =
    let
        guildName : String
        guildName =
            GuildName.toString guild.name
    in
    channelColumnContainer
        [ Ui.el [ MyUi.hoverText guildName ] (Ui.text guildName)
        , Ui.el
            [ Ui.width Ui.shrink
            , Ui.Input.button (PressedLink (GuildRoute guildId InviteLinkCreatorRoute))
            , Ui.Font.color MyUi.font2
            , Ui.width (Ui.px 40)
            , Ui.alignRight
            , Ui.paddingXY 8 0
            , Ui.height Ui.fill
            , Ui.contentCenterY
            ]
            (Ui.html Icons.inviteUserIcon)
        ]
        (Ui.column
            [ scrollable canScroll2
            , Ui.heightMin 0
            , Ui.paddingXY 0 8
            , Ui.attrIf isMobile (Ui.height Ui.fill)
            , bounceScroll isMobile
            ]
            (List.map
                (\( channelId, channel ) ->
                    Ui.column
                        []
                        [ channelColumnRow
                            isMobile
                            channelNameHover
                            channelRoute
                            localUser
                            guildId
                            channelId
                            channel
                        , channelColumnThreads
                            isMobile
                            channelRoute
                            localUser
                            guildId
                            channelId
                            channel
                            (case channelRoute of
                                ChannelRoute channelIdB (ViewThreadWithMaybeMessage threadMessageIndex _) ->
                                    if channelIdB == channelId then
                                        SeqDict.insert threadMessageIndex DmChannel.threadInit channel.threads

                                    else
                                        channel.threads

                                _ ->
                                    channel.threads
                            )
                        ]
                )
                (SeqDict.toList guild.channels)
                ++ [ if localUser.userId == guild.owner then
                        let
                            isSelected =
                                channelRoute == NewChannelRoute
                        in
                        Ui.row
                            [ Ui.paddingXY 4 8
                            , Ui.Font.color MyUi.font3
                            , Ui.Input.button (PressedLink (GuildRoute guildId NewChannelRoute))
                            , Ui.attrIf isSelected (Ui.background (Ui.rgba 255 255 255 0.15))
                            , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
                            , if isSelected then
                                Ui.Font.color MyUi.font1

                              else
                                Ui.Font.color MyUi.font3
                            ]
                            [ Ui.el [ Ui.width (Ui.px 22) ] (Ui.html Icons.plusIcon)
                            , Ui.text " Add new channel"
                            ]

                     else
                        Ui.none
                   ]
            )
        )


channelColumnThreads :
    Bool
    -> ChannelRoute
    -> LocalUser
    -> Id GuildId
    -> Id ChannelId
    -> FrontendChannel
    -> SeqDict (Id ChannelMessageId) Thread
    -> Element FrontendMsg
channelColumnThreads isMobile channelRoute localUser guildId channelId channel threads =
    Ui.column
        []
        (SeqDict.toList threads
            |> List.indexedMap
                (\index ( threadMessageIndex, thread ) ->
                    let
                        threadRoute : ThreadRoute
                        threadRoute =
                            ViewThread threadMessageIndex

                        isSelected : Bool
                        isSelected =
                            case channelRoute of
                                ChannelRoute a (ViewThreadWithMaybeMessage b _) ->
                                    a == channelId && b == threadMessageIndex

                                _ ->
                                    False

                        name =
                            threadPreviewText threadMessageIndex channel localUser
                    in
                    Ui.row
                        [ Ui.attrIf isSelected (Ui.background (Ui.rgba 255 255 255 0.15))
                        , Ui.attrIf
                            (not isMobile)
                            (Ui.Events.onMouseEnter (MouseEnteredChannelName guildId channelId threadRoute))
                        , Ui.attrIf
                            (not isMobile)
                            (Ui.Events.onMouseLeave (MouseExitedChannelName guildId channelId threadRoute))
                        , Ui.clipWithEllipsis
                        , Ui.height (Ui.px channelHeaderHeight)
                        , MyUi.hoverText name
                        , Ui.contentCenterY
                        , MyUi.noShrinking
                        ]
                        [ Ui.el
                            [ Ui.Input.button
                                (PressedLink
                                    (GuildRoute guildId (ChannelRoute channelId (ViewThreadWithMaybeMessage threadMessageIndex Nothing)))
                                )
                            , Ui.height Ui.fill
                            , Ui.contentCenterY
                            , Ui.paddingWith
                                { left = 28
                                , right = 8
                                , top = 0
                                , bottom = 0
                                }
                            , Ui.el
                                [ (if isSelected && not isMobile then
                                    NoNotification

                                   else
                                    channelOrThreadHasNotifications
                                        localUser.userId
                                        (case SeqDict.get ( GuildOrDmId_Guild_NoThread guildId channelId, threadMessageIndex ) localUser.user.lastViewedThreads of
                                            Just id ->
                                                Id.increment id

                                            Nothing ->
                                                Id.fromInt 0
                                        )
                                        thread
                                  )
                                    |> GuildIcon.notificationView 4 5 MyUi.background2
                                , Ui.move { x = 0, y = 0, z = 0 }
                                , Ui.Font.color MyUi.font3
                                , Ui.width Ui.shrink
                                ]
                                (Ui.html
                                    (if SeqDict.size threads == 1 then
                                        Icons.threadSingleSegment

                                     else if SeqDict.size threads - 1 == index then
                                        Icons.threadBottomSegment

                                     else if index == 0 then
                                        Icons.threadTopSegment

                                     else
                                        Icons.threadMiddleSegment
                                    )
                                )
                                |> Ui.inFront
                            , if isSelected then
                                Ui.Font.color MyUi.font1

                              else
                                Ui.Font.color MyUi.font3
                            , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
                            ]
                            (Ui.text name)
                        ]
                )
        )


channelColumnRow :
    Bool
    -> Maybe ( Id GuildId, Id ChannelId, ThreadRoute )
    -> ChannelRoute
    -> LocalUser
    -> Id GuildId
    -> Id ChannelId
    -> FrontendChannel
    -> Element FrontendMsg
channelColumnRow isMobile channelNameHover channelRoute localUser guildId channelId channel =
    let
        isSelected : Bool
        isSelected =
            case channelRoute of
                ChannelRoute a (NoThreadWithMaybeMessage _) ->
                    a == channelId

                EditChannelRoute a ->
                    a == channelId

                _ ->
                    False

        isHover : Bool
        isHover =
            channelNameHover == Just ( guildId, channelId, NoThread )
    in
    Ui.row
        [ Ui.attrIf isSelected (Ui.background (Ui.rgba 255 255 255 0.15))
        , Ui.attrIf
            (not isMobile)
            (Ui.Events.onMouseEnter (MouseEnteredChannelName guildId channelId NoThread))
        , Ui.attrIf
            (not isMobile)
            (Ui.Events.onMouseLeave (MouseExitedChannelName guildId channelId NoThread))
        , Ui.clipWithEllipsis
        , Ui.height (Ui.px channelHeaderHeight)
        , MyUi.hoverText (ChannelName.toString channel.name)
        , Ui.contentCenterY
        , MyUi.noShrinking
        ]
        [ Ui.el
            [ Ui.Input.button (PressedLink (GuildRoute guildId (ChannelRoute channelId (NoThreadWithMaybeMessage Nothing))))
            , Ui.height Ui.fill
            , Ui.contentCenterY
            , Ui.paddingWith
                { left = 26
                , right =
                    if isHover then
                        0

                    else
                        8
                , top = 0
                , bottom = 0
                }
            , Ui.el
                [ (if isSelected && not isMobile then
                    NoNotification

                   else
                    channelOrThreadHasNotifications
                        localUser.userId
                        (case SeqDict.get (GuildOrDmId_Guild_NoThread guildId channelId) localUser.user.lastViewed of
                            Just id ->
                                Id.increment id

                            Nothing ->
                                Id.fromInt 0
                        )
                        channel
                  )
                    |> GuildIcon.notificationView 0 -3 MyUi.background2
                , Ui.width (Ui.px 20)
                , Ui.move { x = 4, y = 0, z = 0 }
                , Ui.centerY
                ]
                (Ui.html Icons.hashtag)
                |> Ui.inFront
            , if isSelected then
                Ui.Font.color MyUi.font1

              else
                Ui.Font.color MyUi.font3
            , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
            ]
            (Ui.text (ChannelName.toString channel.name))
        , if isHover then
            Ui.el
                [ Ui.alignRight
                , Ui.width (Ui.px 26)
                , Ui.contentCenterY
                , Ui.height Ui.fill
                , Ui.paddingWith { left = 0, right = 2, top = 0, bottom = 0 }
                , Ui.Font.color MyUi.font3
                , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
                , Ui.Input.button
                    (PressedLink (GuildRoute guildId (EditChannelRoute channelId)))
                ]
                (Ui.html Icons.gear)

          else
            Ui.none
        ]


friendsColumn : Bool -> Maybe ( Id UserId, ThreadRouteWithMaybeMessage ) -> LocalState -> Element FrontendMsg
friendsColumn isMobile openedOtherUserId local =
    channelColumnContainer
        [ Ui.el
            [ Ui.Font.bold
            , Ui.paddingXY 8 8
            , Ui.spacing 8
            , Ui.Font.color MyUi.font1
            ]
            (Ui.text "Direct messages")
        ]
        (Ui.column
            []
            (List.filterMap
                (\( otherUserId, _ ) ->
                    case LocalState.getUser otherUserId local.localUser of
                        Just otherUser ->
                            Ui.Lazy.lazy4 friendLabel isMobile openedOtherUserId otherUserId otherUser |> Just

                        Nothing ->
                            Nothing
                )
                (SeqDict.toList local.dmChannels)
            )
        )


friendLabel : Bool -> Maybe ( Id UserId, ThreadRouteWithMaybeMessage ) -> Id UserId -> FrontendUser -> Element FrontendMsg
friendLabel isMobile openedOtherUserId otherUserId otherUser =
    let
        isSelected : Bool
        isSelected =
            case openedOtherUserId of
                Just ( openedOtherUserId2, _ ) ->
                    openedOtherUserId2 == otherUserId

                Nothing ->
                    False

        _ =
            Debug.log "rerender friendLabel" ()
    in
    Ui.row
        [ Ui.clipWithEllipsis
        , Ui.spacing 8
        , Ui.padding 4
        , Ui.Input.button (PressedLink (Route.DmRoute otherUserId (NoThreadWithMaybeMessage Nothing)))
        , Ui.Font.color
            (if isSelected then
                MyUi.font1

             else
                MyUi.font3
            )
        , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
        , Ui.attrIf isSelected (Ui.background (Ui.rgba 255 255 255 0.15))
        ]
        [ User.profileImage otherUser.icon
        , Ui.el [] (Ui.text (PersonName.toString otherUser.name))
        ]


newChannelFormInit : NewChannelForm
newChannelFormInit =
    { name = "", pressedSubmit = False }


newGuildFormInit : NewGuildForm
newGuildFormInit =
    { name = "", pressedSubmit = False }


editChannelFormInit : FrontendChannel -> NewChannelForm
editChannelFormInit channel =
    { name = ChannelName.toString channel.name, pressedSubmit = False }


editChannelFormView : Id GuildId -> Id ChannelId -> FrontendChannel -> NewChannelForm -> Element FrontendMsg
editChannelFormView guildId channelId channel form =
    Ui.column
        [ Ui.Font.color MyUi.font1, Ui.padding 16, Ui.alignTop, Ui.spacing 16 ]
        [ Ui.el [ Ui.Font.size 24 ] (Ui.text ("Edit #" ++ ChannelName.toString channel.name))
        , channelNameInput form |> Ui.map (EditChannelFormChanged guildId channelId)
        , Ui.row
            [ Ui.spacing 16 ]
            [ Ui.el
                [ Ui.Input.button (PressedCancelEditChannelChanges guildId channelId)
                , Ui.paddingXY 16 8
                , Ui.background MyUi.cancelButtonBackground
                , Ui.width Ui.shrink
                , Ui.rounded 8
                , Ui.Font.color MyUi.buttonFontColor
                , Ui.Font.bold
                , Ui.borderColor MyUi.buttonBorder
                , Ui.border 1
                ]
                (Ui.text "Cancel")
            , submitButton
                (PressedSubmitEditChannelChanges guildId channelId form)
                "Save changes"
            ]

        --, Ui.el [ Ui.height (Ui.px 1), Ui.background splitterColor ] Ui.none
        , Ui.el
            [ Ui.Input.button (PressedDeleteChannel guildId channelId)
            , Ui.paddingXY 16 8
            , Ui.background MyUi.deleteButtonBackground
            , Ui.width Ui.shrink
            , Ui.rounded 8
            , Ui.Font.color MyUi.deleteButtonFont
            , Ui.Font.bold
            , Ui.borderColor MyUi.buttonBorder
            , Ui.border 1
            ]
            (Ui.text "Delete channel")
        ]


newChannelFormView : Bool -> Id GuildId -> NewChannelForm -> Element FrontendMsg
newChannelFormView isMobile2 guildId form =
    Ui.column
        [ Ui.Font.color MyUi.font1, Ui.alignTop ]
        [ channelHeader isMobile2 (Ui.text "Create new channel")
        , Ui.column
            [ Ui.spacing 16, Ui.padding 16 ]
            [ channelNameInput form |> Ui.map (NewChannelFormChanged guildId)
            , submitButton (PressedSubmitNewChannel guildId form) "Create channel"
            ]
        ]


submitButton : msg -> String -> Element msg
submitButton onPress text =
    Ui.el
        [ Ui.Input.button onPress
        , Ui.paddingXY 16 8
        , Ui.background MyUi.buttonBackground
        , Ui.width Ui.shrink
        , Ui.rounded 8
        , Ui.Font.bold
        , Ui.borderColor MyUi.buttonBorder
        , Ui.border 1
        ]
        (Ui.text text)


channelNameInput : NewChannelForm -> Element NewChannelForm
channelNameInput form =
    let
        nameLabel =
            Ui.Input.label
                "newChannelName"
                [ Ui.Font.color MyUi.font2, Ui.paddingXY 2 0 ]
                (Ui.text "Channel name")
    in
    Ui.column
        []
        [ nameLabel.element
        , Ui.Input.text
            [ Ui.padding 6
            , Ui.background MyUi.inputBackground
            , Ui.borderColor MyUi.inputBorder
            , Ui.widthMax 500
            ]
            { onChange = \text -> { form | name = text }
            , text = form.name
            , placeholder = Nothing
            , label = nameLabel.id
            }
        , case ( form.pressedSubmit, ChannelName.fromString form.name ) of
            ( True, Err error ) ->
                Ui.el [ Ui.paddingXY 2 0, Ui.Font.color MyUi.errorColor ] (Ui.text error)

            _ ->
                Ui.none
        ]


newGuildFormView : NewGuildForm -> Element FrontendMsg
newGuildFormView form =
    Ui.column
        [ Ui.Font.color MyUi.font1
        , Ui.padding 16
        , Ui.alignTop
        , Ui.spacing 16
        , Ui.height Ui.fill
        , Ui.width Ui.fill
        , Ui.background MyUi.background1
        , MyUi.htmlStyle "padding-top" MyUi.insetTop
        ]
        [ Ui.el [ Ui.Font.size 24 ] (Ui.text "Create new guild")
        , guildNameInput form |> Ui.map NewGuildFormChanged
        , Ui.row
            [ Ui.spacing 16 ]
            [ Ui.el
                [ Ui.Input.button PressedCancelNewGuild
                , Ui.paddingXY 16 8
                , Ui.background MyUi.cancelButtonBackground
                , Ui.width Ui.shrink
                , Ui.rounded 8
                , Ui.Font.color MyUi.buttonFontColor
                , Ui.Font.bold
                , Ui.borderColor MyUi.buttonBorder
                , Ui.border 1
                ]
                (Ui.text "Cancel")
            , submitButton (PressedSubmitNewGuild form) "Create guild"
            ]
        ]


guildNameInput : NewGuildForm -> Element NewGuildForm
guildNameInput form =
    let
        nameLabel =
            Ui.Input.label
                "newGuildName"
                [ Ui.Font.color MyUi.font2, Ui.paddingXY 2 0 ]
                (Ui.text "Guild name")
    in
    Ui.column
        []
        [ nameLabel.element
        , Ui.Input.text
            [ Ui.padding 6
            , Ui.background MyUi.inputBackground
            , Ui.borderColor MyUi.inputBorder
            , Ui.widthMax 500
            ]
            { onChange = \text -> { form | name = text }
            , text = form.name
            , placeholder = Nothing
            , label = nameLabel.id
            }
        , case ( form.pressedSubmit, GuildName.fromString form.name ) of
            ( True, Err error ) ->
                Ui.el [ Ui.paddingXY 2 0, Ui.Font.color MyUi.errorColor ] (Ui.text error)

            _ ->
                Ui.none
        ]
