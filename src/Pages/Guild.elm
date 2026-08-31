module Pages.Guild exposing
    ( DmChannelSelection(..)
    , HighlightMessage(..)
    , IsHovered(..)
    , channelDoesNotExistText
    , channelMessageHtmlId
    , channelSearchInputId
    , channelTextInputId
    , chatWithText
    , confirmLeaveGuildText
    , conversationContainerId
    , declineE2eeText
    , decodeMessageView
    , deleteGuildText
    , directMessagesText
    , discordGuildView
    , dropdownButtonId
    , e2eeDeclinedText
    , e2eeSectionIsExpanded
    , e2eeSectionTitle
    , editingText
    , enableE2eeText
    , encodeMessageView
    , friendLabel
    , friendsSearchInputId
    , guildNotFoundText
    , guildView
    , homePageLoggedInView
    , leaveGuildText
    , missingPrivateKeyText
    , newGuildFormInit
    , newGuildFormView
    , newMessagesBadgeText
    , newMessagesId
    , noMatchingChannelsText
    , noUnreadMessagesText
    , olderUnreadMessagesText
    , profileImageButtonId
    , startOfThreadText
    , startedACallText
    , threadMessageHtmlId
    , typingDebouncerDelay
    , typingText
    , userTextMessageContent
    , youDeclinedE2eeText
    )

import Array exposing (Array)
import AsciiArt exposing (AsciiArt)
import Bitwise
import Call
import ChannelDescription
import ChannelHeader
import ChannelName exposing (ChannelName)
import Coord
import CustomEmoji exposing (CustomEmojiData)
import Date exposing (Date)
import Discord
import DmChannel exposing (DiscordFrontendDmChannel, E2eeEnabledData, FrontendDmChannel)
import DmChannelId
import Drawing exposing (Drawing)
import Duration exposing (Duration)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Embed exposing (Embed)
import Emoji exposing (CachedEmojiData, EmojiConfig, EmojiOrCustomEmoji)
import Encryption exposing (BytesHash)
import Env
import FileStatus exposing (FileData, FileHash, FileId, FileStatus)
import GuildColumn
import GuildIcon exposing (ChannelNotificationType(..))
import GuildName exposing (GuildName)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Icons
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, CustomEmojiId, DiscordGuildOrDmId(..), ExportChannelId(..), GuildId, GuildOrDmId(..), Id, StickerId, ThreadMessageId, ThreadRoute(..), ThreadRouteWithMessage(..), UserId)
import ImageEditor
import Json.Decode
import LinkedAndOtherDiscordUsers
import List.Extra
import List.Nonempty exposing (Nonempty)
import LocalState exposing (DiscordFrontendChannel, DiscordFrontendGuild, FrontendChannel, FrontendGuild, LocalState)
import Maybe.Extra
import MembersAndOwner exposing (IsMember(..), MembersAndOwner)
import Message exposing (ContentAndEmbeds, GameType(..), Message(..))
import MessageArray exposing (MessageArray)
import MessageInput
import MessageMenu
import MessageView exposing (MessageViewMsg(..))
import MuteSettings exposing (IsMuted(..))
import MyUi
import NonemptyDict exposing (NonemptyDict)
import NonemptySet exposing (NonemptySet)
import OneOrGreater exposing (OneOrGreater)
import OneToOne
import PersonName exposing (PersonName)
import QRCode
import Quantity
import RichText exposing (RichText)
import Route exposing (ChannelRoute(..), ChannelsVisibleOnMobile(..), DiscordChannelRoute(..), DiscordDmRouteData, DiscordGuildRouteData, DmRouteData, Route(..), ShowChannelSettings(..), ThreadRouteWithFriends(..))
import Scroll
import SecretId
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import SheepGame
import Sticker exposing (AnimationMode(..))
import String.Nonempty
import Thread exposing (DiscordFrontendThread, FrontendGenericThread, FrontendThread, LastTypedAt)
import Time
import Touch
import Types exposing (EditChannelForm, EditGuildForm, EditMessage, EmojiSelector(..), FrontendMsg_(..), LoadedFrontend, LoggedIn2, MessageHover(..), NewChannelForm, NewGuildForm)
import Ui exposing (Element)
import Ui.Anim
import Ui.Events
import Ui.Font
import Ui.Input
import Ui.Keyed
import Ui.Lazy
import Ui.Prose
import User exposing (FrontendCurrentUser, FrontendUser, LocalUser, NotificationLevel(..))
import UserColor exposing (UserColor)
import UserSession exposing (ChannelHeaderTab(..), DiscordFrontendUser, PreviouslyLastViewedMessage(..), Viewing(..))
import VisibleMessages exposing (VisibleMessages)


newMessagesBadgeText : String
newMessagesBadgeText =
    "new"


noUnreadMessagesText : String
noUnreadMessagesText =
    "You have no unread messages!"


startedACallText : String
startedACallText =
    "started a call"


typingText : String
typingText =
    "Typing..."


editingText : String
editingText =
    "Editing..."


e2eeSectionTitle : String
e2eeSectionTitle =
    "End-to-end encryption"


enableE2eeText : String
enableE2eeText =
    "Enable end-to-end encryption"


declineE2eeText : String
declineE2eeText =
    "Decline"


{-| Shown to whoever asked, once the other person has said no. It ends by saying who can
ask next, since the button to do it has gone.
-}
e2eeDeclinedText : String
e2eeDeclinedText =
    "declined your request to enable E2EE Only they can start one now."


youDeclinedE2eeText : String
youDeclinedE2eeText =
    "You declined the request to to enable E2EE."


missingPrivateKeyText : String
missingPrivateKeyText =
    "3. This device is missing a private key in order to decrypt messages. Enter your private key here."


chatWithText : String
chatWithText =
    "Chat with"


deleteGuildText : String
deleteGuildText =
    "Delete guild"


leaveGuildText : String
leaveGuildText =
    "Leave guild"


confirmLeaveGuildText : String
confirmLeaveGuildText =
    "Yes, leave guild"


startOfThreadText : String
startOfThreadText =
    "Start of thread"


channelDoesNotExistText : String
channelDoesNotExistText =
    "Channel does not exist"


guildNotFoundText : String
guildNotFoundText =
    "Guild not found"


directMessagesText : String
directMessagesText =
    "Direct messages"


noMatchingChannelsText : String
noMatchingChannelsText =
    "No matching channels\u{00A0}found"


olderUnreadMessagesText : Int -> String
olderUnreadMessagesText count =
    if count == 1 then
        "1 older unread message"

    else
        String.fromInt count ++ " older unread messages"


loggedInAsView : LocalUser -> Element FrontendMsg_
loggedInAsView localUser =
    Ui.row
        [ Ui.Font.color MyUi.font2
        , Ui.borderColor MyUi.border1
        , Ui.borderWith { left = 0, bottom = 0, top = 1, right = 0 }
        , Ui.background MyUi.background1
        , MyUi.htmlStyle "padding" ("4px 4px calc(" ++ MyUi.insetBottom ++ " + 4px) 4px")
        , Ui.spacing 8
        , Ui.clipWithEllipsis
        ]
        [ User.profileImageNoRounding (Just localUser.user)
        , Ui.text (PersonName.toString localUser.user.name)
        , MyUi.elButton
            (Dom.id "guild_showUserOptions")
            PressedShowUserOption
            [ Ui.width (Ui.px 38)
            , Ui.height Ui.fill
            , Ui.contentCenterY
            , Ui.paddingXY 8 0
            , Ui.alignRight
            , MyUi.hoverText "User settings"
            ]
            (Ui.html Icons.gear)
        ]


type DmChannelSelection
    = SelectedDmChannel DmRouteData
    | SelectedDiscordDmChannel DiscordDmRouteData
    | NoDmChannelSelected


homePageLoggedInView :
    DmChannelSelection
    -> LoadedFrontend
    -> LoggedIn2
    -> LocalState
    -> Element FrontendMsg_
homePageLoggedInView maybeOtherUserId model loggedIn local =
    case loggedIn.showFileToUploadInfo of
        Just fileData ->
            FileStatus.imageInfoView model.timezone PressedCloseImageInfo fileData

        Nothing ->
            if MyUi.isMobile model then
                let
                    canScroll2 : Bool
                    canScroll2 =
                        MyUi.canScroll True model.drag

                    showMembers : ( ShowChannelSettings, Bool )
                    showMembers =
                        Route.toShowMembersTabVisible loggedIn model.route

                    memberColumn : Element FrontendMsg_
                    memberColumn =
                        case showMembers of
                            ( ShowChannelSettings, isThread ) ->
                                case maybeOtherUserId of
                                    SelectedDmChannel dmRoute ->
                                        case DmChannelId.otherUserId local.localUser.session.userId dmRoute.channelId of
                                            Just otherUserId ->
                                                dmChannelSettingsMobile
                                                    canScroll2
                                                    local.localUser
                                                    otherUserId
                                                    isThread
                                                    (dmE2eeStatus otherUserId local)
                                                    (e2eeSectionIsExpanded otherUserId local loggedIn)
                                                    (e2eeKeyInput otherUserId loggedIn)
                                                    |> Ui.el
                                                        [ Ui.height Ui.fill
                                                        , Ui.background MyUi.background3
                                                        , MyUi.htmlStyle "padding" (MyUi.insetTop ++ " 0 0 0")
                                                        , Ui.move
                                                            { x = Call.memberColumnOffset loggedIn.sidebarMode model
                                                            , y = 0
                                                            , z = 0
                                                            }
                                                        , Ui.heightMin 0
                                                        ]

                                            Nothing ->
                                                Ui.none

                                    SelectedDiscordDmChannel routeData ->
                                        case SeqDict.get routeData.channelId local.discordDmChannels of
                                            Just dmChannel ->
                                                discordDmChannelSettingsMobile
                                                    canScroll2
                                                    local.localUser
                                                    routeData.currentDiscordUserId
                                                    routeData.channelId
                                                    dmChannel
                                                    |> Ui.el
                                                        [ Ui.height Ui.fill
                                                        , Ui.background MyUi.background3
                                                        , MyUi.htmlStyle "padding" (MyUi.insetTop ++ " 0 0 0")
                                                        , Ui.move
                                                            { x = Call.memberColumnOffset loggedIn.sidebarMode model
                                                            , y = 0
                                                            , z = 0
                                                            }
                                                        , Ui.heightMin 0
                                                        ]

                                            Nothing ->
                                                Ui.none

                                    NoDmChannelSelected ->
                                        Ui.none

                            ( HideChannelSettings, _ ) ->
                                Ui.none
                in
                Ui.row
                    [ Ui.height Ui.fill
                    , Ui.background MyUi.background1
                    ]
                    [ Ui.column
                        [ Ui.height Ui.fill
                        , Ui.inFront memberColumn
                        , case maybeOtherUserId of
                            SelectedDmChannel dmRoute ->
                                dmChannelView dmRoute loggedIn local model
                                    |> Ui.el
                                        [ Ui.height Ui.fill
                                        , Ui.background MyUi.background3
                                        , MyUi.htmlStyle "padding" (MyUi.insetTop ++ " 0 0 0")
                                        , Ui.move
                                            { x = Call.conversationOffset loggedIn.sidebarMode model
                                            , y = 0
                                            , z = 0
                                            }
                                        , Ui.heightMin 0
                                        , Ui.borderColor MyUi.border1
                                        , Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
                                        ]
                                    |> Ui.inFront

                            SelectedDiscordDmChannel routeData ->
                                discordDmChannelView routeData loggedIn local model
                                    |> Ui.el
                                        [ Ui.height Ui.fill
                                        , Ui.background MyUi.background3
                                        , MyUi.htmlStyle "padding" (MyUi.insetTop ++ " 0 0 0")
                                        , Ui.move
                                            { x = Call.conversationOffset loggedIn.sidebarMode model
                                            , y = 0
                                            , z = 0
                                            }
                                        , Ui.heightMin 0
                                        , Ui.borderColor MyUi.border1
                                        , Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
                                        ]
                                    |> Ui.inFront

                            NoDmChannelSelected ->
                                Ui.noAttr
                        ]
                        [ Ui.row
                            [ Ui.height Ui.fill, Ui.heightMin 0 ]
                            [ GuildColumn.guildColumnLazy True model local
                            , friendsColumnLazy
                                canScroll2
                                True
                                model.time
                                maybeOtherUserId
                                loggedIn.friendsSearch
                                (Maybe.map .htmlId loggedIn.textInputFocus == Just friendsSearchInputId)
                                local
                            ]
                        , Ui.Lazy.lazy loggedInAsView local.localUser
                        ]
                    ]

            else
                Ui.row
                    [ Ui.height Ui.fill
                    , Ui.background MyUi.background1
                    ]
                    [ Ui.column
                        [ Ui.height Ui.fill, Ui.width (Ui.px (MyUi.channelAndGuildColumnWidth model.windowSize)) ]
                        [ Ui.row
                            [ Ui.height Ui.fill, Ui.heightMin 0 ]
                            [ GuildColumn.guildColumnLazy False model local
                            , friendsColumnLazy
                                (MyUi.canScroll False model.drag)
                                False
                                model.time
                                maybeOtherUserId
                                loggedIn.friendsSearch
                                (Maybe.map .htmlId loggedIn.textInputFocus == Just friendsSearchInputId)
                                local
                            ]
                        , Ui.Lazy.lazy loggedInAsView local.localUser
                        ]
                    , case maybeOtherUserId of
                        SelectedDmChannel dmRoute ->
                            dmChannelView dmRoute loggedIn local model
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

                        SelectedDiscordDmChannel routeData ->
                            discordDmChannelView routeData loggedIn local model
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

                        NoDmChannelSelected ->
                            unreadOverviewNotMobile local loggedIn model
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
                    , case ( Route.toShowMembersTabVisible loggedIn model.route, maybeOtherUserId ) of
                        ( ( ShowChannelSettings, isThread ), SelectedDmChannel dmRoute ) ->
                            case DmChannelId.otherUserId local.localUser.session.userId dmRoute.channelId of
                                Just otherUserId ->
                                    dmChannelSettingsNotMobile
                                        local.localUser
                                        otherUserId
                                        isThread
                                        (dmE2eeStatus otherUserId local)
                                        (e2eeSectionIsExpanded otherUserId local loggedIn)
                                        (e2eeKeyInput otherUserId loggedIn)
                                        |> Ui.el
                                            [ Ui.width Ui.shrink
                                            , Ui.height Ui.fill
                                            , MyUi.htmlStyle "padding-top" MyUi.insetTop
                                            ]

                                Nothing ->
                                    Ui.none

                        ( ( ShowChannelSettings, _ ), SelectedDiscordDmChannel routeData ) ->
                            case SeqDict.get routeData.channelId local.discordDmChannels of
                                Just dmChannel ->
                                    Ui.Lazy.lazy4
                                        discordDmMemberColumnNotMobile
                                        local.localUser
                                        routeData.currentDiscordUserId
                                        routeData.channelId
                                        dmChannel
                                        |> Ui.el
                                            [ Ui.width Ui.shrink
                                            , Ui.height Ui.fill
                                            , MyUi.htmlStyle "padding-top" MyUi.insetTop
                                            ]

                                Nothing ->
                                    Ui.none

                        ( ( ShowChannelSettings, _ ), NoDmChannelSelected ) ->
                            Ui.none

                        ( ( HideChannelSettings, _ ), _ ) ->
                            Ui.none
                    ]


{-| The unread messages of one channel or thread, along with where they came from and how
many older unread messages of it aren't shown.
-}
type alias UnreadOverviewChannel =
    { source : Element FrontendMsg_
    , route : Route
    , guildOrDmId : AnyGuildOrDmId
    , threadRoute : ThreadRouteWithMessage
    , additionalUnread : Int
    , oldestAt : Time.Posix
    , messages : UnreadOverviewMessages
    }


{-| Discord messages are kept apart from the rest because they are written by Discord users
rather than our own users, and thread messages are kept apart from channel messages because
they are numbered separately.
-}
type UnreadOverviewMessages
    = UnreadOverviewMessages (List ( Id ChannelMessageId, Message ChannelMessageId (Id UserId) ))
    | UnreadOverviewThreadMessages (Id ChannelMessageId) (List ( Id ThreadMessageId, Message ThreadMessageId (Id UserId) ))
    | UnreadOverviewDiscordMessages (Discord.Id Discord.UserId) (List ( Id ChannelMessageId, Message ChannelMessageId (Discord.Id Discord.UserId) ))
    | UnreadOverviewDiscordThreadMessages (Id ChannelMessageId) (Discord.Id Discord.UserId) (List ( Id ThreadMessageId, Message ThreadMessageId (Discord.Id Discord.UserId) ))


unreadOverviewNotMobile : LocalState -> LoggedIn2 -> LoadedFrontend -> Element FrontendMsg_
unreadOverviewNotMobile local loggedIn model =
    let
        allDiscordUsers : SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
        allDiscordUsers =
            LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers

        allUsers : SeqDict (Id UserId) FrontendUser
        allUsers =
            User.allUsers local.localUser

        containerWidth : Int
        containerWidth =
            conversationWidth model

        unreads : List UnreadOverviewChannel
        unreads =
            unreadOverviewChannels local allDiscordUsers
    in
    Ui.column
        [ Ui.height Ui.fill
        , Ui.heightMin 0
        , Ui.Font.color MyUi.font1

        -- Reacting to a message from here opens the emoji selector over the overview, so it
        -- has to be drawn here as well as over a conversation
        , emojiSelector
            (MyUi.isMobile model)
            local.localUser.user.availableCustomEmojis
            local.localUser.user.availableStickers
            local
            loggedIn
            model
        ]
        [ Ui.row
            [ Ui.paddingXY 8 0
            , Ui.spacing 8
            , Ui.height (Ui.px MyUi.channelHeaderHeight)
            , Ui.contentCenterY
            , MyUi.noShrinking
            , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
            , Ui.borderColor MyUi.border2
            ]
            [ Ui.el [ Ui.Font.bold ] (Ui.text "All unread messages")
            , case unreads of
                [] ->
                    Ui.none

                _ ->
                    MyUi.elButton
                        unreadOverviewMarkAllAsReadId
                        (List.map (\unread -> ( unread.guildOrDmId, unread.threadRoute )) unreads
                            |> PressedMarkAllChannelsAsRead
                        )
                        [ Ui.width Ui.shrink
                        , Ui.alignRight
                        , Ui.paddingXY 8 2
                        , Ui.rounded 4
                        , Ui.border 1
                        , Ui.borderColor MyUi.buttonBorder
                        , Ui.background MyUi.buttonBackground
                        , MyUi.noShrinking
                        ]
                        (Ui.text "Mark all as read")
            ]
        , case unreads of
            [] ->
                let
                    art : AsciiArt
                    art =
                        List.Nonempty.get
                            (Time.toDay model.timezone model.time - Time.toDay model.timezone local.localUser.user.createdAt)
                            AsciiArt.art

                    dpi =
                        model.startupData.devicePixelRatio

                    scaleFactor : Int
                    scaleFactor =
                        min
                            (round (dpi * toFloat containerWidth) // Coord.xRaw art.size)
                            (round (dpi * toFloat (Coord.yRaw model.windowSize - MyUi.channelHeaderHeight - 80)) // Coord.yRaw art.size)
                            |> clamp 1 (round (2 * dpi))
                in
                Ui.column
                    [ Ui.height Ui.fill
                    , Ui.inFront
                        (Ui.el
                            [ Ui.Font.center
                            , Ui.padding 16
                            , Ui.Font.color MyUi.font3
                            , Ui.Font.bold
                            , Ui.Font.size 20
                            ]
                            (Ui.text noUnreadMessagesText)
                        )
                    ]
                    [ Ui.image
                        [ MyUi.htmlStyle "image-rendering" "pixelated"
                        , Ui.centerX
                        , Ui.centerY
                        , Ui.paddingXY 0 16
                        , MyUi.htmlStyle
                            "width"
                            (String.fromFloat (toFloat (Coord.xRaw art.size * scaleFactor) / dpi) ++ "px")
                        , Ui.opacity 0.3
                        , MyUi.hover False [ Ui.Anim.opacity 0.6 ]
                        , Ui.linkNewTab
                            ("https://ascii-collab.app/?x="
                                ++ String.fromInt (Coord.xRaw art.coordinates)
                                ++ "&y="
                                ++ String.fromInt (Coord.yRaw art.coordinates)
                            )
                        ]
                        { source = "/art/" ++ art.url ++ ".png"
                        , description = "Pleasing ascii art drawing"
                        , onLoad = Nothing
                        }
                    ]

            _ ->
                Ui.column
                    [ Ui.height Ui.fill
                    , Ui.heightMin 0
                    , MyUi.scrollable True
                    , Ui.paddingWith { left = 0, right = 0, top = 2, bottom = 0 }
                    ]
                    (List.map
                        (\unread ->
                            unreadOverviewContainer
                                unread
                                (case unread.messages of
                                    UnreadOverviewMessages messages ->
                                        let
                                            revealedSpoilers : SeqDict (Id ChannelMessageId) (NonemptySet Int)
                                            revealedSpoilers =
                                                revealedChannelSpoilers unread.guildOrDmId loggedIn
                                        in
                                        List.map
                                            (\( messageId, message ) ->
                                                ( Message.createdAt message |> Date.fromPosix local.localUser.timezone
                                                , messageView
                                                    model.time
                                                    False
                                                    containerWidth
                                                    False
                                                    revealedSpoilers
                                                    NoHighlight
                                                    (unreadOverviewMessageHover
                                                        unread.guildOrDmId
                                                        (NoThreadWithMessage messageId)
                                                        loggedIn
                                                    )
                                                    False
                                                    local.localUser.session.userId
                                                    allUsers
                                                    local.localUser
                                                    Nothing
                                                    Nothing
                                                    messageId
                                                    message
                                                    |> Ui.map (UnreadOverviewChannelMsg unread.guildOrDmId messageId)
                                                )
                                            )
                                            messages

                                    UnreadOverviewThreadMessages threadId messages ->
                                        let
                                            revealedSpoilers : SeqDict (Id ThreadMessageId) (NonemptySet Int)
                                            revealedSpoilers =
                                                revealedThreadSpoilers unread.guildOrDmId threadId loggedIn
                                        in
                                        List.map
                                            (\( messageId, message ) ->
                                                ( Message.createdAt message |> Date.fromPosix local.localUser.timezone
                                                , threadMessageView
                                                    model.time
                                                    False
                                                    containerWidth
                                                    revealedSpoilers
                                                    NoHighlight
                                                    (unreadOverviewMessageHover
                                                        unread.guildOrDmId
                                                        (ViewThreadWithMessage threadId messageId)
                                                        loggedIn
                                                    )
                                                    False
                                                    allUsers
                                                    local.localUser.session.userId
                                                    local.localUser
                                                    Nothing
                                                    messageId
                                                    message
                                                    |> Ui.map (UnreadOverviewThreadMsg unread.guildOrDmId threadId messageId)
                                                )
                                            )
                                            messages

                                    UnreadOverviewDiscordMessages currentDiscordUserId messages ->
                                        let
                                            revealedSpoilers : SeqDict (Id ChannelMessageId) (NonemptySet Int)
                                            revealedSpoilers =
                                                revealedChannelSpoilers unread.guildOrDmId loggedIn
                                        in
                                        List.map
                                            (\( messageId, message ) ->
                                                ( Message.createdAt message |> Date.fromPosix local.localUser.timezone
                                                , discordMessageView
                                                    model.time
                                                    False
                                                    containerWidth
                                                    False
                                                    revealedSpoilers
                                                    NoHighlight
                                                    (unreadOverviewMessageHover
                                                        unread.guildOrDmId
                                                        (NoThreadWithMessage messageId)
                                                        loggedIn
                                                    )
                                                    currentDiscordUserId
                                                    allDiscordUsers
                                                    local.localUser
                                                    Nothing
                                                    Nothing
                                                    messageId
                                                    message
                                                    |> Ui.map (UnreadOverviewChannelMsg unread.guildOrDmId messageId)
                                                )
                                            )
                                            messages

                                    UnreadOverviewDiscordThreadMessages threadId currentDiscordUserId messages ->
                                        let
                                            revealedSpoilers : SeqDict (Id ThreadMessageId) (NonemptySet Int)
                                            revealedSpoilers =
                                                revealedThreadSpoilers unread.guildOrDmId threadId loggedIn
                                        in
                                        List.map
                                            (\( messageId, message ) ->
                                                ( Message.createdAt message |> Date.fromPosix local.localUser.timezone
                                                , discordThreadMessageView
                                                    model.time
                                                    False
                                                    containerWidth
                                                    revealedSpoilers
                                                    NoHighlight
                                                    (unreadOverviewMessageHover
                                                        unread.guildOrDmId
                                                        (ViewThreadWithMessage threadId messageId)
                                                        loggedIn
                                                    )
                                                    allDiscordUsers
                                                    currentDiscordUserId
                                                    local.localUser
                                                    Nothing
                                                    messageId
                                                    message
                                                    |> Ui.map (UnreadOverviewThreadMsg unread.guildOrDmId threadId messageId)
                                                )
                                            )
                                            messages
                                )
                        )
                        unreads
                    )
        ]


{-| Every channel and thread with unread messages, ordered by the oldest unread message of
each. A channel's place in the overview is decided by when it started being unread, so
messages arriving while the overview is open add to a channel where it already is instead of
moving it.
-}
unreadOverviewChannels :
    LocalState
    -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
    -> List UnreadOverviewChannel
unreadOverviewChannels local allDiscordUsers =
    let
        currentUser : FrontendCurrentUser
        currentUser =
            local.localUser.user

        allUsers : SeqDict (Id UserId) FrontendUser
        allUsers =
            User.allUsers local.localUser
    in
    List.concatMap
        (\( guildId, guild ) ->
            List.concatMap
                (\( channelId, channel ) ->
                    let
                        guildOrDmId : AnyGuildOrDmId
                        guildOrDmId =
                            GuildOrDmId (GuildOrDmId_Guild { guildId = guildId, channelId = channelId })
                    in
                    (case MuteSettings.isChannelMuted currentUser.muteSettings guildId channelId NoThread of
                        IsNotMuted ->
                            unreadMessages (SeqDict.get guildOrDmId currentUser.lastViewedMessage) channel
                                |> Maybe.map
                                    (\unread ->
                                        [ { source = channelSource guild.name channel.name
                                          , route =
                                                GuildRoute
                                                    guildId
                                                    (ChannelRoute channelId (NoThreadWithFriends Nothing HideChannelSettings) Nothing)
                                                    ChannelsHiddenOnMobile
                                          , guildOrDmId = guildOrDmId
                                          , threadRoute = NoThreadWithMessage unread.newestMessageId
                                          , additionalUnread = unread.additionalUnread
                                          , oldestAt = unread.oldestAt
                                          , messages = UnreadOverviewMessages unread.messages
                                          }
                                        ]
                                    )
                                |> Maybe.withDefault []

                        IsMuted ->
                            []
                    )
                        ++ List.filterMap
                            (\( threadId, thread ) ->
                                case MuteSettings.isChannelMuted currentUser.muteSettings guildId channelId (ViewThread threadId) of
                                    IsNotMuted ->
                                        unreadMessages
                                            (SeqDict.get ( guildOrDmId, threadId ) currentUser.lastViewedThreadMessage)
                                            thread
                                            |> Maybe.map
                                                (\unread ->
                                                    { source =
                                                        threadSource
                                                            guild.name
                                                            channel.name
                                                            (threadPreviewText local.localUser.timezone allUsers threadId local.localUser.decryptedMessages channel)
                                                    , route =
                                                        GuildRoute
                                                            guildId
                                                            (ChannelRoute
                                                                channelId
                                                                (ViewThreadWithFriends threadId Nothing HideChannelSettings)
                                                                Nothing
                                                            )
                                                            ChannelsHiddenOnMobile
                                                    , guildOrDmId = guildOrDmId
                                                    , threadRoute =
                                                        ViewThreadWithMessage threadId unread.newestMessageId
                                                    , additionalUnread = unread.additionalUnread
                                                    , oldestAt = unread.oldestAt
                                                    , messages = UnreadOverviewThreadMessages threadId unread.messages
                                                    }
                                                )

                                    IsMuted ->
                                        Nothing
                            )
                            (SeqDict.toList channel.threads)
                )
                (SeqDict.toList guild.channels)
        )
        (SeqDict.toList local.guilds)
        ++ List.concatMap
            (\( otherUserId, dmChannel ) ->
                let
                    guildOrDmId : AnyGuildOrDmId
                    guildOrDmId =
                        GuildOrDmId (GuildOrDmId_Dm { otherUserId = otherUserId })
                in
                (case MuteSettings.isDmMuted currentUser.muteSettings otherUserId NoThread of
                    IsNotMuted ->
                        unreadMessages (SeqDict.get guildOrDmId currentUser.lastViewedMessage) dmChannel
                            |> Maybe.map
                                (\unread ->
                                    [ { source = dmSource otherUserId local.localUser
                                      , route =
                                            DmRoute
                                                { channelId = DmChannelId.fromUserIds local.localUser.session.userId otherUserId
                                                , threadRoute = NoThreadWithFriends Nothing HideChannelSettings
                                                , tab = Nothing
                                                , channelsVisible = ChannelsHiddenOnMobile
                                                }
                                      , guildOrDmId = guildOrDmId
                                      , threadRoute = NoThreadWithMessage unread.newestMessageId
                                      , additionalUnread = unread.additionalUnread
                                      , oldestAt = unread.oldestAt
                                      , messages = UnreadOverviewMessages unread.messages
                                      }
                                    ]
                                )
                            |> Maybe.withDefault []

                    IsMuted ->
                        []
                )
                    ++ List.filterMap
                        (\( threadId, thread ) ->
                            case MuteSettings.isDmMuted currentUser.muteSettings otherUserId (ViewThread threadId) of
                                IsNotMuted ->
                                    unreadMessages
                                        (SeqDict.get ( guildOrDmId, threadId ) currentUser.lastViewedThreadMessage)
                                        thread
                                        |> Maybe.map
                                            (\unread ->
                                                { source =
                                                    dmThreadSource
                                                        otherUserId
                                                        local.localUser
                                                        (threadPreviewText local.localUser.timezone allUsers threadId local.localUser.decryptedMessages dmChannel)
                                                , route =
                                                    DmRoute
                                                        { channelId = DmChannelId.fromUserIds local.localUser.session.userId otherUserId
                                                        , threadRoute = ViewThreadWithFriends threadId Nothing HideChannelSettings
                                                        , tab = Nothing
                                                        , channelsVisible = ChannelsHiddenOnMobile
                                                        }
                                                , guildOrDmId = guildOrDmId
                                                , threadRoute = ViewThreadWithMessage threadId unread.newestMessageId
                                                , additionalUnread = unread.additionalUnread
                                                , oldestAt = unread.oldestAt
                                                , messages = UnreadOverviewThreadMessages threadId unread.messages
                                                }
                                            )

                                IsMuted ->
                                    Nothing
                        )
                        (SeqDict.toList dmChannel.threads)
            )
            (SeqDict.toList local.dmChannels)
        ++ List.concatMap
            (\( guildId, guild ) ->
                case GuildColumn.discordGuildCurrentUserId local.localUser guild of
                    Just currentDiscordUserId ->
                        List.concatMap
                            (\( channelId, channel ) ->
                                let
                                    guildOrDmId : AnyGuildOrDmId
                                    guildOrDmId =
                                        DiscordGuildOrDmId
                                            (DiscordGuildOrDmId_Guild { currentUserId = currentDiscordUserId, guildId = guildId, channelId = channelId })
                                in
                                (case MuteSettings.isDiscordChannelMuted currentUser.muteSettings guildId channelId NoThread of
                                    IsNotMuted ->
                                        unreadMessages (SeqDict.get guildOrDmId currentUser.lastViewedMessage) channel
                                            |> Maybe.map
                                                (\unread ->
                                                    [ { source = channelSource guild.name channel.name
                                                      , route =
                                                            DiscordGuildRoute
                                                                { currentDiscordUserId = currentDiscordUserId
                                                                , guildId = guildId
                                                                , channelRoute =
                                                                    DiscordChannel_ChannelRoute
                                                                        channelId
                                                                        (NoThreadWithFriends Nothing HideChannelSettings)
                                                                        Nothing
                                                                , channelsVisible = ChannelsHiddenOnMobile
                                                                }
                                                      , guildOrDmId = guildOrDmId
                                                      , threadRoute = NoThreadWithMessage unread.newestMessageId
                                                      , additionalUnread = unread.additionalUnread
                                                      , oldestAt = unread.oldestAt
                                                      , messages =
                                                            UnreadOverviewDiscordMessages currentDiscordUserId unread.messages
                                                      }
                                                    ]
                                                )
                                            |> Maybe.withDefault []

                                    IsMuted ->
                                        []
                                )
                                    ++ List.filterMap
                                        (\( threadId, thread ) ->
                                            case MuteSettings.isDiscordChannelMuted currentUser.muteSettings guildId channelId (ViewThread threadId) of
                                                IsNotMuted ->
                                                    unreadMessages
                                                        (SeqDict.get ( guildOrDmId, threadId ) currentUser.lastViewedThreadMessage)
                                                        thread
                                                        |> Maybe.map
                                                            (\unread ->
                                                                { source =
                                                                    threadSource
                                                                        guild.name
                                                                        channel.name
                                                                        (threadPreviewText local.localUser.timezone allDiscordUsers threadId SeqDict.empty channel)
                                                                , route =
                                                                    DiscordGuildRoute
                                                                        { currentDiscordUserId = currentDiscordUserId
                                                                        , guildId = guildId
                                                                        , channelRoute =
                                                                            DiscordChannel_ChannelRoute
                                                                                channelId
                                                                                (ViewThreadWithFriends threadId Nothing HideChannelSettings)
                                                                                Nothing
                                                                        , channelsVisible = ChannelsHiddenOnMobile
                                                                        }
                                                                , guildOrDmId = guildOrDmId
                                                                , threadRoute =
                                                                    ViewThreadWithMessage threadId unread.newestMessageId
                                                                , additionalUnread = unread.additionalUnread
                                                                , oldestAt = unread.oldestAt
                                                                , messages =
                                                                    UnreadOverviewDiscordThreadMessages
                                                                        threadId
                                                                        currentDiscordUserId
                                                                        unread.messages
                                                                }
                                                            )

                                                IsMuted ->
                                                    Nothing
                                        )
                                        (SeqDict.toList channel.threads)
                            )
                            (SeqDict.toList guild.channels)

                    Nothing ->
                        []
            )
            (SeqDict.toList local.discordGuilds)
        ++ List.filterMap
            (\( channelId, dmChannel ) ->
                case
                    ( GuildColumn.discordDmCurrentUserId local.localUser dmChannel
                    , MuteSettings.isDiscordDmMuted currentUser.muteSettings channelId
                    )
                of
                    ( Just currentDiscordUserId, IsNotMuted ) ->
                        let
                            guildOrDmId : AnyGuildOrDmId
                            guildOrDmId =
                                DiscordGuildOrDmId
                                    (DiscordGuildOrDmId_Dm
                                        { currentUserId = currentDiscordUserId, channelId = channelId }
                                    )
                        in
                        unreadMessages (SeqDict.get guildOrDmId currentUser.lastViewedMessage) dmChannel
                            |> Maybe.map
                                (\unread ->
                                    { source = discordDmSource currentDiscordUserId allDiscordUsers dmChannel
                                    , route =
                                        DiscordDmRoute
                                            { currentDiscordUserId = currentDiscordUserId
                                            , channelId = channelId
                                            , viewingMessage = Nothing
                                            , showMembersTab = HideChannelSettings
                                            , tab = Nothing
                                            , channelsVisible = ChannelsHiddenOnMobile
                                            }
                                    , guildOrDmId = guildOrDmId
                                    , threadRoute = NoThreadWithMessage unread.newestMessageId
                                    , additionalUnread = unread.additionalUnread
                                    , oldestAt = unread.oldestAt
                                    , messages =
                                        UnreadOverviewDiscordMessages currentDiscordUserId unread.messages
                                    }
                                )

                    _ ->
                        Nothing
            )
            (SeqDict.toList local.discordDmChannels)
        |> List.sortBy (\unread -> Time.posixToMillis unread.oldestAt)


channelSource : GuildName -> ChannelName -> Element msg
channelSource guildName channelName =
    Ui.row
        [ Ui.spacing 8
        , Ui.width Ui.shrink
        ]
        [ Ui.text (GuildName.toString guildName)
        , Ui.text "/"
        , Ui.row [ Ui.width Ui.shrink ] [ Ui.html Icons.hashtag, Ui.text (ChannelName.toString channelName) ]
        ]


{-| A thread is named after the message it started from, which can be arbitrarily long, so
the guild and channel it belongs to stay at their full width and the thread name is the part
that gets cut short when there isn't enough room.
-}
threadSource : GuildName -> ChannelName -> String -> Element msg
threadSource guildName channelName threadName =
    Ui.row
        [ Ui.spacing 8 ]
        [ Ui.row
            [ Ui.spacing 8, Ui.width Ui.shrink, MyUi.noShrinking ]
            [ Ui.text (GuildName.toString guildName)
            , Ui.text "/"
            , Ui.row [ Ui.width Ui.shrink ] [ Ui.html Icons.hashtag, Ui.text (ChannelName.toString channelName) ]
            , Ui.text "/"
            ]
        , Ui.el [ Ui.clipWithEllipsis, MyUi.hoverText threadName ] (Ui.text threadName)
        ]


{-| A DM is named after the person on the other end of it. Only their name is bold,
so it stands out from the words around it the way a guild and channel name does.
-}
dmSource : Id UserId -> LocalUser -> Element msg
dmSource otherUserId localUser =
    Ui.row
        [ Ui.spacing 4, Ui.width Ui.shrink, MyUi.noShrinking ]
        [ Ui.el [ Ui.Font.weight 400, Ui.width Ui.shrink ] (Ui.text chatWithText)
        , Ui.text (User.toStringAlt otherUserId localUser)
        ]


{-| A thread in a DM. Like threadSource, the DM keeps its full width and the thread
name is the part that gets cut short when there isn't enough room.
-}
dmThreadSource : Id UserId -> LocalUser -> String -> Element msg
dmThreadSource otherUserId localUser threadName =
    Ui.row
        [ Ui.spacing 8 ]
        [ Ui.row
            [ Ui.spacing 8, Ui.width Ui.shrink, MyUi.noShrinking ]
            [ dmSource otherUserId localUser
            , Ui.text "/"
            ]
        , Ui.el [ Ui.clipWithEllipsis, MyUi.hoverText threadName ] (Ui.text threadName)
        ]


{-| The people in a Discord DM channel, not counting the linked Discord account the user
is in the channel as. A DM channel with only us in it is named after us.
-}
discordDmSource :
    Discord.Id Discord.UserId
    -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
    -> DiscordFrontendDmChannel
    -> Element msg
discordDmSource currentDiscordUserId allDiscordUsers dmChannel =
    case NonemptyDict.remove currentDiscordUserId dmChannel.members |> SeqDict.keys of
        [] ->
            Ui.text (User.toString currentDiscordUserId allDiscordUsers)

        others ->
            List.map (\userId -> User.toString userId allDiscordUsers) others |> String.join ", " |> Ui.text


{-| One channel's worth of unread messages in the overview. The messages are shown the same
way the conversation view shows them, so a line and a header saying which channel they are
from is what separates one channel from the next.
-}
unreadOverviewContainer : UnreadOverviewChannel -> List ( Date, Element FrontendMsg_ ) -> Element FrontendMsg_
unreadOverviewContainer unread messageViews =
    Ui.column
        [ MyUi.noShrinking
        , Ui.borderColor MyUi.border2
        , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 2 }
        ]
        (Ui.row
            [ Ui.spacing 8, Ui.paddingWith { left = 8, right = 8, top = 6, bottom = 0 }, Ui.contentCenterY ]
            [ GuildColumn.elLinkButton
                (unreadOverviewHtmlId "guild_unreadOverviewOpenChannel_" unread.guildOrDmId unread.threadRoute)
                unread.route
                [ Ui.Font.bold
                , Ui.Font.color MyUi.font3
                , Ui.clipWithEllipsis
                , MyUi.hover False [ Ui.Anim.fontColor MyUi.font1 ]
                ]
                unread.source
            , MyUi.elButton
                (unreadOverviewHtmlId "guild_unreadOverviewMarkAsRead_" unread.guildOrDmId unread.threadRoute)
                (PressedMarkChannelAsRead unread.guildOrDmId unread.threadRoute)
                [ Ui.width Ui.shrink
                , Ui.alignRight
                , Ui.paddingXY 8 2
                , Ui.rounded 4
                , Ui.border 1
                , Ui.borderColor MyUi.buttonBorder
                , Ui.background MyUi.buttonBackground
                , Ui.Font.color MyUi.font1
                , MyUi.noShrinking
                ]
                (Ui.text "Mark as read")
            ]
            :: (if unread.additionalUnread > 0 then
                    Ui.el
                        [ Ui.Font.color MyUi.font3
                        , Ui.Font.italic
                        , Ui.paddingWith { left = 8, right = 8, top = 0, bottom = 4 }
                        ]
                        (Ui.text (olderUnreadMessagesText unread.additionalUnread))

                else
                    Ui.none
               )
            :: unreadOverviewMessages messageViews
        )


{-| The messages of one channel in the overview, oldest first, with a date divider above the
oldest one and another wherever the messages pass into a new day. The oldest one gets a
divider too because the messages above it aren't shown, so there's nothing else saying which
day they were written on.
-}
unreadOverviewMessages : List ( Date, Element FrontendMsg_ ) -> List (Element FrontendMsg_)
unreadOverviewMessages messageViews =
    List.foldl
        (\( date, messageView2 ) ( maybeLastDate, list ) ->
            ( Just date
            , if maybeLastDate == Just date then
                messageView2 :: list

              else
                messageView2 :: unreadOverviewDateDivider date :: list
            )
        )
        ( Nothing, [] )
        messageViews
        |> Tuple.second
        |> List.reverse


{-| The day the messages below it were written on. The conversation view shows the day that
ended and the day that started on either side of its divider, but the overview leaves gaps
between the messages it shows, so only the day that starts is meaningful here.
-}
unreadOverviewDateDivider : Date -> Element msg
unreadOverviewDateDivider date =
    Ui.el
        [ Ui.paddingXY 8 0, Ui.height (Ui.px 20), Ui.contentCenterY, MyUi.noShrinking ]
        (Ui.el
            [ Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
            , Ui.borderColor MyUi.font3
            , Ui.inFront
                (Ui.el
                    [ Ui.centerX
                    , Ui.width Ui.shrink
                    , Ui.move { x = 0, y = -9, z = 0 }
                    , Ui.background MyUi.background3
                    , Ui.paddingXY 6 0
                    , Ui.Font.color MyUi.font3
                    , Ui.Font.size 14
                    , Ui.Font.bold
                    ]
                    (Ui.text (MyUi.datestampDate date))
                )
            ]
            Ui.none
        )


{-| Buttons in the overview are named after the channel or thread they belong to, since the
overview shows many of them at once.
-}
unreadOverviewHtmlId : String -> AnyGuildOrDmId -> ThreadRouteWithMessage -> HtmlId
unreadOverviewHtmlId prefix guildOrDmId threadRoute =
    (case guildOrDmId of
        GuildOrDmId (GuildOrDmId_Guild { guildId, channelId }) ->
            "guild_" ++ Id.toString guildId ++ "_" ++ Id.toString channelId

        GuildOrDmId (GuildOrDmId_Dm { otherUserId }) ->
            "dm_" ++ Id.toString otherUserId

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild { guildId, channelId }) ->
            "discord_" ++ Discord.idToString guildId ++ "_" ++ Discord.idToString channelId

        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data) ->
            "discordDm_" ++ Discord.idToString data.channelId
    )
        ++ (case threadRoute of
                NoThreadWithMessage _ ->
                    ""

                ViewThreadWithMessage threadId _ ->
                    "_thread_" ++ Id.toString threadId
           )
        |> (\suffix -> Dom.id (prefix ++ suffix))


{-| The button that marks every channel and thread the overview lists as read.
-}
unreadOverviewMarkAllAsReadId : HtmlId
unreadOverviewMarkAllAsReadId =
    Dom.id "guild_unreadOverviewMarkAllAsRead"


{-| The newest unread messages of a channel or thread, oldest first, plus how many older
unread messages aren't shown. The backend only sends `UserSession.unreadOverviewMessageLimit`
of them per channel, but messages that arrive while the overview is open are loaded too, so
the same limit is applied here.

`oldestAt` is when the oldest unread message we have was written, which is older than the
messages we show if some of them were left out. It doesn't change as new messages arrive,
which is what makes it usable for ordering the overview.

-}
unreadMessages :
    Maybe (Id messageId)
    -> { a | messages : MessageArray messageId userId }
    ->
        Maybe
            { messages : List ( Id messageId, Message messageId userId )
            , additionalUnread : Int
            , newestMessageId : Id messageId
            , oldestAt : Time.Posix
            }
unreadMessages maybeLastViewed channel =
    let
        messageCount : Int
        messageCount =
            MessageArray.length channel.messages

        unreadCount : Int
        unreadCount =
            GuildColumn.newMessageCount maybeLastViewed channel

        loaded : List ( Id messageId, Message messageId userId )
        loaded =
            MessageArray.slice
                (messageCount - unreadCount |> Id.fromInt)
                (Id.fromInt messageCount)
                channel.messages
                |> MessageArray.toList

        shown : List ( Id messageId, Message messageId userId )
        shown =
            List.drop (List.length loaded - UserSession.unreadOverviewMessageLimit) loaded
    in
    case ( List.head loaded, List.Extra.last shown ) of
        ( Just ( _, oldest ), Just ( newestMessageId, _ ) ) ->
            Just
                { messages = shown
                , additionalUnread = unreadCount - List.length shown
                , newestMessageId = newestMessageId
                , oldestAt = Message.createdAt oldest
                }

        _ ->
            Nothing


{-| Where the unread divider goes. Opening a conversation marks it as read, so the last
viewed message of the local state has already moved to the newest message by the time it is
drawn. The session remembers where the divider was on the way in, and that is what the
conversation being looked at right now needs, so that its unread messages stay marked while
the reader is still working through them.
-}
unreadDividerAt : Id messageId -> PreviouslyLastViewedMessage messageId -> Id messageId
unreadDividerAt lastViewed previouslyLastViewedMessage =
    case previouslyLastViewedMessage of
        PreviouslyLastViewedMessage messageId ->
            messageId

        DontCare ->
            lastViewed


dmChannelView : DmRouteData -> LoggedIn2 -> LocalState -> LoadedFrontend -> Element FrontendMsg_
dmChannelView dmRoute loggedIn local model =
    case DmChannelId.otherUserId local.localUser.session.userId dmRoute.channelId of
        Nothing ->
            Ui.el
                [ Ui.centerY
                , Ui.Font.center
                , Ui.Font.color MyUi.font1
                , Ui.Font.size 20
                ]
                (Ui.text "Conversation not found")

        Just otherUserId ->
            case User.getUser otherUserId local.localUser of
                Just otherUser ->
                    let
                        dmChannel : FrontendDmChannel
                        dmChannel =
                            SeqDict.get otherUserId local.dmChannels
                                |> Maybe.withDefault DmChannel.frontendInit
                    in
                    case dmRoute.threadRoute of
                        ViewThreadWithFriends threadMessageIndex maybeUrlMessageId _ ->
                            SeqDict.get threadMessageIndex dmChannel.threads
                                |> Maybe.withDefault Thread.frontendInit
                                |> threadConversationView
                                    (let
                                        lastViewed : Id ThreadMessageId
                                        lastViewed =
                                            SeqDict.get
                                                ( GuildOrDmId (GuildOrDmId_Dm { otherUserId = otherUserId }), threadMessageIndex )
                                                local.localUser.user.lastViewedThreadMessage
                                                |> Maybe.withDefault (Id.fromInt -1)
                                     in
                                     case local.localUser.currentlyViewing of
                                        Viewing_DmThread data ->
                                            if data.id == { otherUserId = otherUserId, threadId = threadMessageIndex } then
                                                unreadDividerAt lastViewed data.previouslyLastViewedMessage

                                            else
                                                lastViewed

                                        _ ->
                                            lastViewed
                                    )
                                    (GuildOrDmId_Dm { otherUserId = otherUserId })
                                    maybeUrlMessageId
                                    threadMessageIndex
                                    loggedIn
                                    model
                                    local
                                    (PersonName.toString otherUser.name)
                                    (threadPreviewText
                                        local.localUser.timezone
                                        (User.allUsers local.localUser)
                                        threadMessageIndex
                                        local.localUser.decryptedMessages
                                        dmChannel
                                    )

                        NoThreadWithFriends maybeUrlMessageId _ ->
                            conversationView
                                (let
                                    lastViewed : Id ChannelMessageId
                                    lastViewed =
                                        SeqDict.get
                                            (GuildOrDmId (GuildOrDmId_Dm { otherUserId = otherUserId }))
                                            local.localUser.user.lastViewedMessage
                                            |> Maybe.withDefault (Id.fromInt -1)
                                 in
                                 case local.localUser.currentlyViewing of
                                    Viewing_Dm data ->
                                        if data.id == { otherUserId = otherUserId } then
                                            unreadDividerAt lastViewed data.previouslyLastViewedMessage

                                        else
                                            lastViewed

                                    _ ->
                                        lastViewed
                                )
                                (GuildOrDmId_Dm { otherUserId = otherUserId })
                                maybeUrlMessageId
                                loggedIn
                                model
                                local
                                (PersonName.toString otherUser.name)
                                dmChannel

                Nothing ->
                    Ui.el
                        [ Ui.centerY
                        , Ui.Font.center
                        , Ui.Font.color MyUi.font1
                        , Ui.Font.size 20
                        ]
                        (Ui.text "User not found")


discordDmChannelView :
    DiscordDmRouteData
    -> LoggedIn2
    -> LocalState
    -> LoadedFrontend
    -> Element FrontendMsg_
discordDmChannelView routeData loggedIn local model =
    case SeqDict.get routeData.channelId local.discordDmChannels of
        Just dmChannel ->
            discordConversationView
                (let
                    lastViewed : Id ChannelMessageId
                    lastViewed =
                        SeqDict.get
                            (DiscordGuildOrDmId
                                (DiscordGuildOrDmId_Dm
                                    { currentUserId = routeData.currentDiscordUserId, channelId = routeData.channelId }
                                )
                            )
                            local.localUser.user.lastViewedMessage
                            |> Maybe.withDefault (Id.fromInt -1)
                 in
                 case local.localUser.currentlyViewing of
                    Viewing_DiscordDm data ->
                        if
                            data.id
                                == { currentUserId = routeData.currentDiscordUserId
                                   , channelId = routeData.channelId
                                   }
                        then
                            unreadDividerAt lastViewed data.previouslyLastViewedMessage

                        else
                            lastViewed

                    _ ->
                        lastViewed
                )
                routeData.currentDiscordUserId
                (DiscordGuildOrDmId_Dm
                    { currentUserId = routeData.currentDiscordUserId, channelId = routeData.channelId }
                )
                routeData.viewingMessage
                loggedIn
                model
                local
                (NonemptyDict.toSeqDict dmChannel.members
                    |> SeqDict.remove routeData.currentDiscordUserId
                    |> SeqDict.toList
                    |> List.filterMap
                        (\( userId, _ ) ->
                            case User.getDiscordUser userId local.localUser of
                                Just user ->
                                    PersonName.toString user.name |> Just

                                Nothing ->
                                    Nothing
                        )
                    |> String.join ", "
                )
                { messages = dmChannel.messages
                , isForum = False
                , visibleMessages = dmChannel.visibleMessages
                , lastTypedAt = dmChannel.lastTypedAt
                , threads = SeqDict.empty
                , dateDividerDrawings = dmChannel.dateDividerDrawings
                }
                SeqSet.empty
                SeqSet.empty

        Nothing ->
            Ui.el
                [ Ui.centerY
                , Ui.Font.center
                , Ui.Font.color MyUi.font1
                , Ui.Font.size 20
                ]
                (Ui.text "DM channel not found")


conversationWidth : LoadedFrontend -> Int
conversationWidth model =
    MyUi.conversationWidthIgnoreScrollbar
        model.windowSize
        (case Route.toShowMembersTab model.route of
            ( ShowChannelSettings, _ ) ->
                True

            ( HideChannelSettings, _ ) ->
                False
        )
        - model.startupData.scrollbarWidth
        - (User.profileImageSize + (messagePaddingX * 2) + MessageView.profileImagePaddingRight)


guildView : LoadedFrontend -> Id GuildId -> ChannelRoute -> LoggedIn2 -> LocalState -> Element FrontendMsg_
guildView model guildId channelRoute loggedIn local =
    case loggedIn.showFileToUploadInfo of
        Just fileData ->
            FileStatus.imageInfoView model.timezone PressedCloseImageInfo fileData

        Nothing ->
            case SeqDict.get guildId local.guilds of
                Just guild ->
                    if MyUi.isMobile model then
                        let
                            canScroll2 =
                                MyUi.canScroll (MyUi.isMobile model) model.drag

                            showMembers : ( ShowChannelSettings, Bool )
                            showMembers =
                                Route.toShowMembersTabVisible loggedIn model.route
                        in
                        Ui.column
                            [ Ui.height Ui.fill
                            , Ui.background MyUi.background1
                            , Ui.heightMin 0
                            , Ui.clip
                            , (case showMembers of
                                ( ShowChannelSettings, isThread ) ->
                                    channelSettingsMobile
                                        canScroll2
                                        local.localUser
                                        guildId
                                        channelRoute
                                        guild
                                        loggedIn.editChannelForm
                                        isThread
                                        |> Ui.el
                                            [ Ui.height Ui.fill
                                            , Ui.background MyUi.background3
                                            , MyUi.htmlStyle "padding" (MyUi.insetTop ++ " 0 0 0")
                                            , Ui.move
                                                { x = Call.memberColumnOffset loggedIn.sidebarMode model
                                                , y = 0
                                                , z = 0
                                                }
                                            , Ui.heightMin 0
                                            ]

                                ( HideChannelSettings, _ ) ->
                                    Ui.none
                              )
                                |> Ui.inFront
                            , channelView channelRoute guildId guild loggedIn local model
                                |> Ui.el
                                    [ Ui.height Ui.fill
                                    , Ui.background MyUi.background3
                                    , MyUi.htmlStyle "padding" (MyUi.insetTop ++ " 0 0 0")
                                    , Ui.move
                                        { x = Call.conversationOffset loggedIn.sidebarMode model
                                        , y = 0
                                        , z = 0
                                        }
                                    , Ui.heightMin 0
                                    ]
                                |> Ui.inFront
                            ]
                            [ Ui.row
                                [ Ui.height Ui.fill, Ui.heightMin 0 ]
                                [ GuildColumn.guildColumnLazy True model local
                                , channelColumnLazy True canScroll2 model loggedIn local.localUser guildId guild channelRoute
                                ]
                            , Ui.Lazy.lazy loggedInAsView local.localUser
                            ]

                    else
                        Ui.row
                            [ Ui.height Ui.fill, Ui.background MyUi.background1 ]
                            [ Ui.column
                                [ Ui.height Ui.fill
                                , Ui.width (Ui.px (MyUi.channelAndGuildColumnWidth model.windowSize))
                                ]
                                [ Ui.row
                                    [ Ui.height Ui.fill, Ui.heightMin 0 ]
                                    [ GuildColumn.guildColumnLazy False model local
                                    , channelColumnLazy False True model loggedIn local.localUser guildId guild channelRoute
                                    ]
                                , Ui.Lazy.lazy loggedInAsView local.localUser
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
                            , case Route.toShowMembersTabVisible loggedIn model.route of
                                ( ShowChannelSettings, isThread ) ->
                                    channelSettingsNotMobile
                                        local.localUser
                                        guildId
                                        channelRoute
                                        guild
                                        loggedIn.editChannelForm
                                        isThread
                                        |> Ui.el
                                            [ Ui.width Ui.shrink
                                            , Ui.height Ui.fill
                                            , MyUi.htmlStyle "padding-top" MyUi.insetTop
                                            ]

                                ( HideChannelSettings, _ ) ->
                                    Ui.none
                            ]

                Nothing ->
                    if MyUi.isMobile model then
                        Ui.column
                            [ Ui.height Ui.fill
                            , Ui.background MyUi.background1
                            , Ui.heightMin 0
                            , Ui.clip
                            ]
                            [ Ui.row
                                [ Ui.height Ui.fill, Ui.heightMin 0 ]
                                [ GuildColumn.guildColumnLazy True model local
                                , pageMissingMobile guildNotFoundText
                                ]
                            , Ui.Lazy.lazy loggedInAsView local.localUser
                            ]

                    else
                        Ui.row
                            [ Ui.height Ui.fill, Ui.background MyUi.background1 ]
                            [ Ui.column
                                [ Ui.height Ui.fill
                                , Ui.width (Ui.px (MyUi.channelAndGuildColumnWidth model.windowSize))
                                ]
                                [ Ui.row
                                    [ Ui.height Ui.fill, Ui.heightMin 0 ]
                                    [ GuildColumn.guildColumnLazy False model local
                                    , Ui.el
                                        [ Ui.background MyUi.background2
                                        , Ui.height Ui.fill
                                        , Ui.borderWith { left = 1, right = 0, top = 0, bottom = 0 }
                                        , Ui.borderColor MyUi.border1
                                        ]
                                        Ui.none
                                    ]
                                , Ui.Lazy.lazy loggedInAsView local.localUser
                                ]
                            , pageMissing guildNotFoundText
                            ]


nearestHour : Time.Posix -> Int
nearestHour time =
    Time.posixToMillis time // (60 * 60 * 1000) |> (*) (60 * 60 * 1000)


discordGuildView :
    LoadedFrontend
    -> DiscordGuildRouteData
    -> LoggedIn2
    -> LocalState
    -> Element FrontendMsg_
discordGuildView model routeData loggedIn local =
    case loggedIn.showFileToUploadInfo of
        Just fileData ->
            FileStatus.imageInfoView model.timezone PressedCloseImageInfo fileData

        Nothing ->
            case
                ( SeqDict.get routeData.guildId local.discordGuilds
                , LinkedAndOtherDiscordUsers.getLinkedUser routeData.currentDiscordUserId local.localUser.discordUsers
                )
            of
                ( Just guild, Just currentDiscordUser ) ->
                    if MembersAndOwner.isMember routeData.currentDiscordUserId guild.membersAndOwner == IsNotMember then
                        guildErrorPage
                            ("Selected Discord user ("
                                ++ PersonName.toString currentDiscordUser.name
                                ++ ") is not a member of this guild"
                            )
                            local
                            model

                    else if MyUi.isMobile model then
                        let
                            canScroll2 =
                                MyUi.canScroll (MyUi.isMobile model) model.drag

                            showMembers : ( ShowChannelSettings, Bool )
                            showMembers =
                                Route.toShowMembersTabVisible loggedIn model.route
                        in
                        Ui.column
                            [ Ui.height Ui.fill
                            , Ui.background MyUi.background1
                            , Ui.heightMin 0
                            , Ui.clip
                            , (case showMembers of
                                ( ShowChannelSettings, _ ) ->
                                    case routeData.channelRoute of
                                        DiscordChannel_ChannelRoute channelId threadRoute _ ->
                                            Ui.Lazy.lazy6
                                                discordChannelSettingsMobile
                                                canScroll2
                                                local.localUser
                                                routeData
                                                guild
                                                channelId
                                                threadRoute
                                                |> Ui.el
                                                    [ Ui.height Ui.fill
                                                    , Ui.background MyUi.background3
                                                    , MyUi.htmlStyle "padding" (MyUi.insetTop ++ " 0 0 0")
                                                    , Ui.move
                                                        { x = Call.memberColumnOffset loggedIn.sidebarMode model
                                                        , y = 0
                                                        , z = 0
                                                        }
                                                    , Ui.heightMin 0
                                                    ]

                                        DiscordChannel_NewChannelRoute ->
                                            discordMemberColumnContainer []

                                        DiscordChannel_GuildSettingsRoute ->
                                            discordMemberColumnContainer []

                                ( HideChannelSettings, _ ) ->
                                    Ui.none
                              )
                                |> Ui.inFront
                            , discordChannelView routeData guild loggedIn local model
                                |> Ui.el
                                    [ Ui.height Ui.fill
                                    , Ui.background MyUi.background3
                                    , MyUi.htmlStyle "padding" (MyUi.insetTop ++ " 0 0 0")
                                    , Ui.move
                                        { x = Call.conversationOffset loggedIn.sidebarMode model
                                        , y = 0
                                        , z = 0
                                        }
                                    , Ui.heightMin 0
                                    ]
                                |> Ui.inFront
                            ]
                            [ Ui.row
                                [ Ui.height Ui.fill, Ui.heightMin 0 ]
                                [ GuildColumn.guildColumnLazy True model local
                                , discordChannelColumnLazy True canScroll2 model loggedIn local.localUser routeData guild
                                ]
                            , Ui.Lazy.lazy loggedInAsView local.localUser
                            ]

                    else
                        Ui.row
                            [ Ui.height Ui.fill, Ui.background MyUi.background1 ]
                            [ Ui.column
                                [ Ui.height Ui.fill
                                , Ui.width (Ui.px (MyUi.channelAndGuildColumnWidth model.windowSize))
                                ]
                                [ Ui.row
                                    [ Ui.height Ui.fill, Ui.heightMin 0 ]
                                    [ GuildColumn.guildColumnLazy False model local
                                    , discordChannelColumnLazy False True model loggedIn local.localUser routeData guild
                                    ]
                                , Ui.Lazy.lazy loggedInAsView local.localUser
                                ]
                            , discordChannelView routeData guild loggedIn local model
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
                            , case Route.toShowMembersTabVisible loggedIn model.route of
                                ( ShowChannelSettings, _ ) ->
                                    case routeData.channelRoute of
                                        DiscordChannel_ChannelRoute channelId threadRoute _ ->
                                            Ui.Lazy.lazy6
                                                discordChannelSettingsNotMobile
                                                local.localUser
                                                routeData.guildId
                                                routeData.currentDiscordUserId
                                                guild
                                                channelId
                                                threadRoute
                                                |> Ui.el
                                                    [ Ui.width Ui.shrink
                                                    , Ui.height Ui.fill
                                                    , MyUi.htmlStyle "padding-top" MyUi.insetTop
                                                    ]

                                        DiscordChannel_NewChannelRoute ->
                                            Ui.none

                                        DiscordChannel_GuildSettingsRoute ->
                                            Ui.none

                                ( HideChannelSettings, _ ) ->
                                    Ui.none
                            ]

                ( Just _, Nothing ) ->
                    guildErrorPage "Discord user not found" local model

                ( Nothing, _ ) ->
                    guildErrorPage "Discord guild not found" local model


guildErrorPage : String -> LocalState -> LoadedFrontend -> Element FrontendMsg_
guildErrorPage error local model =
    if MyUi.isMobile model then
        Ui.column
            [ Ui.height Ui.fill
            , Ui.background MyUi.background1
            , Ui.heightMin 0
            , Ui.clip
            ]
            [ Ui.row
                [ Ui.height Ui.fill, Ui.heightMin 0 ]
                [ GuildColumn.guildColumnLazy True model local
                , pageMissingMobile error
                ]
            , Ui.Lazy.lazy loggedInAsView local.localUser
            ]

    else
        Ui.row
            [ Ui.height Ui.fill, Ui.background MyUi.background1 ]
            [ Ui.column
                [ Ui.height Ui.fill
                , Ui.width (Ui.px (MyUi.channelAndGuildColumnWidth model.windowSize))
                ]
                [ Ui.row
                    [ Ui.height Ui.fill, Ui.heightMin 0 ]
                    [ GuildColumn.guildColumnLazy False model local
                    , Ui.el
                        [ Ui.background MyUi.background2
                        , Ui.height Ui.fill
                        , Ui.borderWith { left = 1, right = 0, top = 0, bottom = 0 }
                        , Ui.borderColor MyUi.border1
                        ]
                        Ui.none
                    ]
                , Ui.Lazy.lazy loggedInAsView local.localUser
                ]
            , pageMissing error
            ]


{-| The channel the route has selected, and which of its threads (if any) is open.
The member column is also shown on routes where no channel is selected, hence the
`Maybe`.
-}
channelRouteToChannelIdAndThread : ChannelRoute -> Maybe ( Id ChannelId, ThreadRoute )
channelRouteToChannelIdAndThread channelRoute =
    case channelRoute of
        ChannelRoute channelId threadRoute _ ->
            Just ( channelId, threadRouteWithFriends threadRoute )

        NewChannelRoute ->
            Nothing

        GuildSettingsRoute ->
            Nothing

        JoinRoute _ ->
            Nothing


{-| The thread a route has open, without the extra bits the route carries around for
scrolling to a message and showing the member tab.
-}
threadRouteWithFriends : ThreadRouteWithFriends -> ThreadRoute
threadRouteWithFriends threadRoute =
    case threadRoute of
        ViewThreadWithFriends threadId _ _ ->
            ViewThread threadId

        NoThreadWithFriends _ _ ->
            NoThread


exportChannelButton : ExportChannelId -> Element FrontendMsg_
exportChannelButton exportChannelId =
    MyUi.elButton
        (Dom.id "guild_exportChannel")
        (PressedExportChannel exportChannelId)
        [ Ui.paddingXY 8 4
        , Ui.rounded 4
        , Ui.border 1
        , Ui.borderColor MyUi.buttonBorder
        , Ui.background MyUi.buttonBackground
        , Ui.Font.color MyUi.font1
        , Ui.Font.center
        , Ui.Font.weight 500
        , MyUi.noShrinking
        ]
        (Ui.text "Export channel")


memberColumnContainerNotMobile : Bool -> List (Element FrontendMsg_) -> Element FrontendMsg_
memberColumnContainerNotMobile isThread contents =
    Ui.column
        [ Ui.height Ui.fill
        , Ui.alignRight
        , Ui.background MyUi.background2
        , Ui.Font.color MyUi.font1
        , Ui.width (Ui.px MyUi.memberColumnWidth)
        , Ui.heightMin 0
        , Ui.borderWith { left = 1, right = 0, top = 0, bottom = 0 }
        , Ui.borderColor MyUi.border2
        ]
        [ Ui.row
            [ -- For some reason the bottom border isn't lining up with the ChannelHeader so we need to add a 1px offset
              Ui.height (Ui.px (MyUi.channelHeaderHeight + 1))
            , MyUi.noShrinking
            , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
            , Ui.borderColor MyUi.border1
            ]
            [ Ui.el
                [ Ui.Font.color MyUi.font3, Ui.paddingXY 8 0 ]
                (if isThread then
                    Ui.text "Thread settings"

                 else
                    Ui.text "Channel settings"
                )
            , MyUi.elButton
                (Dom.id "guild_hideMembers")
                PressedHideMembers
                [ Ui.alignRight
                , Ui.width (Ui.px (24 + 24))
                , Ui.height Ui.fill
                , Ui.paddingXY 12 0
                , Ui.contentCenterY
                , Ui.Font.color MyUi.font3
                , MyUi.hover False [ Ui.Anim.fontColor MyUi.font1 ]
                , MyUi.hoverText "Hide members"
                ]
                (Ui.html Icons.x)
            ]
        , Ui.column
            [ Ui.height Ui.fill
            , Ui.scrollable
            , Ui.heightMin 0
            ]
            contents
        ]


{-| Only actual channels can be edited. Threads only get the mute setting, and the
other channel routes show nothing at all.
-}
channelSettingsForm :
    LocalUser
    -> Id GuildId
    -> ChannelRoute
    -> FrontendGuild
    -> SeqDict ( Id GuildId, Id ChannelId ) EditChannelForm
    -> Element FrontendMsg_
channelSettingsForm localUser guildId channelRoute guild editChannelForm =
    case channelRouteToChannelIdAndThread channelRoute of
        Just ( channelId, NoThread ) ->
            case SeqDict.get channelId guild.channels of
                Just channel ->
                    (if localUser.session.userId == MembersAndOwner.owner guild.membersAndOwner then
                        let
                            form : EditChannelForm
                            form =
                                SeqDict.get ( guildId, channelId ) editChannelForm
                                    |> Maybe.withDefault (editChannelFormInit channel)

                            isEmpty : Bool
                            isEmpty =
                                MessageArray.isEmpty channel.messages

                            channelNameString : String
                            channelNameString =
                                ChannelName.toString channel.name

                            channelDescriptionString : String
                            channelDescriptionString =
                                ChannelDescription.toString channel.description

                            hasChanges : Bool
                            hasChanges =
                                form.name /= channelNameString || form.description /= channelDescriptionString

                            confirmationMatches : Bool
                            confirmationMatches =
                                form.deleteConfirmation == channelNameString

                            ( deleteOnPress, deleteEnabled ) =
                                if isEmpty then
                                    ( PressedDeleteChannel guildId channelId, True )

                                else if not form.showDeleteConfirmation then
                                    ( EditChannelFormChanged guildId channelId { form | showDeleteConfirmation = True }, True )

                                else if confirmationMatches then
                                    ( PressedDeleteChannel guildId channelId, True )

                                else
                                    ( FrontendNoOp, False )
                        in
                        [ channelNameInput form |> Ui.map (EditChannelFormChanged guildId channelId)
                        , channelDescriptionInput form |> Ui.map (EditChannelFormChanged guildId channelId)
                        , MuteSettings.view
                            (PressedMuteChannel guildId channelId)
                            (MuteSettings.isChannelSpecificallyMuted localUser.user.muteSettings guildId channelId)
                        , if hasChanges then
                            Ui.row
                                [ Ui.spacing 8 ]
                                [ MyUi.secondaryButton
                                    (Dom.id "guild_resetEditChannel")
                                    (PressedResetEditChannelChanges guildId channelId)
                                    "Reset"
                                , submitButtonWide
                                    (Dom.id "guild_submitEditChannel")
                                    (PressedSubmitEditChannelChanges guildId channelId form)
                                    "Save changes"
                                ]

                          else
                            Ui.none
                        , exportChannelButton (ExportChannel_Guild guildId channelId)
                        , Ui.el [ Ui.height (Ui.px 1), Ui.background MyUi.border1 ] Ui.none
                        , if not isEmpty && form.showDeleteConfirmation then
                            deleteConfirmationInput channelNameString form
                                |> Ui.map (EditChannelFormChanged guildId channelId)

                          else
                            Ui.none
                        , MyUi.elButton
                            (Dom.id "guild_deleteChannel")
                            deleteOnPress
                            [ Ui.background
                                (if deleteEnabled then
                                    MyUi.deleteButtonBackground

                                 else
                                    MyUi.disabledButtonBackground
                                )
                            , Ui.paddingXY 8 4
                            , Ui.rounded 4
                            , Ui.Font.color MyUi.deleteButtonFont
                            , Ui.Font.weight 500
                            , Ui.Font.center
                            , Ui.borderColor
                                (if deleteEnabled then
                                    MyUi.deleteButtonBorder

                                 else
                                    MyUi.disabledButtonBorder
                                )
                            , Ui.border 1
                            ]
                            (Ui.text "Delete channel")
                        ]

                     else
                        [ MuteSettings.view
                            (PressedMuteChannel guildId channelId)
                            (MuteSettings.isChannelSpecificallyMuted localUser.user.muteSettings guildId channelId)
                        , exportChannelButton (ExportChannel_Guild guildId channelId)
                        ]
                    )
                        |> Ui.column [ Ui.Font.color MyUi.font1, Ui.padding 8, Ui.spacing 16 ]

                Nothing ->
                    Ui.none

        Just ( channelId, ViewThread threadId ) ->
            [ MuteSettings.view
                (PressedMuteThread guildId channelId threadId)
                (MuteSettings.isThreadSpecificallyMuted localUser.user.muteSettings guildId channelId threadId)
            ]
                |> Ui.column [ Ui.Font.color MyUi.font1, Ui.padding 8, Ui.spacing 16 ]

        Nothing ->
            Ui.none


memberListView : Bool -> LocalUser -> MembersAndOwner (Id UserId) { joinedAt : Time.Posix } -> Element FrontendMsg_
memberListView isMobile localUser membersAndOwner =
    let
        members : SeqDict (Id UserId) { joinedAt : Time.Posix }
        members =
            MembersAndOwner.members membersAndOwner
    in
    Ui.column
        []
        [ Ui.el [ Ui.paddingXY 8 4 ] (Ui.text ("Members (" ++ String.fromInt (SeqDict.size members + 1) ++ ")"))
        , Ui.column
            [ Ui.height Ui.fill ]
            (memberLabel isMobile localUser (MembersAndOwner.owner membersAndOwner)
                :: SeqDict.foldr (\userId _ list -> memberLabel isMobile localUser userId :: list) [] members
            )
        ]


discordMemberListView :
    Bool
    -> Discord.Id Discord.UserId
    -> LocalUser
    -> Discord.Id Discord.GuildId
    -> DiscordFrontendGuild
    -> Discord.Id Discord.ChannelId
    -> Element FrontendMsg_
discordMemberListView isMobile currentUserId localUser guildId guild channelId =
    case discordChannelViewers guildId guild channelId of
        Nothing ->
            Ui.none

        Just members ->
            Ui.column
                []
                [ Ui.el [ Ui.paddingXY 8 4 ] (Ui.text ("Members (" ++ String.fromInt (SeqDict.size members) ++ ")"))
                , Ui.column
                    [ Ui.height Ui.fill ]
                    (SeqDict.foldr
                        (\userId _ list -> discordMemberLabel isMobile localUser currentUserId userId :: list)
                        []
                        members
                    )
                ]


channelSettingsNotMobile :
    LocalUser
    -> Id GuildId
    -> ChannelRoute
    -> FrontendGuild
    -> SeqDict ( Id GuildId, Id ChannelId ) EditChannelForm
    -> Bool
    -> Element FrontendMsg_
channelSettingsNotMobile localUser guildId channelRoute guild editChannelForm isThread =
    memberColumnContainerNotMobile
        isThread
        [ channelSettingsForm localUser guildId channelRoute guild editChannelForm
        , Ui.Lazy.lazy3 memberListView False localUser guild.membersAndOwner
        ]


{-| Determine which guild members can view the given channel, following the
channel's permission overwrites. The owner is not included here since it's
shown separately and can always view every channel. Returns `Nothing` when no
channel is selected, so the member column can be hidden.
-}
discordChannelViewers :
    Discord.Id Discord.GuildId
    -> DiscordFrontendGuild
    -> Discord.Id Discord.ChannelId
    -> Maybe (SeqDict (Discord.Id Discord.UserId) { joinedAt : Maybe Time.Posix, roles : SeqSet (Discord.Id Discord.RoleId) })
discordChannelViewers guildId guild channelId =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            MembersAndOwner.members guild.membersAndOwner
                |> SeqDict.filter (\userId _ -> LocalState.canViewDiscordChannel guildId channel guild userId)
                |> Just

        Nothing ->
            Nothing


discordChannelSettingsNotMobile :
    LocalUser
    -> Discord.Id Discord.GuildId
    -> Discord.Id Discord.UserId
    -> DiscordFrontendGuild
    -> Discord.Id Discord.ChannelId
    -> ThreadRouteWithFriends
    -> Element FrontendMsg_
discordChannelSettingsNotMobile localUser guildId currentDiscordUserId guild channelId threadRoute =
    memberColumnContainerNotMobile
        (case threadRoute of
            NoThreadWithFriends _ _ ->
                False

            ViewThreadWithFriends _ _ _ ->
                True
        )
        [ discordChannelSettingsForm localUser currentDiscordUserId guildId channelId threadRoute
        , Ui.Lazy.lazy6 discordMemberListView False currentDiscordUserId localUser guildId guild channelId
        ]


{-| Discord channels are managed on Discord, so the only thing to change here is whether
the channel (or the thread inside it) is muted.
-}
discordChannelSettingsForm :
    LocalUser
    -> Discord.Id Discord.UserId
    -> Discord.Id Discord.GuildId
    -> Discord.Id Discord.ChannelId
    -> ThreadRouteWithFriends
    -> Element FrontendMsg_
discordChannelSettingsForm localUser currentDiscordUserId guildId channelId threadRoute =
    (case threadRoute of
        NoThreadWithFriends _ _ ->
            [ MuteSettings.view
                (PressedMuteDiscordChannel currentDiscordUserId guildId channelId)
                (MuteSettings.isDiscordChannelSpecificallyMuted localUser.user.muteSettings guildId channelId)
            , exportChannelButton (ExportChannel_Discord currentDiscordUserId guildId channelId)
            ]

        ViewThreadWithFriends threadId _ _ ->
            [ MuteSettings.view
                (PressedMuteDiscordThread currentDiscordUserId guildId channelId threadId)
                (MuteSettings.isDiscordThreadSpecificallyMuted localUser.user.muteSettings guildId channelId threadId)
            ]
    )
        |> Ui.column [ Ui.Font.color MyUi.font1, Ui.padding 8, Ui.spacing 16 ]


discordMemberColumnContainer : List (Element msg) -> Element msg
discordMemberColumnContainer contents =
    Ui.column
        [ Ui.height Ui.fill
        , Ui.alignRight
        , Ui.background MyUi.background2
        , Ui.Font.color MyUi.font1
        , Ui.width (Ui.px MyUi.memberColumnWidth)
        , Ui.scrollable
        , Ui.heightMin 0
        , Ui.paddingXY 8 4
        ]
        contents


channelSettingsMobile :
    Bool
    -> LocalUser
    -> Id GuildId
    -> ChannelRoute
    -> FrontendGuild
    -> SeqDict ( Id GuildId, Id ChannelId ) EditChannelForm
    -> Bool
    -> Element FrontendMsg_
channelSettingsMobile canScroll2 localUser guildId channelRoute guild editChannelForm isThread =
    Ui.column
        [ Ui.height Ui.fill ]
        [ Ui.row
            [ Ui.contentCenterY
            , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
            , Ui.borderColor MyUi.border2
            , Ui.background MyUi.background3
            , Ui.height (Ui.px MyUi.channelHeaderHeight)
            , MyUi.noShrinking
            ]
            [ ChannelHeader.headerBackButton (Dom.id "guild_memberColumnBack") PressedMemberListBack
            , if isThread then
                Ui.text "Thread settings"

              else
                Ui.text "Channel settings"
            ]
        , Ui.column
            [ Ui.height Ui.fill
            , Ui.background MyUi.background2
            , Ui.Font.color MyUi.font1
            , MyUi.htmlStyle "padding" ("16px 0 calc(" ++ MyUi.insetBottom ++ " + 16px) 0")
            , MyUi.scrollable canScroll2
            , Ui.heightMin 0
            ]
            [ channelSettingsForm localUser guildId channelRoute guild editChannelForm
            , Ui.Lazy.lazy3 memberListView True localUser guild.membersAndOwner
            ]
        ]


discordChannelSettingsMobile :
    Bool
    -> LocalUser
    -> DiscordGuildRouteData
    -> DiscordFrontendGuild
    -> Discord.Id Discord.ChannelId
    -> ThreadRouteWithFriends
    -> Element FrontendMsg_
discordChannelSettingsMobile canScroll2 localUser routeData guild channelId threadRoute =
    Ui.column
        [ Ui.height Ui.fill ]
        [ Ui.row
            [ Ui.contentCenterY
            , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
            , Ui.borderColor MyUi.border2
            , Ui.background MyUi.background3
            , Ui.height (Ui.px MyUi.channelHeaderHeight)
            , MyUi.noShrinking
            ]
            [ ChannelHeader.headerBackButton (Dom.id "guild_memberColumnBack") PressedMemberListBack
            , case threadRoute of
                ViewThreadWithFriends _ _ _ ->
                    Ui.text "Thread members"

                NoThreadWithFriends _ _ ->
                    Ui.text "Channel members"
            ]
        , Ui.column
            [ Ui.height Ui.fill
            , Ui.background MyUi.background2
            , Ui.Font.color MyUi.font1
            , MyUi.htmlStyle "padding" ("16px 0 calc(" ++ MyUi.insetBottom ++ " + 16px) 0")
            , MyUi.scrollable canScroll2
            , Ui.heightMin 0
            ]
            [ discordChannelSettingsForm
                localUser
                routeData.currentDiscordUserId
                routeData.guildId
                channelId
                threadRoute
            , discordMemberListView True routeData.currentDiscordUserId localUser routeData.guildId guild channelId
            ]
        ]


{-| A DM only contains the user and the person they are talking to, unless
they're talking to themselves.
-}
dmMembers : LocalUser -> Id UserId -> List (Id UserId)
dmMembers localUser otherUserId =
    if localUser.session.userId == otherUserId then
        [ otherUserId ]

    else
        [ localUser.session.userId, otherUserId ]


{-| Whether the end-to-end encryption section of a DM's channel settings is open. It
opens on its own while the other person is waiting for an answer, up until the user opens
or closes it themselves.
-}
e2eeSectionIsExpanded : Id UserId -> LocalState -> LoggedIn2 -> Bool
e2eeSectionIsExpanded otherUserId local loggedIn =
    Maybe.withDefault
        (ChannelHeader.showDmSettingsRedDot otherUserId local loggedIn)
        (SeqDict.get otherUserId loggedIn.e2eeSectionsExpanded)


dmE2eeStatus : Id UserId -> LocalState -> DmChannel.E2eeStatus
dmE2eeStatus otherUserId local =
    case SeqDict.get otherUserId local.dmChannels of
        Just dmChannel ->
            dmChannel.e2ee

        Nothing ->
            DmChannel.E2eeDisabled


e2eeSectionView :
    LocalUser
    -> Id UserId
    -> DmChannel.E2eeStatus
    -> Bool
    -> E2eeKeyInput
    -> Element FrontendMsg_
e2eeSectionView localUser otherUserId e2ee isExpanded keyInput =
    let
        risksAccepted : Bool
        risksAccepted =
            localUser.user.e2eeRisksAccepted

        risksLabel : { element : Element FrontendMsg_, id : Ui.Input.Label }
        risksLabel =
            Ui.Input.label
                "guild_e2eeAcceptRisks"
                [ Ui.paddingWith { left = 16, right = 0, top = 0, bottom = 0 }, Ui.pointer, Ui.width Ui.shrink ]
                (Ui.text "I understand and accept the\u{00A0}risks")

        requestedByOtherUser : Bool
        requestedByOtherUser =
            case e2ee of
                DmChannel.E2eeRequestedBy ( requestedBy, _ ) ->
                    requestedBy /= localUser.session.userId

                DmChannel.E2eeDeclinedBy _ ->
                    False

                DmChannel.E2eeDisabled ->
                    False

                DmChannel.E2eeEnabled _ ->
                    False
    in
    MyUi.container
        16
        isExpanded
        (Dom.id "guild_e2eeSection")
        (PressedExpandE2eeSection otherUserId)
        MyUi.background2
        True
        e2eeSectionTitle
        [ Ui.column
            [ Ui.paddingWith { left = 8, right = 8, top = 8, bottom = 0 }, Ui.spacing 16 ]
            [ Ui.column
                [ Ui.attrIf risksAccepted (Ui.opacity 0.5), Ui.spacing 8 ]
                [ MyUi.warningHeader "Before you enable E2EE:"
                , Ui.text "You'll get a private key that you need to store in a password manager. If you lose it, you'll permanently lose access to all your encrypted messages."
                , Ui.row
                    []
                    [ Ui.Input.checkbox
                        []
                        { onChange = PressedE2eeRisksAccepted
                        , icon = Nothing
                        , checked = risksAccepted
                        , label = risksLabel.id
                        }
                    , risksLabel.element
                    ]
                ]
            , case localUser.user.publicKey of
                Just _ ->
                    Ui.text "1. Create private key: completed!"

                Nothing ->
                    Ui.none
            , case e2ee of
                DmChannel.E2eeDisabled ->
                    if not risksAccepted then
                        Ui.none

                    else
                        case localUser.user.publicKey of
                            Nothing ->
                                createPrivateKeyButton

                            Just _ ->
                                MyUi.simpleButton
                                    (Dom.id "guild_enableE2ee")
                                    (PressedEnableE2ee otherUserId)
                                    (Ui.text enableE2eeText)

                DmChannel.E2eeRequestedBy _ ->
                    if requestedByOtherUser then
                        Ui.column
                            [ Ui.spacing 16 ]
                            [ if not risksAccepted then
                                Ui.none

                              else
                                case localUser.user.publicKey of
                                    Nothing ->
                                        createPrivateKeyButton

                                    Just _ ->
                                        privateKeyInput
                                            otherUserId
                                            (Ui.text "2. Enter your private key to enable E2EE")
                                            keyInput

                            -- Turning the request down takes nothing but the decision, so
                            -- this sits outside the steps that lead to accepting it.
                            , MyUi.simpleButton
                                (Dom.id "guild_declineE2ee")
                                (PressedDeclineE2eeRequest otherUserId)
                                (Ui.text declineE2eeText)
                            ]

                    else if otherUserId == localUser.session.userId then
                        privateKeyInput
                            otherUserId
                            (Ui.text "2. Enter your private key to enable E2EE")
                            keyInput

                    else
                        Ui.column
                            [ Ui.spacing 16 ]
                            [ Ui.Prose.paragraph
                                []
                                [ Ui.text
                                    ("2. Waiting for "
                                        ++ User.toStringAlt otherUserId localUser
                                        ++ " to accept message encryption."
                                    )
                                ]
                            , MyUi.simpleButton
                                (Dom.id "guild_cancelE2ee")
                                (PressedCancelE2eeRequest otherUserId)
                                (Ui.text "Cancel")
                            ]

                DmChannel.E2eeDeclinedBy declinedBy ->
                    if declinedBy == localUser.session.userId then
                        Ui.column
                            [ Ui.spacing 16 ]
                            [ Ui.Prose.paragraph [] [ Ui.text youDeclinedE2eeText ]
                            , if not risksAccepted then
                                Ui.none

                              else
                                case localUser.user.publicKey of
                                    Nothing ->
                                        createPrivateKeyButton

                                    Just _ ->
                                        MyUi.simpleButton
                                            (Dom.id "guild_enableE2ee")
                                            (PressedEnableE2ee otherUserId)
                                            (Ui.text enableE2eeText)
                            ]

                    else
                        -- Asking again is theirs to do rather than this user's, so there
                        -- is nothing to press underneath.
                        Ui.Prose.paragraph
                            []
                            [ Ui.text (User.toStringAlt otherUserId localUser ++ " " ++ e2eeDeclinedText) ]

                DmChannel.E2eeEnabled data ->
                    Ui.column
                        [ Ui.spacing 16 ]
                        [ Ui.text ("2. E2EE was enabled on " ++ MyUi.datestamp localUser.timezone data.enabledAt)
                        , if keyInput.hasKeyOnThisDevice then
                            Ui.none

                          else
                            privateKeyInput
                                otherUserId
                                (if data.requestedBy == ( localUser.session.userId, localUser.session.sessionIdHash ) then
                                    "3. "
                                        ++ User.toStringAlt otherUserId localUser
                                        ++ " accepted and E2EE is now enabled. Enter your private key here to decrypted messages"
                                        |> Ui.text

                                 else
                                    Ui.text missingPrivateKeyText
                                )
                                keyInput
                        ]
            ]
        ]


{-| Pulls together what the private key box for one conversation needs from the model.
-}
e2eeKeyInput : Id UserId -> LoggedIn2 -> E2eeKeyInput
e2eeKeyInput otherUserId loggedIn =
    { text = loggedIn.e2eePrivateKeyText
    , error = loggedIn.e2eeError
    , hasKeyOnThisDevice = SeqSet.member otherUserId loggedIn.e2eeKeysOnThisDevice
    }


{-| What the private key box needs to draw itself: what has been typed so far, whether
anything went wrong with the last attempt, and whether this device already has a key and
so does not need to ask at all.
-}
type alias E2eeKeyInput =
    { text : String
    , error : Maybe String
    , hasKeyOnThisDevice : Bool
    }


privateKeyInput : Id UserId -> Element FrontendMsg_ -> E2eeKeyInput -> Element FrontendMsg_
privateKeyInput otherUserId prompt keyInput =
    let
        keyLabel : { element : Element FrontendMsg_, id : Ui.Input.Label }
        keyLabel =
            Ui.Input.label "guild_e2eePrivateKey" [] prompt
    in
    Ui.column
        [ Ui.spacing 4 ]
        [ keyLabel.element
        , Ui.Input.currentPassword
            [ Ui.background MyUi.inputBackground
            , Ui.paddingXY 8 8
            , Ui.widthMax 300
            , Ui.borderColor MyUi.inputBorder
            ]
            { text = keyInput.text
            , onChange = TypedPrivateKey otherUserId
            , placeholder = Just "Your private key"
            , label = keyLabel.id
            , show = False
            }
            |> Ui.el [ ChannelHeader.e2eeRequestDot ]
        , case keyInput.error of
            Just error ->
                Ui.el [ Ui.Font.color MyUi.errorColor ] (Ui.text error)

            Nothing ->
                Ui.none
        ]


createPrivateKeyButton : Element FrontendMsg_
createPrivateKeyButton =
    MyUi.simpleButton
        (Dom.id "guild_addPrivateKey")
        PressedAddPrivateKeyToAccount
        (Ui.text "Create a private key")


dmChannelSettingsNotMobile :
    LocalUser
    -> Id UserId
    -> Bool
    -> DmChannel.E2eeStatus
    -> Bool
    -> E2eeKeyInput
    -> Element FrontendMsg_
dmChannelSettingsNotMobile localUser otherUserId isThread e2ee isExpanded keyInput =
    let
        members : List (Id UserId)
        members =
            dmMembers localUser otherUserId
    in
    memberColumnContainerNotMobile
        isThread
        [ if isThread then
            Ui.none

          else
            Ui.el [ Ui.paddingXY 8 8 ] (exportChannelButton (ExportChannel_Dm otherUserId))
        , Ui.column
            [ Ui.paddingWith { left = 0, right = 0, top = 4, bottom = 16 } ]
            [ Ui.el [ Ui.paddingXY 8 0 ] (Ui.text ("Members (" ++ String.fromInt (List.length members) ++ ")"))
            , Ui.column
                [ Ui.height Ui.fill ]
                (List.map (memberLabel False localUser) members)
            ]
        , if isThread then
            Ui.none

          else
            e2eeSectionView localUser otherUserId e2ee isExpanded keyInput
        ]


dmChannelSettingsMobile :
    Bool
    -> LocalUser
    -> Id UserId
    -> Bool
    -> DmChannel.E2eeStatus
    -> Bool
    -> E2eeKeyInput
    -> Element FrontendMsg_
dmChannelSettingsMobile canScroll2 localUser otherUserId isThread e2ee isExpanded keyInput =
    let
        members : List (Id UserId)
        members =
            dmMembers localUser otherUserId
    in
    Ui.column
        [ Ui.height Ui.fill ]
        [ Ui.row
            [ Ui.contentCenterY
            , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
            , Ui.borderColor MyUi.border2
            , Ui.background MyUi.background3
            , Ui.height (Ui.px MyUi.channelHeaderHeight)
            , MyUi.noShrinking
            ]
            [ ChannelHeader.headerBackButton (Dom.id "guild_memberColumnBack") PressedMemberListBack
            , if isThread then
                Ui.text "Thread settings"

              else
                Ui.text "Channel settings"
            ]
        , Ui.column
            [ Ui.height Ui.fill
            , Ui.background MyUi.background2
            , Ui.Font.color MyUi.font1
            , MyUi.htmlStyle "padding" ("16px 0 calc(" ++ MyUi.insetBottom ++ " + 16px) 0")
            , MyUi.scrollable canScroll2
            , Ui.heightMin 0
            ]
            [ if isThread then
                Ui.none

              else
                Ui.el [ Ui.paddingXY 8 4 ] (exportChannelButton (ExportChannel_Dm otherUserId))
            , Ui.column
                [ Ui.paddingXY 8 4 ]
                [ Ui.text ("Members (" ++ String.fromInt (List.length members) ++ ")")
                , Ui.column
                    [ Ui.height Ui.fill ]
                    (List.map (memberLabel True localUser) members)
                ]
            , if isThread then
                Ui.none

              else
                e2eeSectionView localUser otherUserId e2ee isExpanded keyInput
            ]
        ]


discordDmMemberColumnNotMobile :
    LocalUser
    -> Discord.Id Discord.UserId
    -> Discord.Id Discord.PrivateChannelId
    -> DiscordFrontendDmChannel
    -> Element FrontendMsg_
discordDmMemberColumnNotMobile localUser currentDiscordUserId channelId dmChannel =
    let
        members : List (Discord.Id Discord.UserId)
        members =
            NonemptyDict.keys dmChannel.members |> List.Nonempty.toList
    in
    memberColumnContainerNotMobile
        False
        [ Ui.column
            [ Ui.paddingXY 8 4 ]
            [ Ui.el
                [ Ui.paddingXY 0 4 ]
                (exportChannelButton (ExportChannel_DiscordDm currentDiscordUserId channelId))
            , Ui.text ("Members (" ++ String.fromInt (List.length members) ++ ")")
            , Ui.column
                [ Ui.height Ui.fill ]
                (List.map (discordMemberLabel False localUser currentDiscordUserId) members)
            ]
        ]


discordDmChannelSettingsMobile :
    Bool
    -> LocalUser
    -> Discord.Id Discord.UserId
    -> Discord.Id Discord.PrivateChannelId
    -> DiscordFrontendDmChannel
    -> Element FrontendMsg_
discordDmChannelSettingsMobile canScroll2 localUser currentDiscordUserId channelId dmChannel =
    let
        members : List (Discord.Id Discord.UserId)
        members =
            NonemptyDict.keys dmChannel.members |> List.Nonempty.toList
    in
    Ui.column
        [ Ui.height Ui.fill ]
        [ Ui.row
            [ Ui.contentCenterY
            , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
            , Ui.borderColor MyUi.border2
            , Ui.background MyUi.background3
            , Ui.height (Ui.px MyUi.channelHeaderHeight)
            , MyUi.noShrinking
            ]
            [ ChannelHeader.headerBackButton (Dom.id "guild_memberColumnBack") PressedMemberListBack
            , Ui.text "Channel settings"
            ]
        , Ui.column
            [ Ui.height Ui.fill
            , Ui.background MyUi.background2
            , Ui.Font.color MyUi.font1
            , MyUi.htmlStyle "padding" ("16px 0 calc(" ++ MyUi.insetBottom ++ " + 16px) 0")
            , MyUi.scrollable canScroll2
            , Ui.heightMin 0
            ]
            [ Ui.el
                [ Ui.paddingXY 8 4 ]
                (exportChannelButton (ExportChannel_DiscordDm currentDiscordUserId channelId))
            , Ui.column
                [ Ui.paddingXY 8 4 ]
                [ Ui.text ("Members (" ++ String.fromInt (List.length members) ++ ")")
                , Ui.column
                    [ Ui.height Ui.fill ]
                    (List.map (discordMemberLabel True localUser currentDiscordUserId) members)
                ]
            ]
        ]


memberLabel : Bool -> LocalUser -> Id UserId -> Element FrontendMsg_
memberLabel isMobile localUser userId =
    GuildColumn.rowLinkButton
        (Dom.id ("guild_openDm_" ++ Id.toString userId))
        (DmRoute
            { channelId = DmChannelId.fromUserIds localUser.session.userId userId
            , threadRoute = NoThreadWithFriends Nothing HideChannelSettings
            , tab = Nothing
            , channelsVisible = ChannelsHiddenOnMobile
            }
        )
        [ Ui.spacing 8
        , Ui.paddingXY 8 4
        , MyUi.hover
            isMobile
            [ Ui.Anim.backgroundColor MyUi.weakHoverHighlight
            , Ui.Anim.fontColor MyUi.font1
            ]
        , Ui.Font.color MyUi.font3
        , Ui.clipWithEllipsis
        ]
        (case User.getUser userId localUser of
            Just user ->
                [ User.profileImage (Just user), Ui.text (PersonName.toString user.name) ]

            Nothing ->
                []
        )


discordMemberLabel :
    Bool
    -> LocalUser
    -> Discord.Id Discord.UserId
    -> Discord.Id Discord.UserId
    -> Element FrontendMsg_
discordMemberLabel isMobile localUser currentUserId userId =
    MyUi.rowButton
        (Dom.id ("guild_openDiscordDm_" ++ Discord.idToString userId))
        (PressedDiscordGuildMemberLabel { currentUserId = currentUserId, otherUserId = userId })
        [ Ui.spacing 8
        , Ui.paddingXY 8 4
        , MyUi.hover
            isMobile
            [ Ui.Anim.backgroundColor MyUi.weakHoverHighlight
            , Ui.Anim.fontColor MyUi.font1
            ]
        , Ui.Font.color MyUi.font3
        , Ui.clipWithEllipsis
        ]
        (case User.getDiscordUser userId localUser of
            Just user ->
                [ User.discordProfileImage userId user.icon, Ui.text (PersonName.toString user.name) ]

            Nothing ->
                []
        )


pageMissing : String -> Element msg
pageMissing text =
    Ui.el
        [ Ui.height Ui.fill
        , Ui.contentCenterY
        , Ui.Font.center
        , Ui.Font.color MyUi.font1
        , Ui.Font.size 20
        , Ui.background MyUi.background3
        ]
        (Ui.text text)


pageMissingMobile : String -> Element msg
pageMissingMobile text =
    Ui.el
        [ Ui.height Ui.fill
        , Ui.contentCenterY
        , Ui.Font.center
        , Ui.Font.color MyUi.font1
        , Ui.Font.size 20
        , Ui.background MyUi.background2
        ]
        (Ui.text text)


threadPreviewText :
    Time.Zone
    -> SeqDict userId { a | name : PersonName }
    -> Id ChannelMessageId
    -> SeqDict BytesHash (Result () (ContentAndEmbeds userId))
    -> { b | messages : MessageArray ChannelMessageId userId }
    -> String
threadPreviewText timezone allUsers threadMessageIndex decrypted channel =
    case MessageArray.get threadMessageIndex channel.messages of
        Just message ->
            LocalState.messageToString timezone allUsers decrypted message

        _ ->
            "Thread not found"


channelView : ChannelRoute -> Id GuildId -> FrontendGuild -> LoggedIn2 -> LocalState -> LoadedFrontend -> Element FrontendMsg_
channelView channelRoute guildId guild loggedIn local model =
    case channelRoute of
        ChannelRoute channelId threadRoute _ ->
            case SeqDict.get channelId guild.channels of
                Just channel ->
                    case threadRoute of
                        ViewThreadWithFriends threadMessageIndex maybeUrlMessageId _ ->
                            SeqDict.get threadMessageIndex channel.threads
                                |> Maybe.withDefault Thread.frontendInit
                                |> threadConversationView
                                    (let
                                        lastViewed : Id ThreadMessageId
                                        lastViewed =
                                            SeqDict.get
                                                ( GuildOrDmId (GuildOrDmId_Guild { guildId = guildId, channelId = channelId }), threadMessageIndex )
                                                local.localUser.user.lastViewedThreadMessage
                                                |> Maybe.withDefault (Id.fromInt -1)
                                     in
                                     case local.localUser.currentlyViewing of
                                        Viewing_ChannelThread data ->
                                            if
                                                data.id
                                                    == { guildId = guildId
                                                       , channelId = channelId
                                                       , threadId = threadMessageIndex
                                                       }
                                            then
                                                unreadDividerAt lastViewed data.previouslyLastViewedMessage

                                            else
                                                lastViewed

                                        _ ->
                                            lastViewed
                                    )
                                    (GuildOrDmId_Guild { guildId = guildId, channelId = channelId })
                                    maybeUrlMessageId
                                    threadMessageIndex
                                    loggedIn
                                    model
                                    local
                                    (ChannelName.toString channel.name)
                                    (threadPreviewText
                                        local.localUser.timezone
                                        (User.allUsers local.localUser)
                                        threadMessageIndex
                                        local.localUser.decryptedMessages
                                        channel
                                    )

                        NoThreadWithFriends maybeUrlMessageId _ ->
                            conversationView
                                (let
                                    lastViewed : Id ChannelMessageId
                                    lastViewed =
                                        SeqDict.get
                                            (GuildOrDmId (GuildOrDmId_Guild { guildId = guildId, channelId = channelId }))
                                            local.localUser.user.lastViewedMessage
                                            |> Maybe.withDefault (Id.fromInt -1)
                                 in
                                 case local.localUser.currentlyViewing of
                                    Viewing_Channel data ->
                                        if data.id == { guildId = guildId, channelId = channelId } then
                                            unreadDividerAt lastViewed data.previouslyLastViewedMessage

                                        else
                                            lastViewed

                                    _ ->
                                        lastViewed
                                )
                                (GuildOrDmId_Guild { guildId = guildId, channelId = channelId })
                                maybeUrlMessageId
                                loggedIn
                                model
                                local
                                (ChannelName.toString channel.name)
                                channel

                Nothing ->
                    pageMissing channelDoesNotExistText

        NewChannelRoute ->
            SeqDict.get guildId loggedIn.newChannelForm
                |> Maybe.withDefault newChannelFormInit
                |> newChannelFormView (MyUi.isMobile model) guildId

        GuildSettingsRoute ->
            guildSettingsView model loggedIn local guildId guild

        JoinRoute _ ->
            Ui.none


discordChannelView : DiscordGuildRouteData -> DiscordFrontendGuild -> LoggedIn2 -> LocalState -> LoadedFrontend -> Element FrontendMsg_
discordChannelView routeData guild loggedIn local model =
    case routeData.channelRoute of
        DiscordChannel_ChannelRoute channelId threadRoute _ ->
            case SeqDict.get channelId guild.channels of
                Just channel ->
                    let
                        ( availableCustomEmojis, availableStickers ) =
                            LocalState.discordGuildAvailableStickersAndCustomEmojis local.localUser guild
                    in
                    case threadRoute of
                        ViewThreadWithFriends threadMessageIndex maybeUrlMessageId _ ->
                            SeqDict.get threadMessageIndex channel.threads
                                |> Maybe.withDefault Thread.discordFrontendInit
                                |> discordThreadConversationView
                                    (let
                                        lastViewed : Id ThreadMessageId
                                        lastViewed =
                                            SeqDict.get
                                                ( DiscordGuildOrDmId
                                                    (DiscordGuildOrDmId_Guild { currentUserId = routeData.currentDiscordUserId, guildId = routeData.guildId, channelId = channelId })
                                                , threadMessageIndex
                                                )
                                                local.localUser.user.lastViewedThreadMessage
                                                |> Maybe.withDefault (Id.fromInt -1)
                                     in
                                     case local.localUser.currentlyViewing of
                                        Viewing_DiscordChannelThread data ->
                                            if
                                                data.id
                                                    == { guildId = routeData.guildId
                                                       , channelId = channelId
                                                       , currentUserId = routeData.currentDiscordUserId
                                                       , threadId = threadMessageIndex
                                                       }
                                            then
                                                unreadDividerAt lastViewed data.previouslyLastViewedMessage

                                            else
                                                lastViewed

                                        _ ->
                                            lastViewed
                                    )
                                    routeData.currentDiscordUserId
                                    (DiscordGuildOrDmId_Guild { currentUserId = routeData.currentDiscordUserId, guildId = routeData.guildId, channelId = channelId })
                                    maybeUrlMessageId
                                    threadMessageIndex
                                    loggedIn
                                    model
                                    local
                                    (ChannelName.toString channel.name
                                        ++ " / "
                                        ++ threadPreviewText
                                            local.localUser.timezone
                                            (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                                            threadMessageIndex
                                            SeqDict.empty
                                            channel
                                    )
                                    availableCustomEmojis
                                    availableStickers

                        NoThreadWithFriends maybeUrlMessageId _ ->
                            discordConversationView
                                (let
                                    lastViewed : Id ChannelMessageId
                                    lastViewed =
                                        SeqDict.get
                                            (DiscordGuildOrDmId
                                                (DiscordGuildOrDmId_Guild { currentUserId = routeData.currentDiscordUserId, guildId = routeData.guildId, channelId = channelId })
                                            )
                                            local.localUser.user.lastViewedMessage
                                            |> Maybe.withDefault (Id.fromInt -1)
                                 in
                                 case local.localUser.currentlyViewing of
                                    Viewing_DiscordChannel data ->
                                        if
                                            data.id
                                                == { guildId = routeData.guildId
                                                   , channelId = channelId
                                                   , currentUserId = routeData.currentDiscordUserId
                                                   }
                                        then
                                            unreadDividerAt lastViewed data.previouslyLastViewedMessage

                                        else
                                            lastViewed

                                    _ ->
                                        lastViewed
                                )
                                routeData.currentDiscordUserId
                                (DiscordGuildOrDmId_Guild { currentUserId = routeData.currentDiscordUserId, guildId = routeData.guildId, channelId = channelId })
                                maybeUrlMessageId
                                loggedIn
                                model
                                local
                                (ChannelName.toString channel.name)
                                channel
                                availableCustomEmojis
                                availableStickers

                Nothing ->
                    pageMissing channelDoesNotExistText

        DiscordChannel_NewChannelRoute ->
            pageMissing "Adding Discord channels not supported yet"

        DiscordChannel_GuildSettingsRoute ->
            discordGuildSettingsView (MyUi.isMobile model) routeData.currentDiscordUserId routeData.guildId guild local


discordGuildSettingsView :
    Bool
    -> Discord.Id Discord.UserId
    -> Discord.Id Discord.GuildId
    -> DiscordFrontendGuild
    -> LocalState
    -> Element FrontendMsg_
discordGuildSettingsView isMobile currentUserId guildId guild local =
    Ui.el
        [ Ui.height Ui.fill ]
        (Ui.column
            [ Ui.Font.color MyUi.font1
            , Ui.alignTop
            , Ui.spacing 16
            , Ui.padding 16
            ]
            [ Ui.el [ Ui.Font.bold, Ui.Font.size 20 ] (Ui.text "Discord Guild Settings")
            , Ui.column
                [ Ui.paddingXY 8 0 ]
                [ Ui.el [ Ui.paddingXY 8 0, Ui.Font.bold ] (Ui.text "Owner")
                , discordMemberLabel isMobile local.localUser currentUserId (MembersAndOwner.owner guild.membersAndOwner)
                ]
            , Ui.el
                [ Ui.paddingXY 16 0 ]
                (MyUi.radioColumn
                    (Dom.id "guild_discordNotificationLevel")
                    (PressedDiscordGuildNotificationLevel currentUserId guildId)
                    (if SeqSet.member guildId local.localUser.user.discordNotifyOnAllMessages then
                        Just NotifyOnEveryMessage

                     else
                        Just NotifyOnMention
                    )
                    (Ui.text "Guild notifications")
                    [ ( NotifyOnMention, "Only when mentioned" )
                    , ( NotifyOnEveryMessage, "On every message" )
                    ]
                )
            , Ui.el
                [ Ui.paddingXY 16 0 ]
                (MuteSettings.view
                    (PressedMuteDiscordGuild currentUserId guildId)
                    (MuteSettings.isDiscordGuildSpecificallyMute local.localUser.user.muteSettings guildId)
                )
            ]
        )


guildSettingsView : LoadedFrontend -> LoggedIn2 -> LocalState -> Id GuildId -> FrontendGuild -> Element FrontendMsg_
guildSettingsView model loggedIn local guildId guild =
    let
        isMobile =
            MyUi.isMobile model

        owner =
            MembersAndOwner.owner guild.membersAndOwner

        isOwner : Bool
        isOwner =
            owner == local.localUser.session.userId

        editGuildForm : EditGuildForm
        editGuildForm =
            SeqDict.get guildId loggedIn.editGuildForm
                |> Maybe.withDefault (editGuildFormInit guild)

        guildIconEditor : ImageEditor.Model
        guildIconEditor =
            case loggedIn.guildIconEditor of
                Just ( existingGuildId, editor ) ->
                    if existingGuildId == guildId then
                        editor

                    else
                        ImageEditor.init

                Nothing ->
                    ImageEditor.init
    in
    Ui.el
        [ Ui.height Ui.fill ]
        (Ui.column
            [ Ui.Font.color MyUi.font1
            , Ui.alignTop
            , Ui.spacing 16
            , MyUi.scrollable (MyUi.canScroll (MyUi.isMobile model) model.drag)
            ]
            [ ChannelHeader.channelHeader isMobile (Ui.text "Guild settings") Nothing
            , Ui.column
                [ Ui.paddingXY 8 0 ]
                [ Ui.el [ Ui.paddingXY 8 0, Ui.Font.bold ] (Ui.text "Owner")
                , memberLabel isMobile local.localUser owner
                ]
            , if isOwner then
                editGuildNameSection guildId guild editGuildForm

              else
                Ui.none
            , if isOwner then
                Ui.column
                    [ Ui.spacing 8, Ui.paddingXY 16 0 ]
                    [ Ui.el [ Ui.Font.bold ] (Ui.text "Guild icon")
                    , Ui.row
                        [ Ui.spacing 12, Ui.alignLeft ]
                        [ GuildIcon.view (GuildIcon.Normal NoNotification) guild
                        , ImageEditor.view model.windowSize (guild.icon /= Nothing) guildIconEditor
                            |> Ui.map (GuildIconEditorMsg guildId)
                        ]
                    ]

              else
                Ui.none
            , Ui.el
                [ Ui.paddingXY 16 0 ]
                (submitButton (Dom.id "guild_createInviteLink") (PressedCreateInviteLink guildId) "Create invite link")
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
                                    Route.encode (GuildRoute guildId (JoinRoute inviteId) ChannelsHiddenOnMobile)

                                inviteLink : String
                                inviteLink =
                                    Env.domain ++ url

                                showQrCode : Bool
                                showQrCode =
                                    Just inviteId == loggedIn.showInviteLinkQrCode
                            in
                            Ui.column
                                [ Ui.spacing 8 ]
                                [ Ui.row
                                    [ Ui.spacing 16 ]
                                    [ Ui.el
                                        [ Ui.widthMax 300 ]
                                        (MyUi.copyBox
                                            (Dom.id "guild_inviteLinkCopy")
                                            Nothing
                                            PressedCopyText
                                            FrontendNoOp
                                            model
                                            inviteLink
                                        )
                                    , MyUi.elButton
                                        (Dom.id ("guild_inviteLinkQrCode_" ++ SecretId.toString inviteId))
                                        (PressedToggleInviteLinkQrCode inviteId)
                                        [ Ui.Font.color MyUi.font2
                                        , Ui.rounded 4
                                        , Ui.border 1
                                        , Ui.borderColor MyUi.inputBorder
                                        , Ui.paddingXY 6 0
                                        , Ui.width Ui.shrink
                                        , Ui.height Ui.fill
                                        , Ui.contentCenterY
                                        , Ui.Font.size 14
                                        ]
                                        (Ui.text
                                            (if showQrCode then
                                                "Hide QR code"

                                             else
                                                "Show QR code"
                                            )
                                        )
                                    , if isOwner then
                                        MyUi.deleteButton
                                            (Dom.id ("guild_deleteInviteLink_" ++ SecretId.toString inviteId))
                                            (PressedDeleteInviteLink guildId inviteId)

                                      else
                                        Ui.none
                                    , if Duration.from data.createdAt model.time |> Quantity.lessThan (Duration.minutes 5) then
                                        Ui.text "Created just now!"

                                      else
                                        Ui.none
                                    ]
                                , if showQrCode then
                                    Ui.Lazy.lazy2 inviteLinkQrCodeView (conversationWidth model) inviteLink

                                  else
                                    Ui.none
                                ]
                        )
                )
            , Ui.el
                [ Ui.paddingXY 16 0 ]
                (MyUi.radioColumn
                    (Dom.id "guild_notificationLevel")
                    (PressedGuildNotificationLevel guildId)
                    (if SeqSet.member guildId local.localUser.user.notifyOnAllMessages then
                        Just NotifyOnEveryMessage

                     else
                        Just NotifyOnMention
                    )
                    (Ui.text "Guild notifications")
                    [ ( NotifyOnMention, "Only when mentioned" )
                    , ( NotifyOnEveryMessage, "On every message" )
                    ]
                )
            , Ui.el
                [ Ui.paddingXY 16 0 ]
                (MuteSettings.view
                    (PressedMuteGuild guildId)
                    (MuteSettings.isGuildSpecificallyMute local.localUser.user.muteSettings guildId)
                )
            , if isOwner then
                deleteGuildSection guildId guild editGuildForm

              else
                leaveGuildSection guildId editGuildForm
            ]
        )


editGuildFormInit : FrontendGuild -> EditGuildForm
editGuildFormInit guild =
    { name = GuildName.toString guild.name
    , deleteConfirmation = ""
    , showDeleteConfirmation = False
    , showLeaveConfirmation = False
    , pressedSubmit = False
    }


editGuildNameSection : Id GuildId -> FrontendGuild -> EditGuildForm -> Element FrontendMsg_
editGuildNameSection guildId guild form =
    let
        nameLabel =
            Ui.Input.label
                "editGuildName"
                [ Ui.Font.bold, Ui.paddingXY 2 0 ]
                (Ui.text "Guild name")

        hasChanges : Bool
        hasChanges =
            form.name /= GuildName.toString guild.name
    in
    Ui.column
        [ Ui.spacing 8, Ui.paddingXY 16 0 ]
        [ nameLabel.element
        , Ui.Input.text
            [ Ui.padding 6
            , Ui.background MyUi.inputBackground
            , Ui.borderColor MyUi.inputBorder
            , Ui.widthMax 500
            ]
            { onChange = \text -> EditGuildFormChanged guildId { form | name = text }
            , text = form.name
            , placeholder = Nothing
            , label = nameLabel.id
            }
        , case ( form.pressedSubmit, GuildName.fromString form.name ) of
            ( True, Err error ) ->
                Ui.el [ Ui.paddingXY 2 0, Ui.Font.color MyUi.errorColor ] (Ui.text error)

            _ ->
                Ui.none
        , if hasChanges then
            Ui.row
                [ Ui.spacing 8 ]
                [ MyUi.secondaryButton
                    (Dom.id "guild_resetEditGuild")
                    (PressedResetEditGuildChanges guildId)
                    "Reset"
                , submitButton
                    (Dom.id "guild_submitEditGuild")
                    (PressedSubmitEditGuildChanges guildId form)
                    "Save changes"
                ]

          else
            Ui.none
        ]


deleteGuildSection : Id GuildId -> FrontendGuild -> EditGuildForm -> Element FrontendMsg_
deleteGuildSection guildId guild form =
    let
        guildNameString : String
        guildNameString =
            GuildName.toString guild.name

        confirmationMatches : Bool
        confirmationMatches =
            form.deleteConfirmation == guildNameString

        ( deleteOnPress, deleteEnabled ) =
            if not form.showDeleteConfirmation then
                ( EditGuildFormChanged guildId { form | showDeleteConfirmation = True }, True )

            else if confirmationMatches then
                ( PressedDeleteGuild guildId, True )

            else
                ( FrontendNoOp, False )
    in
    Ui.column
        [ Ui.spacing 12, Ui.paddingXY 16 0 ]
        [ Ui.el [ Ui.height (Ui.px 1), Ui.background MyUi.border2 ] Ui.none
        , if form.showDeleteConfirmation then
            deleteGuildConfirmationInput guildId guildNameString form

          else
            Ui.none
        , MyUi.elButton
            (Dom.id "guild_deleteGuild")
            deleteOnPress
            [ Ui.paddingXY 16 4
            , Ui.background
                (if deleteEnabled then
                    MyUi.deleteButtonBackground

                 else
                    MyUi.disabledButtonBackground
                )
            , Ui.width Ui.shrink
            , Ui.rounded 4
            , Ui.Font.color MyUi.deleteButtonFont
            , Ui.Font.bold
            , Ui.borderColor
                (if deleteEnabled then
                    MyUi.deleteButtonBorder

                 else
                    MyUi.disabledButtonBorder
                )
            , Ui.border 1
            ]
            (Ui.text deleteGuildText)
        ]


leaveGuildSection : Id GuildId -> EditGuildForm -> Element FrontendMsg_
leaveGuildSection guildId form =
    Ui.column
        [ Ui.spacing 12, Ui.paddingXY 16 0 ]
        [ Ui.el [ Ui.height (Ui.px 1), Ui.background MyUi.border2 ] Ui.none
        , if form.showLeaveConfirmation then
            Ui.el
                [ Ui.Font.color MyUi.font2 ]
                (Ui.text "You'll need to use an invite link to rejoin. Are you sure?")

          else
            Ui.none
        , MyUi.elButton
            (Dom.id "guild_leaveGuild")
            (if form.showLeaveConfirmation then
                PressedLeaveGuild guildId

             else
                EditGuildFormChanged guildId { form | showLeaveConfirmation = True }
            )
            [ Ui.paddingXY 16 4
            , Ui.background MyUi.deleteButtonBackground
            , Ui.width Ui.shrink
            , Ui.rounded 4
            , Ui.Font.color MyUi.deleteButtonFont
            , Ui.Font.bold
            , Ui.borderColor MyUi.deleteButtonBorder
            , Ui.border 1
            ]
            (Ui.text
                (if form.showLeaveConfirmation then
                    confirmLeaveGuildText

                 else
                    leaveGuildText
                )
            )
        ]


deleteGuildConfirmationInput : Id GuildId -> String -> EditGuildForm -> Element FrontendMsg_
deleteGuildConfirmationInput guildId guildNameString form =
    let
        confirmLabel =
            Ui.Input.label
                "deleteGuildConfirmation"
                [ Ui.Font.color MyUi.font2, Ui.paddingXY 2 0 ]
                (Ui.text ("Type \"" ++ guildNameString ++ "\" to confirm deletion"))
    in
    Ui.column
        []
        [ confirmLabel.element
        , Ui.Input.text
            [ Ui.padding 6
            , Ui.background MyUi.inputBackground
            , Ui.borderColor MyUi.inputBorder
            , Ui.widthMax 500
            ]
            { onChange = \text -> EditGuildFormChanged guildId { form | deleteConfirmation = text }
            , text = form.deleteConfirmation
            , placeholder = Nothing
            , label = confirmLabel.id
            }
        ]


inviteLinkQrCodeView : Int -> String -> Element msg
inviteLinkQrCodeView containerWidth inviteLink =
    case QRCode.fromString inviteLink of
        Ok qrCode ->
            let
                size =
                    min 300 containerWidth
            in
            Ui.el
                [ Ui.background MyUi.white
                , Ui.padding 12
                , Ui.rounded 8
                , Ui.width Ui.shrink
                ]
                (QRCode.toSvgWithoutQuietZone
                    [ MyUi.widthAttr size, MyUi.heightAttr size ]
                    qrCode
                    |> Ui.html
                )

        Err _ ->
            Ui.none


channelTextInputId : HtmlId
channelTextInputId =
    "channel_textinput" |> Dom.id


messageHover : AnyGuildOrDmId -> ThreadRouteWithMessage -> LoggedIn2 -> LoadedFrontend -> IsHovered
messageHover guildOrDmId threadRoute loggedIn model =
    case loggedIn.messageHover of
        MessageMenu messageMenu ->
            if guildOrDmId == messageMenu.guildOrDmId && threadRoute == messageMenu.threadRoute then
                IsHoveredButNoMenu

            else
                IsNotHovered

        MessageHover guildOrDmIdA threadRouteA ->
            if guildOrDmId == guildOrDmIdA then
                if threadRouteA == threadRoute then
                    if drawingIsSelectingAnchor loggedIn model then
                        IsHoveredWhileSelectingAnchor

                    else
                        IsHovered

                else
                    notHoveredWhileSelectingAnchor loggedIn model

            else
                notHoveredWhileSelectingAnchor loggedIn model

        _ ->
            notHoveredWhileSelectingAnchor loggedIn model


{-| Hovering a message in the unread overview restarts the animated emojis, stickers and
embeds inside it, the same as it does in a channel, and brings up a menu offering to react
to it. That's all the menu offers: editing and replying belong to the channel the message
came from.
-}
unreadOverviewMessageHover : AnyGuildOrDmId -> ThreadRouteWithMessage -> LoggedIn2 -> IsHovered
unreadOverviewMessageHover guildOrDmId threadRoute loggedIn =
    case loggedIn.messageHover of
        MessageHover hoveredGuildOrDmId hoveredThreadRoute ->
            if guildOrDmId == hoveredGuildOrDmId && threadRoute == hoveredThreadRoute then
                IsHoveredReactionsOnly

            else
                IsNotHovered

        _ ->
            IsNotHovered


{-| A message the pointer isn't hovering over. Fingers can't hover, so on mobile
every message offers up its drawing anchors while the drawing tab waits for one
to be picked, instead of only the hovered message.
-}
notHoveredWhileSelectingAnchor : LoggedIn2 -> LoadedFrontend -> IsHovered
notHoveredWhileSelectingAnchor loggedIn model =
    if MyUi.isMobile model && drawingIsSelectingAnchor loggedIn model then
        IsHoveredWhileSelectingAnchor

    else
        IsNotHovered


revealedChannelSpoilers : AnyGuildOrDmId -> LoggedIn2 -> SeqDict (Id ChannelMessageId) (NonemptySet Int)
revealedChannelSpoilers guildOrDmId loggedIn =
    case SeqDict.get guildOrDmId loggedIn.revealedSpoilers of
        Just revealed ->
            revealed.messages

        Nothing ->
            SeqDict.empty


revealedThreadSpoilers : AnyGuildOrDmId -> Id ChannelMessageId -> LoggedIn2 -> SeqDict (Id ThreadMessageId) (NonemptySet Int)
revealedThreadSpoilers guildOrDmId threadId loggedIn =
    case SeqDict.get guildOrDmId loggedIn.revealedSpoilers of
        Just revealedSpoilers2 ->
            SeqDict.get threadId revealedSpoilers2.threadMessages |> Maybe.withDefault SeqDict.empty

        Nothing ->
            SeqDict.empty


conversationViewHelper :
    Id ChannelMessageId
    -> GuildOrDmId
    -> Maybe (Id ChannelMessageId)
    ->
        { a
            | messages : MessageArray ChannelMessageId (Id UserId)
            , visibleMessages : VisibleMessages ChannelMessageId
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) FrontendThread
            , dateDividerDrawings : SeqDict Date (Drawing (Id UserId))
        }
    -> LoggedIn2
    -> LocalState
    -> LoadedFrontend
    -> List ( String, Element FrontendMsg_ )
conversationViewHelper lastViewedIndex guildOrDmIdNoThread maybeUrlMessageId channel loggedIn local model =
    let
        guildOrDmId : ( AnyGuildOrDmId, ThreadRoute )
        guildOrDmId =
            ( GuildOrDmId guildOrDmIdNoThread, NoThread )

        maybeEditing : Maybe EditMessage
        maybeEditing =
            SeqDict.get guildOrDmId loggedIn.editMessage

        othersEditing : SeqSet (Id ChannelMessageId)
        othersEditing =
            SeqDict.remove local.localUser.session.userId channel.lastTypedAt
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
            revealedChannelSpoilers (GuildOrDmId guildOrDmIdNoThread) loggedIn

        containerWidth : Int
        containerWidth =
            conversationWidth model

        isMobile : Bool
        isMobile =
            MyUi.isMobile model

        isSelectingAnchor =
            drawingIsSelectingAnchor loggedIn model
    in
    MessageArray.foldr
        (\messageId maybeMessage ( maybeLastDate, list ) ->
            let
                index : Int
                index =
                    Id.toInt messageId
            in
            case maybeMessage of
                Just message ->
                    let
                        threadRoute2 : ThreadRouteWithMessage
                        threadRoute2 =
                            NoThreadWithMessage messageId

                        threadId : Id ChannelMessageId
                        threadId =
                            Id.fromInt index

                        messageHover2 : IsHovered
                        messageHover2 =
                            messageHover (GuildOrDmId guildOrDmIdNoThread) threadRoute2 loggedIn model

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

                        highlight : HighlightMessage
                        highlight =
                            if maybeUrlMessageId == Just messageId then
                                UrlHighlight

                            else if replyToIndex == Just messageId then
                                ReplyToHighlight

                            else
                                NoHighlight

                        maybeRepliedTo2 : Maybe ( Id ChannelMessageId, Message ChannelMessageId (Id UserId) )
                        maybeRepliedTo2 =
                            maybeRepliedTo message channel

                        date : Date
                        date =
                            Message.createdAt message |> Date.fromPosix local.localUser.timezone
                    in
                    ( Just date
                    , ( String.fromInt index
                      , case isEditing of
                            Just edit ->
                                if MyUi.isMobile model then
                                    -- On mobile, we show the editor at the bottom instead
                                    messageView
                                        model.time
                                        isMobile
                                        containerWidth
                                        False
                                        revealedSpoilers
                                        highlight
                                        messageHover2
                                        otherUserIsEditing
                                        local.localUser.session.userId
                                        (User.allUsers local.localUser)
                                        local.localUser
                                        maybeRepliedTo2
                                        (SeqDict.get threadId channel.threads)
                                        messageId
                                        message
                                        |> Ui.map (MessageViewMsg (GuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                else
                                    let
                                        allUsers =
                                            User.allUsers local.localUser

                                        editRichText : Maybe (Nonempty (RichText (Id UserId)))
                                        editRichText =
                                            case String.Nonempty.fromString edit.text of
                                                Just nonempty ->
                                                    RichText.fromNonemptyString local.localUser.timezone allUsers nonempty |> Just

                                                Nothing ->
                                                    Nothing

                                        charsLeft =
                                            RichText.maxLength - String.length edit.text
                                    in
                                    messageEditingView
                                        containerWidth
                                        model.time
                                        isMobile
                                        guildOrDmId
                                        threadRoute2
                                        message
                                        maybeRepliedTo2
                                        (SeqDict.get threadId channel.threads)
                                        revealedSpoilers
                                        charsLeft
                                        edit
                                        editRichText
                                        loggedIn
                                        local.localUser.decryptedMessages
                                        local.localUser.session.userId
                                        allUsers
                                        local

                            Nothing ->
                                case SeqDict.get threadId channel.threads of
                                    Nothing ->
                                        case maybeRepliedTo2 of
                                            Just _ ->
                                                messageView
                                                    model.time
                                                    isMobile
                                                    containerWidth
                                                    False
                                                    revealedSpoilers
                                                    highlight
                                                    messageHover2
                                                    otherUserIsEditing
                                                    local.localUser.session.userId
                                                    (User.allUsers local.localUser)
                                                    local.localUser
                                                    maybeRepliedTo2
                                                    Nothing
                                                    messageId
                                                    message
                                                    |> Ui.map (MessageViewMsg (GuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                            Nothing ->
                                                Ui.Lazy.lazy5
                                                    messageViewNotThreadStarter
                                                    (encodeMessageView isMobile messageHover2 containerWidth otherUserIsEditing highlight model.time)
                                                    revealedSpoilers
                                                    local.localUser
                                                    index
                                                    message
                                                    |> Ui.map (MessageViewMsg (GuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                    Just thread ->
                                        case maybeRepliedTo2 of
                                            Just _ ->
                                                messageView
                                                    model.time
                                                    isMobile
                                                    containerWidth
                                                    False
                                                    revealedSpoilers
                                                    highlight
                                                    messageHover2
                                                    otherUserIsEditing
                                                    local.localUser.session.userId
                                                    (User.allUsers local.localUser)
                                                    local.localUser
                                                    maybeRepliedTo2
                                                    (Just thread)
                                                    messageId
                                                    message
                                                    |> Ui.map (MessageViewMsg (GuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                            Nothing ->
                                                Ui.Lazy.lazy6
                                                    messageViewThreadStarter
                                                    (encodeMessageView isMobile messageHover2 containerWidth otherUserIsEditing highlight model.time)
                                                    revealedSpoilers
                                                    local.localUser
                                                    index
                                                    thread
                                                    message
                                                    |> Ui.map (MessageViewMsg (GuildOrDmId guildOrDmIdNoThread) threadRoute2)
                      )
                        |> (\keyedMessage ->
                                keyedMessage
                                    :: List.map
                                        (Tuple.mapSecond (Ui.map (MessageViewMsg (GuildOrDmId guildOrDmIdNoThread) threadRoute2)))
                                        (newMessageLine
                                            (User.userColor local.localUser)
                                            isSelectingAnchor
                                            channel.dateDividerDrawings
                                            maybeLastDate
                                            date
                                            lastViewedIndex
                                            index
                                            messageId
                                        )
                                    ++ list
                           )
                    )

                Nothing ->
                    ( maybeLastDate, ( String.fromInt index, unloadedMessageView index ) :: list )
        )
        ( Nothing, [] )
        (VisibleMessages.slice channel)
        |> Tuple.second
        |> prependUnreadDivider lastViewedIndex channel.visibleMessages.oldest


userTextMessageRepliedTo :
    { a | repliedTo : Maybe (Id messageId) }
    -> { b | messages : MessageArray messageId userId }
    -> Maybe ( Id messageId, Message messageId userId )
userTextMessageRepliedTo data channel =
    case data.repliedTo of
        Just repliedToIndex ->
            case MessageArray.get repliedToIndex channel.messages of
                Just message2 ->
                    Just ( repliedToIndex, message2 )

                _ ->
                    Nothing

        Nothing ->
            Nothing


maybeRepliedTo : Message messageId userId -> { a | messages : MessageArray messageId userId } -> Maybe ( Id messageId, Message messageId userId )
maybeRepliedTo message channel =
    case message of
        UserTextMessage data ->
            userTextMessageRepliedTo data channel

        EncryptedUserTextMessage data ->
            userTextMessageRepliedTo data channel

        UserJoinedMessage _ _ _ _ ->
            Nothing

        DeletedMessage _ ->
            Nothing

        CallStarted _ ->
            Nothing

        GameStarted _ ->
            Nothing


drawingIsSelectingAnchor : LoggedIn2 -> LoadedFrontend -> Bool
drawingIsSelectingAnchor loggedIn model =
    loggedIn.drawingMode == Drawing.NoSelectedAnchor && Route.toChannelHeaderTab model.route == Just ChannelHeaderTab_Draw


discordConversationViewHelper :
    Id ChannelMessageId
    -> Discord.Id Discord.UserId
    -> DiscordGuildOrDmId
    -> Maybe (Id ChannelMessageId)
    ->
        { a
            | messages : MessageArray ChannelMessageId (Discord.Id Discord.UserId)
            , visibleMessages : VisibleMessages ChannelMessageId
            , lastTypedAt : SeqDict (Discord.Id Discord.UserId) (LastTypedAt ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) DiscordFrontendThread
            , dateDividerDrawings : SeqDict Date (Drawing (Discord.Id Discord.UserId))
        }
    -> LoggedIn2
    -> LocalState
    -> LoadedFrontend
    -> List ( String, Element FrontendMsg_ )
discordConversationViewHelper lastViewedIndex currentDiscordUserId guildOrDmIdNoThread maybeUrlMessageId channel loggedIn local model =
    let
        guildOrDmId : ( AnyGuildOrDmId, ThreadRoute )
        guildOrDmId =
            ( DiscordGuildOrDmId guildOrDmIdNoThread, NoThread )

        maybeEditing : Maybe EditMessage
        maybeEditing =
            SeqDict.get guildOrDmId loggedIn.editMessage

        othersEditing : SeqSet (Id ChannelMessageId)
        othersEditing =
            SeqDict.remove currentDiscordUserId channel.lastTypedAt
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
            revealedChannelSpoilers (DiscordGuildOrDmId guildOrDmIdNoThread) loggedIn

        containerWidth : Int
        containerWidth =
            conversationWidth model

        isMobile : Bool
        isMobile =
            MyUi.isMobile model

        isSelectingAnchor =
            drawingIsSelectingAnchor loggedIn model
    in
    MessageArray.foldr
        (\messageId maybeMessage ( maybeLastDate, list ) ->
            let
                index : Int
                index =
                    Id.toInt messageId
            in
            case maybeMessage of
                Just message ->
                    let
                        threadRoute2 : ThreadRouteWithMessage
                        threadRoute2 =
                            NoThreadWithMessage messageId

                        threadId : Id ChannelMessageId
                        threadId =
                            Id.fromInt index

                        messageHover2 : IsHovered
                        messageHover2 =
                            messageHover (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2 loggedIn model

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

                        highlight : HighlightMessage
                        highlight =
                            if maybeUrlMessageId == Just messageId then
                                UrlHighlight

                            else if replyToIndex == Just messageId then
                                ReplyToHighlight

                            else
                                NoHighlight

                        maybeRepliedTo2 =
                            maybeRepliedTo message channel

                        date : Date
                        date =
                            Message.createdAt message |> Date.fromPosix local.localUser.timezone
                    in
                    ( Just date
                    , ( String.fromInt index
                      , case isEditing of
                            Just edit ->
                                if MyUi.isMobile model then
                                    -- On mobile, we show the editor at the bottom instead
                                    discordMessageView
                                        model.time
                                        isMobile
                                        containerWidth
                                        False
                                        revealedSpoilers
                                        highlight
                                        messageHover2
                                        currentDiscordUserId
                                        (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                                        local.localUser
                                        maybeRepliedTo2
                                        (SeqDict.get threadId channel.threads)
                                        messageId
                                        message
                                        |> Ui.map (MessageViewMsg (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                else
                                    let
                                        allUsers =
                                            LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers

                                        editRichText : Maybe (Nonempty (RichText (Discord.Id Discord.UserId)))
                                        editRichText =
                                            case String.Nonempty.fromString edit.text of
                                                Just nonempty ->
                                                    RichText.fromNonemptyString local.localUser.timezone allUsers nonempty |> Just

                                                Nothing ->
                                                    Nothing
                                    in
                                    messageEditingView
                                        containerWidth
                                        model.time
                                        isMobile
                                        guildOrDmId
                                        threadRoute2
                                        message
                                        maybeRepliedTo2
                                        (SeqDict.get threadId channel.threads)
                                        revealedSpoilers
                                        (RichText.discordCharsLeft OneToOne.empty editRichText)
                                        edit
                                        editRichText
                                        loggedIn
                                        SeqDict.empty
                                        currentDiscordUserId
                                        allUsers
                                        local

                            Nothing ->
                                case SeqDict.get threadId channel.threads of
                                    Nothing ->
                                        case maybeRepliedTo2 of
                                            Just _ ->
                                                discordMessageView
                                                    model.time
                                                    isMobile
                                                    containerWidth
                                                    False
                                                    revealedSpoilers
                                                    highlight
                                                    messageHover2
                                                    currentDiscordUserId
                                                    (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                                                    local.localUser
                                                    maybeRepliedTo2
                                                    Nothing
                                                    messageId
                                                    message
                                                    |> Ui.map (MessageViewMsg (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                            Nothing ->
                                                Ui.Lazy.lazy6
                                                    discordMessageViewNotThreadStarter
                                                    (encodeMessageView isMobile messageHover2 containerWidth otherUserIsEditing highlight model.time)
                                                    revealedSpoilers
                                                    currentDiscordUserId
                                                    local.localUser
                                                    index
                                                    message
                                                    |> Ui.map (MessageViewMsg (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                    Just thread ->
                                        case maybeRepliedTo2 of
                                            Just _ ->
                                                discordMessageView
                                                    model.time
                                                    isMobile
                                                    containerWidth
                                                    False
                                                    revealedSpoilers
                                                    highlight
                                                    messageHover2
                                                    currentDiscordUserId
                                                    (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                                                    local.localUser
                                                    maybeRepliedTo2
                                                    (Just thread)
                                                    messageId
                                                    message
                                                    |> Ui.map (MessageViewMsg (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                            Nothing ->
                                                discordMessageViewThreadStarter
                                                    (encodeMessageView isMobile messageHover2 containerWidth otherUserIsEditing highlight model.time)
                                                    revealedSpoilers
                                                    currentDiscordUserId
                                                    local.localUser
                                                    index
                                                    thread
                                                    message
                                                    |> Ui.map (MessageViewMsg (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2)
                      )
                        |> (\keyedMessage ->
                                keyedMessage
                                    :: List.map
                                        (Tuple.mapSecond (Ui.map (MessageViewMsg (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2)))
                                        (newMessageLine
                                            (User.discordUserColor local.localUser)
                                            isSelectingAnchor
                                            channel.dateDividerDrawings
                                            maybeLastDate
                                            date
                                            lastViewedIndex
                                            index
                                            messageId
                                        )
                                    ++ list
                           )
                    )

                Nothing ->
                    ( maybeLastDate, ( String.fromInt index, unloadedMessageView index ) :: list )
        )
        ( Nothing, [] )
        (VisibleMessages.slice channel)
        |> Tuple.second
        |> prependUnreadDivider lastViewedIndex channel.visibleMessages.oldest


newMessageLine :
    (userId -> UserColor)
    -> Bool
    -> SeqDict Date (Drawing userId)
    -> Maybe Date
    -> Date
    -> Id messageId
    -> Int
    -> Id messageId
    -> List ( String, Element MessageViewMsg )
newMessageLine drawingUserColor isSelectingAnchor dateDividerDrawings maybeLastDate date lastViewedIndex index messageId =
    case maybeLastDate of
        Just lastDate ->
            case ( lastViewedIndex == messageId, date == lastDate ) of
                ( True, True ) ->
                    [ ( "n" ++ String.fromInt index
                      , Ui.el
                            ([ Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
                             , Ui.borderColor MyUi.alertColor
                             ]
                                ++ newContentLabel
                            )
                            Ui.none
                      )
                    ]

                ( False, False ) ->
                    [ ( "n" ++ String.fromInt index
                      , Ui.el
                            [ Ui.paddingXY 8 0
                            , Ui.height (Ui.px 36)
                            , Ui.contentCenterY
                            , MyUi.noShrinking
                            ]
                            (Ui.el
                                [ Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
                                , Ui.borderColor MyUi.font3
                                , dateDivider drawingUserColor isSelectingAnchor dateDividerDrawings date lastDate
                                ]
                                Ui.none
                            )
                      )
                    ]

                ( True, False ) ->
                    [ ( "n" ++ String.fromInt index
                      , Ui.el
                            [ Ui.height (Ui.px 36), Ui.contentCenterY, MyUi.noShrinking ]
                            (Ui.el
                                ([ Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
                                 , Ui.borderColor MyUi.alertColor
                                 , dateDivider drawingUserColor isSelectingAnchor dateDividerDrawings date lastDate
                                 ]
                                    ++ newContentLabel
                                )
                                Ui.none
                            )
                      )
                    ]

                ( False, True ) ->
                    []

        Nothing ->
            []


{-| The divider is drawn underneath the last message the reader had already seen, so a
reader who hasn't seen anything yet has no message to hang it off and newMessageLine draws
nothing. The same happens further up a long conversation, where the message they stopped at
is older than anything loaded. Both mean everything on screen is new, which is the divider
sitting above all of it.
-}
prependUnreadDivider :
    Id messageId
    -> Id messageId
    -> List ( String, Element msg )
    -> List ( String, Element msg )
prependUnreadDivider lastViewedIndex oldestVisibleMessage list =
    if List.isEmpty list || Id.toInt lastViewedIndex >= Id.toInt oldestVisibleMessage then
        list

    else
        ( "nTop"
        , Ui.el
            ([ Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
             , Ui.borderColor MyUi.alertColor
             ]
                ++ newContentLabel
            )
            Ui.none
        )
            :: list


threadConversationViewHelper :
    Id ThreadMessageId
    -> GuildOrDmId
    -> Id ChannelMessageId
    -> Maybe (Id ThreadMessageId)
    -> FrontendThread
    -> LoggedIn2
    -> LocalState
    -> LoadedFrontend
    -> List ( String, Element FrontendMsg_ )
threadConversationViewHelper lastViewedIndex guildOrDmIdNoThread threadId maybeUrlMessageId thread loggedIn local model =
    let
        guildOrDmId : ( AnyGuildOrDmId, ThreadRoute )
        guildOrDmId =
            ( GuildOrDmId guildOrDmIdNoThread, ViewThread threadId )

        maybeEditing : Maybe EditMessage
        maybeEditing =
            SeqDict.get guildOrDmId loggedIn.editMessage

        othersEditing : SeqSet (Id ThreadMessageId)
        othersEditing =
            SeqDict.remove local.localUser.session.userId thread.lastTypedAt
                |> SeqDict.values
                |> List.filterMap
                    (\a ->
                        if Duration.from a.time model.time |> Quantity.lessThan (Duration.seconds 3) then
                            a.messageIndex

                        else
                            Nothing
                    )
                |> SeqSet.fromList

        replyToIndex : Maybe (Id ThreadMessageId)
        replyToIndex =
            SeqDict.get guildOrDmId loggedIn.replyTo |> Maybe.map Id.changeType

        revealedSpoilers : SeqDict (Id ThreadMessageId) (NonemptySet Int)
        revealedSpoilers =
            revealedThreadSpoilers (GuildOrDmId guildOrDmIdNoThread) threadId loggedIn

        containerWidth : Int
        containerWidth =
            conversationWidth model

        isMobile : Bool
        isMobile =
            MyUi.isMobile model

        isSelectingAnchor =
            drawingIsSelectingAnchor loggedIn model
    in
    MessageArray.foldr
        (\messageId maybeMessage ( maybeLastDate, list ) ->
            let
                index : Int
                index =
                    Id.toInt messageId
            in
            case maybeMessage of
                Just message ->
                    let
                        threadRoute2 =
                            ViewThreadWithMessage threadId messageId

                        messageHover2 : IsHovered
                        messageHover2 =
                            messageHover (GuildOrDmId guildOrDmIdNoThread) threadRoute2 loggedIn model

                        otherUserIsEditing : Bool
                        otherUserIsEditing =
                            SeqSet.member messageId othersEditing

                        isEditing : Maybe EditMessage
                        isEditing =
                            case maybeEditing of
                                Just editing ->
                                    if editing.messageIndex == Id.changeType messageId then
                                        Just editing

                                    else
                                        Nothing

                                Nothing ->
                                    Nothing

                        highlight : HighlightMessage
                        highlight =
                            if maybeUrlMessageId == Just messageId then
                                UrlHighlight

                            else if replyToIndex == Just messageId then
                                ReplyToHighlight

                            else
                                NoHighlight

                        maybeRepliedTo2 : Maybe ( Id ThreadMessageId, Message ThreadMessageId (Id UserId) )
                        maybeRepliedTo2 =
                            maybeRepliedTo message thread

                        date : Date
                        date =
                            Message.createdAt message |> Date.fromPosix local.localUser.timezone
                    in
                    ( Just date
                    , ( String.fromInt index
                      , case isEditing of
                            Just editing ->
                                if MyUi.isMobile model then
                                    -- On mobile, we show the editor at the bottom instead
                                    threadMessageView
                                        model.time
                                        isMobile
                                        containerWidth
                                        revealedSpoilers
                                        highlight
                                        messageHover2
                                        otherUserIsEditing
                                        (User.allUsers local.localUser)
                                        local.localUser.session.userId
                                        local.localUser
                                        maybeRepliedTo2
                                        messageId
                                        message
                                        |> Ui.map (MessageViewMsg (GuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                else
                                    let
                                        allUsers =
                                            User.allUsers local.localUser

                                        editRichText : Maybe (Nonempty (RichText (Id UserId)))
                                        editRichText =
                                            case String.Nonempty.fromString editing.text of
                                                Just text ->
                                                    Just (RichText.fromNonemptyString local.localUser.timezone allUsers text)

                                                Nothing ->
                                                    Nothing
                                    in
                                    threadMessageEditingView
                                        containerWidth
                                        model.time
                                        isMobile
                                        guildOrDmId
                                        threadId
                                        (Id.fromInt index)
                                        message
                                        maybeRepliedTo2
                                        revealedSpoilers
                                        (RichText.maxLength - String.length editing.text)
                                        editing
                                        editRichText
                                        loggedIn
                                        local.localUser.decryptedMessages
                                        local.localUser.session.userId
                                        allUsers
                                        local

                            Nothing ->
                                case maybeRepliedTo2 of
                                    Just _ ->
                                        threadMessageView
                                            model.time
                                            isMobile
                                            containerWidth
                                            revealedSpoilers
                                            highlight
                                            messageHover2
                                            otherUserIsEditing
                                            (User.allUsers local.localUser)
                                            local.localUser.session.userId
                                            local.localUser
                                            maybeRepliedTo2
                                            messageId
                                            message
                                            |> Ui.map (MessageViewMsg (GuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                    Nothing ->
                                        Ui.Lazy.lazy5
                                            threadMessageViewLazy
                                            (encodeMessageView isMobile messageHover2 containerWidth otherUserIsEditing highlight model.time)
                                            revealedSpoilers
                                            local.localUser
                                            index
                                            message
                                            |> Ui.map (MessageViewMsg (GuildOrDmId guildOrDmIdNoThread) threadRoute2)
                      )
                        :: List.map
                            (Tuple.mapSecond (Ui.map (MessageViewMsg (GuildOrDmId guildOrDmIdNoThread) threadRoute2)))
                            (newMessageLine
                                (User.userColor local.localUser)
                                isSelectingAnchor
                                thread.dateDividerDrawings
                                maybeLastDate
                                date
                                lastViewedIndex
                                index
                                messageId
                            )
                        ++ list
                    )

                Nothing ->
                    ( maybeLastDate, ( String.fromInt index, unloadedMessageView index ) :: list )
        )
        ( Nothing, [] )
        (VisibleMessages.slice thread)
        |> Tuple.second
        |> prependUnreadDivider lastViewedIndex thread.visibleMessages.oldest


discordThreadConversationViewHelper :
    Id ThreadMessageId
    -> Discord.Id Discord.UserId
    -> DiscordGuildOrDmId
    -> Id ChannelMessageId
    -> Maybe (Id ThreadMessageId)
    -> DiscordFrontendThread
    -> LoggedIn2
    -> LocalState
    -> LoadedFrontend
    -> List ( String, Element FrontendMsg_ )
discordThreadConversationViewHelper lastViewedIndex currentDiscordUserId guildOrDmIdNoThread threadId maybeUrlMessageId thread loggedIn local model =
    let
        guildOrDmId : ( AnyGuildOrDmId, ThreadRoute )
        guildOrDmId =
            ( DiscordGuildOrDmId guildOrDmIdNoThread, ViewThread threadId )

        maybeEditing : Maybe EditMessage
        maybeEditing =
            SeqDict.get guildOrDmId loggedIn.editMessage

        othersEditing : SeqSet (Id ThreadMessageId)
        othersEditing =
            SeqDict.remove currentDiscordUserId thread.lastTypedAt
                |> SeqDict.values
                |> List.filterMap
                    (\a ->
                        if Duration.from a.time model.time |> Quantity.lessThan (Duration.seconds 3) then
                            a.messageIndex

                        else
                            Nothing
                    )
                |> SeqSet.fromList

        replyToIndex : Maybe (Id ThreadMessageId)
        replyToIndex =
            SeqDict.get guildOrDmId loggedIn.replyTo |> Maybe.map Id.changeType

        revealedSpoilers : SeqDict (Id ThreadMessageId) (NonemptySet Int)
        revealedSpoilers =
            revealedThreadSpoilers (DiscordGuildOrDmId guildOrDmIdNoThread) threadId loggedIn

        containerWidth : Int
        containerWidth =
            conversationWidth model

        isMobile : Bool
        isMobile =
            MyUi.isMobile model

        isSelectingAnchor =
            drawingIsSelectingAnchor loggedIn model
    in
    MessageArray.foldr
        (\messageId maybeMessage ( maybeLastDate, list ) ->
            let
                index : Int
                index =
                    Id.toInt messageId
            in
            case maybeMessage of
                Just message ->
                    let
                        threadRoute2 =
                            ViewThreadWithMessage threadId messageId

                        messageHover2 : IsHovered
                        messageHover2 =
                            messageHover (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2 loggedIn model

                        otherUserIsEditing : Bool
                        otherUserIsEditing =
                            SeqSet.member messageId othersEditing

                        isEditing : Maybe EditMessage
                        isEditing =
                            case maybeEditing of
                                Just editing ->
                                    if editing.messageIndex == Id.changeType messageId then
                                        Just editing

                                    else
                                        Nothing

                                Nothing ->
                                    Nothing

                        highlight : HighlightMessage
                        highlight =
                            if maybeUrlMessageId == Just messageId then
                                UrlHighlight

                            else if replyToIndex == Just messageId then
                                ReplyToHighlight

                            else
                                NoHighlight

                        maybeRepliedTo2 : Maybe ( Id ThreadMessageId, Message ThreadMessageId (Discord.Id Discord.UserId) )
                        maybeRepliedTo2 =
                            maybeRepliedTo message thread

                        date : Date
                        date =
                            Message.createdAt message |> Date.fromPosix local.localUser.timezone
                    in
                    ( Just date
                    , ( String.fromInt index
                      , case isEditing of
                            Just editing ->
                                if MyUi.isMobile model then
                                    -- On mobile, we show the editor at the bottom instead
                                    discordThreadMessageView
                                        model.time
                                        isMobile
                                        containerWidth
                                        revealedSpoilers
                                        highlight
                                        messageHover2
                                        (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                                        currentDiscordUserId
                                        local.localUser
                                        maybeRepliedTo2
                                        messageId
                                        message
                                        |> Ui.map (MessageViewMsg (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                else
                                    let
                                        allUsers =
                                            LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers

                                        editRichText : Maybe (Nonempty (RichText (Discord.Id Discord.UserId)))
                                        editRichText =
                                            case String.Nonempty.fromString editing.text of
                                                Just text ->
                                                    Just (RichText.fromNonemptyString local.localUser.timezone allUsers text)

                                                Nothing ->
                                                    Nothing
                                    in
                                    threadMessageEditingView
                                        containerWidth
                                        model.time
                                        isMobile
                                        guildOrDmId
                                        threadId
                                        (Id.fromInt index)
                                        message
                                        maybeRepliedTo2
                                        revealedSpoilers
                                        (RichText.discordCharsLeft OneToOne.empty editRichText)
                                        editing
                                        editRichText
                                        loggedIn
                                        SeqDict.empty
                                        currentDiscordUserId
                                        allUsers
                                        local

                            Nothing ->
                                case maybeRepliedTo2 of
                                    Just _ ->
                                        discordThreadMessageView
                                            model.time
                                            isMobile
                                            containerWidth
                                            revealedSpoilers
                                            highlight
                                            messageHover2
                                            (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                                            currentDiscordUserId
                                            local.localUser
                                            maybeRepliedTo2
                                            messageId
                                            message
                                            |> Ui.map (MessageViewMsg (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                    Nothing ->
                                        Ui.Lazy.lazy6
                                            discordThreadMessageViewLazy
                                            (encodeMessageView isMobile messageHover2 containerWidth otherUserIsEditing highlight model.time)
                                            revealedSpoilers
                                            currentDiscordUserId
                                            local.localUser
                                            index
                                            message
                                            |> Ui.map (MessageViewMsg (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2)
                      )
                        :: List.map
                            (Tuple.mapSecond (Ui.map (MessageViewMsg (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2)))
                            (newMessageLine
                                (User.discordUserColor local.localUser)
                                isSelectingAnchor
                                thread.dateDividerDrawings
                                maybeLastDate
                                date
                                lastViewedIndex
                                index
                                messageId
                            )
                        ++ list
                    )

                Nothing ->
                    ( maybeLastDate, ( String.fromInt index, unloadedMessageView index ) :: list )
        )
        ( Nothing, [] )
        (VisibleMessages.slice thread)
        |> Tuple.second
        |> prependUnreadDivider lastViewedIndex thread.visibleMessages.oldest


unloadedMessageView : Int -> Element msg
unloadedMessageView index =
    Ui.el
        [ Ui.paddingXY 8 8
        , Ui.background MyUi.alertColor
        , Ui.Font.italic
        ]
        (Ui.text ("Something went wrong when loading message " ++ String.fromInt index))


dateDivider : (userId -> UserColor) -> Bool -> SeqDict Date (Drawing userId) -> Date -> Date -> Ui.Attribute MessageViewMsg
dateDivider userIdToColor isSelectingAnchor dateDividerDrawings laterDate newDate =
    Ui.inFront
        (Ui.column
            ([ Ui.Font.color MyUi.font3
             , Ui.centerX
             , Ui.Font.size 14
             , Ui.Font.bold
             , Ui.move { x = 0, y = -20, z = 0 }
             , Ui.rounded 4
             , Ui.paddingXY 4 0
             ]
                ++ Drawing.anchorHighlight
                    (("guild_dateDivider_" ++ Date.toIsoString newDate) |> Dom.id)
                    userIdToColor
                    (MessageView_PressedDateDivider newDate)
                    isSelectingAnchor
                    (SeqDict.get newDate dateDividerDrawings
                        |> Maybe.withDefault Drawing.emptyDrawing
                    )
            )
            [ Ui.el [ MyUi.noPointerEvents, Ui.Font.center ] (Ui.text (MyUi.datestampDate laterDate))
            , Ui.el [ MyUi.noPointerEvents, Ui.Font.center ] (Ui.text (MyUi.datestampDate newDate))
            ]
        )


newContentLabel : List (Ui.Attribute msg)
newContentLabel =
    [ Ui.inFront
        (Ui.el
            [ Ui.move { x = -6, y = -11, z = 0 }
            , Ui.alignRight
            , Ui.width Ui.shrink
            , Ui.Font.bold
            , Ui.Font.size 14
            ]
            (Ui.text newMessagesBadgeText)
        )
    , Ui.inFront
        (Ui.el
            [ Ui.Font.color MyUi.font1
            , Ui.background MyUi.alertColor
            , Ui.width (Ui.px 42)
            , Ui.alignRight
            , Ui.height (Ui.px 15)
            , Ui.roundedWith
                { bottomLeft = 8, bottomRight = 0, topLeft = 8, topRight = 0 }
            , Ui.move { x = 0, y = -8, z = 0 }
            ]
            Ui.none
        )
    ]


{-| The lazy wrappers a message view goes through take six arguments at most, so the flags,
the container width and the current time travel as a single Int. The time is what the
timestamps in a message count down from, rounded to the minute so that a message is only
redrawn when that countdown would read differently. It is multiplied in rather than shifted
in because Bitwise only reaches 32 bits.
-}
encodeMessageView : Bool -> IsHovered -> Int -> Bool -> HighlightMessage -> Time.Posix -> Int
encodeMessageView isMobile isHovered containerWidth otherUserIsEditing highlight time =
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

                IsHoveredWhileSelectingAnchor ->
                    3

                IsHoveredReactionsOnly ->
                    4
            )
        + Bitwise.shiftLeftBy
            4
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
            6
            (if isMobile then
                1

             else
                0
            )
        + Bitwise.shiftLeftBy 7 containerWidth
        + (Time.posixToMillis time // msInMinute * timePackingOffset)


{-| Where the time starts in the Int `encodeMessageView` packs. The flags take the bottom
seven bits and the container width sits above them, so this leaves room for a container up to
65535px wide, and the whole packed number stays well inside the range integers are exact in.
-}
timePackingOffset : Int
timePackingOffset =
    2 ^ 23


msInMinute : Int
msInMinute =
    1000 * 60


decodeMessageView :
    Int
    ->
        { containerWidth : Int
        , isEditing : Bool
        , highlight : HighlightMessage
        , isHovered : IsHovered
        , isMobile : Bool
        , time : Time.Posix
        }
decodeMessageView packed =
    let
        value : Int
        value =
            modBy timePackingOffset packed
    in
    { isEditing = Bitwise.and 0x01 value == 1
    , isHovered =
        case Bitwise.shiftRightBy 1 value |> Bitwise.and 0x07 of
            1 ->
                IsHovered

            2 ->
                IsHoveredButNoMenu

            3 ->
                IsHoveredWhileSelectingAnchor

            4 ->
                IsHoveredReactionsOnly

            _ ->
                IsNotHovered
    , highlight =
        case Bitwise.shiftRightBy 4 value |> Bitwise.and 0x03 of
            1 ->
                ReplyToHighlight

            2 ->
                MentionHighlight

            3 ->
                UrlHighlight

            _ ->
                NoHighlight
    , isMobile = Bitwise.shiftRightBy 6 value |> Bitwise.and 0x01 |> (==) 1
    , containerWidth = Bitwise.shiftRightBy 7 value
    , time = packed // timePackingOffset * msInMinute |> Time.millisToPosix
    }


{-| The friends column and the labels in it are both one argument over what their lazy
wrappers take, so each packs its one flag in with the time the same way a message view
packs its own. The time is already rounded to the minute by the time it gets here.
-}
encodeFriendsColumn : Bool -> Int -> Int
encodeFriendsColumn canScroll time =
    (if canScroll then
        1

     else
        0
    )
        + (time // msInMinute * 2)


decodeFriendsColumn : Int -> { canScroll : Bool, time : Int }
decodeFriendsColumn packed =
    { canScroll = modBy 2 packed == 1
    , time = packed // 2 * msInMinute
    }


encodeFriendLabel : Bool -> Int -> Int
encodeFriendLabel isSelected time =
    (if isSelected then
        1

     else
        0
    )
        + (time // msInMinute * 2)


decodeFriendLabel : Int -> { isSelected : Bool, time : Time.Posix }
decodeFriendLabel packed =
    { isSelected = modBy 2 packed == 1
    , time = packed // 2 * msInMinute |> Time.millisToPosix
    }


conversationContainerId : HtmlId
conversationContainerId =
    Dom.id "conversationContainer"


emojiSelector :
    Bool
    -> SeqSet (Id CustomEmojiId)
    -> SeqSet (Id StickerId)
    -> LocalState
    -> LoggedIn2
    -> LoadedFrontend
    -> Ui.Attribute FrontendMsg_
emojiSelector isMobile availableCustomEmojis availableStickers local loggedIn model =
    let
        emojiConfig : EmojiConfig
        emojiConfig =
            local.localUser.user.emojiConfig

        paddingX : number
        paddingX =
            4

        x : Int
        x =
            if isMobile then
                Coord.xRaw model.windowSize - paddingX * 2

            else
                Coord.xRaw model.windowSize - MyUi.channelAndGuildColumnWidth model.windowSize - paddingX * 2

        {- Reacting doesn't happen anywhere in particular, so the selector opens along the
           bottom rather than pointing at whatever was pressed.
        -}
        atBottomOfTheConversation : Ui.Attribute FrontendMsg_
        atBottomOfTheConversation =
            Ui.inFront
                (Emoji.selector
                    model.startupData.scrollbarWidth
                    x
                    loggedIn.emojiSelector
                    emojiConfig
                    model.emojiData
                    availableCustomEmojis
                    local.localUser.customEmojis
                    availableStickers
                    local.localUser.stickers
                    |> Ui.el
                        [ Ui.alignBottom
                        , Ui.paddingXY paddingX 0
                        , if isMobile then
                            Ui.width Ui.fill

                          else
                            Ui.width Ui.shrink
                        , emojiSelectorZIndex
                        ]
                    |> Ui.map EmojiSelectorMsg
                )
    in
    case loggedIn.showEmojiSelector of
        EmojiSelectorHidden ->
            Ui.noAttr

        EmojiSelectorForReaction _ _ ->
            atBottomOfTheConversation

        EmojiSelectorForSheepGameReaction _ _ _ ->
            atBottomOfTheConversation

        EmojiSelectorForMessage _ ->
            Ui.inFront
                (Emoji.selector
                    model.startupData.scrollbarWidth
                    x
                    loggedIn.emojiSelector
                    emojiConfig
                    model.emojiData
                    availableCustomEmojis
                    local.localUser.customEmojis
                    availableStickers
                    local.localUser.stickers
                    |> Ui.el
                        [ Ui.alignBottom
                        , Ui.paddingXY paddingX 0
                        , if isMobile then
                            Ui.width Ui.fill

                          else
                            Ui.width Ui.shrink
                        , emojiSelectorZIndex
                        ]
                    |> Ui.map EmojiSelectorMsg
                )

        EmojiSelectorForEditMessage position _ ->
            let
                y =
                    Coord.yRaw position - Emoji.selectorHeight - MyUi.channelHeaderHeight
            in
            Ui.inFront
                (Emoji.selector
                    model.startupData.scrollbarWidth
                    x
                    loggedIn.emojiSelector
                    emojiConfig
                    model.emojiData
                    availableCustomEmojis
                    local.localUser.customEmojis
                    availableStickers
                    local.localUser.stickers
                    |> Ui.el
                        [ Ui.paddingXY paddingX 0
                        , Ui.move
                            { x = 0
                            , y =
                                if y < 0 then
                                    Coord.yRaw position

                                else
                                    y
                            , z = 0
                            }
                        , emojiSelectorZIndex
                        ]
                    |> Ui.map EmojiSelectorMsg
                )

        EmojiSelectorForSheepGameInput _ position _ ->
            let
                y : Int
                y =
                    Coord.yRaw position
                        - MyUi.channelHeaderHeight
                        -- A question near the bottom of the window doesn't have the room to
                        -- draw the whole selector underneath it, so it slides back up far
                        -- enough to fit rather than running off the screen.
                        |> min (Coord.yRaw model.windowSize - MyUi.channelHeaderHeight - Emoji.selectorHeight)
                        |> max 0
            in
            Ui.inFront
                (Emoji.selector
                    model.startupData.scrollbarWidth
                    x
                    loggedIn.emojiSelector
                    emojiConfig
                    model.emojiData
                    availableCustomEmojis
                    local.localUser.customEmojis
                    availableStickers
                    local.localUser.stickers
                    |> Ui.el
                        [ Ui.paddingXY paddingX 0
                        , Ui.move { x = 0, y = y, z = 0 }
                        , emojiSelectorZIndex
                        ]
                    |> Ui.map EmojiSelectorMsg
                )


emojiSelectorZIndex : Ui.Attribute msg
emojiSelectorZIndex =
    MyUi.htmlStyle "z-index" "30"


replyToHeader :
    ( AnyGuildOrDmId, ThreadRoute )
    -> Maybe (Id messageId)
    -> SeqDict userId { a | name : PersonName }
    -> { b | messages : MessageArray messageId2 userId }
    -> Element FrontendMsg_
replyToHeader guildOrDmIdNoThread replyTo allUsers channel =
    case replyTo of
        Just messageIndex ->
            case MessageArray.get (Id.changeType messageIndex) channel.messages of
                Just message ->
                    case message of
                        UserTextMessage data ->
                            replyToHeaderHelper (PressedCloseReplyTo guildOrDmIdNoThread) (Just data.createdBy) allUsers

                        EncryptedUserTextMessage data ->
                            replyToHeaderHelper (PressedCloseReplyTo guildOrDmIdNoThread) (Just data.createdBy) allUsers

                        UserJoinedMessage _ userId _ _ ->
                            replyToHeaderHelper (PressedCloseReplyTo guildOrDmIdNoThread) (Just userId) allUsers

                        DeletedMessage _ ->
                            Ui.none

                        CallStarted { startedBy } ->
                            replyToHeaderHelper (PressedCloseReplyTo guildOrDmIdNoThread) (Just startedBy) allUsers

                        GameStarted { startedBy } ->
                            replyToHeaderHelper (PressedCloseReplyTo guildOrDmIdNoThread) (Just startedBy) allUsers

                _ ->
                    Ui.none

        Nothing ->
            Ui.none


replyToHeaderHelper : msg -> Maybe userId -> SeqDict userId { a | name : PersonName } -> Element msg
replyToHeaderHelper onPress userId allUsers =
    Ui.Prose.paragraph
        [ Ui.Font.color MyUi.font2
        , Ui.background MyUi.background2
        , Ui.paddingXY 32 10
        , Ui.roundedWith { topLeft = 8, topRight = 8, bottomLeft = 0, bottomRight = 0 }
        , Ui.borderWith { left = 1, right = 1, top = 1, bottom = 0 }
        , Ui.borderColor MyUi.border1
        , Ui.inFront
            (MyUi.elButton
                (Dom.id "guild_closeReplyToHeader")
                onPress
                [ Ui.width (Ui.px 32)
                , Ui.paddingWith { left = 4, right = 4, top = 4, bottom = 0 }
                , Ui.alignRight
                , MyUi.hoverText "Cancel reply"
                ]
                (Ui.html Icons.x)
            )
        , Ui.inFront
            (Ui.el [ Ui.width (Ui.px 18), Ui.move { x = 10, y = 8, z = 0 } ] (Ui.html Icons.reply))
        ]
        [ Ui.text "Reply to "
        , case userId of
            Just userId2 ->
                Ui.el [ Ui.Font.bold ] (Ui.text (User.toString userId2 allUsers))

            Nothing ->
                Ui.text "message"
        ]
        |> Ui.el [ Ui.paddingWith { left = 0, right = 36, top = 0, bottom = 0 }, Ui.move { x = 0, y = 1, z = 0 } ]


newMessagesId : HtmlId
newMessagesId =
    Dom.id "guild_newMessages"


{-| Messages that arrived without the conversation scrolling to the bottom, either
because the user had scrolled up or because the drawing tab held the scroll
position, are counted in this warning above the message input. Pressing it
deselects the drawing anchor and scrolls to the bottom.
-}
newMessagesView : LoadedFrontend -> LoggedIn2 -> Element FrontendMsg_
newMessagesView model loggedIn =
    if loggedIn.newMessagesWhileNotScrolledToBottom > 0 then
        MyUi.elButton
            newMessagesId
            PressedNewMessagesWarning
            [ Ui.Font.color MyUi.font1
            , Ui.background MyUi.buttonBackground
            , Ui.paddingXY 12 8
            , Ui.roundedWith { topLeft = 8, topRight = 8, bottomLeft = 0, bottomRight = 0 }
            , Ui.borderWith { left = 1, right = 1, top = 1, bottom = 0 }
            , Ui.borderColor MyUi.buttonBorder
            , Ui.pointer
            , MyUi.hover (MyUi.isMobile model) [ Ui.Anim.backgroundColor MyUi.highlightedBorder ]
            ]
            (Ui.Prose.paragraph
                []
                [ Ui.text
                    ((if loggedIn.newMessagesWhileNotScrolledToBottom == 1 then
                        "1 new message"

                      else
                        String.fromInt loggedIn.newMessagesWhileNotScrolledToBottom ++ " new messages"
                     )
                        ++ ". Click here to jump to the bottom."
                    )
                ]
            )

    else
        Ui.none


{-| Attributes added to the conversation while the drawing tab is open. Until
an anchor is picked, valid anchor elements are highlighted when hovering over
them. Once an anchor is picked an overlay captures mouse events for freehand
drawing.
-}
drawingModeAttributes : Route -> Drawing.Model -> List (Ui.Attribute FrontendMsg_)
drawingModeAttributes route drawingMode =
    if Route.toChannelHeaderTab route == Just ChannelHeaderTab_Draw then
        case drawingMode of
            Drawing.NoSelectedAnchor ->
                []

            Drawing.SelectedAnchor selected ->
                Ui.inFront (Drawing.inputOverlay (selected.stroke /= Nothing) DrawingMsg)
                    :: (if selected.zoom /= 1 then
                            -- Keep the magnified conversation clipped to its normal
                            -- area so zooming in doesn't push the rest of the page around.
                            [ Ui.clip ]

                        else
                            []
                       )

    else
        []


{-| Css transform applied to the conversation container so the area around the
selected anchor is magnified for more precise drawing.
-}
drawingZoomAttributes : Route -> Drawing.Model -> List (Ui.Attribute FrontendMsg_)
drawingZoomAttributes route drawingMode =
    case ( Route.toChannelHeaderTab route, drawingMode ) of
        ( Just ChannelHeaderTab_Draw, Drawing.SelectedAnchor selected ) ->
            case ( selected.zoom /= 1, Drawing.zoomCssOrigin selected ) of
                ( True, Just ( originX, originY ) ) ->
                    [ MyUi.htmlStyle "transform" ("scale(" ++ String.fromFloat selected.zoom ++ ")")
                    , MyUi.htmlStyle
                        "transform-origin"
                        (String.fromFloat originX ++ "px " ++ String.fromFloat originY ++ "px")
                    ]

                _ ->
                    []

        _ ->
            []


conversationView :
    Id ChannelMessageId
    -> GuildOrDmId
    -> Maybe (Id ChannelMessageId)
    -> LoggedIn2
    -> LoadedFrontend
    -> LocalState
    -> String
    ->
        { a
            | messages : MessageArray ChannelMessageId (Id UserId)
            , visibleMessages : VisibleMessages ChannelMessageId
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) FrontendThread
            , dateDividerDrawings : SeqDict Date (Drawing (Id UserId))
        }
    -> Element FrontendMsg_
conversationView lastViewedIndex guildOrDmIdNoThread maybeUrlMessageId loggedIn model local name channel =
    let
        allUsers : SeqDict (Id UserId) FrontendUser
        allUsers =
            User.allUsers local.localUser

        replyTo : Maybe (Id ChannelMessageId)
        replyTo =
            SeqDict.get ( GuildOrDmId guildOrDmIdNoThread, NoThread ) loggedIn.replyTo

        isMobile : Bool
        isMobile =
            MyUi.isMobile model

        draft : String
        draft =
            case SeqDict.get ( GuildOrDmId guildOrDmIdNoThread, NoThread ) loggedIn.drafts of
                Just text ->
                    String.Nonempty.toString text

                Nothing ->
                    ""

        draftRichText : Maybe (Nonempty (RichText (Id UserId)))
        draftRichText =
            case SeqDict.get ( GuildOrDmId guildOrDmIdNoThread, NoThread ) loggedIn.drafts of
                Just text ->
                    Just (RichText.fromNonemptyString local.localUser.timezone allUsers text)

                Nothing ->
                    Nothing
    in
    Ui.column
        [ Ui.height Ui.fill
        , Ui.heightMin 0
        ]
        [ ChannelHeader.channel isMobile name guildOrDmIdNoThread local loggedIn model
        , Ui.el
            ([ emojiSelector
                isMobile
                local.localUser.user.availableCustomEmojis
                local.localUser.user.availableStickers
                local
                loggedIn
                model
             , Ui.heightMin 0
             , Ui.height Ui.fill
             ]
                ++ drawingModeAttributes model.route loggedIn.drawingMode
            )
            (Ui.Keyed.column
                ([ Ui.height Ui.fill
                 , Ui.width Ui.fill
                 , Ui.paddingWith { left = 0, right = 0, top = 200, bottom = 16 }
                 , MyUi.scrollable (MyUi.canScroll (MyUi.isMobile model) model.drag)
                 , MyUi.htmlStyle "overflow-wrap" "break-word"
                 , Ui.id (Dom.idToString conversationContainerId)
                 , Ui.Events.on
                    "scroll"
                    (Scroll.decodeScrollToBottom
                        (UserScrolled (GuildOrDmId guildOrDmIdNoThread) NoThread)
                        loggedIn.channelScrollPosition
                    )
                 , Ui.heightMin 0
                 , MyUi.bounceScroll isMobile
                 , MyUi.htmlStyle "background-image" "url(/grid1.png)"
                 ]
                    ++ drawingZoomAttributes model.route loggedIn.drawingMode
                )
                (( "a"
                 , Ui.el
                    [ Ui.Font.color MyUi.font2, Ui.paddingXY 8 4, Ui.alignBottom, Ui.Font.size 20 ]
                    (if VisibleMessages.startIsVisible channel.visibleMessages then
                        case guildOrDmIdNoThread of
                            GuildOrDmId_Guild _ ->
                                Ui.text ("This is the start of #" ++ name)

                            GuildOrDmId_Dm { otherUserId } ->
                                Ui.text
                                    (if otherUserId == local.localUser.session.userId then
                                        "This is the start of a conversation with yourself"

                                     else
                                        "This is the start of your conversation with " ++ name
                                    )

                     else
                        Ui.none
                    )
                 )
                    :: conversationViewHelper
                        lastViewedIndex
                        guildOrDmIdNoThread
                        maybeUrlMessageId
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
            , case SeqDict.get ( GuildOrDmId guildOrDmIdNoThread, NoThread ) loggedIn.filesToUpload of
                Just filesToUpload2 ->
                    fileUploadPreview
                        (PressedDeleteAttachedFile ( GuildOrDmId guildOrDmIdNoThread, NoThread ))
                        (PressedViewAttachedFileInfo ( GuildOrDmId guildOrDmIdNoThread, NoThread ))
                        (PressedToggleAttachedFileSpoiler ( GuildOrDmId guildOrDmIdNoThread, NoThread ))
                        draftRichText
                        filesToUpload2
                        |> Ui.inFront

                Nothing ->
                    Ui.noAttr
            ]
            [ newMessagesView model loggedIn
            , replyToHeader ( GuildOrDmId guildOrDmIdNoThread, NoThread ) replyTo allUsers channel
            , MessageInput.view
                (Dom.id "messageMenu_channelInput")
                (replyTo == Nothing)
                (MyUi.isMobile model)
                channelTextInputId
                (case guildOrDmIdNoThread of
                    GuildOrDmId_Guild _ ->
                        "Write a message in #" ++ name

                    GuildOrDmId_Dm { otherUserId } ->
                        "Write a message to "
                            ++ (if otherUserId == local.localUser.session.userId then
                                    "yourself"

                                else
                                    name
                               )
                )
                (RichText.maxLength - String.length draft)
                draft
                draftRichText
                (case SeqDict.get ( GuildOrDmId guildOrDmIdNoThread, NoThread ) loggedIn.filesToUpload of
                    Just attachedFiles ->
                        NonemptyDict.toSeqDict attachedFiles

                    Nothing ->
                        SeqDict.empty
                )
                local.localUser
                loggedIn
                (User.allUsers local.localUser)
                |> Ui.map (MessageInputMsg (GuildOrDmId guildOrDmIdNoThread) NoThread)
            , peopleAreTypingView allUsers channel local.localUser.session.userId model
            ]
        ]


discordConversationView :
    Id ChannelMessageId
    -> Discord.Id Discord.UserId
    -> DiscordGuildOrDmId
    -> Maybe (Id ChannelMessageId)
    -> LoggedIn2
    -> LoadedFrontend
    -> LocalState
    -> String
    ->
        { a
            | messages : MessageArray ChannelMessageId (Discord.Id Discord.UserId)
            , isForum : Bool
            , visibleMessages : VisibleMessages ChannelMessageId
            , lastTypedAt : SeqDict (Discord.Id Discord.UserId) (LastTypedAt ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) DiscordFrontendThread
            , dateDividerDrawings : SeqDict Date (Drawing (Discord.Id Discord.UserId))
        }
    -> SeqSet (Id CustomEmojiId)
    -> SeqSet (Id StickerId)
    -> Element FrontendMsg_
discordConversationView lastViewedIndex currentDiscordUserId guildOrDmIdNoThread maybeUrlMessageId loggedIn model local name channel availableCustomEmojis availableStickers =
    let
        guildOrDmId : ( AnyGuildOrDmId, ThreadRoute )
        guildOrDmId =
            ( DiscordGuildOrDmId guildOrDmIdNoThread, NoThread )

        allUsers : SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
        allUsers =
            LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers

        replyTo : Maybe (Id ChannelMessageId)
        replyTo =
            SeqDict.get guildOrDmId loggedIn.replyTo

        isMobile : Bool
        isMobile =
            MyUi.isMobile model

        draft : String
        draft =
            case SeqDict.get guildOrDmId loggedIn.drafts of
                Just text ->
                    String.Nonempty.toString text

                Nothing ->
                    ""

        draftRichText : Maybe (Nonempty (RichText (Discord.Id Discord.UserId)))
        draftRichText =
            case SeqDict.get guildOrDmId loggedIn.drafts of
                Just text ->
                    Just (RichText.fromNonemptyString local.localUser.timezone allUsers text)

                Nothing ->
                    Nothing
    in
    Ui.column
        [ Ui.height Ui.fill
        , Ui.heightMin 0
        ]
        [ ChannelHeader.discordChannel isMobile name guildOrDmIdNoThread local loggedIn model
        , Ui.el
            ([ emojiSelector isMobile availableCustomEmojis availableStickers local loggedIn model
             , Ui.heightMin 0
             , Ui.height Ui.fill
             ]
                ++ drawingModeAttributes model.route loggedIn.drawingMode
            )
            (Ui.Keyed.column
                ([ Ui.height Ui.fill
                 , Ui.width Ui.fill
                 , Ui.paddingWith { left = 0, right = 0, top = 200, bottom = 16 }
                 , MyUi.scrollable (MyUi.canScroll (MyUi.isMobile model) model.drag)
                 , MyUi.htmlStyle "overflow-wrap" "break-word"
                 , Ui.id (Dom.idToString conversationContainerId)
                 , Ui.Events.on
                    "scroll"
                    (Scroll.decodeScrollToBottom
                        (UserScrolled (DiscordGuildOrDmId guildOrDmIdNoThread) NoThread)
                        loggedIn.channelScrollPosition
                    )
                 , Ui.heightMin 0
                 , MyUi.bounceScroll isMobile
                 , MyUi.htmlStyle "background-image" "url(/grid1.png)"
                 ]
                    ++ drawingZoomAttributes model.route loggedIn.drawingMode
                )
                (( "a"
                 , Ui.el
                    [ Ui.Font.color MyUi.font2, Ui.paddingXY 8 4, Ui.alignBottom, Ui.Font.size 20 ]
                    (if VisibleMessages.startIsVisible channel.visibleMessages then
                        case guildOrDmIdNoThread of
                            DiscordGuildOrDmId_Guild _ ->
                                Ui.text ("This is the start of #" ++ name)

                            DiscordGuildOrDmId_Dm data ->
                                Ui.text
                                    (if ChannelHeader.chattingWithYourself data local then
                                        "This is the start of a conversation with yourself"

                                     else
                                        "This is the start of your conversation with " ++ name
                                    )

                     else
                        Ui.none
                    )
                 )
                    :: discordConversationViewHelper
                        lastViewedIndex
                        currentDiscordUserId
                        guildOrDmIdNoThread
                        maybeUrlMessageId
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
                    fileUploadPreview
                        (PressedDeleteAttachedFile guildOrDmId)
                        (PressedViewAttachedFileInfo guildOrDmId)
                        (PressedToggleAttachedFileSpoiler guildOrDmId)
                        draftRichText
                        filesToUpload2
                        |> Ui.inFront

                Nothing ->
                    Ui.noAttr
            ]
            [ newMessagesView model loggedIn
            , replyToHeader ( DiscordGuildOrDmId guildOrDmIdNoThread, NoThread ) replyTo allUsers channel
            , case ( LocalState.canSendDiscordMessage local guildOrDmIdNoThread, channel.isForum ) of
                ( Ok (), False ) ->
                    MessageInput.view
                        (Dom.id "messageMenu_channelInput")
                        (replyTo == Nothing)
                        (MyUi.isMobile model)
                        channelTextInputId
                        (case guildOrDmIdNoThread of
                            DiscordGuildOrDmId_Guild _ ->
                                "Write a message in #" ++ name

                            DiscordGuildOrDmId_Dm data ->
                                "Write a message to "
                                    ++ (if ChannelHeader.chattingWithYourself data local then
                                            "yourself"

                                        else
                                            name
                                       )
                        )
                        (RichText.discordCharsLeft OneToOne.empty draftRichText)
                        draft
                        draftRichText
                        (case SeqDict.get guildOrDmId loggedIn.filesToUpload of
                            Just attachedFiles ->
                                NonemptyDict.toSeqDict attachedFiles

                            Nothing ->
                                SeqDict.empty
                        )
                        local.localUser
                        loggedIn
                        (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                        |> Ui.map (MessageInputMsg (DiscordGuildOrDmId guildOrDmIdNoThread) NoThread)

                ( Err error, _ ) ->
                    MessageInput.disabledView
                        (replyTo == Nothing)
                        error
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
                        local.localUser

                ( _, True ) ->
                    MessageInput.disabledView
                        (replyTo == Nothing)
                        "Forum channel posting is unsupported"
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
                        local.localUser
            , peopleAreTypingView allUsers channel currentDiscordUserId model
            ]
        ]


typingDebouncerDelay : Duration
typingDebouncerDelay =
    Duration.seconds 7


peopleAreTypingView :
    SeqDict userId { a | name : PersonName }
    -> { b | lastTypedAt : SeqDict userId (LastTypedAt messageId) }
    -> userId
    -> LoadedFrontend
    -> Element msg
peopleAreTypingView allUsers channel currentUserId model =
    (case
        SeqDict.filter
            (\_ a ->
                (Duration.from a.time model.time |> Quantity.lessThan (Quantity.plus Duration.second typingDebouncerDelay))
                    && (a.messageIndex == Nothing)
            )
            (SeqDict.remove currentUserId channel.lastTypedAt)
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
            , MyUi.htmlStyle "user-select" "none"
            , MyUi.htmlStyle
                "padding"
                ("0 calc(12px + "
                    ++ MyUi.insetBottom
                    ++ " * 0.5) "
                    ++ (if model.virtualKeyboardOpen then
                            "0"

                        else
                            MyUi.insetBottom
                       )
                    ++ " calc(12px + "
                    ++ MyUi.insetBottom
                    ++ " * 0.5)"
                )
            ]


threadConversationView :
    Id ThreadMessageId
    -> GuildOrDmId
    -> Maybe (Id ThreadMessageId)
    -> Id ChannelMessageId
    -> LoggedIn2
    -> LoadedFrontend
    -> LocalState
    -> String
    -> String
    -> FrontendThread
    -> Element FrontendMsg_
threadConversationView lastViewedIndex guildOrDmIdNoThread maybeUrlMessageId threadId loggedIn model local name threadName channel =
    let
        guildOrDmId : ( AnyGuildOrDmId, ThreadRoute )
        guildOrDmId =
            ( GuildOrDmId guildOrDmIdNoThread, ViewThread threadId )

        allUsers : SeqDict (Id UserId) FrontendUser
        allUsers =
            User.allUsers local.localUser

        replyTo : Maybe (Id ChannelMessageId)
        replyTo =
            SeqDict.get guildOrDmId loggedIn.replyTo

        isMobile : Bool
        isMobile =
            MyUi.isMobile model

        draft : String
        draft =
            case SeqDict.get guildOrDmId loggedIn.drafts of
                Just text ->
                    String.Nonempty.toString text

                Nothing ->
                    ""

        draftRichText : Maybe (Nonempty (RichText (Id UserId)))
        draftRichText =
            case SeqDict.get guildOrDmId loggedIn.drafts of
                Just text ->
                    Just (RichText.fromNonemptyString local.localUser.timezone allUsers text)

                Nothing ->
                    Nothing
    in
    Ui.column
        [ Ui.height Ui.fill
        , Ui.heightMin 0
        ]
        [ ChannelHeader.thread isMobile name threadName guildOrDmIdNoThread local loggedIn model
        , Ui.el
            ([ emojiSelector
                isMobile
                local.localUser.user.availableCustomEmojis
                local.localUser.user.availableStickers
                local
                loggedIn
                model
             , Ui.heightMin 0
             , Ui.height Ui.fill
             ]
                ++ drawingModeAttributes model.route loggedIn.drawingMode
            )
            (Ui.Keyed.column
                ([ Ui.height Ui.fill
                 , Ui.width Ui.fill
                 , Ui.paddingWith { left = 0, right = 0, top = 200, bottom = 16 }
                 , MyUi.scrollable (MyUi.canScroll (MyUi.isMobile model) model.drag)
                 , MyUi.htmlStyle "overflow-wrap" "break-word"
                 , Ui.id (Dom.idToString conversationContainerId)
                 , Ui.Events.on
                    "scroll"
                    (Scroll.decodeScrollToBottom
                        (UserScrolled (GuildOrDmId guildOrDmIdNoThread) (ViewThread threadId))
                        loggedIn.channelScrollPosition
                    )
                 , Ui.heightMin 0
                 , MyUi.bounceScroll isMobile
                 , MyUi.htmlStyle "background-image" "url(/grid1.png)"
                 ]
                    ++ drawingZoomAttributes model.route loggedIn.drawingMode
                )
                (( "a"
                 , Ui.column
                    [ Ui.alignBottom ]
                    (if VisibleMessages.startIsVisible channel.visibleMessages then
                        [ Ui.el
                            [ Ui.Font.color MyUi.font2, Ui.paddingXY 8 4, Ui.alignBottom, Ui.Font.size 20 ]
                            (Ui.text startOfThreadText)
                        , case guildOrDmIdNoThread of
                            GuildOrDmId_Guild { guildId, channelId } ->
                                case LocalState.getGuildAndChannel { guildId = guildId, channelId = channelId } local of
                                    Just ( _, channel2 ) ->
                                        threadStarterMessage
                                            isMobile
                                            guildOrDmIdNoThread
                                            threadId
                                            channel2
                                            loggedIn
                                            local
                                            model

                                    Nothing ->
                                        Ui.none

                            GuildOrDmId_Dm { otherUserId } ->
                                case SeqDict.get otherUserId local.dmChannels of
                                    Just dmChannel2 ->
                                        threadStarterMessage
                                            isMobile
                                            guildOrDmIdNoThread
                                            threadId
                                            dmChannel2
                                            loggedIn
                                            local
                                            model

                                    Nothing ->
                                        Ui.none
                        ]

                     else
                        []
                    )
                 )
                    :: threadConversationViewHelper
                        lastViewedIndex
                        guildOrDmIdNoThread
                        threadId
                        maybeUrlMessageId
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
                    fileUploadPreview
                        (PressedDeleteAttachedFile guildOrDmId)
                        (PressedViewAttachedFileInfo guildOrDmId)
                        (PressedToggleAttachedFileSpoiler guildOrDmId)
                        draftRichText
                        filesToUpload2
                        |> Ui.inFront

                Nothing ->
                    Ui.noAttr
            ]
            [ newMessagesView model loggedIn
            , replyToHeader guildOrDmId replyTo allUsers channel
            , MessageInput.view
                (Dom.id "messageMenu_channelInput")
                (replyTo == Nothing)
                (MyUi.isMobile model)
                channelTextInputId
                (case guildOrDmIdNoThread of
                    GuildOrDmId_Guild _ ->
                        "Write a message in this thread"

                    GuildOrDmId_Dm _ ->
                        "Write a message in this thread"
                )
                (RichText.maxLength - String.length draft)
                draft
                draftRichText
                (case SeqDict.get guildOrDmId loggedIn.filesToUpload of
                    Just attachedFiles ->
                        NonemptyDict.toSeqDict attachedFiles

                    Nothing ->
                        SeqDict.empty
                )
                local.localUser
                loggedIn
                (User.allUsers local.localUser)
                |> Ui.map (MessageInputMsg (GuildOrDmId guildOrDmIdNoThread) (ViewThread threadId))
            , peopleAreTypingView allUsers channel local.localUser.session.userId model
            ]
        ]


discordThreadConversationView :
    Id ThreadMessageId
    -> Discord.Id Discord.UserId
    -> DiscordGuildOrDmId
    -> Maybe (Id ThreadMessageId)
    -> Id ChannelMessageId
    -> LoggedIn2
    -> LoadedFrontend
    -> LocalState
    -> String
    -> SeqSet (Id CustomEmojiId)
    -> SeqSet (Id StickerId)
    -> DiscordFrontendThread
    -> Element FrontendMsg_
discordThreadConversationView lastViewedIndex currentDiscordUserId guildOrDmIdNoThread maybeUrlMessageId threadId loggedIn model local name availableCustomEmojis availableStickers channel =
    let
        guildOrDmId : ( AnyGuildOrDmId, ThreadRoute )
        guildOrDmId =
            ( DiscordGuildOrDmId guildOrDmIdNoThread, ViewThread threadId )

        allUsers : SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
        allUsers =
            LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers

        replyTo : Maybe (Id ChannelMessageId)
        replyTo =
            SeqDict.get guildOrDmId loggedIn.replyTo

        isMobile : Bool
        isMobile =
            MyUi.isMobile model

        draft : String
        draft =
            case SeqDict.get guildOrDmId loggedIn.drafts of
                Just text ->
                    String.Nonempty.toString text

                Nothing ->
                    ""

        draftRichText : Maybe (Nonempty (RichText (Discord.Id Discord.UserId)))
        draftRichText =
            case SeqDict.get guildOrDmId loggedIn.drafts of
                Just text ->
                    Just (RichText.fromNonemptyString local.localUser.timezone allUsers text)

                Nothing ->
                    Nothing
    in
    Ui.column
        [ Ui.height Ui.fill
        , Ui.heightMin 0
        ]
        [ ChannelHeader.discordThread isMobile name guildOrDmIdNoThread local loggedIn model
        , Ui.el
            ([ emojiSelector isMobile availableCustomEmojis availableStickers local loggedIn model
             , Ui.heightMin 0
             , Ui.height Ui.fill
             ]
                ++ drawingModeAttributes model.route loggedIn.drawingMode
            )
            (Ui.Keyed.column
                ([ Ui.height Ui.fill
                 , Ui.width Ui.fill
                 , Ui.paddingWith { left = 0, right = 0, top = 200, bottom = 16 }
                 , MyUi.scrollable (MyUi.canScroll (MyUi.isMobile model) model.drag)
                 , MyUi.htmlStyle "overflow-wrap" "break-word"
                 , Ui.id (Dom.idToString conversationContainerId)
                 , Ui.Events.on
                    "scroll"
                    (Scroll.decodeScrollToBottom
                        (UserScrolled (DiscordGuildOrDmId guildOrDmIdNoThread) (ViewThread threadId))
                        loggedIn.channelScrollPosition
                    )
                 , Ui.heightMin 0
                 , MyUi.bounceScroll isMobile
                 , MyUi.htmlStyle "background-image" "url(/grid1.png)"
                 ]
                    ++ drawingZoomAttributes model.route loggedIn.drawingMode
                )
                (( "a"
                 , Ui.column
                    [ Ui.alignBottom ]
                    (if VisibleMessages.startIsVisible channel.visibleMessages then
                        [ Ui.el
                            [ Ui.Font.color MyUi.font2, Ui.paddingXY 8 4, Ui.alignBottom, Ui.Font.size 20 ]
                            (Ui.text startOfThreadText)
                        , case guildOrDmIdNoThread of
                            DiscordGuildOrDmId_Guild { guildId, channelId } ->
                                case LocalState.getDiscordGuildAndChannel guildId channelId local of
                                    Just ( _, channel2 ) ->
                                        discordThreadStarterMessage
                                            isMobile
                                            guildOrDmIdNoThread
                                            threadId
                                            channel2
                                            loggedIn
                                            local
                                            model

                                    Nothing ->
                                        Ui.none

                            DiscordGuildOrDmId_Dm _ ->
                                Ui.none
                        ]

                     else
                        []
                    )
                 )
                    :: discordThreadConversationViewHelper
                        lastViewedIndex
                        currentDiscordUserId
                        guildOrDmIdNoThread
                        threadId
                        maybeUrlMessageId
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
                    fileUploadPreview
                        (PressedDeleteAttachedFile guildOrDmId)
                        (PressedViewAttachedFileInfo guildOrDmId)
                        (PressedToggleAttachedFileSpoiler guildOrDmId)
                        draftRichText
                        filesToUpload2
                        |> Ui.inFront

                Nothing ->
                    Ui.noAttr
            ]
            [ newMessagesView model loggedIn
            , replyToHeader guildOrDmId replyTo allUsers channel
            , MessageInput.view
                (Dom.id "messageMenu_channelInput")
                (replyTo == Nothing)
                (MyUi.isMobile model)
                channelTextInputId
                (case guildOrDmIdNoThread of
                    DiscordGuildOrDmId_Guild _ ->
                        "Write a message in this thread"

                    DiscordGuildOrDmId_Dm _ ->
                        "Write a message in this thread"
                )
                (RichText.discordCharsLeft OneToOne.empty draftRichText)
                draft
                draftRichText
                (case SeqDict.get guildOrDmId loggedIn.filesToUpload of
                    Just attachedFiles ->
                        NonemptyDict.toSeqDict attachedFiles

                    Nothing ->
                        SeqDict.empty
                )
                local.localUser
                loggedIn
                (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                |> Ui.map (MessageInputMsg (DiscordGuildOrDmId guildOrDmIdNoThread) (ViewThread threadId))
            , peopleAreTypingView allUsers channel currentDiscordUserId model
            ]
        ]


threadStarterMessage :
    Bool
    -> GuildOrDmId
    -> Id ChannelMessageId
    -> { a | messages : MessageArray ChannelMessageId (Id UserId) }
    -> LoggedIn2
    -> LocalState
    -> LoadedFrontend
    -> Element FrontendMsg_
threadStarterMessage isMobile normalGuildOrDmIdNoThread threadMessageIndex channel loggedIn local model =
    let
        guildOrDmIdNoThread : AnyGuildOrDmId
        guildOrDmIdNoThread =
            GuildOrDmId normalGuildOrDmIdNoThread

        guildOrDmId : ( AnyGuildOrDmId, ThreadRoute )
        guildOrDmId =
            ( guildOrDmIdNoThread, NoThread )

        threadRoute : ThreadRouteWithMessage
        threadRoute =
            NoThreadWithMessage threadMessageIndex

        revealedSpoilers : SeqDict (Id ChannelMessageId) (NonemptySet Int)
        revealedSpoilers =
            revealedChannelSpoilers (GuildOrDmId normalGuildOrDmIdNoThread) loggedIn

        containerWidth : Int
        containerWidth =
            conversationWidth model
    in
    case MessageArray.get threadMessageIndex channel.messages of
        Just message ->
            case SeqDict.get guildOrDmId loggedIn.editMessage of
                Just edit ->
                    if edit.messageIndex == threadMessageIndex then
                        let
                            allUsers : SeqDict (Id UserId) FrontendUser
                            allUsers =
                                User.allUsers local.localUser

                            editRichText : Maybe (Nonempty (RichText (Id UserId)))
                            editRichText =
                                case String.Nonempty.fromString edit.text of
                                    Just nonempty ->
                                        RichText.fromNonemptyString local.localUser.timezone allUsers nonempty |> Just

                                    Nothing ->
                                        Nothing

                            charsLeft =
                                RichText.maxLength - String.length edit.text
                        in
                        messageEditingView
                            containerWidth
                            model.time
                            isMobile
                            guildOrDmId
                            (NoThreadWithMessage threadMessageIndex)
                            message
                            Nothing
                            Nothing
                            SeqDict.empty
                            charsLeft
                            edit
                            editRichText
                            loggedIn
                            local.localUser.decryptedMessages
                            local.localUser.session.userId
                            allUsers
                            local

                    else
                        messageView
                            model.time
                            isMobile
                            (conversationWidth model)
                            True
                            revealedSpoilers
                            NoHighlight
                            (messageHover guildOrDmIdNoThread threadRoute loggedIn model)
                            False
                            local.localUser.session.userId
                            (User.allUsers local.localUser)
                            local.localUser
                            Nothing
                            Nothing
                            threadMessageIndex
                            message
                            |> Ui.map (MessageViewMsg guildOrDmIdNoThread threadRoute)

                Nothing ->
                    messageView
                        model.time
                        isMobile
                        (conversationWidth model)
                        True
                        revealedSpoilers
                        NoHighlight
                        (messageHover guildOrDmIdNoThread threadRoute loggedIn model)
                        False
                        local.localUser.session.userId
                        (User.allUsers local.localUser)
                        local.localUser
                        Nothing
                        Nothing
                        threadMessageIndex
                        message
                        |> Ui.map (MessageViewMsg guildOrDmIdNoThread threadRoute)

        _ ->
            Ui.none


discordThreadStarterMessage :
    Bool
    -> DiscordGuildOrDmId
    -> Id ChannelMessageId
    -> { a | messages : MessageArray ChannelMessageId (Discord.Id Discord.UserId) }
    -> LoggedIn2
    -> LocalState
    -> LoadedFrontend
    -> Element FrontendMsg_
discordThreadStarterMessage isMobile discordGuildOrDmId threadMessageIndex channel loggedIn local model =
    let
        currentUserId : Discord.Id Discord.UserId
        currentUserId =
            case discordGuildOrDmId of
                DiscordGuildOrDmId_Guild id ->
                    id.currentUserId

                DiscordGuildOrDmId_Dm data ->
                    data.currentUserId

        guildOrDmIdNoThread : AnyGuildOrDmId
        guildOrDmIdNoThread =
            DiscordGuildOrDmId discordGuildOrDmId

        guildOrDmId : ( AnyGuildOrDmId, ThreadRoute )
        guildOrDmId =
            ( guildOrDmIdNoThread, NoThread )

        threadRoute : ThreadRouteWithMessage
        threadRoute =
            NoThreadWithMessage threadMessageIndex

        revealedSpoilers : SeqDict (Id ChannelMessageId) (NonemptySet Int)
        revealedSpoilers =
            revealedChannelSpoilers guildOrDmIdNoThread loggedIn

        containerWidth : Int
        containerWidth =
            conversationWidth model
    in
    case MessageArray.get threadMessageIndex channel.messages of
        Just message ->
            case SeqDict.get guildOrDmId loggedIn.editMessage of
                Just edit ->
                    if edit.messageIndex == threadMessageIndex then
                        let
                            allUsers =
                                LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers

                            editRichText : Maybe (Nonempty (RichText (Discord.Id Discord.UserId)))
                            editRichText =
                                case String.Nonempty.fromString edit.text of
                                    Just nonempty ->
                                        RichText.fromNonemptyString local.localUser.timezone allUsers nonempty |> Just

                                    Nothing ->
                                        Nothing
                        in
                        messageEditingView
                            containerWidth
                            model.time
                            isMobile
                            guildOrDmId
                            (NoThreadWithMessage threadMessageIndex)
                            message
                            Nothing
                            Nothing
                            SeqDict.empty
                            (RichText.discordCharsLeft OneToOne.empty editRichText)
                            edit
                            editRichText
                            loggedIn
                            SeqDict.empty
                            currentUserId
                            allUsers
                            local

                    else
                        discordMessageView
                            model.time
                            isMobile
                            (conversationWidth model)
                            True
                            revealedSpoilers
                            NoHighlight
                            (messageHover guildOrDmIdNoThread threadRoute loggedIn model)
                            currentUserId
                            (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                            local.localUser
                            Nothing
                            Nothing
                            threadMessageIndex
                            message
                            |> Ui.map (MessageViewMsg guildOrDmIdNoThread threadRoute)

                Nothing ->
                    discordMessageView
                        model.time
                        isMobile
                        (conversationWidth model)
                        True
                        revealedSpoilers
                        NoHighlight
                        (messageHover guildOrDmIdNoThread threadRoute loggedIn model)
                        currentUserId
                        (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                        local.localUser
                        Nothing
                        Nothing
                        threadMessageIndex
                        message
                        |> Ui.map (MessageViewMsg guildOrDmIdNoThread threadRoute)

        _ ->
            Ui.none


dropdownButtonId : Int -> HtmlId
dropdownButtonId index =
    Dom.id ("dropdown_button" ++ String.fromInt index)


messageEditingView :
    Int
    -> Time.Posix
    -> Bool
    -> ( AnyGuildOrDmId, ThreadRoute )
    -> ThreadRouteWithMessage
    -> Message ChannelMessageId userId
    -> Maybe ( Id ChannelMessageId, Message ChannelMessageId userId )
    -> Maybe (FrontendGenericThread userId)
    -> SeqDict (Id ChannelMessageId) (NonemptySet Int)
    -> Int
    -> EditMessage
    -> Maybe (Nonempty (RichText userId))
    -> LoggedIn2
    -> SeqDict BytesHash (Result () (ContentAndEmbeds userId))
    -> userId
    -> SeqDict userId { a | name : PersonName, icon : Maybe FileHash }
    -> LocalState
    -> Element FrontendMsg_
messageEditingView containerWidth time isMobile guildOrDmId threadRouteWithMessage message maybeRepliedTo2 maybeThread revealedSpoilers charsLeft editing editingRichText loggedIn decrypted currentUserId allUsers local =
    case message of
        UserTextMessage data ->
            let
                maybeReactions : Maybe (Element MessageViewMsg)
                maybeReactions =
                    MessageView.reactionEmojiView local.localUser.emojiData MessageView.ReactionsHovered currentUserId local.localUser.customEmojis allUsers LoopAFewTimesOnLoad containerWidth data.reactions

                ( guildOrDmIdNoThread, threadRoute ) =
                    guildOrDmId

                messageInput =
                    MessageInput.view
                        (Dom.id "messageMenu_editDesktop")
                        True
                        False
                        MessageMenu.editMessageTextInputId
                        ""
                        charsLeft
                        editing.text
                        editingRichText
                        editing.attachedFiles
                        local.localUser
                        loggedIn
                        allUsers
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
                , (case threadRouteWithMessage of
                    ViewThreadWithMessage _ messageId ->
                        Id.changeType messageId

                    NoThreadWithMessage messageId ->
                        messageId
                  )
                    |> channelMessageHtmlId
                    |> Dom.idToString
                    |> Ui.id
                ]
                [ replyToHeaderAboveMessage
                    isMobile
                    local.localUser.timezone
                    time
                    maybeRepliedTo2
                    revealedSpoilers
                    local.localUser.customEmojis
                    decrypted
                    allUsers
                    |> Ui.el [ Ui.paddingXY 8 0 ]
                    |> Ui.map (MessageViewMsg guildOrDmIdNoThread threadRouteWithMessage)
                , User.toString data.createdBy allUsers
                    ++ " "
                    |> Ui.text
                    |> Ui.el [ Ui.Font.bold, Ui.paddingXY 8 0 ]
                , Ui.column
                    [ case NonemptyDict.fromSeqDict editing.attachedFiles of
                        Just filesToUpload ->
                            fileUploadPreview
                                (EditMessage_PressedDeleteAttachedFile guildOrDmId)
                                (EditMessage_PressedViewAttachedFileInfo guildOrDmId)
                                (EditMessage_PressedToggleAttachedFileSpoiler guildOrDmId)
                                editingRichText
                                filesToUpload
                                |> Ui.inFront

                        Nothing ->
                            Ui.noAttr
                    ]
                    [ messageInput
                        |> Ui.map (EditMessage_MessageInputMsg guildOrDmIdNoThread threadRoute)
                        |> Ui.el [ Ui.paddingXY 5 0 ]
                    , Ui.row
                        [ Ui.Font.size 14
                        , Ui.Font.color MyUi.font3
                        , Ui.paddingXY 12 0
                        , MyUi.prewrap
                        ]
                        [ Ui.text "Press "
                        , MyUi.elButton
                            (Dom.id "guild_exitEditMessage")
                            (PressedCancelMessageEdit guildOrDmId)
                            [ Ui.Font.color MyUi.font1
                            , Ui.width Ui.shrink
                            ]
                            (Ui.text "escape")
                        , Ui.text " to cancel edit"
                        ]
                    ]
                , case maybeReactions of
                    Just reactionView ->
                        Ui.el [ Ui.paddingXY 8 0 ] reactionView
                            |> Ui.map (MessageViewMsg guildOrDmIdNoThread threadRouteWithMessage)

                    Nothing ->
                        Ui.none
                , case ( threadRouteWithMessage, maybeThread ) of
                    ( NoThreadWithMessage messageId, Just thread ) ->
                        previewThreadLastMessage
                            local.localUser.timezone
                            time
                            local.localUser.customEmojis
                            allUsers
                            decrypted
                            messageId
                            thread
                            |> Ui.el [ Ui.paddingXY 8 0 ]
                            |> Ui.map (MessageViewMsg guildOrDmIdNoThread threadRouteWithMessage)

                    _ ->
                        Ui.none
                ]

        EncryptedUserTextMessage _ ->
            Ui.none

        UserJoinedMessage _ _ _ _ ->
            Ui.none

        DeletedMessage _ ->
            Ui.none

        CallStarted _ ->
            Ui.none

        GameStarted _ ->
            Ui.none


threadMessageEditingView :
    Int
    -> Time.Posix
    -> Bool
    -> ( AnyGuildOrDmId, ThreadRoute )
    -> Id ChannelMessageId
    -> Id ThreadMessageId
    -> Message ThreadMessageId userId
    -> Maybe ( Id ThreadMessageId, Message ThreadMessageId userId )
    -> SeqDict (Id ThreadMessageId) (NonemptySet Int)
    -> Int
    -> EditMessage
    -> Maybe (Nonempty (RichText userId))
    -> LoggedIn2
    -> SeqDict BytesHash (Result () (ContentAndEmbeds userId))
    -> userId
    -> SeqDict userId { a | name : PersonName, icon : Maybe FileHash }
    -> LocalState
    -> Element FrontendMsg_
threadMessageEditingView containerWidth time isMobile guildOrDmId threadId messageId message maybeRepliedTo2 revealedSpoilers charsLeft editing editingRichText loggedIn decrypted currentUserId allUsers local =
    case message of
        UserTextMessage data ->
            let
                maybeReactions =
                    MessageView.reactionEmojiView local.localUser.emojiData MessageView.ReactionsHovered currentUserId local.localUser.customEmojis allUsers LoopAFewTimesOnLoad containerWidth data.reactions

                ( guildOrDmIdNoThread, _ ) =
                    guildOrDmId

                threadRouteWithMessage =
                    ViewThreadWithMessage threadId messageId

                messageInput =
                    MessageInput.view
                        (Dom.id "messageMenu_editDesktop")
                        True
                        False
                        MessageMenu.editMessageTextInputId
                        ""
                        charsLeft
                        editing.text
                        editingRichText
                        editing.attachedFiles
                        local.localUser
                        loggedIn
                        allUsers
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
                , threadMessageHtmlId messageId |> Dom.idToString |> Ui.id
                ]
                [ replyToHeaderAboveMessage
                    isMobile
                    local.localUser.timezone
                    time
                    maybeRepliedTo2
                    revealedSpoilers
                    local.localUser.customEmojis
                    decrypted
                    allUsers
                    |> Ui.el [ Ui.paddingXY 8 0 ]
                    |> Ui.map (MessageViewMsg guildOrDmIdNoThread threadRouteWithMessage)
                , User.toString data.createdBy allUsers
                    ++ " "
                    |> Ui.text
                    |> Ui.el [ Ui.Font.bold, Ui.paddingXY 8 0 ]
                , Ui.column
                    [ case NonemptyDict.fromSeqDict editing.attachedFiles of
                        Just filesToUpload ->
                            fileUploadPreview
                                (EditMessage_PressedDeleteAttachedFile guildOrDmId)
                                (EditMessage_PressedViewAttachedFileInfo guildOrDmId)
                                (EditMessage_PressedToggleAttachedFileSpoiler guildOrDmId)
                                editingRichText
                                filesToUpload
                                |> Ui.inFront

                        Nothing ->
                            Ui.noAttr
                    ]
                    [ messageInput
                        |> Ui.map (EditMessage_MessageInputMsg guildOrDmIdNoThread (ViewThread threadId))
                        |> Ui.el [ Ui.paddingXY 5 0 ]
                    , Ui.row
                        [ Ui.Font.size 14
                        , Ui.Font.color MyUi.font3
                        , Ui.paddingXY 12 0
                        , MyUi.prewrap
                        ]
                        [ Ui.text "Press "
                        , MyUi.elButton
                            (Dom.id "guild_exitEditMessage")
                            (PressedCancelMessageEdit guildOrDmId)
                            [ Ui.Font.color MyUi.font1
                            , Ui.width Ui.shrink
                            ]
                            (Ui.text "escape")
                        , Ui.text " to cancel edit"
                        ]
                    ]
                , case maybeReactions of
                    Just reactionView ->
                        Ui.el [ Ui.paddingXY 8 0 ] reactionView
                            |> Ui.map (MessageViewMsg guildOrDmIdNoThread threadRouteWithMessage)

                    Nothing ->
                        Ui.none
                ]

        EncryptedUserTextMessage _ ->
            Ui.none

        UserJoinedMessage _ _ _ _ ->
            Ui.none

        DeletedMessage _ ->
            Ui.none

        CallStarted _ ->
            Ui.none

        GameStarted _ ->
            Ui.none


type IsHovered
    = IsNotHovered
    | IsHovered
    | IsHoveredButNoMenu
    | IsHoveredReactionsOnly
    | IsHoveredWhileSelectingAnchor


messageViewNotThreadStarter :
    Int
    -> SeqDict (Id ChannelMessageId) (NonemptySet Int)
    -> LocalUser
    -> Int
    -> Message ChannelMessageId (Id UserId)
    -> Element MessageViewMsg
messageViewNotThreadStarter data revealedSpoilers localUser messageIndex message =
    let
        { containerWidth, isEditing, highlight, isHovered, isMobile, time } =
            decodeMessageView data
    in
    messageView
        time
        isMobile
        containerWidth
        False
        revealedSpoilers
        highlight
        isHovered
        isEditing
        localUser.session.userId
        (User.allUsers localUser)
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
    -> FrontendGenericThread (Id UserId)
    -> Message ChannelMessageId (Id UserId)
    -> Element MessageViewMsg
messageViewThreadStarter data revealedSpoilers localUser messageIndex thread message =
    let
        { containerWidth, isEditing, highlight, isHovered, isMobile, time } =
            decodeMessageView data
    in
    messageView
        time
        isMobile
        containerWidth
        False
        revealedSpoilers
        highlight
        isHovered
        isEditing
        localUser.session.userId
        (User.allUsers localUser)
        localUser
        Nothing
        (Just thread)
        (Id.fromInt messageIndex)
        message


discordMessageViewNotThreadStarter :
    Int
    -> SeqDict (Id ChannelMessageId) (NonemptySet Int)
    -> Discord.Id Discord.UserId
    -> LocalUser
    -> Int
    -> Message ChannelMessageId (Discord.Id Discord.UserId)
    -> Element MessageViewMsg
discordMessageViewNotThreadStarter data revealedSpoilers currentDiscordUserId localUser messageIndex message =
    let
        { containerWidth, highlight, isHovered, isMobile, time } =
            decodeMessageView data
    in
    --Ui.el
    --    [ Ui.inFront (MyUi.lazyChangedValue "revealedSpoilers" revealedSpoilers)
    --    , Ui.inFront (MyUi.lazyChangedValue "localUser" localUser)
    --    , Ui.inFront (MyUi.lazyChangedValue "messageIndex" messageIndex)
    --    , Ui.inFront (MyUi.lazyChangedValue "message" message)
    --    , Ui.inFront (MyUi.lazyChangedValue "data" data)
    --    , Ui.inFront (MyUi.lazyChangedValue "currentDiscordUserId" currentDiscordUserId)
    --    ]
    discordMessageView
        time
        isMobile
        containerWidth
        False
        revealedSpoilers
        highlight
        isHovered
        currentDiscordUserId
        (LinkedAndOtherDiscordUsers.allDiscordUsers localUser.discordUsers)
        localUser
        Nothing
        Nothing
        (Id.fromInt messageIndex)
        message


discordMessageViewThreadStarter :
    Int
    -> SeqDict (Id ChannelMessageId) (NonemptySet Int)
    -> Discord.Id Discord.UserId
    -> LocalUser
    -> Int
    -> DiscordFrontendThread
    -> Message ChannelMessageId (Discord.Id Discord.UserId)
    -> Element MessageViewMsg
discordMessageViewThreadStarter data revealedSpoilers currentDiscordUserId localUser messageIndex thread message =
    let
        { containerWidth, highlight, isHovered, isMobile, time } =
            decodeMessageView data
    in
    discordMessageView
        time
        isMobile
        containerWidth
        False
        revealedSpoilers
        highlight
        isHovered
        currentDiscordUserId
        (LinkedAndOtherDiscordUsers.allDiscordUsers localUser.discordUsers)
        localUser
        Nothing
        (Just thread)
        (Id.fromInt messageIndex)
        message


threadMessageViewLazy :
    Int
    -> SeqDict (Id ThreadMessageId) (NonemptySet Int)
    -> LocalUser
    -> Int
    -> Message ThreadMessageId (Id UserId)
    -> Element MessageViewMsg
threadMessageViewLazy data revealedSpoilers localUser messageIndex message =
    let
        { containerWidth, isEditing, highlight, isHovered, isMobile, time } =
            decodeMessageView data
    in
    threadMessageView
        time
        isMobile
        containerWidth
        revealedSpoilers
        highlight
        isHovered
        isEditing
        (User.allUsers localUser)
        localUser.session.userId
        localUser
        Nothing
        (Id.fromInt messageIndex)
        message


discordThreadMessageViewLazy :
    Int
    -> SeqDict (Id ThreadMessageId) (NonemptySet Int)
    -> Discord.Id Discord.UserId
    -> LocalUser
    -> Int
    -> Message ThreadMessageId (Discord.Id Discord.UserId)
    -> Element MessageViewMsg
discordThreadMessageViewLazy data revealedSpoilers currentDiscordUserId localUser messageIndex message =
    let
        { containerWidth, highlight, isHovered, isMobile, time } =
            decodeMessageView data
    in
    discordThreadMessageView
        time
        isMobile
        containerWidth
        revealedSpoilers
        highlight
        isHovered
        (LinkedAndOtherDiscordUsers.allDiscordUsers localUser.discordUsers)
        currentDiscordUserId
        localUser
        Nothing
        (Id.fromInt messageIndex)
        message


type HighlightMessage
    = NoHighlight
    | ReplyToHighlight
    | MentionHighlight
    | UrlHighlight


{-| Which custom emojis the one-click reactions on a Discord message may offer.

Discord only accepts a reaction with an emoji it knows about, so a custom emoji picked
up from an at-chat guild is rejected when it's used on a Discord message. Narrowing the
offer to the current Discord guild's own emojis would mean carrying that guild's emoji
set into the message view, and the Discord message views have already spent every
argument `Ui.Lazy` has room for. The reactions offered up front are therefore unicode
emojis, which Discord always takes; the emoji selector still offers the guild's custom
emojis.

-}
discordQuickReactionCustomEmojis : SeqSet (Id CustomEmojiId)
discordQuickReactionCustomEmojis =
    SeqSet.empty


messageView :
    Time.Posix
    -> Bool
    -> Int
    -> Bool
    -> SeqDict (Id ChannelMessageId) (NonemptySet Int)
    -> HighlightMessage
    -> IsHovered
    -> Bool
    -> Id UserId
    -> SeqDict (Id UserId) FrontendUser
    -> LocalUser
    -> Maybe ( Id ChannelMessageId, Message ChannelMessageId (Id UserId) )
    -> Maybe (FrontendGenericThread (Id UserId))
    -> Id ChannelMessageId
    -> Message ChannelMessageId (Id UserId)
    -> Element MessageViewMsg
messageView time isMobile containerWidth isThreadStarter revealedSpoilers highlight isHovered isBeingEdited currentUserId allUsers localUser maybeRepliedTo2 maybeThreadStarter messageId message =
    let
        decrypted : SeqDict BytesHash (Result () (ContentAndEmbeds (Id UserId)))
        decrypted =
            localUser.decryptedMessages
    in
    case message of
        UserTextMessage data ->
            messageContainer
                containerWidth
                isThreadStarter
                localUser.timezone
                time
                localUser.user.availableCustomEmojis
                localUser.customEmojis
                localUser.emojiData
                allUsers
                (case highlight of
                    NoHighlight ->
                        if SeqSet.member currentUserId (RichText.mentionsUser data.content) then
                            MentionHighlight

                        else
                            highlight

                    _ ->
                        highlight
                )
                messageId
                (currentUserId == data.createdBy)
                currentUserId
                localUser.user
                data.reactions
                maybeThreadStarter
                decrypted
                isHovered
                (userTextMessageContent
                    time
                    (Dom.id "spoiler")
                    containerWidth
                    isBeingEdited
                    isMobile
                    maybeRepliedTo2
                    localUser
                    revealedSpoilers
                    allUsers
                    (User.userColor localUser)
                    isHovered
                    messageId
                    { content = data.content, embeds = data.embeds }
                    False
                    data
                )

        EncryptedUserTextMessage data ->
            case SeqDict.get (Encryption.hash data.encryptedData) decrypted of
                Just result ->
                    messageContainer
                        containerWidth
                        isThreadStarter
                        localUser.timezone
                        time
                        localUser.user.availableCustomEmojis
                        localUser.customEmojis
                        localUser.emojiData
                        allUsers
                        highlight
                        messageId
                        (currentUserId == data.createdBy)
                        currentUserId
                        localUser.user
                        data.reactions
                        maybeThreadStarter
                        decrypted
                        isHovered
                        (userTextMessageContent
                            time
                            (Dom.id "spoiler")
                            containerWidth
                            isBeingEdited
                            isMobile
                            maybeRepliedTo2
                            localUser
                            revealedSpoilers
                            allUsers
                            (User.userColor localUser)
                            isHovered
                            messageId
                            (Result.withDefault { content = RichText.failedToDecryptMessage, embeds = Array.empty } result)
                            True
                            data
                        )

                Nothing ->
                    Ui.none

        UserJoinedMessage joinedAt userId reactions drawings ->
            messageContainer
                containerWidth
                isThreadStarter
                localUser.timezone
                time
                localUser.user.availableCustomEmojis
                localUser.customEmojis
                localUser.emojiData
                allUsers
                highlight
                messageId
                False
                currentUserId
                localUser.user
                reactions
                maybeThreadStarter
                decrypted
                isHovered
                (Ui.row
                    []
                    [ userJoinedContent userId allUsers
                    , messageTimestamp
                        (User.userColor localUser)
                        drawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        joinedAt
                        localUser.timezone
                    , messageIdView messageId
                    ]
                )

        DeletedMessage createdAt ->
            messageContainer
                containerWidth
                isThreadStarter
                localUser.timezone
                time
                localUser.user.availableCustomEmojis
                localUser.customEmojis
                localUser.emojiData
                allUsers
                highlight
                messageId
                False
                currentUserId
                localUser.user
                SeqDict.empty
                maybeThreadStarter
                decrypted
                isHovered
                (deletedMessageContent
                    messageId
                    (isHovered == IsHoveredWhileSelectingAnchor)
                    highlight
                    createdAt
                    localUser.timezone
                )

        CallStarted callStartedData ->
            messageContainer
                containerWidth
                isThreadStarter
                localUser.timezone
                time
                localUser.user.availableCustomEmojis
                localUser.customEmojis
                localUser.emojiData
                allUsers
                highlight
                messageId
                False
                currentUserId
                localUser.user
                callStartedData.reactions
                maybeThreadStarter
                decrypted
                isHovered
                (Ui.row
                    [ Ui.contentTop ]
                    [ callStartedCard
                        (User.userColor localUser)
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        callStartedData.cardDrawings
                        callStartedData.startedBy
                        callStartedData.startedAt
                        callStartedData.endedAt
                        allUsers
                    , messageTimestamp
                        (User.userColor localUser)
                        callStartedData.timestampDrawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        callStartedData.startedAt
                        localUser.timezone
                    , messageIdView messageId
                    ]
                )

        GameStarted gameStarted ->
            messageContainer
                containerWidth
                isThreadStarter
                localUser.timezone
                time
                localUser.user.availableCustomEmojis
                localUser.customEmojis
                localUser.emojiData
                allUsers
                highlight
                messageId
                False
                currentUserId
                localUser.user
                gameStarted.reactions
                maybeThreadStarter
                decrypted
                isHovered
                (Ui.row
                    [ Ui.contentTop ]
                    [ goMatchStartedCard
                        (User.userColor localUser)
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        gameStarted.cardDrawings
                        messageId
                        gameStarted.startedBy
                        allUsers
                        gameStarted.gameType
                    , messageTimestamp
                        (User.userColor localUser)
                        gameStarted.timestampDrawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        gameStarted.startedAt
                        localUser.timezone
                    , messageIdView messageId
                    ]
                )


discordMessageView :
    Time.Posix
    -> Bool
    -> Int
    -> Bool
    -> SeqDict (Id ChannelMessageId) (NonemptySet Int)
    -> HighlightMessage
    -> IsHovered
    -> Discord.Id Discord.UserId
    -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
    -> LocalUser
    -> Maybe ( Id ChannelMessageId, Message ChannelMessageId (Discord.Id Discord.UserId) )
    -> Maybe (FrontendGenericThread (Discord.Id Discord.UserId))
    -> Id ChannelMessageId
    -> Message ChannelMessageId (Discord.Id Discord.UserId)
    -> Element MessageViewMsg
discordMessageView time isMobile containerWidth isThreadStarter revealedSpoilers highlight isHovered currentUserId allUsers localUser maybeRepliedTo2 maybeThreadStarter messageId message =
    case message of
        UserTextMessage data ->
            messageContainer
                containerWidth
                isThreadStarter
                localUser.timezone
                time
                discordQuickReactionCustomEmojis
                localUser.customEmojis
                localUser.emojiData
                allUsers
                (case highlight of
                    NoHighlight ->
                        if SeqSet.member currentUserId (RichText.mentionsUser data.content) then
                            MentionHighlight

                        else
                            highlight

                    _ ->
                        highlight
                )
                messageId
                (currentUserId == data.createdBy)
                currentUserId
                localUser.user
                data.reactions
                maybeThreadStarter
                SeqDict.empty
                isHovered
                (discordUserTextMessageContent
                    time
                    (Dom.id "spoiler")
                    containerWidth
                    isMobile
                    maybeRepliedTo2
                    localUser
                    revealedSpoilers
                    allUsers
                    isHovered
                    messageId
                    data.content
                    data.embeds
                    data
                )

        EncryptedUserTextMessage data ->
            messageContainer
                containerWidth
                isThreadStarter
                localUser.timezone
                time
                discordQuickReactionCustomEmojis
                localUser.customEmojis
                localUser.emojiData
                allUsers
                highlight
                messageId
                (currentUserId == data.createdBy)
                currentUserId
                localUser.user
                data.reactions
                maybeThreadStarter
                SeqDict.empty
                isHovered
                (discordUserTextMessageContent
                    time
                    (Dom.id "spoiler")
                    containerWidth
                    isMobile
                    maybeRepliedTo2
                    localUser
                    revealedSpoilers
                    allUsers
                    isHovered
                    messageId
                    RichText.failedToDecryptMessage
                    Array.empty
                    data
                )

        UserJoinedMessage joinedAt userId reactions drawings ->
            messageContainer
                containerWidth
                isThreadStarter
                localUser.timezone
                time
                discordQuickReactionCustomEmojis
                localUser.customEmojis
                localUser.emojiData
                allUsers
                highlight
                messageId
                False
                currentUserId
                localUser.user
                reactions
                maybeThreadStarter
                SeqDict.empty
                isHovered
                (Ui.row
                    []
                    [ userJoinedContent userId allUsers
                    , messageTimestamp
                        (User.discordUserColor localUser)
                        drawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        joinedAt
                        localUser.timezone
                    , messageIdView messageId
                    ]
                )

        DeletedMessage createdAt ->
            messageContainer
                containerWidth
                isThreadStarter
                localUser.timezone
                time
                discordQuickReactionCustomEmojis
                localUser.customEmojis
                localUser.emojiData
                allUsers
                highlight
                messageId
                False
                currentUserId
                localUser.user
                SeqDict.empty
                maybeThreadStarter
                SeqDict.empty
                isHovered
                (deletedMessageContent
                    messageId
                    (isHovered == IsHoveredWhileSelectingAnchor)
                    highlight
                    createdAt
                    localUser.timezone
                )

        CallStarted callStartedData ->
            messageContainer
                containerWidth
                isThreadStarter
                localUser.timezone
                time
                discordQuickReactionCustomEmojis
                localUser.customEmojis
                localUser.emojiData
                allUsers
                highlight
                messageId
                False
                currentUserId
                localUser.user
                callStartedData.reactions
                maybeThreadStarter
                SeqDict.empty
                isHovered
                (Ui.row
                    [ Ui.contentTop ]
                    [ callStartedCard
                        (User.discordUserColor localUser)
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        callStartedData.cardDrawings
                        callStartedData.startedBy
                        callStartedData.startedAt
                        callStartedData.endedAt
                        allUsers
                    , messageTimestamp
                        (User.discordUserColor localUser)
                        callStartedData.timestampDrawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        callStartedData.startedAt
                        localUser.timezone
                    , messageIdView messageId
                    ]
                )

        GameStarted gameStarted ->
            messageContainer
                containerWidth
                isThreadStarter
                localUser.timezone
                time
                discordQuickReactionCustomEmojis
                localUser.customEmojis
                localUser.emojiData
                allUsers
                highlight
                messageId
                False
                currentUserId
                localUser.user
                gameStarted.reactions
                maybeThreadStarter
                SeqDict.empty
                isHovered
                (Ui.row
                    [ Ui.contentTop ]
                    [ goMatchStartedCard
                        (User.discordUserColor localUser)
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        gameStarted.cardDrawings
                        messageId
                        gameStarted.startedBy
                        allUsers
                        gameStarted.gameType
                    , messageTimestamp
                        (User.discordUserColor localUser)
                        gameStarted.timestampDrawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        gameStarted.startedAt
                        localUser.timezone
                    , messageIdView messageId
                    ]
                )


threadMessageView :
    Time.Posix
    -> Bool
    -> Int
    -> SeqDict (Id ThreadMessageId) (NonemptySet Int)
    -> HighlightMessage
    -> IsHovered
    -> Bool
    -> SeqDict (Id UserId) FrontendUser
    -> Id UserId
    -> LocalUser
    -> Maybe ( Id ThreadMessageId, Message ThreadMessageId (Id UserId) )
    -> Id ThreadMessageId
    -> Message ThreadMessageId (Id UserId)
    -> Element MessageViewMsg
threadMessageView time isMobile containerWidth revealedSpoilers highlight isHovered isBeingEdited allUsers currentUserId localUser maybeRepliedTo2 messageId message =
    let
        decrypted : SeqDict BytesHash (Result () (ContentAndEmbeds (Id UserId)))
        decrypted =
            localUser.decryptedMessages
    in
    case message of
        UserTextMessage message2 ->
            threadMessageContainer
                containerWidth
                (case highlight of
                    NoHighlight ->
                        if SeqSet.member currentUserId (RichText.mentionsUser message2.content) then
                            MentionHighlight

                        else
                            highlight

                    _ ->
                        highlight
                )
                messageId
                (currentUserId == message2.createdBy)
                currentUserId
                localUser.user
                message2.reactions
                localUser.user.availableCustomEmojis
                localUser.customEmojis
                localUser.emojiData
                allUsers
                isHovered
                (userTextMessageContent
                    time
                    (Dom.id "threadSpoiler")
                    containerWidth
                    isBeingEdited
                    isMobile
                    maybeRepliedTo2
                    localUser
                    revealedSpoilers
                    allUsers
                    (User.userColor localUser)
                    isHovered
                    messageId
                    { content = message2.content, embeds = message2.embeds }
                    False
                    message2
                )

        EncryptedUserTextMessage message2 ->
            case SeqDict.get (Encryption.hash message2.encryptedData) decrypted of
                Just result ->
                    threadMessageContainer
                        containerWidth
                        highlight
                        messageId
                        (currentUserId == message2.createdBy)
                        currentUserId
                        localUser.user
                        message2.reactions
                        localUser.user.availableCustomEmojis
                        localUser.customEmojis
                        localUser.emojiData
                        allUsers
                        isHovered
                        (userTextMessageContent
                            time
                            (Dom.id "threadSpoiler")
                            containerWidth
                            isBeingEdited
                            isMobile
                            maybeRepliedTo2
                            localUser
                            revealedSpoilers
                            allUsers
                            (User.userColor localUser)
                            isHovered
                            messageId
                            (Result.withDefault { content = RichText.failedToDecryptMessage, embeds = Array.empty } result)
                            True
                            message2
                        )

                Nothing ->
                    Ui.none

        UserJoinedMessage joinedAt userId reactions drawings ->
            threadMessageContainer
                containerWidth
                highlight
                messageId
                False
                currentUserId
                localUser.user
                reactions
                localUser.user.availableCustomEmojis
                localUser.customEmojis
                localUser.emojiData
                allUsers
                isHovered
                (Ui.row
                    []
                    [ userJoinedContent userId allUsers
                    , messageTimestamp
                        (User.userColor localUser)
                        drawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        joinedAt
                        localUser.timezone
                    ]
                )

        DeletedMessage createdAt ->
            threadMessageContainer
                containerWidth
                highlight
                messageId
                False
                currentUserId
                localUser.user
                SeqDict.empty
                localUser.user.availableCustomEmojis
                localUser.customEmojis
                localUser.emojiData
                allUsers
                isHovered
                (deletedMessageContent
                    messageId
                    (isHovered == IsHoveredWhileSelectingAnchor)
                    highlight
                    createdAt
                    localUser.timezone
                )

        CallStarted callStartedData ->
            threadMessageContainer
                containerWidth
                highlight
                messageId
                False
                currentUserId
                localUser.user
                callStartedData.reactions
                localUser.user.availableCustomEmojis
                localUser.customEmojis
                localUser.emojiData
                allUsers
                isHovered
                (Ui.row
                    []
                    [ callStartedCard
                        (User.userColor localUser)
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        callStartedData.cardDrawings
                        callStartedData.startedBy
                        callStartedData.startedAt
                        callStartedData.endedAt
                        allUsers
                    , messageTimestamp
                        (User.userColor localUser)
                        callStartedData.timestampDrawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        callStartedData.startedAt
                        localUser.timezone
                    ]
                )

        GameStarted gameStarted ->
            threadMessageContainer
                containerWidth
                highlight
                messageId
                False
                currentUserId
                localUser.user
                gameStarted.reactions
                localUser.user.availableCustomEmojis
                localUser.customEmojis
                localUser.emojiData
                allUsers
                isHovered
                (Ui.row
                    []
                    [ goMatchStartedCard
                        (User.userColor localUser)
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        gameStarted.cardDrawings
                        messageId
                        gameStarted.startedBy
                        allUsers
                        gameStarted.gameType
                    , messageTimestamp
                        (User.userColor localUser)
                        gameStarted.timestampDrawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        gameStarted.startedAt
                        localUser.timezone
                    ]
                )


discordThreadMessageView :
    Time.Posix
    -> Bool
    -> Int
    -> SeqDict (Id ThreadMessageId) (NonemptySet Int)
    -> HighlightMessage
    -> IsHovered
    -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
    -> Discord.Id Discord.UserId
    -> LocalUser
    -> Maybe ( Id ThreadMessageId, Message ThreadMessageId (Discord.Id Discord.UserId) )
    -> Id ThreadMessageId
    -> Message ThreadMessageId (Discord.Id Discord.UserId)
    -> Element MessageViewMsg
discordThreadMessageView time isMobile containerWidth revealedSpoilers highlight isHovered allUsers currentUserId localUser maybeRepliedTo2 messageId message =
    case message of
        UserTextMessage message2 ->
            threadMessageContainer
                containerWidth
                (case highlight of
                    NoHighlight ->
                        if SeqSet.member currentUserId (RichText.mentionsUser message2.content) then
                            MentionHighlight

                        else
                            highlight

                    _ ->
                        highlight
                )
                messageId
                (currentUserId == message2.createdBy)
                currentUserId
                localUser.user
                message2.reactions
                discordQuickReactionCustomEmojis
                localUser.customEmojis
                localUser.emojiData
                allUsers
                isHovered
                (discordUserTextMessageContent
                    time
                    (Dom.id "threadSpoiler")
                    containerWidth
                    isMobile
                    maybeRepliedTo2
                    localUser
                    revealedSpoilers
                    allUsers
                    isHovered
                    messageId
                    message2.content
                    message2.embeds
                    message2
                )

        EncryptedUserTextMessage message2 ->
            threadMessageContainer
                containerWidth
                highlight
                messageId
                (currentUserId == message2.createdBy)
                currentUserId
                localUser.user
                message2.reactions
                discordQuickReactionCustomEmojis
                localUser.customEmojis
                localUser.emojiData
                allUsers
                isHovered
                (discordUserTextMessageContent
                    time
                    (Dom.id "threadSpoiler")
                    containerWidth
                    isMobile
                    maybeRepliedTo2
                    localUser
                    revealedSpoilers
                    allUsers
                    isHovered
                    messageId
                    RichText.failedToDecryptMessage
                    Array.empty
                    message2
                )

        UserJoinedMessage joinedAt userId reactions drawings ->
            threadMessageContainer
                containerWidth
                highlight
                messageId
                False
                currentUserId
                localUser.user
                reactions
                discordQuickReactionCustomEmojis
                localUser.customEmojis
                localUser.emojiData
                allUsers
                isHovered
                (Ui.row
                    []
                    [ userJoinedContent userId allUsers
                    , messageTimestamp
                        (User.discordUserColor localUser)
                        drawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        joinedAt
                        localUser.timezone
                    ]
                )

        DeletedMessage createdAt ->
            threadMessageContainer
                containerWidth
                highlight
                messageId
                False
                currentUserId
                localUser.user
                SeqDict.empty
                discordQuickReactionCustomEmojis
                localUser.customEmojis
                localUser.emojiData
                allUsers
                isHovered
                (deletedMessageContent
                    messageId
                    (isHovered == IsHoveredWhileSelectingAnchor)
                    highlight
                    createdAt
                    localUser.timezone
                )

        CallStarted callStartedData ->
            threadMessageContainer
                containerWidth
                highlight
                messageId
                False
                currentUserId
                localUser.user
                callStartedData.reactions
                discordQuickReactionCustomEmojis
                localUser.customEmojis
                localUser.emojiData
                allUsers
                isHovered
                (Ui.row
                    []
                    [ callStartedCard
                        (User.discordUserColor localUser)
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        callStartedData.cardDrawings
                        callStartedData.startedBy
                        callStartedData.startedAt
                        callStartedData.endedAt
                        allUsers
                    , messageTimestamp
                        (User.discordUserColor localUser)
                        callStartedData.timestampDrawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        callStartedData.startedAt
                        localUser.timezone
                    ]
                )

        GameStarted gameStarted ->
            threadMessageContainer
                containerWidth
                highlight
                messageId
                False
                currentUserId
                localUser.user
                gameStarted.reactions
                discordQuickReactionCustomEmojis
                localUser.customEmojis
                localUser.emojiData
                allUsers
                isHovered
                (Ui.row
                    []
                    [ goMatchStartedCard
                        (User.discordUserColor localUser)
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        gameStarted.cardDrawings
                        messageId
                        gameStarted.startedBy
                        allUsers
                        gameStarted.gameType
                    , messageTimestamp
                        (User.discordUserColor localUser)
                        gameStarted.timestampDrawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        gameStarted.startedAt
                        localUser.timezone
                    ]
                )


{-| A reaction's popup comes up while whatever it is attached to is hovered, which for a
message means the menu is up too. The places that show a message without its menu don't bring
popups up either.
-}
reactionsHover : IsHovered -> MessageView.ReactionsHover
reactionsHover isHovered =
    case isHovered of
        IsHovered ->
            MessageView.ReactionsHovered

        IsNotHovered ->
            MessageView.ReactionsNotHovered

        IsHoveredButNoMenu ->
            MessageView.ReactionsNotHovered

        IsHoveredReactionsOnly ->
            MessageView.ReactionsNotHovered

        IsHoveredWhileSelectingAnchor ->
            MessageView.ReactionsNotHovered


isHoveredToAnimationMode : IsHovered -> AnimationMode
isHoveredToAnimationMode isHovered =
    case isHovered of
        IsNotHovered ->
            Sticker.LoopAFewTimesOnLoad

        IsHovered ->
            Sticker.ResetAndLoopAFewTimes

        IsHoveredButNoMenu ->
            Sticker.ResetAndLoopAFewTimes

        IsHoveredReactionsOnly ->
            Sticker.ResetAndLoopAFewTimes

        IsHoveredWhileSelectingAnchor ->
            Sticker.ResetAndLoopAFewTimes


profileImageButtonId : Id messageId -> HtmlId
profileImageButtonId messageId =
    Dom.id ("guild_profileImage_" ++ Id.toString messageId)


openDmButton : Id messageId -> MessageViewMsg -> List (Ui.Attribute MessageViewMsg)
openDmButton messageId onPress =
    [ Ui.pointer
    , profileImageButtonId messageId |> Dom.idToString |> Ui.id
    , Ui.Events.onClick onPress
    , MyUi.hoverText "Go to direct messages"
    ]


userTextMessageContent :
    Time.Posix
    -> HtmlId
    -> Int
    -> Bool
    -> Bool
    -> Maybe ( Id messageId, Message messageId (Id UserId) )
    -> LocalUser
    -> SeqDict (Id messageId) (NonemptySet Int)
    -> SeqDict (Id UserId) FrontendUser
    -> (Id UserId -> UserColor)
    -> IsHovered
    -> Id messageId
    -> ContentAndEmbeds (Id UserId)
    -> Bool
    ->
        { a
            | createdAt : Time.Posix
            , createdBy : Id UserId
            , reactions : SeqDict EmojiOrCustomEmoji (NonemptySet (Id UserId))
            , editedAt : Maybe Time.Posix
            , repliedTo : Maybe (Id messageId)
            , attachedFiles : SeqDict (Id FileId) FileData
            , timestampDrawings : Drawing (Id UserId)
            , userIconDrawings : Drawing (Id UserId)
            , imageAttachmentDrawings : SeqDict (Id FileId) (Drawing (Id UserId))
            , embedDrawings : SeqDict Int (Drawing (Id UserId))
        }
    -> Element MessageViewMsg
userTextMessageContent time spoilerHtmlId containerWidth isBeingEdited isMobile maybeRepliedTo2 localUser revealedSpoilers allUsers drawingColor isHovered messageId { content, embeds } showEncryptionIcon message2 =
    let
        decrypted : SeqDict BytesHash (Result () (ContentAndEmbeds (Id UserId)))
        decrypted =
            localUser.decryptedMessages
    in
    Ui.row
        []
        [ User.profileImage (SeqDict.get message2.createdBy allUsers)
            |> Ui.el
                (Drawing.anchorHighlight
                    (Drawing.profileImageAnchorId messageId)
                    drawingColor
                    MessageView_PressedUserIconAnchor
                    (isHovered == IsHoveredWhileSelectingAnchor)
                    message2.userIconDrawings
                    ++ (if isHovered == IsHoveredWhileSelectingAnchor then
                            [ Ui.rounded User.profileImageRounding ]

                        else
                            openDmButton messageId (MessageView_PressedUserIconButton message2.createdBy)
                       )
                )
            |> Ui.el
                [ Ui.paddingWith
                    { left = 0
                    , right = MessageView.profileImagePaddingRight
                    , top =
                        case maybeRepliedTo2 of
                            Just _ ->
                                24

                            Nothing ->
                                2
                    , bottom = 0
                    }
                , Ui.width Ui.shrink
                , Ui.alignTop
                ]
        , Ui.column
            []
            [ replyToHeaderAboveMessage
                isMobile
                localUser.timezone
                time
                maybeRepliedTo2
                revealedSpoilers
                localUser.customEmojis
                decrypted
                allUsers
            , Ui.row
                []
                [ User.toStringView message2.createdBy allUsers
                , if showEncryptionIcon then
                    Ui.html Icons.lockClosed

                  else
                    Ui.none
                , messageTimestamp
                    drawingColor
                    message2.timestampDrawings
                    (isHovered == IsHoveredWhileSelectingAnchor)
                    messageId
                    message2.createdAt
                    localUser.timezone
                ]
            , Html.div
                [ Html.Attributes.style "white-space" "pre-wrap" ]
                (RichText.view
                    (Dom.id (Dom.idToString spoilerHtmlId ++ "_" ++ Id.toString messageId))
                    containerWidth
                    MessageView_PressedNonWhitelistLink
                    MessageView_PressedSpoiler
                    MessageView_PressedImage
                    { revealedSpoilers =
                        case SeqDict.get messageId revealedSpoilers of
                            Just nonempty ->
                                NonemptySet.toSeqSet nonempty

                            Nothing ->
                                SeqSet.empty
                    , users = allUsers
                    , attachedFiles = message2.attachedFiles
                    , domainWhitelist = localUser.user.domainWhitelist
                    , customEmojis = localUser.customEmojis
                    , stickers = localUser.stickers
                    , animationMode = isHoveredToAnimationMode isHovered
                    , timezone = localUser.timezone
                    , time = time
                    , drawings = message2.imageAttachmentDrawings
                    , embedDrawings = message2.embedDrawings
                    , drawingUserColor = drawingColor
                    , isSelectingAnchor = isHovered == IsHoveredWhileSelectingAnchor
                    , devicePixelRatio = localUser.devicePixelRatio
                    , isHovered =
                        case isHovered of
                            IsNotHovered ->
                                False

                            IsHovered ->
                                True

                            IsHoveredButNoMenu ->
                                True

                            IsHoveredReactionsOnly ->
                                True

                            IsHoveredWhileSelectingAnchor ->
                                False
                    }
                    embeds
                    content
                    ++ (if isBeingEdited then
                            [ Html.span
                                [ Html.Attributes.style "color" (MyUi.colorToStyle MyUi.dimFont)
                                , Html.Attributes.style "font-size" "12px"
                                ]
                                [ Html.text " (editing...)" ]
                            ]

                        else
                            case message2.editedAt of
                                Just editedAt ->
                                    [ Html.span
                                        [ Html.Attributes.style "color" (MyUi.colorToStyle MyUi.dimFont)
                                        , Html.Attributes.style "font-size" "12px"
                                        , MyUi.datestamp localUser.timezone editedAt |> Html.Attributes.title
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


discordUserTextMessageContent :
    Time.Posix
    -> HtmlId
    -> Int
    -> Bool
    -> Maybe ( Id messageId, Message messageId (Discord.Id Discord.UserId) )
    -> LocalUser
    -> SeqDict (Id messageId) (NonemptySet Int)
    -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
    -> IsHovered
    -> Id messageId
    -> Nonempty (RichText (Discord.Id Discord.UserId))
    -> Array Embed
    ->
        { a
            | createdAt : Time.Posix
            , createdBy : Discord.Id Discord.UserId
            , reactions : SeqDict EmojiOrCustomEmoji (NonemptySet (Discord.Id Discord.UserId))
            , editedAt : Maybe Time.Posix
            , repliedTo : Maybe (Id messageId)
            , attachedFiles : SeqDict (Id FileId) FileData
            , timestampDrawings : Drawing (Discord.Id Discord.UserId)
            , userIconDrawings : Drawing (Discord.Id Discord.UserId)
            , imageAttachmentDrawings : SeqDict (Id FileId) (Drawing (Discord.Id Discord.UserId))
            , embedDrawings : SeqDict Int (Drawing (Discord.Id Discord.UserId))
        }
    -> Element MessageViewMsg
discordUserTextMessageContent time spoilerHtmlId containerWidth isMobile maybeRepliedTo2 localUser revealedSpoilers allUsers isHovered messageId content embeds message2 =
    Ui.row
        []
        [ (case SeqDict.get message2.createdBy allUsers of
            Just user ->
                User.discordProfileImage message2.createdBy user.icon

            Nothing ->
                User.discordProfileImage message2.createdBy Nothing
          )
            |> Ui.el
                (Drawing.anchorHighlight
                    (Drawing.profileImageAnchorId messageId)
                    (User.discordUserColor localUser)
                    MessageView_PressedUserIconAnchor
                    (isHovered == IsHoveredWhileSelectingAnchor)
                    message2.userIconDrawings
                    ++ (if isHovered == IsHoveredWhileSelectingAnchor then
                            [ Ui.rounded User.profileImageRounding ]

                        else
                            openDmButton messageId (MessageView_PressedDiscordUserIconButton message2.createdBy)
                       )
                )
            |> Ui.el
                [ Ui.paddingWith
                    { left = 0
                    , right = MessageView.profileImagePaddingRight
                    , top =
                        case maybeRepliedTo2 of
                            Just _ ->
                                24

                            Nothing ->
                                2
                    , bottom = 0
                    }
                , Ui.width Ui.shrink
                , Ui.alignTop
                ]
        , Ui.column
            []
            [ replyToHeaderAboveMessage
                isMobile
                localUser.timezone
                time
                maybeRepliedTo2
                revealedSpoilers
                localUser.customEmojis
                SeqDict.empty
                allUsers
            , Ui.row
                []
                [ User.toStringView message2.createdBy allUsers
                , messageTimestamp
                    (User.discordUserColor localUser)
                    message2.timestampDrawings
                    (isHovered == IsHoveredWhileSelectingAnchor)
                    messageId
                    message2.createdAt
                    localUser.timezone
                , messageIdView messageId
                ]
            , Html.div
                [ Html.Attributes.style "white-space" "pre-wrap" ]
                (RichText.view
                    (Dom.id (Dom.idToString spoilerHtmlId ++ "_" ++ Id.toString messageId))
                    containerWidth
                    MessageView_PressedNonWhitelistLink
                    MessageView_PressedSpoiler
                    MessageView_PressedImage
                    { revealedSpoilers =
                        case SeqDict.get messageId revealedSpoilers of
                            Just nonempty ->
                                NonemptySet.toSeqSet nonempty

                            Nothing ->
                                SeqSet.empty
                    , users = allUsers
                    , attachedFiles = message2.attachedFiles
                    , domainWhitelist = localUser.user.domainWhitelist
                    , customEmojis = localUser.customEmojis
                    , stickers = localUser.stickers
                    , animationMode = isHoveredToAnimationMode isHovered
                    , timezone = localUser.timezone
                    , time = time
                    , drawings = message2.imageAttachmentDrawings
                    , embedDrawings = message2.embedDrawings
                    , drawingUserColor = User.discordUserColor localUser
                    , isSelectingAnchor = isHovered == IsHoveredWhileSelectingAnchor
                    , devicePixelRatio = localUser.devicePixelRatio
                    , isHovered =
                        case isHovered of
                            IsNotHovered ->
                                False

                            IsHovered ->
                                True

                            IsHoveredButNoMenu ->
                                True

                            IsHoveredReactionsOnly ->
                                True

                            IsHoveredWhileSelectingAnchor ->
                                False
                    }
                    embeds
                    content
                    ++ (case message2.editedAt of
                            Just editedAt ->
                                [ Html.span
                                    [ Html.Attributes.style "color" (MyUi.colorToStyle MyUi.dimFont)
                                    , Html.Attributes.style "font-size" "12px"
                                    , MyUi.datestamp localUser.timezone editedAt |> Html.Attributes.title
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


messageIdView : Id messageId -> Element msg
messageIdView _ =
    Ui.none



--if Env.isProduction then
--    Ui.none
--
--else
--    Ui.el [ Ui.Font.size 14, Ui.width Ui.shrink, Ui.paddingLeft 4 ] (Ui.text (Id.toString messageId))


deletedMessageContent : Id messageId -> Bool -> HighlightMessage -> Time.Posix -> Time.Zone -> Element MessageViewMsg
deletedMessageContent messageId isSelectingAnchor highlight createdAt timezone =
    Ui.row
        [ Ui.paddingWith { left = 4, right = 0, top = 4, bottom = 0 } ]
        [ Ui.el
            [ Ui.Font.color MyUi.font3
            , Ui.Font.italic
            , Ui.Font.size 14
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
            (Ui.text LocalState.messageDeleted)
        , messageTimestamp (\_ -> UserColor.default) Drawing.emptyDrawing isSelectingAnchor messageId createdAt timezone
        ]


messageTimestamp : (userId -> UserColor) -> Drawing userId -> Bool -> Id messageId -> Time.Posix -> Time.Zone -> Element MessageViewMsg
messageTimestamp userIdToColor drawings isSelectingAnchor messageId createdAt timezone =
    Ui.el
        ([ Ui.Font.size 14
         , Ui.Font.color MyUi.font3
         , Ui.paddingXY 4 0
         , Ui.rounded 4
         ]
            ++ Drawing.anchorHighlight
                ("guild_messageTimestamp_" ++ Id.toString messageId |> Dom.id)
                userIdToColor
                MessageView_PressedTimestamp
                isSelectingAnchor
                drawings
        )
        (Ui.el [ MyUi.noPointerEvents ] (Ui.text (MyUi.timestamp createdAt timezone)))


messagePreviewTimestamp : Time.Posix -> Time.Zone -> Html msg
messagePreviewTimestamp createdAt timezone =
    Html.span
        [ Html.Attributes.style "font-size" "14px"
        , Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font3)
        ]
        [ MyUi.timestamp createdAt timezone |> Html.text ]


replyToHeaderAboveMessage_userTextMessage :
    Bool
    -> Id messageId
    -> Time.Zone
    -> Time.Posix
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> SeqDict userId { a | name : PersonName }
    -> SeqDict (Id messageId) (NonemptySet Int)
    -> Nonempty (RichText userId)
    -> { b | createdBy : userId, attachedFiles : SeqDict (Id FileId) FileData }
    -> Element MessageViewMsg
replyToHeaderAboveMessage_userTextMessage isMobile repliedToIndex timezone time customEmojis allUsers revealedSpoilers content repliedToData =
    replyToHeaderAboveMessageHelper
        isMobile
        repliedToIndex
        (userTextMessagePreview
            timezone
            time
            customEmojis
            allUsers
            (case SeqDict.get repliedToIndex revealedSpoilers of
                Just set ->
                    NonemptySet.toSeqSet set

                Nothing ->
                    SeqSet.empty
            )
            content
            repliedToData
        )


replyToHeaderAboveMessage :
    Bool
    -> Time.Zone
    -> Time.Posix
    -> Maybe ( Id messageId, Message messageId userId )
    -> SeqDict (Id messageId) (NonemptySet Int)
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> SeqDict BytesHash (Result () (ContentAndEmbeds userId))
    -> SeqDict userId { a | name : PersonName, icon : Maybe FileHash }
    -> Element MessageViewMsg
replyToHeaderAboveMessage isMobile timezone time maybeRepliedTo2 revealedSpoilers customEmojis decrypted allUsers =
    case maybeRepliedTo2 of
        Just ( repliedToIndex, UserTextMessage repliedToData ) ->
            replyToHeaderAboveMessage_userTextMessage
                isMobile
                repliedToIndex
                timezone
                time
                customEmojis
                allUsers
                revealedSpoilers
                repliedToData.content
                repliedToData

        Just ( repliedToIndex, EncryptedUserTextMessage repliedToData ) ->
            case SeqDict.get (Encryption.hash repliedToData.encryptedData) decrypted of
                Just result ->
                    replyToHeaderAboveMessage_userTextMessage
                        isMobile
                        repliedToIndex
                        timezone
                        time
                        customEmojis
                        allUsers
                        revealedSpoilers
                        (case result of
                            Ok ok ->
                                ok.content

                            Err () ->
                                RichText.failedToDecryptMessage
                        )
                        repliedToData

                Nothing ->
                    Ui.none

        Just ( repliedToIndex, UserJoinedMessage _ userId _ _ ) ->
            replyToHeaderAboveMessageHelper isMobile repliedToIndex (userJoinedContent userId allUsers)

        Just ( repliedToIndex, DeletedMessage _ ) ->
            replyToHeaderAboveMessageHelper
                isMobile
                repliedToIndex
                (Ui.el
                    [ Ui.Font.italic, Ui.Font.color MyUi.font3 ]
                    (Ui.text LocalState.messageDeleted)
                )

        Just ( repliedToIndex, CallStarted { startedAt, endedAt, startedBy } ) ->
            replyToHeaderAboveMessageHelper isMobile repliedToIndex (callStarted startedBy startedAt endedAt allUsers)

        Just ( repliedToIndex, GameStarted { startedBy } ) ->
            replyToHeaderAboveMessageHelper isMobile repliedToIndex (goMatchStarted startedBy allUsers)

        Nothing ->
            Ui.none


userTextMessagePreview :
    Time.Zone
    -> Time.Posix
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> SeqDict userId { a | name : PersonName }
    -> SeqSet Int
    -> Nonempty (RichText userId)
    -> { b | createdBy : userId, attachedFiles : SeqDict (Id FileId) FileData }
    -> Element MessageViewMsg
userTextMessagePreview timezone time customEmojis allUsers revealedSpoilers content message =
    Html.div
        [ Html.Attributes.style "white-space" "nowrap"
        , Html.Attributes.style "overflow" "hidden"
        , Html.Attributes.style "text-overflow" "ellipsis"
        ]
        (Html.span
            [ Html.Attributes.style "color" (MyUi.colorToStyle MyUi.dimFont)
            , Html.Attributes.style "padding" "0 6px 0 2px"
            ]
            [ Html.text (User.toString message.createdBy allUsers) ]
            :: RichText.preview
                (\_ -> MessageView_NoOp)
                { revealedSpoilers = revealedSpoilers
                , users = allUsers
                , attachedFiles = message.attachedFiles
                , customEmojis = customEmojis
                , domainWhitelist = SeqSet.empty
                , timezone = timezone
                , time = time
                }
                content
        )
        |> Ui.html


channelMessageHtmlId : Id ChannelMessageId -> HtmlId
channelMessageHtmlId messageIndex =
    "guild_message_" ++ Id.toString messageIndex |> Dom.id


threadMessageHtmlId : Id ThreadMessageId -> HtmlId
threadMessageHtmlId messageIndex =
    "thread_message_" ++ Id.toString messageIndex |> Dom.id


replyToHeaderAboveMessageHelper : Bool -> Id messageId -> Element MessageViewMsg -> Element MessageViewMsg
replyToHeaderAboveMessageHelper isMobile messageId content =
    MyUi.rowButton
        (Dom.id ("guild_replyLink_" ++ Id.toString messageId))
        MessageView_PressedReplyLink
        [ Ui.Font.size 14
        , Ui.paddingWith { left = 0, right = 8, top = 2, bottom = 0 }
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


userJoinedContent : userId -> SeqDict userId { a | name : PersonName } -> Element msg
userJoinedContent userId allUsers =
    Ui.Prose.paragraph
        [ Ui.paddingXY 0 4 ]
        [ User.toString userId allUsers |> Ui.text |> Ui.el [ Ui.Font.bold ]
        , Ui.el [] (Ui.text " joined!")
        ]


callStarted : userId -> Time.Posix -> Maybe Time.Posix -> SeqDict userId { a | name : PersonName } -> Element msg
callStarted userId startedAt endedAt allUsers =
    Ui.Prose.paragraph
        [ Ui.paddingXY 0 4 ]
        [ User.toString userId allUsers
            |> Ui.text
            |> Ui.el [ Ui.Font.bold ]
        , " started a call" ++ eventDurationText startedAt endedAt |> Ui.text |> Ui.el []
        ]


eventDurationText : Time.Posix -> Maybe Time.Posix -> String
eventDurationText start end =
    case end of
        Just endedAt2 ->
            ", lasted " ++ MyUi.timeElapsed start endedAt2

        Nothing ->
            ""


goMatchStarted : userId -> SeqDict userId { a | name : PersonName } -> Element msg
goMatchStarted userId allUsers =
    Ui.Prose.paragraph
        [ Ui.paddingXY 0 4 ]
        [ User.toString userId allUsers
            |> Ui.text
            |> Ui.el [ Ui.Font.bold ]
        , Ui.text " started a Go match" |> Ui.el []
        ]


callStartedCard :
    (userId -> UserColor)
    -> Bool
    -> Id messageId
    -> Drawing userId
    -> userId
    -> Time.Posix
    -> Maybe Time.Posix
    -> SeqDict userId { a | name : PersonName }
    -> Element MessageViewMsg
callStartedCard userIdToColor isSelectingAnchor messageId drawings userId startedAt endedAt allUsers =
    eventCard
        userIdToColor
        isSelectingAnchor
        messageId
        drawings
        (Dom.id "guild_callStartedCard")
        MessageViewMsg_PressedCallStartedCard
        (Ui.html Icons.phone)
        (User.toString userId allUsers)
        (startedACallText ++ eventDurationText startedAt endedAt)


goMatchStartedCard :
    (userId -> UserColor)
    -> Bool
    -> Drawing userId
    -> Id messageId
    -> userId
    -> SeqDict userId { a | name : PersonName }
    -> GameType
    -> Element MessageViewMsg
goMatchStartedCard userIdToColor isSelectingAnchor drawings messageId userId allUsers game =
    case game of
        GameType_Go ->
            eventCard
                userIdToColor
                isSelectingAnchor
                messageId
                drawings
                (Dom.id ("guild_gameStartedCard_" ++ Id.toString messageId))
                MessageViewMsg_PressedGameStartedCard
                (Ui.html Icons.go)
                (User.toString userId allUsers)
                "started a Go match"

        GameType_WordSpellingGame ->
            eventCard
                userIdToColor
                isSelectingAnchor
                messageId
                drawings
                (Dom.id ("guild_gameStartedCard_" ++ Id.toString messageId))
                MessageViewMsg_PressedGameStartedCard
                (Ui.html Icons.go)
                (User.toString userId allUsers)
                "started a Word Spelling game"

        GameType_SheepGame ->
            eventCard
                userIdToColor
                isSelectingAnchor
                messageId
                drawings
                (Dom.id ("guild_gameStartedCard_" ++ Id.toString messageId))
                MessageViewMsg_PressedGameStartedCard
                (Ui.html Icons.go)
                (User.toString userId allUsers)
                "started a Sheep Game"


eventCard :
    (userId -> UserColor)
    -> Bool
    -> Id messageId
    -> Drawing userId
    -> HtmlId
    -> MessageViewMsg
    -> Element MessageViewMsg
    -> String
    -> String
    -> Element MessageViewMsg
eventCard userIdToColor isSelectingAnchor messageId drawings htmlId onPress icon userName action =
    Ui.el
        []
        (Ui.el
            (Ui.rounded 6
                :: Drawing.anchorHighlight
                    ("guild_eventCard_" ++ Id.toString messageId |> Dom.id)
                    userIdToColor
                    MessageView_PressedCardAnchor
                    isSelectingAnchor
                    drawings
            )
            (MyUi.rowButton
                htmlId
                onPress
                [ Ui.spacing 12
                , Ui.paddingXY 16 6
                , Ui.background MyUi.background2
                , Ui.border 1
                , Ui.borderColor MyUi.border1
                , Ui.rounded 6
                , Ui.width Ui.shrink
                , Ui.Font.color MyUi.font3
                , MyUi.hover False [ Ui.Anim.fontColor MyUi.font1 ]
                , if isSelectingAnchor then
                    MyUi.noPointerEvents

                  else
                    Ui.noAttr
                ]
                [ icon
                , Ui.column
                    [ Ui.spacing 2, Ui.width Ui.shrink ]
                    [ Ui.el
                        [ Ui.Font.bold, Ui.Font.color MyUi.font1, Ui.widthMax 200, Ui.clipWithEllipsis ]
                        (Ui.text userName)
                    , Ui.el [ Ui.Font.size 13 ] (Ui.text action)
                    ]
                ]
            )
        )


messagePaddingX : number
messagePaddingX =
    8


{-| Decodes a "contextmenu" event into a message that opens the message menu.
If the right-click landed on an image attachment or a hyperlink we also grab
their urls (exposed via the "data-image-url"/"data-link-url" attributes) so that
the menu can offer "Copy image"/"Copy image link"/"Copy link" options.
-}
decodeMessageContextMenu : Bool -> Json.Decode.Decoder ( MessageViewMsg, Bool )
decodeMessageContextMenu isThreadStarter =
    Json.Decode.map3
        (\x y target ->
            ( MessageView_AltPressedMessage isThreadStarter target.imageUrl target.linkUrl (Coord.xy (round x) (round y))
            , True
            )
        )
        (Json.Decode.field "clientX" Json.Decode.float)
        (Json.Decode.field "clientY" Json.Decode.float)
        decodeEventTarget


{-| Reads the "data-image-url"/"data-link-url" off the event's target (walking up
its ancestors). Falls back to no urls when there is no target (e.g. in tests).
-}
decodeEventTarget : Json.Decode.Decoder ContextMenuTarget
decodeEventTarget =
    Json.Decode.oneOf
        [ Json.Decode.field "target" (decodeContextMenuTarget 20)
        , Json.Decode.succeed emptyContextMenuTarget
        ]


type alias ContextMenuTarget =
    { imageUrl : Maybe String, linkUrl : Maybe String }


emptyContextMenuTarget : ContextMenuTarget
emptyContextMenuTarget =
    { imageUrl = Nothing, linkUrl = Nothing }


{-| Walks up from the event target through its ancestors looking for the nearest
"data-image-url"/"data-link-url" attributes. We have to climb the tree because
the element actually under the cursor is often a descendant of the one carrying
the attribute (e.g. the <canvas>/<img> that an animated-image-player web
component appends inside itself, or the favicon/label inside a link).
-}
decodeContextMenuTarget : Int -> Json.Decode.Decoder ContextMenuTarget
decodeContextMenuTarget depth =
    Json.Decode.map2
        (\here parent ->
            { imageUrl = orElseMaybe here.imageUrl parent.imageUrl
            , linkUrl = orElseMaybe here.linkUrl parent.linkUrl
            }
        )
        (Json.Decode.map2 ContextMenuTarget
            (Json.Decode.maybe (Json.Decode.at [ "dataset", "imageUrl" ] Json.Decode.string))
            (Json.Decode.maybe (Json.Decode.at [ "dataset", "linkUrl" ] Json.Decode.string))
        )
        (if depth <= 0 then
            Json.Decode.succeed emptyContextMenuTarget

         else
            Json.Decode.oneOf
                [ Json.Decode.field "parentElement" (Json.Decode.lazy (\() -> decodeContextMenuTarget (depth - 1)))
                , Json.Decode.succeed emptyContextMenuTarget
                ]
        )


orElseMaybe : Maybe a -> Maybe a -> Maybe a
orElseMaybe first second =
    case first of
        Just _ ->
            first

        Nothing ->
            second


messageContainer :
    Int
    -> Bool
    -> Time.Zone
    -> Time.Posix
    -> SeqSet (Id CustomEmojiId)
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> Maybe CachedEmojiData
    -> SeqDict userId { a | name : PersonName }
    -> HighlightMessage
    -> Id ChannelMessageId
    -> Bool
    -> userId
    -> FrontendCurrentUser
    -> SeqDict EmojiOrCustomEmoji (NonemptySet userId)
    -> Maybe (FrontendGenericThread userId)
    -> SeqDict BytesHash (Result () (ContentAndEmbeds userId))
    -> IsHovered
    -> Element MessageViewMsg
    -> Element MessageViewMsg
messageContainer containerWidth isThreadStarter timezone currentTime availableCustomEmojis customEmojis emojiData allUsers highlight messageIndex canEdit currentUserId currentUser reactions maybeThread decrypted isHovered messageContent =
    let
        maybeReactions : Maybe (Element MessageViewMsg)
        maybeReactions =
            MessageView.reactionEmojiView emojiData (reactionsHover isHovered) currentUserId customEmojis allUsers (isHoveredToAnimationMode isHovered) containerWidth reactions
    in
    Ui.column
        ([ Ui.Font.color MyUi.font1
         , Ui.Events.onMouseEnter MessageView_MouseEnteredMessage
         , Ui.Events.onMouseLeave MessageView_MouseExitedMessage
         , Ui.Events.on
            "touchstart"
            (Json.Decode.map2
                (\toMsg target -> toMsg target.imageUrl target.linkUrl)
                (Touch.decodeTouchEvent
                    (\time touches imageUrl linkUrl ->
                        MessageView_TouchStart
                            time
                            isThreadStarter
                            imageUrl
                            linkUrl
                            (NonemptyDict.map
                                (\_ touch -> { touch | target = channelMessageHtmlId messageIndex |> Just })
                                touches
                            )
                    )
                )
                decodeEventTarget
            )
         , Ui.Events.preventDefaultOn "contextmenu" (decodeMessageContextMenu isThreadStarter)
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
                        , MessageView.miniView currentUser isThreadStarter canEdit availableCustomEmojis customEmojis |> Ui.inFront
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

                    IsHoveredReactionsOnly ->
                        [ case highlight of
                            NoHighlight ->
                                Ui.background MyUi.hoverHighlight

                            ReplyToHighlight ->
                                Ui.background MyUi.hoverAndReplyToColor

                            MentionHighlight ->
                                Ui.background MyUi.hoverAndMentionColor

                            UrlHighlight ->
                                Ui.background MyUi.hoverAndReplyToColor
                        , MessageView.reactionsMiniView currentUser availableCustomEmojis customEmojis |> Ui.inFront
                        ]

                    IsHoveredWhileSelectingAnchor ->
                        []
               )
        )
        (messageContent
            :: Maybe.Extra.toList maybeReactions
            ++ (case maybeThread of
                    Just thread ->
                        [ previewThreadLastMessage timezone currentTime customEmojis allUsers decrypted messageIndex thread
                        ]

                    Nothing ->
                        []
               )
        )


threadMessageContainer :
    Int
    -> HighlightMessage
    -> Id ThreadMessageId
    -> Bool
    -> userId
    -> FrontendCurrentUser
    -> SeqDict EmojiOrCustomEmoji (NonemptySet userId)
    -> SeqSet (Id CustomEmojiId)
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> Maybe CachedEmojiData
    -> SeqDict userId { a | name : PersonName }
    -> IsHovered
    -> Element MessageViewMsg
    -> Element MessageViewMsg
threadMessageContainer containerWidth highlight messageIndex canEdit currentUserId currentUser reactions availableCustomEmojis customEmojis emojiData allUsers isHovered messageContent =
    let
        maybeReactions : Maybe (Element MessageViewMsg)
        maybeReactions =
            MessageView.reactionEmojiView emojiData (reactionsHover isHovered) currentUserId customEmojis allUsers (isHoveredToAnimationMode isHovered) containerWidth reactions
    in
    Ui.column
        ([ Ui.Font.color MyUi.font1
         , Ui.Events.onMouseEnter MessageView_MouseEnteredMessage
         , Ui.Events.onMouseLeave MessageView_MouseExitedMessage
         , Ui.Events.on
            "touchstart"
            (Json.Decode.map2
                (\toMsg target -> toMsg target.imageUrl target.linkUrl)
                (Touch.decodeTouchEvent
                    (\time touches imageUrl linkUrl ->
                        MessageView_TouchStart
                            time
                            False
                            imageUrl
                            linkUrl
                            (NonemptyDict.map
                                (\_ touch -> { touch | target = threadMessageHtmlId messageIndex |> Just })
                                touches
                            )
                    )
                )
                decodeEventTarget
            )
         , Ui.Events.preventDefaultOn "contextmenu" (decodeMessageContextMenu False)
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
         , threadMessageHtmlId messageIndex |> Dom.idToString |> Ui.id
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
                        , MessageView.miniView currentUser False canEdit availableCustomEmojis customEmojis |> Ui.inFront
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

                    IsHoveredReactionsOnly ->
                        [ case highlight of
                            NoHighlight ->
                                Ui.background MyUi.hoverHighlight

                            ReplyToHighlight ->
                                Ui.background MyUi.hoverAndReplyToColor

                            MentionHighlight ->
                                Ui.background MyUi.hoverAndMentionColor

                            UrlHighlight ->
                                Ui.background MyUi.hoverAndReplyToColor
                        , MessageView.reactionsMiniView currentUser availableCustomEmojis customEmojis |> Ui.inFront
                        ]

                    IsHoveredWhileSelectingAnchor ->
                        []
               )
        )
        (messageContent :: Maybe.Extra.toList maybeReactions)


previewThreadLastMessage_userTextMessage :
    Time.Posix
    -> Time.Zone
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> SeqDict userId { a | name : PersonName }
    -> Nonempty (RichText userId)
    -> { c | createdBy : userId, attachedFiles : SeqDict (Id FileId) FileData }
    -> List (Html MessageViewMsg)
previewThreadLastMessage_userTextMessage time timezone customEmojis allUsers content data =
    Html.span
        [ Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font3)
        , Html.Attributes.style "padding" "0 6px 0 2px"
        ]
        [ Html.text (User.toString data.createdBy allUsers) ]
        :: RichText.preview
            (\_ -> MessageView_NoOp)
            { revealedSpoilers = SeqSet.empty
            , users = allUsers
            , attachedFiles = data.attachedFiles
            , customEmojis = customEmojis
            , domainWhitelist = SeqSet.empty
            , timezone = timezone
            , time = time
            }
            content


previewThreadLastMessage :
    Time.Zone
    -> Time.Posix
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> SeqDict userId { a | name : PersonName }
    -> SeqDict BytesHash (Result () (ContentAndEmbeds userId))
    -> Id ChannelMessageId
    -> FrontendGenericThread userId
    -> Element MessageViewMsg
previewThreadLastMessage timezone time customEmojis allUsers decrypted messageId thread =
    let
        lastMessage =
            MessageArray.last thread.messages
    in
    Html.button
        [ Html.Attributes.style "white-space" "nowrap"
        , Html.Attributes.style "text-overflow" "ellipsis"
        , Html.Attributes.style "overflow" "hidden"
        , Html.Attributes.style "background-color" (MyUi.colorToStyle MyUi.background1)
        , Html.Attributes.style "border" ("1px solid " ++ MyUi.colorToStyle MyUi.border1)
        , Html.Attributes.style "padding" "4px 8px 4px 8px"
        , Html.Attributes.style "width" "fit-content"
        , Html.Attributes.style "max-width" "calc(min(100% - 16px, 800px))"
        , Html.Attributes.style "min-width" "250px"
        , Html.Attributes.style "margin" "0"
        , Html.Attributes.style "color" "inherit"
        , Html.Attributes.style "font-size" "inherit"
        , Html.Attributes.style "text-align" "left"
        , Html.Attributes.id ("guild_threadStarterIndicator_" ++ Id.toString messageId)
        , Html.Events.onClick MessageView_PressedViewThreadLink
        , Html.Attributes.style "cursor" "pointer"
        ]
        (Html.div
            [ Html.Attributes.style "display" "flex"
            , Html.Attributes.style "align-content" "center"
            , Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font3)
            ]
            [ Icons.hashtag
            , case MessageArray.length thread.messages of
                1 ->
                    Html.text "1 message"

                count ->
                    Html.text (String.fromInt count ++ " messages")
            , Html.div [ Html.Attributes.style "flex-grow" "1" ] []
            , case lastMessage of
                Just message ->
                    messagePreviewTimestamp (Message.createdAt message) timezone

                _ ->
                    Html.text ""
            ]
            :: (case lastMessage of
                    Just last ->
                        case last of
                            UserTextMessage data ->
                                previewThreadLastMessage_userTextMessage time timezone customEmojis allUsers data.content data

                            EncryptedUserTextMessage data ->
                                case SeqDict.get (Encryption.hash data.encryptedData) decrypted of
                                    Just result ->
                                        previewThreadLastMessage_userTextMessage
                                            time
                                            timezone
                                            customEmojis
                                            allUsers
                                            (case result of
                                                Ok ok ->
                                                    ok.content

                                                Err () ->
                                                    RichText.failedToDecryptMessage
                                            )
                                            data

                                    Nothing ->
                                        []

                            UserJoinedMessage _ userId _ _ ->
                                [ Html.span
                                    []
                                    [ Html.b [] [ User.toString userId allUsers |> Html.text ]
                                    , Html.text " joined!"
                                    ]
                                ]

                            DeletedMessage _ ->
                                [ Html.i
                                    [ Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font3) ]
                                    [ Html.text LocalState.messageDeleted ]
                                ]

                            CallStarted { endedAt, startedBy } ->
                                [ Html.span
                                    []
                                    [ Html.b [] [ User.toString startedBy allUsers |> Html.text ]
                                    , case endedAt of
                                        Just _ ->
                                            Html.text "'s call ended"

                                        Nothing ->
                                            Html.text " started a call"
                                    ]
                                ]

                            GameStarted { startedBy } ->
                                [ Html.span
                                    []
                                    [ Html.b [] [ User.toString startedBy allUsers |> Html.text ]
                                    , Html.text " started a Go match"
                                    ]
                                ]

                    _ ->
                        []
               )
        )
        |> Ui.html


channelColumnLazy :
    Bool
    -> Bool
    -> LoadedFrontend
    -> LoggedIn2
    -> LocalUser
    -> Id GuildId
    -> FrontendGuild
    -> ChannelRoute
    -> Element FrontendMsg_
channelColumnLazy isMobile canScroll2 model loggedIn localUser guildId guild channelRoute =
    if loggedIn.channelSearch /= "" then
        -- The search text changes too often for laziness to be worth it here
        channelColumn
            isMobile
            (Time.millisToPosix (nearestHour model.time))
            localUser
            guildId
            guild
            channelRoute
            canScroll2
            loggedIn.channelSearch

    else
        Ui.Lazy.lazy5
            (if isMobile then
                if canScroll2 then
                    channelColumnCanScrollMobile

                else
                    channelColumnCannotScrollMobile

             else
                channelColumnNotMobile
            )
            localUser
            (nearestHour model.time)
            guildId
            guild
            channelRoute


discordChannelColumnLazy :
    Bool
    -> Bool
    -> LoadedFrontend
    -> LoggedIn2
    -> LocalUser
    -> DiscordGuildRouteData
    -> DiscordFrontendGuild
    -> Element FrontendMsg_
discordChannelColumnLazy isMobile canScroll2 model loggedIn localUser routeData guild =
    if loggedIn.channelSearch /= "" then
        -- The search text changes too often for laziness to be worth it here
        discordChannelColumn
            isMobile
            (Time.millisToPosix (nearestHour model.time))
            localUser
            routeData
            guild
            canScroll2
            loggedIn.channelSearch

    else
        Ui.Lazy.lazy4
            (if isMobile then
                if canScroll2 then
                    discordChannelColumnCanScrollMobile

                else
                    discordChannelColumnCannotScrollMobile

             else
                discordChannelColumnNotMobile
            )
            (nearestHour model.time)
            localUser
            routeData
            guild


channelColumnNotMobile :
    LocalUser
    -> Int
    -> Id GuildId
    -> FrontendGuild
    -> ChannelRoute
    -> Element FrontendMsg_
channelColumnNotMobile localUser time guildId guild channelRoute =
    channelColumn False (Time.millisToPosix time) localUser guildId guild channelRoute True ""


discordChannelColumnNotMobile :
    Int
    -> LocalUser
    -> DiscordGuildRouteData
    -> DiscordFrontendGuild
    -> Element FrontendMsg_
discordChannelColumnNotMobile time localUser routeData guild =
    discordChannelColumn False (Time.millisToPosix time) localUser routeData guild True ""


channelColumnCanScrollMobile :
    LocalUser
    -> Int
    -> Id GuildId
    -> FrontendGuild
    -> ChannelRoute
    -> Element FrontendMsg_
channelColumnCanScrollMobile localUser time guildId guild channelRoute =
    channelColumn True (Time.millisToPosix time) localUser guildId guild channelRoute True ""


channelColumnCannotScrollMobile :
    LocalUser
    -> Int
    -> Id GuildId
    -> FrontendGuild
    -> ChannelRoute
    -> Element FrontendMsg_
channelColumnCannotScrollMobile localUser time guildId guild channelRoute =
    channelColumn True (Time.millisToPosix time) localUser guildId guild channelRoute False ""


discordChannelColumnCanScrollMobile :
    Int
    -> LocalUser
    -> DiscordGuildRouteData
    -> DiscordFrontendGuild
    -> Element FrontendMsg_
discordChannelColumnCanScrollMobile time localUser guildId guild =
    discordChannelColumn True (Time.millisToPosix time) localUser guildId guild True ""


discordChannelColumnCannotScrollMobile :
    Int
    -> LocalUser
    -> DiscordGuildRouteData
    -> DiscordFrontendGuild
    -> Element FrontendMsg_
discordChannelColumnCannotScrollMobile time localUser guildId guild =
    discordChannelColumn True (Time.millisToPosix time) localUser guildId guild False ""


channelColumnContainer : List (Element msg) -> Element msg -> Element msg -> Element msg
channelColumnContainer header subHeader content =
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
                , Ui.height (Ui.px MyUi.channelHeaderHeight)
                , MyUi.noShrinking
                , Ui.clipWithEllipsis
                ]
                header
            , subHeader
            , content
            ]
        )


channelColumn :
    Bool
    -> Time.Posix
    -> LocalUser
    -> Id GuildId
    -> FrontendGuild
    -> ChannelRoute
    -> Bool
    -> String
    -> Element FrontendMsg_
channelColumn isMobile time localUser guildId guild channelRoute canScroll2 channelSearch =
    let
        guildName : String
        guildName =
            GuildName.toString guild.name

        showSearch : Bool
        showSearch =
            SeqDict.size guild.channels > channelSearchMinChannels

        searchFilter : String
        searchFilter =
            if showSearch then
                String.trim channelSearch |> String.toLower

            else
                ""

        directMentions : Maybe (NonemptyDict ( Id ChannelId, ThreadRoute ) OneOrGreater)
        directMentions =
            SeqDict.get guildId localUser.user.directMentions

        newChannelButton : Element FrontendMsg_
        newChannelButton =
            case MembersAndOwner.isMember localUser.session.userId guild.membersAndOwner of
                IsOwner ->
                    let
                        isSelected =
                            channelRoute == NewChannelRoute
                    in
                    GuildColumn.rowLinkButton
                        (Dom.id "guild_newChannel")
                        (GuildRoute guildId NewChannelRoute ChannelsHiddenOnMobile)
                        [ Ui.paddingXY 4 8
                        , Ui.Font.color MyUi.font3
                        , Ui.attrIf isSelected (Ui.background MyUi.selectedHighlight)
                        , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
                        , if isSelected then
                            Ui.Font.color MyUi.font1

                          else
                            Ui.Font.color MyUi.font3
                        ]
                        [ Ui.el [ Ui.width (Ui.px 22) ] (Ui.html Icons.plusIcon)
                        , Ui.text " Add new channel"
                        ]

                _ ->
                    Ui.none
    in
    channelColumnContainer
        [ Ui.el [ MyUi.hoverText guildName ] (Ui.text guildName)
        , GuildColumn.elLinkButton
            (Dom.id "guild_inviteLinkCreatorRoute")
            (GuildRoute guildId GuildSettingsRoute ChannelsHiddenOnMobile)
            [ Ui.Font.color MyUi.font2
            , Ui.width (Ui.px 40)
            , Ui.alignRight
            , Ui.paddingXY 8 0
            , Ui.height Ui.fill
            , Ui.contentCenterY
            , MyUi.hoverText "Invite users"
            ]
            (Ui.html Icons.gear)
        ]
        (if showSearch then
            channelSearchRow isMobile channelSearch

         else
            Ui.none
        )
        (Ui.column
            [ MyUi.scrollable canScroll2
            , Ui.heightMin 0
            , Ui.paddingXY 0 8
            , Ui.attrIf isMobile (Ui.height Ui.fill)
            , MyUi.bounceScroll isMobile
            ]
            ((SeqDict.toList guild.channels
                |> List.filter (\( _, channel ) -> channelMatchesSearch searchFilter channel)
                |> List.map
                    (\( channelId, channel ) ->
                        let
                            channelMuted =
                                MuteSettings.isChannelMuted localUser.user.muteSettings guildId channelId NoThread

                            hasNotifications : ChannelNotificationType
                            hasNotifications =
                                GuildColumn.channelOrThreadHasNotifications
                                    channelMuted
                                    directMentions
                                    (SeqSet.member guildId localUser.user.notifyOnAllMessages)
                                    channelId
                                    NoThread
                                    (SeqDict.get (GuildOrDmId (GuildOrDmId_Guild { guildId = guildId, channelId = channelId })) localUser.user.lastViewedMessage)
                                    channel
                        in
                        ( channelSortName hasNotifications channel
                        , Ui.column
                            []
                            [ channelColumnRow
                                isMobile
                                channelMuted
                                hasNotifications
                                channelRoute
                                guildId
                                channelId
                                channel
                            , channelColumnThreads
                                isMobile
                                time
                                channelRoute
                                directMentions
                                localUser
                                guildId
                                channelId
                                channel
                                (case channelRoute of
                                    ChannelRoute channelIdB (ViewThreadWithFriends threadMessageIndex _ _) _ ->
                                        if channelIdB == channelId then
                                            SeqDict.insert threadMessageIndex Thread.frontendInit channel.threads

                                        else
                                            channel.threads

                                    _ ->
                                        channel.threads
                                )
                            ]
                        )
                    )
                |> List.sortBy Tuple.first
                |> List.map Tuple.second
                |> channelColumnNoResults searchFilter
             )
                ++ (if searchFilter == "" then
                        [ newChannelButton ]

                    else
                        []
                   )
            )
        )


channelSortName : ChannelNotificationType -> { a | name : ChannelName } -> String
channelSortName hasNotifications channel =
    (case hasNotifications of
        NoNotification ->
            "c"

        NewMessage _ ->
            "b"

        NewMessageForUser _ ->
            "a"
    )
        ++ ChannelName.toString channel.name


{-| The channel search input is only shown for guilds with more channels than this.
-}
channelSearchMinChannels : Int
channelSearchMinChannels =
    6


channelSearchInputId : HtmlId
channelSearchInputId =
    Dom.id "guild_channelSearchInput"


channelMatchesSearch : String -> { a | name : ChannelName } -> Bool
channelMatchesSearch searchFilter channel =
    (searchFilter == "")
        || String.contains searchFilter (String.toLower (ChannelName.toString channel.name))


channelColumnNoResults : String -> List (Element FrontendMsg_) -> List (Element FrontendMsg_)
channelColumnNoResults searchFilter channelRows =
    if (searchFilter /= "") && List.isEmpty channelRows then
        [ Ui.Prose.paragraph
            [ Ui.Font.italic
            , Ui.Font.lineHeight 1.5
            , Ui.Font.color MyUi.font2
            , Ui.paddingXY 8 8
            ]
            [ Ui.text noMatchingChannelsText ]
        ]

    else
        channelRows


{-| Sits in its own row below the channel column header's bottom border. It is part of
the fixed header area, not the scrollable channel list.
-}
channelSearchRow : Bool -> String -> Element FrontendMsg_
channelSearchRow isMobile channelSearch =
    let
        clearPaddingX =
            12
    in
    Ui.el
        [ Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
        , Ui.borderColor MyUi.border1
        , MyUi.noShrinking
        , Ui.spacing 4
        , if channelSearch == "" then
            Ui.el
                [ Ui.Font.color MyUi.font3
                , Ui.height Ui.fill
                , Ui.contentCenterY
                , Ui.paddingXY clearPaddingX 0
                , MyUi.noPointerEvents
                , Ui.alignRight
                ]
                (Ui.html Icons.magnifyingGlass)
                |> Ui.inFront

          else
            MyUi.elButton
                (Dom.id "guild_clearChannelSearch")
                PressedClearChannelSearch
                [ Ui.Font.color MyUi.font3
                , Ui.width Ui.shrink
                , Ui.height Ui.fill
                , Ui.contentCenterY
                , Ui.paddingXY clearPaddingX 0
                , Ui.background MyUi.inputBackground
                , Ui.alignRight
                , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font3 ]
                , MyUi.hoverText "Clear search"
                ]
                (Ui.html Icons.x)
                |> Ui.el
                    [ -- Don't cover up the input focus outline
                      Ui.padding 2
                    , Ui.height Ui.fill
                    ]
                |> Ui.inFront
        ]
        (Ui.Input.text
            [ Ui.id (Dom.idToString channelSearchInputId)
            , Ui.background (Ui.rgba 0 0 0 0)
            , Ui.border 0
            , Ui.paddingWith { left = 8, top = 8, bottom = 8, right = clearPaddingX * 2 + 24 + 8 }
            , Ui.Font.color MyUi.font1
            ]
            { onChange = TypedChannelSearch
            , text = channelSearch
            , placeholder = Just "Search channels"
            , label = Ui.Input.labelHidden (Dom.idToString channelSearchInputId)
            }
        )


discordChannelColumn :
    Bool
    -> Time.Posix
    -> LocalUser
    -> DiscordGuildRouteData
    -> DiscordFrontendGuild
    -> Bool
    -> String
    -> Element FrontendMsg_
discordChannelColumn isMobile time localUser routeData guild canScroll2 channelSearch =
    let
        guildName : String
        guildName =
            GuildName.toString guild.name

        showSearch : Bool
        showSearch =
            SeqDict.size guild.channels > channelSearchMinChannels

        searchFilter : String
        searchFilter =
            if showSearch then
                String.trim channelSearch |> String.toLower

            else
                ""

        directMentions : Maybe (NonemptyDict ( Discord.Id Discord.ChannelId, ThreadRoute ) OneOrGreater)
        directMentions =
            SeqDict.get routeData.guildId localUser.user.discordDirectMentions
    in
    channelColumnContainer
        [ Ui.row
            [ MyUi.hoverText guildName
            , Ui.spacing 4
            ]
            [ GuildIcon.discordLogo
            , Ui.text guildName
            ]
        , GuildColumn.elLinkButton
            (Dom.id "guild_inviteLinkCreatorRoute")
            (DiscordGuildRoute
                { currentDiscordUserId = routeData.currentDiscordUserId
                , guildId = routeData.guildId
                , channelRoute = DiscordChannel_GuildSettingsRoute
                , channelsVisible = ChannelsHiddenOnMobile
                }
            )
            [ Ui.Font.color MyUi.font2
            , Ui.width (Ui.px 40)
            , Ui.alignRight
            , Ui.paddingXY 8 0
            , Ui.height Ui.fill
            , Ui.contentCenterY
            , MyUi.hoverText "Invite users"
            ]
            (Ui.html Icons.gear)
        ]
        (if showSearch then
            channelSearchRow isMobile channelSearch

         else
            Ui.none
        )
        (Ui.column
            [ MyUi.scrollable canScroll2
            , Ui.heightMin 0
            , Ui.paddingXY 0 8
            , Ui.attrIf isMobile (Ui.height Ui.fill)
            , MyUi.bounceScroll isMobile
            ]
            (SeqDict.toList guild.channels
                |> List.filter (\( _, channel ) -> channelMatchesSearch searchFilter channel)
                |> List.map
                    (\( channelId, channel ) ->
                        let
                            channelMuted : IsMuted
                            channelMuted =
                                MuteSettings.isDiscordChannelMuted
                                    localUser.user.muteSettings
                                    routeData.guildId
                                    channelId
                                    NoThread

                            hasNotifications : ChannelNotificationType
                            hasNotifications =
                                GuildColumn.channelOrThreadHasNotifications
                                    channelMuted
                                    directMentions
                                    (SeqSet.member routeData.guildId localUser.user.discordNotifyOnAllMessages)
                                    channelId
                                    NoThread
                                    (SeqDict.get (DiscordGuildOrDmId (DiscordGuildOrDmId_Guild { currentUserId = routeData.currentDiscordUserId, guildId = routeData.guildId, channelId = channelId })) localUser.user.lastViewedMessage)
                                    channel
                        in
                        ( channelSortName hasNotifications channel
                        , Ui.column
                            []
                            [ discordChannelColumnRow
                                isMobile
                                channelMuted
                                hasNotifications
                                routeData
                                channelId
                                channel
                            , discordChannelColumnThreads
                                isMobile
                                time
                                routeData
                                directMentions
                                localUser
                                channelId
                                channel
                                (case routeData.channelRoute of
                                    DiscordChannel_ChannelRoute channelIdB (ViewThreadWithFriends threadMessageIndex _ _) _ ->
                                        if channelIdB == channelId then
                                            SeqDict.insert threadMessageIndex Thread.discordFrontendInit channel.threads

                                        else
                                            channel.threads

                                    _ ->
                                        channel.threads
                                )
                            ]
                        )
                    )
                |> List.sortBy Tuple.first
                |> List.map Tuple.second
                |> channelColumnNoResults searchFilter
            )
        )


dmColumnThreads :
    Bool
    -> Time.Posix
    -> Maybe ThreadRouteWithFriends
    -> LocalUser
    -> Id UserId
    -> { b | messages : MessageArray ChannelMessageId (Id UserId) }
    -> SeqDict (Id ChannelMessageId) FrontendThread
    -> Element FrontendMsg_
dmColumnThreads isMobile now threadRoute localUser otherUserId channel threads =
    let
        threads2 : List ( Id ChannelMessageId, ( IsMuted, ChannelNotificationType ), Bool )
        threads2 =
            List.filterMap
                (\( threadMessageIndex, thread ) ->
                    let
                        isSelected : Bool
                        isSelected =
                            case threadRoute of
                                Just (ViewThreadWithFriends b _ _) ->
                                    b == threadMessageIndex

                                _ ->
                                    False

                        isMuted =
                            MuteSettings.isDmMuted
                                localUser.user.muteSettings
                                otherUserId
                                (ViewThread threadMessageIndex)

                        hasNotifications : ChannelNotificationType
                        hasNotifications =
                            case isMuted of
                                IsMuted ->
                                    NoNotification

                                IsNotMuted ->
                                    -- Every message in a DM is meant for you, so unread ones
                                    -- always get the red count. Guild channels save that for
                                    -- messages that mention you and show the plain one otherwise.
                                    case
                                        GuildColumn.newMessageCount
                                            (SeqDict.get
                                                ( GuildOrDmId (GuildOrDmId_Dm { otherUserId = otherUserId }), threadMessageIndex )
                                                localUser.user.lastViewedThreadMessage
                                            )
                                            thread
                                            |> OneOrGreater.fromInt
                                    of
                                        Just unreadCount ->
                                            NewMessageForUser unreadCount

                                        Nothing ->
                                            NoNotification
                    in
                    case ( hasNotifications, isSelected, MessageArray.last thread.messages ) of
                        ( NoNotification, False, Just message ) ->
                            if Duration.from (Message.createdAt message) now |> Quantity.lessThan Duration.week then
                                Just ( threadMessageIndex, ( isMuted, hasNotifications ), isSelected )

                            else
                                Nothing

                        _ ->
                            Just ( threadMessageIndex, ( isMuted, hasNotifications ), isSelected )
                )
                (SeqDict.toList threads)

        count =
            List.length threads2
    in
    List.indexedMap
        (\index ( threadMessageIndex, ( isMuted, hasNotifications ), isSelected ) ->
            channelColumnThreadsHelper
                isMobile
                isSelected
                isMuted
                hasNotifications
                index
                count
                (Dom.id ("guild_viewDmThread_" ++ Id.toString otherUserId ++ "_" ++ Id.toString threadMessageIndex))
                (DmRoute
                    { channelId = DmChannelId.fromUserIds otherUserId localUser.session.userId
                    , threadRoute = ViewThreadWithFriends threadMessageIndex Nothing HideChannelSettings
                    , tab = Nothing
                    , channelsVisible = ChannelsHiddenOnMobile
                    }
                )
                (threadPreviewText localUser.timezone (User.allUsers localUser) threadMessageIndex localUser.decryptedMessages channel)
        )
        threads2
        |> Ui.column []


channelColumnThreads :
    Bool
    -> Time.Posix
    -> ChannelRoute
    -> Maybe (NonemptyDict ( Id ChannelId, ThreadRoute ) OneOrGreater)
    -> LocalUser
    -> Id GuildId
    -> Id ChannelId
    -> FrontendChannel
    -> SeqDict (Id ChannelMessageId) FrontendThread
    -> Element FrontendMsg_
channelColumnThreads isMobile now channelRoute directMentions localUser guildId channelId channel threads =
    let
        threads2 : List ( Id ChannelMessageId, ( IsMuted, ChannelNotificationType ), Bool )
        threads2 =
            List.filterMap
                (\( threadMessageIndex, thread ) ->
                    let
                        isSelected : Bool
                        isSelected =
                            case channelRoute of
                                ChannelRoute a (ViewThreadWithFriends b _ _) _ ->
                                    a == channelId && b == threadMessageIndex

                                _ ->
                                    False

                        isMuted =
                            MuteSettings.isChannelMuted
                                localUser.user.muteSettings
                                guildId
                                channelId
                                (ViewThread threadMessageIndex)

                        hasNotifications : ChannelNotificationType
                        hasNotifications =
                            GuildColumn.channelOrThreadHasNotifications
                                isMuted
                                directMentions
                                (SeqSet.member guildId localUser.user.notifyOnAllMessages)
                                channelId
                                (ViewThread threadMessageIndex)
                                (SeqDict.get
                                    ( GuildOrDmId (GuildOrDmId_Guild { guildId = guildId, channelId = channelId }), threadMessageIndex )
                                    localUser.user.lastViewedThreadMessage
                                )
                                thread
                    in
                    case ( hasNotifications, isSelected, MessageArray.last thread.messages ) of
                        ( NoNotification, False, Just message ) ->
                            if Duration.from (Message.createdAt message) now |> Quantity.lessThan Duration.week then
                                Just ( threadMessageIndex, ( isMuted, hasNotifications ), isSelected )

                            else
                                Nothing

                        _ ->
                            Just ( threadMessageIndex, ( isMuted, hasNotifications ), isSelected )
                )
                (SeqDict.toList threads)

        count =
            List.length threads2
    in
    List.indexedMap
        (\index ( threadMessageIndex, ( isMuted, hasNotifications ), isSelected ) ->
            channelColumnThreadsHelper
                isMobile
                isSelected
                isMuted
                hasNotifications
                index
                count
                (Dom.id ("guild_viewThread_" ++ Id.toString channelId ++ "_" ++ Id.toString threadMessageIndex))
                (GuildRoute
                    guildId
                    (ChannelRoute channelId (ViewThreadWithFriends threadMessageIndex Nothing HideChannelSettings) Nothing)
                    ChannelsHiddenOnMobile
                )
                (threadPreviewText localUser.timezone (User.allUsers localUser) threadMessageIndex localUser.decryptedMessages channel)
        )
        threads2
        |> Ui.column []


channelColumnThreadsHelper :
    Bool
    -> Bool
    -> IsMuted
    -> ChannelNotificationType
    -> Int
    -> Int
    -> HtmlId
    -> Route
    -> String
    -> Element FrontendMsg_
channelColumnThreadsHelper isMobile isSelected isMuted hasNotifications index visibleThreadCount htmlId route name =
    GuildColumn.rowLinkButton
        htmlId
        route
        [ Ui.paddingWith { left = 28, right = 8, top = 0, bottom = 0 }
        , Ui.el
            [ (if isSelected && not isMobile then
                NoNotification

               else
                hasNotifications
              )
                |> GuildIcon.notificationView 4 5 MyUi.background2
            , Ui.move { x = 0, y = 0, z = 0 }
            , Ui.Font.color MyUi.font3
            , Ui.width Ui.shrink
            ]
            (Ui.html
                (if visibleThreadCount == 1 then
                    Icons.threadSingleSegment

                 else if visibleThreadCount - 1 == index then
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
        , Ui.attrIf isSelected (Ui.background MyUi.selectedHighlight)
        , Ui.clipWithEllipsis
        , Ui.height (Ui.px MyUi.channelHeaderHeight)
        , MyUi.hoverText name
        , Ui.contentCenterY
        , MyUi.noShrinking
        ]
        [ Ui.text name
        , channelIsMuted isMuted
        ]


discordChannelColumnThreads :
    Bool
    -> Time.Posix
    -> DiscordGuildRouteData
    -> Maybe (NonemptyDict ( Discord.Id Discord.ChannelId, ThreadRoute ) OneOrGreater)
    -> LocalUser
    -> Discord.Id Discord.ChannelId
    -> DiscordFrontendChannel
    -> SeqDict (Id ChannelMessageId) DiscordFrontendThread
    -> Element FrontendMsg_
discordChannelColumnThreads isMobile now routeData directMentions localUser channelId channel threads =
    let
        threads2 : List ( Id ChannelMessageId, ( IsMuted, ChannelNotificationType ), Bool )
        threads2 =
            List.filterMap
                (\( threadMessageIndex, thread ) ->
                    let
                        isSelected : Bool
                        isSelected =
                            case routeData.channelRoute of
                                DiscordChannel_ChannelRoute a (ViewThreadWithFriends b _ _) _ ->
                                    a == channelId && b == threadMessageIndex

                                _ ->
                                    False

                        isMuted =
                            MuteSettings.isDiscordChannelMuted
                                localUser.user.muteSettings
                                routeData.guildId
                                channelId
                                (ViewThread threadMessageIndex)

                        hasNotifications : ChannelNotificationType
                        hasNotifications =
                            GuildColumn.channelOrThreadHasNotifications
                                isMuted
                                directMentions
                                (SeqSet.member routeData.guildId localUser.user.discordNotifyOnAllMessages)
                                channelId
                                (ViewThread threadMessageIndex)
                                (SeqDict.get
                                    ( DiscordGuildOrDmId (DiscordGuildOrDmId_Guild { currentUserId = routeData.currentDiscordUserId, guildId = routeData.guildId, channelId = channelId })
                                    , threadMessageIndex
                                    )
                                    localUser.user.lastViewedThreadMessage
                                )
                                thread
                    in
                    case ( hasNotifications, isSelected, MessageArray.last thread.messages ) of
                        ( NoNotification, False, Just message ) ->
                            if Duration.from (Message.createdAt message) now |> Quantity.lessThan Duration.week then
                                Just ( threadMessageIndex, ( isMuted, hasNotifications ), isSelected )

                            else
                                Nothing

                        _ ->
                            Just ( threadMessageIndex, ( isMuted, hasNotifications ), isSelected )
                )
                (SeqDict.toList threads)

        count : Int
        count =
            List.length threads2
    in
    List.indexedMap
        (\index ( threadMessageIndex, ( isMuted, hasNotifications ), isSelected ) ->
            channelColumnThreadsHelper
                isMobile
                isSelected
                isMuted
                hasNotifications
                index
                count
                (Dom.id ("guild_viewThread_" ++ Discord.idToString channelId ++ "_" ++ Id.toString threadMessageIndex))
                (DiscordGuildRoute
                    { currentDiscordUserId = routeData.currentDiscordUserId
                    , guildId = routeData.guildId
                    , channelRoute =
                        DiscordChannel_ChannelRoute
                            channelId
                            (ViewThreadWithFriends threadMessageIndex Nothing HideChannelSettings)
                            Nothing
                    , channelsVisible = ChannelsHiddenOnMobile
                    }
                )
                (threadPreviewText localUser.timezone (LinkedAndOtherDiscordUsers.allDiscordUsers localUser.discordUsers) threadMessageIndex SeqDict.empty channel)
        )
        threads2
        |> Ui.column []


channelColumnRow :
    Bool
    -> IsMuted
    -> ChannelNotificationType
    -> ChannelRoute
    -> Id GuildId
    -> Id ChannelId
    -> FrontendChannel
    -> Element FrontendMsg_
channelColumnRow isMobile isMuted hasNotification channelRoute guildId channelId channel =
    let
        isSelected : Bool
        isSelected =
            case channelRoute of
                ChannelRoute a (NoThreadWithFriends _ _) _ ->
                    a == channelId

                _ ->
                    False
    in
    GuildColumn.rowLinkButton
        (Dom.id ("guild_openChannel_" ++ Id.toString channelId))
        (GuildRoute
            guildId
            (ChannelRoute channelId (NoThreadWithFriends Nothing HideChannelSettings) Nothing)
            ChannelsHiddenOnMobile
        )
        [ Ui.paddingWith { left = 26, right = 8, top = 0, bottom = 0 }
        , Ui.el
            [ (if isSelected && not isMobile then
                NoNotification

               else
                hasNotification
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
        , Ui.attrIf isSelected (Ui.background MyUi.selectedHighlight)
        , Ui.clipWithEllipsis
        , Ui.height (Ui.px MyUi.channelHeaderHeight)
        , MyUi.hoverText (ChannelName.toString channel.name)
        , Ui.contentCenterY
        , MyUi.noShrinking
        ]
        [ Ui.text (ChannelName.toString channel.name)
        , channelIsMuted isMuted
        ]


channelIsMuted : IsMuted -> Element msg
channelIsMuted isMuted =
    case isMuted of
        IsMuted ->
            Ui.el
                [ MyUi.noShrinking
                , Ui.paddingWith { left = 0, right = 0, top = 0, bottom = 0 }
                , Ui.alignRight
                ]
                (Ui.html Icons.bellSlash)

        IsNotMuted ->
            Ui.none


discordChannelColumnRow :
    Bool
    -> IsMuted
    -> ChannelNotificationType
    -> DiscordGuildRouteData
    -> Discord.Id Discord.ChannelId
    -> DiscordFrontendChannel
    -> Element FrontendMsg_
discordChannelColumnRow isMobile isMuted hasNotifications routeData channelId channel =
    let
        isSelected : Bool
        isSelected =
            case routeData.channelRoute of
                DiscordChannel_ChannelRoute a (NoThreadWithFriends _ _) _ ->
                    a == channelId

                _ ->
                    False
    in
    GuildColumn.rowLinkButton
        (Dom.id ("guild_openChannel_" ++ Discord.idToString channelId))
        (DiscordGuildRoute
            { currentDiscordUserId = routeData.currentDiscordUserId
            , guildId = routeData.guildId
            , channelRoute =
                DiscordChannel_ChannelRoute
                    channelId
                    (NoThreadWithFriends Nothing HideChannelSettings)
                    Nothing
            , channelsVisible = ChannelsHiddenOnMobile
            }
        )
        [ Ui.paddingWith
            { left = 26
            , right = 8
            , top = 0
            , bottom = 0
            }
        , Ui.el
            [ (if isSelected && not isMobile then
                NoNotification

               else
                hasNotifications
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
        , Ui.attrIf isSelected (Ui.background MyUi.selectedHighlight)
        , Ui.clipWithEllipsis
        , Ui.height (Ui.px MyUi.channelHeaderHeight)
        , MyUi.hoverText (ChannelName.toString channel.name)
        , Ui.contentCenterY
        , MyUi.noShrinking
        ]
        [ Ui.text (ChannelName.toString channel.name)
        , channelIsMuted isMuted
        ]


friendsColumnLazy :
    Bool
    -> Bool
    -> Time.Posix
    -> DmChannelSelection
    -> String
    -> Bool
    -> LocalState
    -> Element FrontendMsg_
friendsColumnLazy canScroll2 isMobile currentTime openedOtherUserId friendsSearch friendsSearchHasFocus local =
    let
        currentTimeRoundedToMinute : Int
        currentTimeRoundedToMinute =
            Time.posixToMillis currentTime // msInMinute |> (*) msInMinute

        packed : Int
        packed =
            encodeFriendsColumn canScroll2 currentTimeRoundedToMinute
    in
    if (friendsSearch /= "") || friendsSearchHasFocus then
        -- The search text changes too often for laziness to be worth it here
        friendsColumn
            canScroll2
            isMobile
            currentTimeRoundedToMinute
            friendsSearch
            friendsSearchHasFocus
            openedOtherUserId
            local.dmChannels
            local.discordDmChannels
            local.localUser

    else
        case openedOtherUserId of
            NoDmChannelSelected ->
                Ui.Lazy.lazy5
                    friendsColumn_NoDmChannelSelected
                    packed
                    isMobile
                    local.dmChannels
                    local.discordDmChannels
                    local.localUser

            SelectedDmChannel dmRouteData ->
                Ui.Lazy.lazy5
                    (if isMobile then
                        friendsColumn_SelectedDmChannel_Mobile

                     else
                        friendsColumn_SelectedDmChannel_NotMobile
                    )
                    packed
                    dmRouteData
                    local.dmChannels
                    local.discordDmChannels
                    local.localUser

            SelectedDiscordDmChannel discordDmRouteData ->
                Ui.Lazy.lazy5
                    (if isMobile then
                        friendsColumn_SelectedDiscordDmChannel_Mobile

                     else
                        friendsColumn_SelectedDiscordDmChannel_NotMobile
                    )
                    packed
                    discordDmRouteData
                    local.dmChannels
                    local.discordDmChannels
                    local.localUser


friendsColumn_NoDmChannelSelected : Int -> Bool -> SeqDict (Id UserId) FrontendDmChannel -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel -> LocalUser -> Element FrontendMsg_
friendsColumn_NoDmChannelSelected packed isMobile dmChannels discordDmChannels localUser =
    let
        { canScroll, time } =
            decodeFriendsColumn packed
    in
    friendsColumn canScroll isMobile time "" False NoDmChannelSelected dmChannels discordDmChannels localUser


friendsColumn_SelectedDiscordDmChannel_Mobile : Int -> DiscordDmRouteData -> SeqDict (Id UserId) FrontendDmChannel -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel -> LocalUser -> Element FrontendMsg_
friendsColumn_SelectedDiscordDmChannel_Mobile packed discordDmRoute dmChannels discordDmChannels localUser =
    let
        { canScroll, time } =
            decodeFriendsColumn packed
    in
    friendsColumn canScroll True time "" False (SelectedDiscordDmChannel discordDmRoute) dmChannels discordDmChannels localUser


friendsColumn_SelectedDiscordDmChannel_NotMobile : Int -> DiscordDmRouteData -> SeqDict (Id UserId) FrontendDmChannel -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel -> LocalUser -> Element FrontendMsg_
friendsColumn_SelectedDiscordDmChannel_NotMobile packed discordDmRoute dmChannels discordDmChannels localUser =
    let
        { canScroll, time } =
            decodeFriendsColumn packed
    in
    friendsColumn canScroll False time "" False (SelectedDiscordDmChannel discordDmRoute) dmChannels discordDmChannels localUser


friendsColumn_SelectedDmChannel_Mobile : Int -> DmRouteData -> SeqDict (Id UserId) FrontendDmChannel -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel -> LocalUser -> Element FrontendMsg_
friendsColumn_SelectedDmChannel_Mobile packed dmRoute dmChannels discordDmChannels localUser =
    let
        { canScroll, time } =
            decodeFriendsColumn packed
    in
    friendsColumn canScroll True time "" False (SelectedDmChannel dmRoute) dmChannels discordDmChannels localUser


friendsColumn_SelectedDmChannel_NotMobile : Int -> DmRouteData -> SeqDict (Id UserId) FrontendDmChannel -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel -> LocalUser -> Element FrontendMsg_
friendsColumn_SelectedDmChannel_NotMobile packed dmRoute dmChannels discordDmChannels localUser =
    let
        { canScroll, time } =
            decodeFriendsColumn packed
    in
    friendsColumn canScroll False time "" False (SelectedDmChannel dmRoute) dmChannels discordDmChannels localUser


friendsColumn :
    Bool
    -> Bool
    -> Int
    -> String
    -> Bool
    -> DmChannelSelection
    -> SeqDict (Id UserId) FrontendDmChannel
    -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel
    -> LocalUser
    -> Element FrontendMsg_
friendsColumn canScroll2 isMobile currentTime friendsSearch friendsSearchHasFocus dmChannelSelection dmChannels discordDmChannels localUser =
    let
        dmChannelsIncludingCurrentUser : SeqDict (Id UserId) FrontendDmChannel
        dmChannelsIncludingCurrentUser =
            SeqDict.update
                localUser.session.userId
                (\maybe -> Maybe.withDefault DmChannel.frontendInit maybe |> Just)
                dmChannels

        discordDmChannelsIncludingLinkedUsers : SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel
        discordDmChannelsIncludingLinkedUsers =
            discordDmChannels

        searchIsVisible : Bool
        searchIsVisible =
            friendsSearchHasFocus || (friendsSearch /= "")

        searchFilter : String
        searchFilter =
            String.trim friendsSearch |> String.toLower

        matchesSearch : PersonName -> Bool
        matchesSearch name =
            String.contains searchFilter (String.toLower (PersonName.toString name))

        columnItems =
            List.filterMap
                (\( otherUserId, dmChannel ) ->
                    case User.getUser otherUserId localUser of
                        Just otherUser ->
                            if matchesSearch otherUser.name then
                                let
                                    -- The route being viewed in this DM, or Nothing when the
                                    -- open DM belongs to somebody else
                                    threadRoute : Maybe ThreadRouteWithFriends
                                    threadRoute =
                                        case dmChannelSelection of
                                            SelectedDmChannel dmRoute ->
                                                if DmChannelId.otherUserId localUser.session.userId dmRoute.channelId == Just otherUserId then
                                                    Just dmRoute.threadRoute

                                                else
                                                    Nothing

                                            SelectedDiscordDmChannel _ ->
                                                Nothing

                                            NoDmChannelSelected ->
                                                Nothing
                                in
                                ( case MessageArray.last dmChannel.messages of
                                    Just message2 ->
                                        Message.createdAt message2

                                    _ ->
                                        Time.millisToPosix 0
                                , Ui.column
                                    []
                                    [ Ui.Lazy.lazy5
                                        (if isMobile then
                                            friendLabelMobile

                                         else
                                            friendLabelNotMobile
                                        )
                                        (encodeFriendLabel
                                            (case threadRoute of
                                                Just (NoThreadWithFriends _ _) ->
                                                    True

                                                _ ->
                                                    False
                                            )
                                            currentTime
                                        )
                                        localUser
                                        otherUserId
                                        otherUser
                                        dmChannel
                                    , dmColumnThreads
                                        isMobile
                                        (Time.millisToPosix currentTime)
                                        threadRoute
                                        localUser
                                        otherUserId
                                        dmChannel
                                        (case threadRoute of
                                            -- A thread that was just opened isn't in the local
                                            -- state yet but still belongs in the list
                                            Just (ViewThreadWithFriends threadMessageIndex _ _) ->
                                                SeqDict.insert threadMessageIndex Thread.frontendInit dmChannel.threads

                                            _ ->
                                                dmChannel.threads
                                        )
                                    ]
                                )
                                    |> Just

                            else
                                Nothing

                        Nothing ->
                            Nothing
                )
                (SeqDict.toList dmChannelsIncludingCurrentUser)
                ++ List.filterMap
                    (\( channelId, dmChannel ) ->
                        if
                            (searchFilter == "")
                                || List.any
                                    (\( userId, _ ) ->
                                        case User.getDiscordUser userId localUser of
                                            Just discordUser ->
                                                matchesSearch discordUser.name

                                            Nothing ->
                                                False
                                    )
                                    (NonemptyDict.toList dmChannel.members)
                        then
                            ( case MessageArray.last dmChannel.messages of
                                Just message2 ->
                                    Message.createdAt message2

                                _ ->
                                    Time.millisToPosix 0
                            , Ui.Lazy.lazy5
                                (if isMobile then
                                    discordFriendLabelMobile

                                 else
                                    discordFriendLabelNotMobile
                                )
                                currentTime
                                (case dmChannelSelection of
                                    SelectedDiscordDmChannel routeData ->
                                        routeData.channelId == channelId

                                    _ ->
                                        False
                                )
                                channelId
                                dmChannel
                                localUser
                            )
                                |> Just

                        else
                            Nothing
                    )
                    (SeqDict.toList discordDmChannelsIncludingLinkedUsers)
    in
    channelColumnContainer
        [ Ui.el
            [ Ui.height Ui.fill
            , -- The search input is always in the DOM, invisible and covering the magnifying glass
              -- icon so that clicking the icon focuses it. It has to stay in the DOM while hidden
              -- because recreating it on press would drop the browser focus that reveals it.
              Ui.inFront
                (Ui.row
                    [ Ui.height Ui.fill ]
                    [ Ui.Input.text
                        (Ui.id (Dom.idToString friendsSearchInputId)
                            :: (if searchIsVisible then
                                    [ Ui.background MyUi.background2
                                    , Ui.border 0
                                    , Ui.rounded 4
                                    , Ui.paddingXY 8 4
                                    , Ui.Font.color MyUi.font1
                                    , Ui.centerY
                                    ]

                                else
                                    [ Ui.opacity 0
                                    , Ui.border 0
                                    , Ui.width (Ui.px 40)
                                    , Ui.alignRight
                                    , Ui.height Ui.fill
                                    , Ui.pointer
                                    ]
                               )
                        )
                        { onChange = TypedFriendsSearch
                        , text = friendsSearch
                        , placeholder =
                            if searchIsVisible then
                                Just "Filter friends"

                            else
                                Nothing
                        , label = Ui.Input.labelHidden (Dom.idToString friendsSearchInputId)
                        }
                    , if searchIsVisible then
                        MyUi.elButton
                            (Dom.id "guild_clearFriendsSearch")
                            PressedClearFriendsSearch
                            [ Ui.Font.color MyUi.font2
                            , Ui.width (Ui.px 40)
                            , Ui.paddingXY 8 0
                            , Ui.height Ui.fill
                            , Ui.contentCenterY
                            , MyUi.hoverText "Clear search"
                            ]
                            (Ui.html Icons.x)

                      else
                        Ui.none
                    ]
                )
            ]
            (Ui.row
                [ Ui.height Ui.fill
                , Ui.attrIf searchIsVisible (Ui.opacity 0)
                ]
                [ Ui.el
                    [ Ui.Font.bold
                    , Ui.paddingXY 8 8
                    , Ui.Font.color MyUi.font1
                    ]
                    (Ui.text directMessagesText)
                , Ui.el
                    [ Ui.Font.color MyUi.font2
                    , Ui.width (Ui.px 40)
                    , Ui.alignRight
                    , Ui.paddingXY 8 0
                    , Ui.height Ui.fill
                    , Ui.contentCenterY
                    ]
                    (Ui.html Icons.magnifyingGlass)
                ]
            )
        ]
        Ui.none
        (case columnItems of
            [] ->
                Ui.Prose.paragraph
                    [ Ui.Font.italic
                    , Ui.Font.lineHeight 1.5
                    , Ui.paddingXY 16 20
                    ]
                    [ Ui.text "No results found for "
                    , Ui.el [ Ui.Font.bold ] (Ui.text friendsSearch)
                    ]

            _ ->
                List.sortBy (\( time, _ ) -> Time.posixToMillis time |> negate) columnItems
                    |> List.map Tuple.second
                    |> Ui.column [ MyUi.scrollable canScroll2, Ui.heightMin 0 ]
        )


friendsSearchInputId : HtmlId
friendsSearchInputId =
    Dom.id "guild_friendsSearchInput"


friendLabelMobile :
    Int
    -> LocalUser
    -> Id UserId
    -> FrontendUser
    -> FrontendDmChannel
    -> Element FrontendMsg_
friendLabelMobile packed localUser otherUserId otherUser channel =
    let
        { isSelected, time } =
            decodeFriendLabel packed
    in
    friendLabel True time isSelected localUser otherUserId otherUser channel


friendLabelNotMobile :
    Int
    -> LocalUser
    -> Id UserId
    -> FrontendUser
    -> FrontendDmChannel
    -> Element FrontendMsg_
friendLabelNotMobile packed localUser otherUserId otherUser channel =
    let
        { isSelected, time } =
            decodeFriendLabel packed
    in
    friendLabel False time isSelected localUser otherUserId otherUser channel


type SomeoneIsTyping
    = SomeoneIsTyping
    | SomeoneIsEditing
    | NoOneIsTyping


someoneIsTyping : Time.Posix -> SeqDict userId (LastTypedAt messageId) -> SomeoneIsTyping
someoneIsTyping time lastTypedAt =
    SeqDict.foldl
        (\_ a state ->
            case state of
                SomeoneIsTyping ->
                    state

                _ ->
                    if Duration.from a.time time |> Quantity.lessThan (Quantity.plus Duration.second typingDebouncerDelay) then
                        case a.messageIndex of
                            Just _ ->
                                SomeoneIsEditing

                            Nothing ->
                                SomeoneIsTyping

                    else
                        state
        )
        NoOneIsTyping
        lastTypedAt


friendLabel :
    Bool
    -> Time.Posix
    -> Bool
    -> LocalUser
    -> Id UserId
    -> FrontendUser
    -> FrontendDmChannel
    -> Element FrontendMsg_
friendLabel isMobile time isSelected localUser otherUserId otherUser channel =
    let
        allUsers : SeqDict (Id UserId) FrontendUser
        allUsers =
            User.allUsers localUser

        decrypted : SeqDict BytesHash (Result () (ContentAndEmbeds (Id UserId)))
        decrypted =
            localUser.decryptedMessages

        message : Maybe (Message ChannelMessageId (Id UserId))
        message =
            MessageArray.last channel.messages

        messagePreview : String
        messagePreview =
            case someoneIsTyping time (SeqDict.remove localUser.session.userId channel.lastTypedAt) of
                SomeoneIsTyping ->
                    typingText

                SomeoneIsEditing ->
                    editingText

                NoOneIsTyping ->
                    case message of
                        Just message2 ->
                            case message2 of
                                UserTextMessage a ->
                                    (if a.createdBy == localUser.session.userId then
                                        "You: "

                                     else
                                        ""
                                    )
                                        ++ RichText.toString localUser.timezone True allUsers a.content

                                EncryptedUserTextMessage a ->
                                    (if a.createdBy == localUser.session.userId then
                                        "You: "

                                     else
                                        ""
                                    )
                                        ++ (case SeqDict.get (Encryption.hash a.encryptedData) decrypted of
                                                Just result ->
                                                    RichText.toString
                                                        localUser.timezone
                                                        True
                                                        allUsers
                                                        (case result of
                                                            Ok ok ->
                                                                ok.content

                                                            Err () ->
                                                                RichText.failedToDecryptMessage
                                                        )

                                                Nothing ->
                                                    ""
                                           )

                                UserJoinedMessage _ userId _ _ ->
                                    User.toString userId allUsers
                                        ++ " joined!"

                                DeletedMessage _ ->
                                    LocalState.messageDeleted

                                CallStarted { endedAt } ->
                                    LocalState.callStartedText endedAt

                                GameStarted { gameType } ->
                                    LocalState.gameStartedText gameType

                        Nothing ->
                            ""
    in
    GuildColumn.rowLinkButton
        (Dom.id ("guild_friendLabel_" ++ Id.toString otherUserId))
        (Route.DmRoute
            { channelId = DmChannelId.fromUserIds localUser.session.userId otherUserId
            , threadRoute = NoThreadWithFriends Nothing HideChannelSettings
            , tab = Nothing
            , channelsVisible = ChannelsHiddenOnMobile
            }
        )
        [ Ui.clipWithEllipsis
        , Ui.spacing 8
        , Ui.padding 4
        , MyUi.hoverText messagePreview
        , Ui.Font.color
            (if isSelected then
                MyUi.font1

             else
                MyUi.font3
            )
        , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
        , Ui.attrIf isSelected (Ui.background MyUi.selectedHighlight)
        ]
        [ User.profileImage (Just otherUser)
        , Ui.column
            []
            [ Ui.el [ Ui.Font.bold ] (Ui.text (PersonName.toString otherUser.name))
            , friendLabelMessagePreview time messagePreview message
            ]
        ]


friendLabelMessagePreview : Time.Posix -> String -> Maybe (Message messageId userId) -> Element msg
friendLabelMessagePreview time messagePreview message =
    Ui.row
        [ Ui.Font.size 13, Ui.spacing 4 ]
        [ Ui.el [] (Ui.text messagePreview)
        , case message of
            Just message2 ->
                MyUi.timeElapsedShort time (Message.createdAt message2)
                    |> Ui.text
                    |> Ui.el [ Ui.alignRight, Ui.opacity 0.7 ]

            Nothing ->
                Ui.none
        ]


discordFriendLabelMobile :
    Int
    -> Bool
    -> Discord.Id Discord.PrivateChannelId
    -> DiscordFrontendDmChannel
    -> LocalUser
    -> Element FrontendMsg_
discordFriendLabelMobile time isSelected dmChannelId channel localUser =
    discordFriendLabel True (Time.millisToPosix time) isSelected dmChannelId channel localUser


discordFriendLabelNotMobile :
    Int
    -> Bool
    -> Discord.Id Discord.PrivateChannelId
    -> DiscordFrontendDmChannel
    -> LocalUser
    -> Element FrontendMsg_
discordFriendLabelNotMobile time isSelected dmChannelId channel localUser =
    discordFriendLabel False (Time.millisToPosix time) isSelected dmChannelId channel localUser


discordFriendLabel :
    Bool
    -> Time.Posix
    -> Bool
    -> Discord.Id Discord.PrivateChannelId
    -> DiscordFrontendDmChannel
    -> LocalUser
    -> Element FrontendMsg_
discordFriendLabel isMobile time isSelected dmChannelId channel localUser =
    let
        message : Maybe (Message ChannelMessageId (Discord.Id Discord.UserId))
        message =
            MessageArray.last channel.messages

        messagePreview : String
        messagePreview =
            case someoneIsTyping time (SeqDict.diff channel.lastTypedAt (LinkedAndOtherDiscordUsers.linkedUsers localUser.discordUsers)) of
                SomeoneIsTyping ->
                    typingText

                SomeoneIsEditing ->
                    editingText

                NoOneIsTyping ->
                    case message of
                        Just message2 ->
                            case message2 of
                                UserTextMessage a ->
                                    (if LinkedAndOtherDiscordUsers.isLinkedUser a.createdBy localUser.discordUsers then
                                        "You: "

                                     else
                                        ""
                                    )
                                        ++ RichText.toString
                                            localUser.timezone
                                            True
                                            (LinkedAndOtherDiscordUsers.allDiscordUsers localUser.discordUsers)
                                            a.content

                                EncryptedUserTextMessage a ->
                                    if LinkedAndOtherDiscordUsers.isLinkedUser a.createdBy localUser.discordUsers then
                                        "You: " ++ RichText.failedToDecryptMessageText

                                    else
                                        RichText.failedToDecryptMessageText

                                UserJoinedMessage _ userId _ _ ->
                                    User.toString
                                        userId
                                        (LinkedAndOtherDiscordUsers.allDiscordUsers localUser.discordUsers)
                                        ++ " joined!"

                                DeletedMessage _ ->
                                    LocalState.messageDeleted

                                CallStarted { endedAt } ->
                                    LocalState.callStartedText endedAt

                                GameStarted { gameType } ->
                                    LocalState.gameStartedText gameType

                        Nothing ->
                            ""

        maybeCurrentUserId : Maybe (Discord.Id Discord.UserId)
        maybeCurrentUserId =
            List.Extra.findMap
                (\( userId, _ ) ->
                    if NonemptyDict.member userId channel.members then
                        Just userId

                    else
                        Nothing
                )
                (SeqDict.toList (LinkedAndOtherDiscordUsers.linkedUsers localUser.discordUsers))
    in
    case maybeCurrentUserId of
        Just currentUserId ->
            let
                members2 : List (Discord.Id Discord.UserId)
                members2 =
                    NonemptyDict.remove currentUserId channel.members |> SeqDict.keys

                notification : ChannelNotificationType
                notification =
                    if isSelected then
                        NoNotification

                    else
                        case GuildColumn.discordDmHasNotifications localUser dmChannelId channel of
                            Just ( _, count ) ->
                                NewMessageForUser count

                            Nothing ->
                                NoNotification
            in
            MyUi.rowButton
                ("guild_discordFriendLabel_" ++ Discord.idToString dmChannelId |> Dom.id)
                (PressedLink
                    (DiscordDmRoute
                        { currentDiscordUserId = currentUserId
                        , channelId = dmChannelId
                        , viewingMessage = Nothing
                        , showMembersTab = HideChannelSettings
                        , tab = Nothing
                        , channelsVisible = ChannelsHiddenOnMobile
                        }
                    )
                )
                [ Ui.clipWithEllipsis
                , Ui.spacing 8
                , MyUi.hoverText messagePreview
                , Ui.padding 4
                , Ui.Font.color
                    (if isSelected then
                        MyUi.font1

                     else
                        MyUi.font3
                    )
                , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
                , Ui.attrIf isSelected (Ui.background MyUi.selectedHighlight)
                ]
                (case members2 of
                    [] ->
                        case User.getDiscordUser currentUserId localUser of
                            Just otherUser ->
                                [ Ui.el
                                    [ GuildIcon.discordNotificationView 4 -3 notification
                                    , Ui.width Ui.shrink
                                    ]
                                    (User.discordProfileImage currentUserId otherUser.icon)
                                , Ui.column
                                    []
                                    [ Ui.el [ Ui.Font.bold ] (Ui.text (PersonName.toString otherUser.name))
                                    , friendLabelMessagePreview time messagePreview message
                                    ]
                                ]

                            Nothing ->
                                []

                    rest ->
                        [ List.filterMap
                            (\userId ->
                                case User.getDiscordUser userId localUser of
                                    Just user ->
                                        Just ( userId, user.icon )

                                    Nothing ->
                                        Nothing
                            )
                            members2
                            |> User.multipleProfileImages
                            |> Ui.el
                                [ GuildIcon.discordNotificationView 4 -3 notification
                                , Ui.width Ui.shrink
                                ]
                        , Ui.column
                            []
                            [ List.filterMap
                                (\userId ->
                                    case User.getDiscordUser userId localUser of
                                        Just otherUser ->
                                            PersonName.toString otherUser.name |> Just

                                        Nothing ->
                                            Nothing
                                )
                                rest
                                |> String.join ", "
                                |> Ui.text
                                |> Ui.el [ Ui.Font.bold ]
                            , friendLabelMessagePreview time messagePreview message
                            ]
                        ]
                )

        Nothing ->
            Ui.text "Something went wrong"


newChannelFormInit : NewChannelForm
newChannelFormInit =
    { name = "", description = "", pressedSubmit = False }


newGuildFormInit : NewGuildForm
newGuildFormInit =
    { name = "", pressedSubmit = False }


editChannelFormInit : FrontendChannel -> EditChannelForm
editChannelFormInit channel =
    { name = ChannelName.toString channel.name
    , description = ChannelDescription.toString channel.description
    , deleteConfirmation = ""
    , showDeleteConfirmation = False
    , pressedSubmit = False
    }


deleteConfirmationInput : String -> EditChannelForm -> Element EditChannelForm
deleteConfirmationInput channelNameString form =
    let
        confirmLabel =
            Ui.Input.label
                "deleteChannelConfirmation"
                [ Ui.Font.color MyUi.font2, Ui.paddingXY 2 0 ]
                (Ui.text ("Type \"" ++ channelNameString ++ "\" to confirm deletion"))
    in
    Ui.column
        []
        [ confirmLabel.element
        , Ui.Input.text
            [ Ui.padding 6
            , Ui.background MyUi.inputBackground
            , Ui.borderColor MyUi.inputBorder
            , Ui.widthMax 500
            ]
            { onChange = \text -> { form | deleteConfirmation = text }
            , text = form.deleteConfirmation
            , placeholder = Nothing
            , label = confirmLabel.id
            }
        ]


newChannelFormView : Bool -> Id GuildId -> NewChannelForm -> Element FrontendMsg_
newChannelFormView isMobile2 guildId form =
    Ui.column
        [ Ui.Font.color MyUi.font1, Ui.alignTop ]
        [ ChannelHeader.channelHeader isMobile2 (Ui.text "Create new channel") Nothing
        , Ui.column
            [ Ui.spacing 16, Ui.padding 16 ]
            [ channelNameInput form |> Ui.map (NewChannelFormChanged guildId)
            , channelDescriptionInput form |> Ui.map (NewChannelFormChanged guildId)
            , submitButton (Dom.id "guild_createChannel") (PressedSubmitNewChannel guildId form) "Create channel"
            ]
        ]


submitButton : HtmlId -> msg -> String -> Element msg
submitButton htmlId onPress text =
    MyUi.elButton
        htmlId
        onPress
        [ Ui.paddingXY 16 4
        , Ui.background MyUi.buttonBackground
        , Ui.width Ui.shrink
        , Ui.rounded 4
        , Ui.Font.weight 500
        , Ui.borderColor MyUi.buttonBorder
        , Ui.border 1
        ]
        (Ui.text text)


submitButtonWide : HtmlId -> msg -> String -> Element msg
submitButtonWide htmlId onPress text =
    MyUi.elButton
        htmlId
        onPress
        [ Ui.paddingXY 8 4
        , Ui.background MyUi.buttonBackground
        , Ui.Font.center
        , Ui.rounded 4
        , Ui.Font.weight 500
        , Ui.borderColor MyUi.buttonBorder
        , Ui.border 1
        ]
        (Ui.text text)


channelNameInput : { a | name : String, pressedSubmit : Bool } -> Element { a | name : String, pressedSubmit : Bool }
channelNameInput form =
    let
        nameLabel =
            Ui.Input.label
                "newChannelName"
                [ Ui.Font.color MyUi.font2, Ui.paddingXY 2 0 ]
                (Ui.text "Name")
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


channelDescriptionInput : { a | description : String, pressedSubmit : Bool } -> Element { a | description : String, pressedSubmit : Bool }
channelDescriptionInput form =
    let
        descriptionLabel =
            Ui.Input.label
                "channelDescription"
                [ Ui.Font.color MyUi.font2, Ui.paddingXY 2 0 ]
                (Ui.text "Description")
    in
    Ui.column
        []
        [ descriptionLabel.element
        , Ui.Input.multiline
            [ Ui.padding 6
            , Ui.background MyUi.inputBackground
            , Ui.borderColor MyUi.inputBorder
            , Ui.widthMax 500
            ]
            { onChange = \text -> { form | description = text }
            , text = form.description
            , placeholder = Nothing
            , label = descriptionLabel.id
            , spellcheck = True
            }
        , case ( form.pressedSubmit, ChannelDescription.fromString form.description ) of
            ( True, Err error ) ->
                Ui.el [ Ui.paddingXY 2 0, Ui.Font.color MyUi.errorColor ] (Ui.text error)

            _ ->
                Ui.none
        ]


newGuildFormView : NewGuildForm -> Element FrontendMsg_
newGuildFormView form =
    Ui.column
        [ Ui.Font.color MyUi.font1
        , Ui.paddingXY 0 16
        , Ui.alignTop
        , Ui.spacing 16
        , Ui.height Ui.fill
        , Ui.background MyUi.background1
        , MyUi.htmlStyle "padding-top" MyUi.insetTop
        ]
        [ Ui.el [ Ui.Font.size 24, Ui.paddingXY 16 0 ] (Ui.text "Create new guild")
        , guildNameInput form |> Ui.map NewGuildFormChanged
        , Ui.row
            [ Ui.spacing 16, Ui.paddingXY 16 0 ]
            [ MyUi.secondaryButton
                (Dom.id "guild_cancelNewGuild")
                (PressedLink HomePageRoute)
                "Cancel"
            , submitButton (Dom.id "guild_createGuildSubmit") (PressedSubmitNewGuild form) "Create guild"
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
        [ Ui.paddingXY 16 0 ]
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


fileUploadPreview :
    (Id FileId -> msg)
    -> (Id FileId -> msg)
    -> ({ fileId : Id FileId, removeSpoiler : Bool } -> msg)
    -> Maybe (Nonempty (RichText userId))
    -> NonemptyDict (Id FileId) FileStatus
    -> Element msg
fileUploadPreview onPressDelete onPressInfo onPressSpoiler richText filesToUpload2 =
    Ui.row
        [ Ui.spacing 4
        , Ui.move { x = 0, y = -SheepGame.fileUploadPreviewSize, z = 0 }
        , Ui.width Ui.shrink
        , Ui.paddingXY 8 0
        ]
        (SheepGame.fileUploadPreview onPressDelete onPressInfo onPressSpoiler richText filesToUpload2)
