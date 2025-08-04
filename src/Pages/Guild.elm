module Pages.Guild exposing
    ( channelHeaderHeight
    , channelTextInputId
    , conversationContainerId
    , dropdownButtonId
    , guildView
    , homePageLoggedInView
    , messageHtmlId
    , messageHtmlIdPrefix
    , messageInputConfig
    , newGuildFormInit
    , repliedToUserId
    )

import Array exposing (Array)
import ChannelName
import Coord
import DmChannel exposing (LastTypedAt)
import Duration
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Emoji exposing (Emoji)
import Env
import GuildIcon exposing (NotificationType(..))
import GuildName
import Html
import Html.Attributes
import Icons
import Id exposing (ChannelId, GuildId, Id, UserId)
import Json.Decode
import List.Extra
import LocalState exposing (FrontendChannel, FrontendGuild, LocalState, LocalUser)
import Maybe.Extra
import Message exposing (Message(..))
import MessageInput exposing (MentionUserDropdown, MsgConfig)
import MessageMenu
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
import User exposing (BackendUser, FrontendUser, GuildOrDmId(..))


repliedToUserId : Maybe Int -> FrontendChannel -> Maybe (Id UserId)
repliedToUserId maybeRepliedTo channel =
    case maybeRepliedTo of
        Just repliedTo ->
            case Array.get repliedTo channel.messages of
                Just (UserTextMessage repliedToData) ->
                    Just repliedToData.createdBy

                Just (UserJoinedMessage _ joinedUser _) ->
                    Just joinedUser

                Just DeletedMessage ->
                    Nothing

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


channelHasNotifications :
    Id UserId
    -> BackendUser
    -> GuildOrDmId
    -> FrontendChannel
    -> NotificationType
channelHasNotifications currentUserId currentUser guildOrDmId channel =
    let
        lastViewed : Int
        lastViewed =
            SeqDict.get guildOrDmId currentUser.lastViewed
                |> Maybe.withDefault -1
                |> (+) 1
    in
    Array.slice lastViewed (Array.length channel.messages) channel.messages
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

                            DeletedMessage ->
                                state
            )
            NoNotification


guildHasNotifications : Id UserId -> BackendUser -> Id GuildId -> FrontendGuild -> NotificationType
guildHasNotifications currentUserId currentUser guildId guild =
    List.foldl
        (\( channelId, channel ) state ->
            case state of
                NewMessageForUser ->
                    state

                _ ->
                    case channelHasNotifications currentUserId currentUser (GuildOrDmId_Guild guildId channelId) channel of
                        NoNotification ->
                            state

                        notification ->
                            notification
        )
        NoNotification
        (SeqDict.toList guild.channels)


canScroll : LoadedFrontend -> Bool
canScroll model =
    case model.drag of
        Dragging dragging ->
            not dragging.horizontalStart

        _ ->
            True


guildColumn : Route -> Id UserId -> BackendUser -> SeqDict (Id GuildId) FrontendGuild -> Bool -> Element FrontendMsg
guildColumn route currentUserId currentUser guilds canScroll2 =
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
            , Ui.width Ui.shrink
            , Ui.height Ui.fill
            , Ui.background MyUi.background1
            , scrollable canScroll2
            , Ui.htmlAttribute (Html.Attributes.class "disable-scrollbars")
            , MyUi.htmlStyle "padding" ("calc(max(6px, " ++ MyUi.insetTop ++ ")) 0 4px 0")
            ]
            (GuildIcon.showFriendsButton (route == HomePageRoute) (PressedLink HomePageRoute)
                :: List.map
                    (\( guildId, guild ) ->
                        Ui.el
                            [ Ui.Input.button
                                (PressedLink
                                    (GuildRoute
                                        guildId
                                        (ChannelRoute
                                            (SeqDict.get guildId currentUser.lastChannelViewed
                                                |> Maybe.withDefault guild.announcementChannel
                                            )
                                            Nothing
                                        )
                                    )
                                )
                            ]
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
                ++ [ GuildIcon.addGuildButton False PressedCreateGuild ]
            )
        )


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
        , Ui.el
            [ Ui.width (Ui.px 30)
            , Ui.paddingXY 4 0
            , Ui.alignRight
            , Ui.Input.button PressedShowUserOption
            ]
            (Ui.html Icons.gearIcon)
        ]


homePageLoggedInView : Maybe (Id UserId) -> Maybe Int -> LoadedFrontend -> LoggedIn2 -> LocalState -> Element FrontendMsg
homePageLoggedInView maybeOtherUserId maybeMessageHighlight model loggedIn local =
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
                        ]
                        [ Ui.row
                            [ Ui.height Ui.fill, Ui.heightMin 0 ]
                            [ Ui.Lazy.lazy5
                                guildColumn
                                model.route
                                local.localUser.userId
                                local.localUser.user
                                local.guilds
                                (canScroll model)
                            , friendsColumn maybeOtherUserId local
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
                            [ Ui.Lazy.lazy5
                                guildColumn
                                model.route
                                local.localUser.userId
                                local.localUser.user
                                local.guilds
                                (canScroll model)
                            , friendsColumn maybeOtherUserId local
                            ]
                        , loggedInAsView local
                        ]
                    , case maybeOtherUserId of
                        Just otherUserId ->
                            dmChannelView otherUserId maybeMessageHighlight loggedIn local model
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
                            Ui.el [ Ui.Font.color MyUi.font1, Ui.contentCenterX ] (Ui.text "Work in progress")
                    ]


dmChannelView : Id UserId -> Maybe Int -> LoggedIn2 -> LocalState -> LoadedFrontend -> Element FrontendMsg
dmChannelView otherUserId maybeMessageHighlight loggedIn local model =
    case LocalState.getUser otherUserId local of
        Just otherUser ->
            SeqDict.get otherUserId local.dmChannels
                |> Maybe.withDefault DmChannel.init
                |> conversationView
                    (GuildOrDmId_Dm otherUserId)
                    maybeMessageHighlight
                    loggedIn
                    model
                    local
                    (PersonName.toString otherUser.name)

        Nothing ->
            Ui.el
                [ Ui.centerY
                , Ui.Font.center
                , Ui.Font.color MyUi.font1
                , Ui.Font.size 20
                ]
                (Ui.text "User not found")


guildView : LoadedFrontend -> Id GuildId -> ChannelRoute -> LoggedIn2 -> LocalState -> Element FrontendMsg
guildView model guildId channelRoute loggedIn local =
    case loggedIn.newGuildForm of
        Just form ->
            newGuildFormView form

        Nothing ->
            case SeqDict.get guildId local.guilds of
                Just guild ->
                    let
                        canScroll2 =
                            canScroll model
                    in
                    if MyUi.isMobile model then
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
                                [ Ui.Lazy.lazy5
                                    guildColumn
                                    model.route
                                    local.localUser.userId
                                    local.localUser.user
                                    local.guilds
                                    canScroll2
                                , Ui.Lazy.lazy6
                                    (if canScroll2 then
                                        channelColumnCanScroll

                                     else
                                        channelColumnCannotScroll
                                    )
                                    local.localUser.userId
                                    local.localUser.user
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
                                    [ Ui.Lazy.lazy5
                                        guildColumn
                                        model.route
                                        local.localUser.userId
                                        local.localUser.user
                                        local.guilds
                                        canScroll2
                                    , Ui.Lazy.lazy6
                                        (if canScroll2 then
                                            channelColumnCanScroll

                                         else
                                            channelColumnCannotScroll
                                        )
                                        local.localUser.userId
                                        local.localUser.user
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
                            , memberColumn local guild
                                |> Ui.el
                                    [ Ui.width Ui.shrink
                                    , Ui.height Ui.fill
                                    , MyUi.htmlStyle "padding-top" MyUi.insetTop
                                    ]
                            ]

                Nothing ->
                    homePageLoggedInView Nothing Nothing model loggedIn local


memberColumn : LocalState -> FrontendGuild -> Element FrontendMsg
memberColumn local guild =
    Ui.column
        [ Ui.height Ui.fill
        , Ui.alignRight
        , Ui.background MyUi.background2
        , Ui.Font.color MyUi.font1
        , Ui.width (Ui.px 200)
        , Ui.scrollable
        ]
        [ Ui.column
            [ Ui.paddingXY 4 4 ]
            [ Ui.text "Owner"
            , memberLabel local guild.owner
            ]
        , Ui.column
            [ Ui.paddingXY 4 4 ]
            [ Ui.text "Members"
            , Ui.column
                [ Ui.height Ui.fill ]
                (List.map
                    (\( userId, _ ) ->
                        memberLabel local userId
                    )
                    (SeqDict.toList guild.members)
                )
            ]
        ]


memberLabel : LocalState -> Id UserId -> Element FrontendMsg
memberLabel local userId =
    Ui.row
        [ Ui.spacing 8
        , Ui.paddingXY 4 4
        , Ui.Input.button (PressedLink (DmRoute userId Nothing))
        , MyUi.hover
            [ Ui.Anim.backgroundColor (Ui.rgba 255 255 255 0.1)
            , Ui.Anim.fontColor MyUi.font1
            ]
        , Ui.Font.color MyUi.font3
        ]
        [ User.profileImage
        , case LocalState.getUser userId local of
            Just user ->
                Ui.text (PersonName.toString user.name)

            Nothing ->
                Ui.none
        ]


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


channelView : ChannelRoute -> Id GuildId -> FrontendGuild -> LoggedIn2 -> LocalState -> LoadedFrontend -> Element FrontendMsg
channelView channelRoute guildId guild loggedIn local model =
    case channelRoute of
        ChannelRoute channelId maybeMessageHighlight ->
            case SeqDict.get channelId guild.channels of
                Just channel ->
                    conversationView
                        (GuildOrDmId_Guild guildId channelId)
                        maybeMessageHighlight
                        loggedIn
                        model
                        local
                        (ChannelName.toString channel.name)
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
        , Ui.el
            [ Ui.Input.button (PressedCopyText text)
            , Ui.Font.color MyUi.font2
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


conversationViewHelper :
    GuildOrDmId
    -> Maybe Int
    -> { a | lastTypedAt : SeqDict (Id UserId) LastTypedAt, messages : Array Message }
    -> LoggedIn2
    -> LocalState
    -> LoadedFrontend
    -> List (Element FrontendMsg)
conversationViewHelper guildOrDmId maybeMessageHighlight channel loggedIn local model =
    let
        maybeEditing : Maybe EditMessage
        maybeEditing =
            SeqDict.get guildOrDmId loggedIn.editMessage

        othersEditing : SeqSet Int
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

        replyToIndex : Maybe Int
        replyToIndex =
            SeqDict.get guildOrDmId loggedIn.replyTo

        revealedSpoilers : SeqDict Int (NonemptySet Int)
        revealedSpoilers =
            case loggedIn.revealedSpoilers of
                Just revealed ->
                    if revealed.guildOrDmId == guildOrDmId then
                        revealed.messages

                    else
                        SeqDict.empty

                Nothing ->
                    SeqDict.empty

        lastViewedIndex : Int
        lastViewedIndex =
            SeqDict.get guildOrDmId local.localUser.user.lastViewed |> Maybe.withDefault -1
    in
    Array.foldr
        (\message ( index, list ) ->
            let
                messageHover : IsHovered
                messageHover =
                    case loggedIn.messageHover of
                        MessageMenu messageMenu ->
                            if guildOrDmId == messageMenu.guildOrDmId then
                                if messageMenu.messageIndex == index then
                                    IsHoveredButNoMenu

                                else
                                    IsNotHovered

                            else
                                IsNotHovered

                        MessageHover guildOrDmIdA messageIndex ->
                            if guildOrDmId == guildOrDmIdA then
                                if messageIndex == index then
                                    IsHovered

                                else
                                    IsNotHovered

                            else
                                IsNotHovered

                        _ ->
                            IsNotHovered

                otherUserIsEditing : Bool
                otherUserIsEditing =
                    SeqSet.member index othersEditing

                isEditing : Maybe EditMessage
                isEditing =
                    case maybeEditing of
                        Just editing ->
                            if editing.messageIndex == index then
                                Just editing

                            else
                                Nothing

                        Nothing ->
                            Nothing

                highlight : HighlightMessage
                highlight =
                    if maybeMessageHighlight == Just index then
                        UrlHighlight

                    else if replyToIndex == Just index then
                        ReplyToHighlight

                    else
                        NoHighlight

                newLine : List (Element msg)
                newLine =
                    if lastViewedIndex == index - 1 then
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
                                    , Ui.Font.bold
                                    , Ui.height (Ui.px 15)
                                    , Ui.roundedWith
                                        { bottomLeft = 4, bottomRight = 0, topLeft = 0, topRight = 0 }
                                    ]
                                    (Ui.text "New")
                                )
                            ]
                            Ui.none
                        ]

                    else
                        []

                maybeRepliedTo : Maybe ( Int, Message )
                maybeRepliedTo =
                    case message of
                        UserTextMessage data ->
                            case data.repliedTo of
                                Just repliedToIndex ->
                                    case Array.get repliedToIndex channel.messages of
                                        Just message2 ->
                                            Just ( repliedToIndex, message2 )

                                        Nothing ->
                                            Nothing

                                Nothing ->
                                    Nothing

                        UserJoinedMessage _ _ _ ->
                            Nothing

                        DeletedMessage ->
                            Nothing
            in
            ( index - 1
            , newLine
                ++ (case isEditing of
                        Just editing ->
                            if MyUi.isMobile model then
                                -- On mobile, we show the editor at the bottom instead
                                messageView
                                    revealedSpoilers
                                    highlight
                                    messageHover
                                    otherUserIsEditing
                                    local.localUser
                                    maybeRepliedTo
                                    index
                                    message

                            else
                                messageEditingView
                                    guildOrDmId
                                    index
                                    message
                                    maybeRepliedTo
                                    revealedSpoilers
                                    editing
                                    loggedIn.pingUser
                                    local

                        Nothing ->
                            case messageHover of
                                IsNotHovered ->
                                    case highlight of
                                        NoHighlight ->
                                            case maybeRepliedTo of
                                                Just _ ->
                                                    messageView
                                                        revealedSpoilers
                                                        highlight
                                                        messageHover
                                                        otherUserIsEditing
                                                        local.localUser
                                                        maybeRepliedTo
                                                        index
                                                        message

                                                Nothing ->
                                                    Ui.Lazy.lazy5
                                                        messageViewNotHovered
                                                        otherUserIsEditing
                                                        revealedSpoilers
                                                        local.localUser
                                                        index
                                                        message

                                        _ ->
                                            messageView
                                                revealedSpoilers
                                                highlight
                                                messageHover
                                                otherUserIsEditing
                                                local.localUser
                                                maybeRepliedTo
                                                index
                                                message

                                _ ->
                                    messageView
                                        revealedSpoilers
                                        highlight
                                        messageHover
                                        otherUserIsEditing
                                        local.localUser
                                        maybeRepliedTo
                                        index
                                        message
                   )
                :: list
            )
        )
        ( Array.length channel.messages - 1, [] )
        channel.messages
        |> Tuple.second


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
    , typedMessage = TypedMessage guildOrDmId
    , pressedSendMessage = PressedSendMessage guildOrDmId
    , pressedArrowInDropdown = PressedArrowInDropdown guildOrDmId
    , pressedArrowUpInEmptyInput = PressedArrowUpInEmptyInput guildOrDmId
    , pressedPingUser = PressedPingUser guildOrDmId
    , pressedPingDropdownContainer = PressedPingDropdownContainer
    , target = MessageInput.NewMessage
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
    GuildOrDmId
    -> Maybe Int
    -> LoggedIn2
    -> LoadedFrontend
    -> LocalState
    -> String
    -> { a | lastTypedAt : SeqDict (Id UserId) LastTypedAt, messages : Array Message }
    -> Element FrontendMsg
conversationView guildOrDmId maybeMessageHighlight loggedIn model local name channel =
    let
        allUsers : SeqDict (Id UserId) FrontendUser
        allUsers =
            LocalState.allUsers local

        replyTo : Maybe Int
        replyTo =
            SeqDict.get guildOrDmId loggedIn.replyTo
    in
    Ui.column
        [ Ui.height Ui.fill
        , Ui.heightMin 0
        ]
        [ channelHeader
            (MyUi.isMobile model)
            (case guildOrDmId of
                GuildOrDmId_Dm otherUserId ->
                    Ui.row
                        [ Ui.Font.color MyUi.font1 ]
                        (if otherUserId == local.localUser.userId then
                            [ Ui.el
                                [ Ui.Font.color MyUi.font3
                                , Ui.width Ui.shrink
                                , MyUi.prewrap
                                ]
                                (Ui.text "Private chat with yourself")
                            ]

                         else
                            [ Ui.el
                                [ Ui.Font.color MyUi.font3
                                , Ui.width Ui.shrink
                                , MyUi.prewrap
                                ]
                                (Ui.text "Private chat with ")
                            , Ui.text name
                            ]
                        )

                GuildOrDmId_Guild _ _ ->
                    Ui.row
                        [ Ui.Font.color MyUi.font1, Ui.spacing 2 ]
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
                , Ui.id (Dom.idToString conversationContainerId)
                , Ui.Events.on "scroll" (scrollToBottomDecoder model.scrolledToBottomOfChannel)
                , Ui.heightMin 0
                ]
                (Ui.el
                    [ Ui.Font.color MyUi.font2, Ui.paddingXY 8 4 ]
                    (case guildOrDmId of
                        GuildOrDmId_Guild _ _ ->
                            Ui.text ("This is the start of #" ++ name)

                        GuildOrDmId_Dm otherUserId ->
                            Ui.text
                                ("This is the start of your conversation with "
                                    ++ (if otherUserId == local.localUser.userId then
                                            "yourself"

                                        else
                                            name
                                       )
                                )
                    )
                    :: conversationViewHelper
                        guildOrDmId
                        maybeMessageHighlight
                        channel
                        loggedIn
                        local
                        model
                )
            )
        , Ui.column
            [ Ui.paddingXY 2 0, Ui.heightMin 0, MyUi.noShrinking ]
            [ case replyTo of
                Just messageIndex ->
                    case Array.get messageIndex channel.messages of
                        Just (UserTextMessage data) ->
                            replyToHeader (PressedCloseReplyTo guildOrDmId) data.createdBy local

                        Just (UserJoinedMessage _ userId _) ->
                            replyToHeader (PressedCloseReplyTo guildOrDmId) userId local

                        Just DeletedMessage ->
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
                    GuildOrDmId_Guild _ _ ->
                        "Write a message in #" ++ name

                    GuildOrDmId_Dm otherUserId ->
                        "Write a message to "
                            ++ (if otherUserId == local.localUser.userId then
                                    "yourself"

                                else
                                    name
                               )
                )
                (case SeqDict.get guildOrDmId loggedIn.drafts of
                    Just text ->
                        String.Nonempty.toString text

                    Nothing ->
                        ""
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
                            ++ MyUi.insetBottom
                            ++ " calc(12px + "
                            ++ MyUi.insetBottom
                            ++ " * 0.5)"
                        )
                    ]
            ]
        ]


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


reactionEmojiView : Int -> Id UserId -> SeqDict Emoji (NonemptySet (Id UserId)) -> Maybe (Element FrontendMsg)
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
                                PressedReactionEmoji_Remove messageIndex emoji

                             else
                                PressedReactionEmoji_Add messageIndex emoji
                            )
                        ]
                        [ Emoji.view emoji, Ui.text (String.fromInt (NonemptySet.size users)) ]
                )
                (SeqDict.toList reactions)
            )
            |> Just


messageEditingView :
    GuildOrDmId
    -> Int
    -> Message
    -> Maybe ( Int, Message )
    -> SeqDict Int (NonemptySet Int)
    -> EditMessage
    -> Maybe MentionUserDropdown
    -> LocalState
    -> Element FrontendMsg
messageEditingView guildOrDmId messageIndex message maybeRepliedTo revealedSpoilers editing pingUser local =
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
                , messageHtmlId messageIndex |> Dom.idToString |> Ui.id
                ]
                [ repliedToMessage maybeRepliedTo revealedSpoilers (LocalState.allUsers local)
                    |> Ui.el [ Ui.paddingXY 8 0 ]
                , User.toString data.createdBy (LocalState.allUsers local)
                    ++ " "
                    |> Ui.text
                    |> Ui.el [ Ui.Font.bold, Ui.paddingXY 8 0 ]
                , Ui.column
                    []
                    [ MessageInput.view
                        True
                        False
                        (MessageMenu.editMessageTextInputConfig guildOrDmId)
                        MessageMenu.editMessageTextInputId
                        ""
                        editing.text
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
                        Ui.el [ Ui.paddingXY 8 0 ] reactionView

                    Nothing ->
                        Ui.none
                ]

        UserJoinedMessage _ _ _ ->
            Ui.none

        DeletedMessage ->
            Ui.none


type IsHovered
    = IsNotHovered
    | IsHovered
    | IsHoveredButNoMenu


messageViewNotHovered :
    Bool
    -> SeqDict Int (NonemptySet Int)
    -> LocalUser
    -> Int
    -> Message
    -> Element FrontendMsg
messageViewNotHovered isEditing revealedSpoilers localUser messageIndex message =
    messageView
        revealedSpoilers
        NoHighlight
        IsNotHovered
        isEditing
        localUser
        Nothing
        messageIndex
        message


type HighlightMessage
    = NoHighlight
    | ReplyToHighlight
    | MentionHighlight
    | UrlHighlight


messageView :
    SeqDict Int (NonemptySet Int)
    -> HighlightMessage
    -> IsHovered
    -> Bool
    -> LocalUser
    -> Maybe ( Int, Message )
    -> Int
    -> Message
    -> Element FrontendMsg
messageView revealedSpoilers highlight isHovered isBeingEdited localUser maybeRepliedTo messageIndex message =
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
                isHovered
                (Ui.row
                    []
                    [ Ui.el
                        [ Ui.paddingWith
                            { left = 0
                            , right = 8
                            , top =
                                case maybeRepliedTo of
                                    Just _ ->
                                        22

                                    Nothing ->
                                        2
                            , bottom = 0
                            }
                        , Ui.width Ui.shrink
                        , Ui.alignTop
                        ]
                        User.profileImage
                    , Ui.column
                        []
                        [ repliedToMessage maybeRepliedTo revealedSpoilers allUsers
                        , User.toString message2.createdBy allUsers
                            ++ " "
                            |> Ui.text
                            |> Ui.el [ Ui.Font.bold ]
                        , Html.div
                            [ Html.Attributes.style "white-space" "pre-wrap" ]
                            (RichText.view
                                (PressedSpoiler messageIndex)
                                (case SeqDict.get messageIndex revealedSpoilers of
                                    Just nonempty ->
                                        NonemptySet.toSeqSet nonempty

                                    Nothing ->
                                        SeqSet.empty
                                )
                                allUsers
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

        UserJoinedMessage _ userId reactions ->
            messageContainer
                highlight
                messageIndex
                False
                localUser.userId
                reactions
                isHovered
                (userJoinedContent userId allUsers)

        DeletedMessage ->
            Ui.el
                [ Ui.Font.color MyUi.font3
                , Ui.Font.italic
                , Ui.Font.size 14
                , Ui.paddingXY 8 4
                , messageHtmlId messageIndex |> Dom.idToString |> Ui.id
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


repliedToMessage :
    Maybe ( Int, Message )
    -> SeqDict Int (NonemptySet Int)
    -> SeqDict (Id UserId) FrontendUser
    -> Element FrontendMsg
repliedToMessage maybeRepliedTo revealedSpoilers allUsers =
    case maybeRepliedTo of
        Just ( repliedToIndex, UserTextMessage repliedToData ) ->
            repliedToHeaderHelper
                repliedToIndex
                (Html.div
                    [ Html.Attributes.style "white-space" "nowrap"
                    , Html.Attributes.style "overflow" "hidden"
                    , Html.Attributes.style "text-overflow" "ellipsis"
                    ]
                    (Html.span
                        [ Html.Attributes.style "color" "rgb(200,200,200)"
                        , Html.Attributes.style "padding" "0 6px 0 2px"
                        ]
                        [ Html.text (User.toString repliedToData.createdBy allUsers) ]
                        :: RichText.view
                            (\_ -> FrontendNoOp)
                            (case SeqDict.get repliedToIndex revealedSpoilers of
                                Just set ->
                                    NonemptySet.toSeqSet set

                                Nothing ->
                                    SeqSet.empty
                            )
                            allUsers
                            repliedToData.content
                    )
                    |> Ui.html
                )

        Just ( repliedToIndex, UserJoinedMessage _ userId _ ) ->
            repliedToHeaderHelper repliedToIndex (userJoinedContent userId allUsers)

        Just ( repliedToIndex, DeletedMessage ) ->
            repliedToHeaderHelper
                repliedToIndex
                (Ui.el
                    [ Ui.Font.italic, Ui.Font.color MyUi.font3 ]
                    (Ui.text "Message deleted")
                )

        Nothing ->
            Ui.none


messageHtmlId : Int -> HtmlId
messageHtmlId messageIndex =
    messageHtmlIdPrefix ++ String.fromInt messageIndex |> Dom.id


messageHtmlIdPrefix : String
messageHtmlIdPrefix =
    "guild_message_"


repliedToHeaderHelper : Int -> Element FrontendMsg -> Element FrontendMsg
repliedToHeaderHelper messageIndex content =
    Ui.row
        [ Ui.Font.color MyUi.font1
        , Ui.Font.size 14
        , Ui.paddingWith { left = 0, right = 8, top = 2, bottom = 0 }
        , Ui.Input.button (PressedReplyLink messageIndex)
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


messageContainer :
    HighlightMessage
    -> Int
    -> Bool
    -> Id UserId
    -> SeqDict Emoji (NonemptySet (Id UserId))
    -> IsHovered
    -> Element FrontendMsg
    -> Element FrontendMsg
messageContainer highlight messageIndex canEdit currentUserId reactions isHovered messageContent =
    let
        maybeReactions =
            reactionEmojiView messageIndex currentUserId reactions
    in
    Ui.column
        ([ Ui.Font.color MyUi.font1
         , Ui.Events.onMouseEnter (MouseEnteredMessage messageIndex)
         , Ui.Events.onMouseLeave (MouseExitedMessage messageIndex)
         , Ui.Events.on
            "touchstart"
            (Touch.touchEventDecoder
                (\time touches ->
                    TouchStart
                        time
                        (NonemptyDict.map (\_ touch -> { touch | target = messageHtmlId messageIndex }) touches)
                )
            )
         , Ui.Events.preventDefaultOn "contextmenu"
            (Json.Decode.map2
                (\x y -> ( AltPressedMessage messageIndex (Coord.xy (round x) (round y)), True ))
                (Json.Decode.field "clientX" Json.Decode.float)
                (Json.Decode.field "clientY" Json.Decode.float)
            )
         , Ui.paddingWith
            { left = 8
            , right = 8
            , top = 4
            , bottom =
                if maybeReactions == Nothing then
                    8

                else
                    4
            }
         , Ui.spacing 4
         , messageHtmlId messageIndex |> Dom.idToString |> Ui.id
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
                        , MessageMenu.miniView canEdit messageIndex
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
        (messageContent :: Maybe.Extra.toList maybeReactions)


channelColumnCanScroll : Id UserId -> BackendUser -> Id GuildId -> FrontendGuild -> ChannelRoute -> Maybe ( Id GuildId, Id ChannelId ) -> Element FrontendMsg
channelColumnCanScroll currentUserId currentUser guildId guild channelRoute channelNameHover =
    channelColumn currentUserId currentUser guildId guild channelRoute channelNameHover True


channelColumnCannotScroll : Id UserId -> BackendUser -> Id GuildId -> FrontendGuild -> ChannelRoute -> Maybe ( Id GuildId, Id ChannelId ) -> Element FrontendMsg
channelColumnCannotScroll currentUserId currentUser guildId guild channelRoute channelNameHover =
    channelColumn currentUserId currentUser guildId guild channelRoute channelNameHover False


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
                , Ui.height (Ui.px 40)
                , MyUi.noShrinking
                , Ui.clipWithEllipsis
                ]
                header
            , content
            ]
        )


channelColumn :
    Id UserId
    -> BackendUser
    -> Id GuildId
    -> FrontendGuild
    -> ChannelRoute
    -> Maybe ( Id GuildId, Id ChannelId )
    -> Bool
    -> Element FrontendMsg
channelColumn currentUserId currentUser guildId guild channelRoute channelNameHover canScroll2 =
    let
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
            [ Ui.paddingXY 0 8, scrollable canScroll2 ]
            (List.map
                (\( channelId, channel ) ->
                    let
                        isSelected : Bool
                        isSelected =
                            case channelRoute of
                                ChannelRoute a _ ->
                                    a == channelId

                                EditChannelRoute a ->
                                    a == channelId

                                _ ->
                                    False

                        isHover : Bool
                        isHover =
                            channelNameHover == Just ( guildId, channelId )
                    in
                    Ui.row
                        [ Ui.attrIf isSelected (Ui.background (Ui.rgba 255 255 255 0.15))
                        , Ui.Events.onMouseEnter (MouseEnteredChannelName guildId channelId)
                        , Ui.Events.onMouseLeave (MouseExitedChannelName guildId channelId)
                        , Ui.clipWithEllipsis
                        , Ui.height (Ui.px channelHeaderHeight)
                        , MyUi.hoverText (ChannelName.toString channel.name)
                        , Ui.contentCenterY
                        , MyUi.noShrinking
                        ]
                        [ Ui.el
                            [ Ui.Input.button (PressedLink (GuildRoute guildId (ChannelRoute channelId Nothing)))
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
                                [ channelHasNotifications
                                    currentUserId
                                    currentUser
                                    (GuildOrDmId_Guild guildId channelId)
                                    channel
                                    |> GuildIcon.notificationView MyUi.background2
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
                            , MyUi.hover [ Ui.Anim.fontColor MyUi.font1 ]
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
                                , MyUi.hover [ Ui.Anim.fontColor MyUi.font1 ]
                                , Ui.Input.button
                                    (PressedLink (GuildRoute guildId (EditChannelRoute channelId)))
                                ]
                                (Ui.html Icons.gearIcon)

                          else
                            Ui.none
                        ]
                )
                (SeqDict.toList guild.channels)
                ++ [ if currentUserId == guild.owner then
                        let
                            isSelected =
                                channelRoute == NewChannelRoute
                        in
                        Ui.row
                            [ Ui.paddingXY 4 8
                            , Ui.Font.color MyUi.font3
                            , Ui.Input.button (PressedLink (GuildRoute guildId NewChannelRoute))
                            , Ui.attrIf isSelected (Ui.background (Ui.rgba 255 255 255 0.15))
                            , MyUi.hover [ Ui.Anim.fontColor MyUi.font1 ]
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


friendsColumn : Maybe (Id UserId) -> LocalState -> Element FrontendMsg
friendsColumn openedOtherUserId local =
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
                    case LocalState.getUser otherUserId local of
                        Just otherUser ->
                            let
                                isSelected : Bool
                                isSelected =
                                    Just otherUserId == openedOtherUserId
                            in
                            Ui.row
                                [ Ui.clipWithEllipsis
                                , Ui.spacing 8
                                , Ui.padding 4
                                , Ui.Input.button (PressedLink (Route.DmRoute otherUserId Nothing))
                                , Ui.Font.color
                                    (if isSelected then
                                        MyUi.font1

                                     else
                                        MyUi.font3
                                    )
                                , MyUi.hover [ Ui.Anim.fontColor MyUi.font1 ]
                                , Ui.attrIf isSelected (Ui.background (Ui.rgba 255 255 255 0.15))
                                ]
                                [ User.profileImage
                                , Ui.el [] (Ui.text (PersonName.toString otherUser.name))
                                ]
                                |> Just

                        Nothing ->
                            Nothing
                )
                (SeqDict.toList local.dmChannels)
            )
        )


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
