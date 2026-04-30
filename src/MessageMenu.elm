module MessageMenu exposing
    ( close
    , editMessageTextInputId
    , messageMenuSpeed
    , mobileMenuMaxHeight
    , mobileMenuOpeningOffset
    , view
    )

import Array exposing (Array)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Discord
import DmChannel
import Duration exposing (Seconds)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Emoji exposing (EmojiOrCustomEmoji(..))
import FileStatus
import Html exposing (Html)
import Icons
import Id exposing (AnyGuildOrDmId(..), CustomEmojiId, DiscordGuildOrDmId(..), GuildOrDmId(..), Id, ThreadRouteWithMessage(..), UserId)
import List.Nonempty exposing (Nonempty)
import LocalState exposing (LocalState)
import Message exposing (Message(..), MessageState(..))
import MessageInput
import MessageView
import MyUi
import NonemptySet exposing (NonemptySet)
import OneToOne
import PersonName exposing (PersonName)
import Quantity exposing (Quantity, Rate)
import RichText exposing (RichText)
import SeqDict exposing (SeqDict)
import SeqSet
import String.Nonempty
import Types exposing (EditMessage, FrontendMsg(..), LoadedFrontend, LoggedIn2, MessageHover(..), MessageHoverMobileMode(..), MessageMenuExtraOptions)
import Ui exposing (Element)
import Ui.Anim
import Ui.Font
import User


width : number
width =
    216


close : LoadedFrontend -> LoggedIn2 -> LoggedIn2
close model loggedIn =
    case loggedIn.messageHover of
        NoMessageHover ->
            loggedIn

        MessageHover _ _ ->
            loggedIn

        MessageMenu extraOptions ->
            let
                isMobile =
                    MyUi.isMobile model
            in
            { loggedIn
                | messageHover =
                    if isMobile then
                        { extraOptions
                            | mobileMode =
                                case extraOptions.mobileMode of
                                    MessageMenuClosing offset maybeEdit ->
                                        MessageMenuClosing offset maybeEdit

                                    MessageMenuOpening { offset } ->
                                        MessageMenuClosing offset (showEdit extraOptions loggedIn)

                                    MessageMenuDragging { offset } ->
                                        MessageMenuClosing offset (showEdit extraOptions loggedIn)

                                    MessageMenuFixed offset ->
                                        MessageMenuClosing offset (showEdit extraOptions loggedIn)
                        }
                            |> MessageMenu

                    else
                        NoMessageHover
                , editMessage =
                    if isMobile then
                        SeqDict.remove
                            ( extraOptions.guildOrDmId, Id.threadRouteWithoutMessage extraOptions.threadRoute )
                            loggedIn.editMessage

                    else
                        loggedIn.editMessage
            }


mobileMenuMaxHeight : MessageMenuExtraOptions -> LocalState -> LoadedFrontend -> Quantity Float CssPixels
mobileMenuMaxHeight extraOptions local model =
    menuItems True extraOptions.guildOrDmId extraOptions.threadRoute False Coord.origin local model
        |> List.length
        |> mobileMenuMaxHeightHelper
        |> CssPixels.cssPixels


mobileMenuMaxHeightHelper : Int -> Float
mobileMenuMaxHeightHelper itemCount =
    toFloat itemCount * buttonHeight True + toFloat itemCount - 1 + mobileCloseButton + topPadding + bottomPadding


mobileMenuOpeningOffset :
    AnyGuildOrDmId
    -> ThreadRouteWithMessage
    -> LocalState
    -> LoadedFrontend
    -> Quantity Float CssPixels
mobileMenuOpeningOffset guildOrDmId threadRoute local model =
    let
        itemCount : Float
        itemCount =
            menuItems True guildOrDmId threadRoute False Coord.origin local model |> List.length |> toFloat |> min 3.4
    in
    itemCount * buttonHeight True + itemCount - 1 + mobileCloseButton + topPadding + bottomPadding |> CssPixels.cssPixels


messageMenuSpeed : Quantity Float (Rate CssPixels Seconds)
messageMenuSpeed =
    Quantity.rate (CssPixels.cssPixels 800) Duration.second


desktopMenuHeightHelper : Int -> Int
desktopMenuHeightHelper itemCount =
    itemCount * buttonHeight False + 2 + desktopMenuPaddingTop + desktopMenuPaddingBottom


desktopMenuPaddingTop : number
desktopMenuPaddingTop =
    8


desktopMenuPaddingBottom : number
desktopMenuPaddingBottom =
    16


topPadding : number
topPadding =
    4


bottomPadding : number
bottomPadding =
    8


mobileCloseButton : number
mobileCloseButton =
    12


showEdit : MessageMenuExtraOptions -> LoggedIn2 -> Maybe EditMessage
showEdit extraOptions loggedIn =
    case
        SeqDict.get
            ( extraOptions.guildOrDmId, Id.threadRouteWithoutMessage extraOptions.threadRoute )
            loggedIn.editMessage
    of
        Just edit ->
            case extraOptions.threadRoute of
                ViewThreadWithMessage _ messageId ->
                    if edit.messageIndex == Id.changeType messageId then
                        Just edit

                    else
                        Nothing

                NoThreadWithMessage messageId ->
                    if edit.messageIndex == messageId then
                        Just edit

                    else
                        Nothing

        Nothing ->
            Nothing


showEditViewed : MessageMenuExtraOptions -> LoggedIn2 -> Maybe EditMessage
showEditViewed extraOptions loggedIn =
    case extraOptions.mobileMode of
        MessageMenuClosing _ maybeEditing ->
            maybeEditing

        MessageMenuOpening _ ->
            showEdit extraOptions loggedIn

        MessageMenuDragging _ ->
            showEdit extraOptions loggedIn

        MessageMenuFixed _ ->
            showEdit extraOptions loggedIn


viewMobile : Float -> MessageMenuExtraOptions -> LoggedIn2 -> LocalState -> LoadedFrontend -> Element FrontendMsg
viewMobile offset extraOptions loggedIn local model =
    let
        height : Int
        height =
            1000

        menuItems2 : List (Element FrontendMsg)
        menuItems2 =
            menuItems
                True
                extraOptions.guildOrDmId
                extraOptions.threadRoute
                extraOptions.isThreadStarter
                extraOptions.position
                local
                model
    in
    Ui.column
        [ Ui.move { x = 0, y = negate offset |> round |> (+) height, z = 0 }
        , Ui.roundedWith { topLeft = 16, topRight = 16, bottomRight = 0, bottomLeft = 0 }
        , Ui.background (Ui.rgb 0 0 0)
        , MyUi.htmlStyle
            "padding"
            (String.fromInt topPadding
                ++ "px 8px calc("
                ++ MyUi.insetBottom
                ++ " * 0.5 + "
                ++ String.fromInt bottomPadding
                ++ "px) 8px"
            )
        , MyUi.blockClickPropagation MessageMenu_PressedContainer
        , Ui.height (Ui.px height)
        ]
        (MyUi.elButton
            (Dom.id "messageMenu_close")
            MessageMenu_PressedClose
            [ Ui.height (Ui.px mobileCloseButton) ]
            (Ui.el
                [ Ui.background (Ui.rgb 40 50 60)
                , Ui.rounded 99
                , Ui.width (Ui.px 40)
                , Ui.height (Ui.px 4)
                , Ui.centerX
                , Ui.centerY
                ]
                Ui.none
            )
            :: (case showEditViewed extraOptions loggedIn of
                    Just edit ->
                        let
                            editView :
                                Int
                                -> Maybe (Nonempty (RichText userId))
                                -> SeqDict userId { b | name : PersonName }
                                -> Element MessageInput.Msg
                            editView charsLeft richText allUsers =
                                MessageInput.editView
                                    (Dom.id "messageMenu_editMobile")
                                    (mobileMenuMaxHeightHelper (List.length menuItems2) |> round |> (+) -32)
                                    True
                                    True
                                    editMessageTextInputId
                                    ""
                                    charsLeft
                                    edit.text
                                    richText
                                    (FileStatus.hasUploadingFile edit.attachedFiles)
                                    edit.attachedFiles
                                    local.localUser.customEmojis
                                    local.localUser.stickers
                                    loggedIn.textInputFocus
                                    allUsers
                        in
                        [ (case extraOptions.guildOrDmId of
                            GuildOrDmId _ ->
                                let
                                    allUsers =
                                        LocalState.allUsers local.localUser

                                    richText : Maybe (Nonempty (RichText (Id UserId)))
                                    richText =
                                        case String.Nonempty.fromString edit.text of
                                            Just nonempty ->
                                                RichText.fromNonemptyString allUsers nonempty |> Just

                                            Nothing ->
                                                Nothing
                                in
                                editView (RichText.maxLength - String.length edit.text) richText allUsers

                            DiscordGuildOrDmId _ ->
                                let
                                    allUsers =
                                        LocalState.allDiscordUsers local.localUser

                                    richText : Maybe (Nonempty (RichText (Discord.Id Discord.UserId)))
                                    richText =
                                        case String.Nonempty.fromString edit.text of
                                            Just nonempty ->
                                                RichText.fromNonemptyString allUsers nonempty |> Just

                                            Nothing ->
                                                Nothing
                                in
                                editView
                                    (RichText.discordCharsLeft
                                        -- Not providing a mapping between CustomEmojiId And Discord emoji IDs will make
                                        -- the count slightly wrong but hopefully not enough to matter.
                                        -- I don't think it's worth the added complexity to send the mapping to clients
                                        OneToOne.empty
                                        richText
                                    )
                                    richText
                                    allUsers
                          )
                            |> Ui.map
                                (EditMessage_MessageInputMsg
                                    extraOptions.guildOrDmId
                                    (Id.threadRouteWithoutMessage extraOptions.threadRoute)
                                )
                        ]

                    Nothing ->
                        List.intersperse
                            (Ui.el
                                [ Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
                                , Ui.borderColor MyUi.border2
                                ]
                                Ui.none
                            )
                            menuItems2
               )
        )


view : LoadedFrontend -> MessageMenuExtraOptions -> LocalState -> LoggedIn2 -> Element FrontendMsg
view model extraOptions local loggedIn =
    if MyUi.isMobile model then
        let
            offset =
                Types.messageMenuMobileOffset extraOptions.mobileMode
                    |> CssPixels.inCssPixels
        in
        Ui.el
            [ Ui.height Ui.fill
            , Ui.background (Ui.rgba 0 0 0 (0.3 * clamp 0 1 ((offset - 30) / 30)))
            , viewMobile offset extraOptions loggedIn local model |> Ui.below
            ]
            Ui.none

    else
        let
            menuItems2 : List (Element FrontendMsg)
            menuItems2 =
                menuItems
                    False
                    extraOptions.guildOrDmId
                    extraOptions.threadRoute
                    extraOptions.isThreadStarter
                    extraOptions.position
                    local
                    model

            height : Int
            height =
                desktopMenuHeightHelper (List.length menuItems2)

            x =
                Coord.xRaw extraOptions.position

            y =
                Coord.yRaw extraOptions.position
        in
        Ui.column
            [ Ui.move
                { x =
                    if width + x > Coord.xRaw model.windowSize then
                        x - width

                    else
                        x
                , y =
                    if height + y > Coord.yRaw model.windowSize then
                        y - height

                    else
                        y
                , z = 0
                }
            , Ui.background MyUi.background1
            , Ui.border 1
            , Ui.borderColor MyUi.border1
            , Ui.width (Ui.px width)
            , Ui.rounded 8
            , Ui.paddingWith { left = 8, right = 8, top = desktopMenuPaddingTop, bottom = desktopMenuPaddingBottom }
            , MyUi.blockClickPropagation MessageMenu_PressedContainer
            ]
            menuItems2


editMessageTextInputId : HtmlId
editMessageTextInputId =
    Dom.id "editMessageTextInput"


menuItems : Bool -> AnyGuildOrDmId -> ThreadRouteWithMessage -> Bool -> Coord CssPixels -> LocalState -> LoadedFrontend -> List (Element FrontendMsg)
menuItems isMobile guildOrDmId threadRoute isThreadStarter position local model =
    let
        helper : Id messageId -> { a | messages : Array (MessageState messageId (Id UserId)) } -> Maybe ( Bool, String, List (Id CustomEmojiId) )
        helper messageId thread =
            case DmChannel.getArray messageId thread.messages of
                Just (MessageLoaded message) ->
                    ( case message of
                        UserTextMessage data ->
                            data.createdBy == local.localUser.session.userId

                        _ ->
                            False
                    , LocalState.messageToString (LocalState.allUsers local.localUser) message
                    , messageCustomEmojiIds message
                    )
                        |> Just

                _ ->
                    Nothing

        discordHelper : Id messageId -> { a | messages : Array (MessageState messageId (Discord.Id Discord.UserId)) } -> Maybe ( Bool, String, List (Id CustomEmojiId) )
        discordHelper messageId thread =
            case DmChannel.getArray messageId thread.messages of
                Just (MessageLoaded message) ->
                    ( case message of
                        UserTextMessage data ->
                            SeqDict.member data.createdBy local.localUser.linkedDiscordUsers

                        _ ->
                            False
                    , LocalState.messageToString (LocalState.allDiscordUsers local.localUser) message
                    , messageCustomEmojiIds message
                    )
                        |> Just

                _ ->
                    Nothing

        maybeData : Maybe ( Bool, String, List (Id CustomEmojiId) )
        maybeData =
            case guildOrDmId of
                GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
                    case LocalState.getGuildAndChannel guildId channelId local of
                        Just ( _, channel ) ->
                            case threadRoute of
                                ViewThreadWithMessage threadMessageIndex messageId ->
                                    case SeqDict.get threadMessageIndex channel.threads of
                                        Just thread ->
                                            helper messageId thread

                                        Nothing ->
                                            Nothing

                                NoThreadWithMessage messageId ->
                                    helper messageId channel

                        Nothing ->
                            Nothing

                GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
                    case SeqDict.get otherUserId local.dmChannels of
                        Just dmChannel ->
                            case threadRoute of
                                ViewThreadWithMessage threadMessageIndex messageId ->
                                    case SeqDict.get threadMessageIndex dmChannel.threads of
                                        Just thread ->
                                            helper messageId thread

                                        Nothing ->
                                            Nothing

                                NoThreadWithMessage messageId ->
                                    helper messageId dmChannel

                        Nothing ->
                            Nothing

                DiscordGuildOrDmId (DiscordGuildOrDmId_Guild _ guildId channelId) ->
                    case LocalState.getDiscordGuildAndChannel guildId channelId local of
                        Just ( _, channel ) ->
                            case threadRoute of
                                ViewThreadWithMessage threadMessageIndex messageId ->
                                    case SeqDict.get threadMessageIndex channel.threads of
                                        Just thread ->
                                            discordHelper messageId thread

                                        Nothing ->
                                            Nothing

                                NoThreadWithMessage messageId ->
                                    discordHelper messageId channel

                        Nothing ->
                            Nothing

                DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data) ->
                    case SeqDict.get data.channelId local.discordDmChannels of
                        Just channel ->
                            case threadRoute of
                                ViewThreadWithMessage _ _ ->
                                    Nothing

                                NoThreadWithMessage messageId ->
                                    discordHelper messageId channel

                        Nothing ->
                            Nothing
    in
    case maybeData of
        Just ( canEditAndDelete, text, messageCustomEmojiIdsList ) ->
            let
                newCustomEmojiIds : Maybe (NonemptySet (Id CustomEmojiId))
                newCustomEmojiIds =
                    List.filter
                        (\id ->
                            SeqDict.member id local.localUser.customEmojis
                                && not (SeqSet.member id local.localUser.user.availableCustomEmojis)
                        )
                        messageCustomEmojiIdsList
                        |> NonemptySet.fromList
            in
            [ Ui.row
                []
                [ -- We need to have this container around the button, otherwise the divider between button and emojis isn't centered for some reason
                  Ui.el
                    []
                    (button
                        isMobile
                        (Dom.id "messageMenu_addReaction")
                        Icons.smile
                        "Add reaction emoji"
                        (MessageMenu_PressedShowReactionEmojiSelector guildOrDmId threadRoute position)
                    )
                , if isMobile then
                    let
                        commonEmojis : List (Element FrontendMsg)
                        commonEmojis =
                            User.commonlyUsedEmojis local.localUser.user
                                |> List.take 3
                                |> List.indexedMap
                                    (\index ( emoji, _ ) ->
                                        MyUi.elButton
                                            (Dom.id ("messageMenu_mobileReactionEmoji_" ++ String.fromInt index))
                                            (MessageMenu_PressedReactionEmoji emoji)
                                            [ Ui.contentCenterX
                                            , Ui.contentCenterY
                                            , buttonHeight isMobile |> Ui.px |> Ui.height
                                            , Ui.Font.size 24
                                            ]
                                            (Ui.html (MessageView.reactionEmojiButtonContent local.localUser.customEmojis emoji))
                                    )
                    in
                    Ui.el
                        [ Ui.paddingXY 0 4, Ui.width (Ui.px 1), Ui.height Ui.fill ]
                        (Ui.el [ Ui.height Ui.fill, Ui.background MyUi.buttonBorder ] Ui.none)
                        :: commonEmojis
                        |> Ui.row [ Ui.height (Ui.px (buttonHeight True)), MyUi.noShrinking, Ui.width Ui.fill ]

                  else
                    Ui.none
                ]
                |> Just
            , if canEditAndDelete then
                button
                    isMobile
                    (Dom.id "messageMenu_editMessage")
                    Icons.pencil
                    "Edit message"
                    (MessageMenu_PressedEditMessage guildOrDmId threadRoute)
                    |> Just

              else
                Nothing
            , if isThreadStarter then
                Nothing

              else
                button
                    isMobile
                    (Dom.id "messageMenu_replyTo")
                    Icons.reply
                    "Reply to"
                    (MessageMenu_PressedReply threadRoute)
                    |> Just
            , case ( threadRoute, guildOrDmId ) of
                ( _, DiscordGuildOrDmId (DiscordGuildOrDmId_Dm _) ) ->
                    Nothing

                ( NoThreadWithMessage messageId, _ ) ->
                    button
                        isMobile
                        (Dom.id "messageMenu_openThread")
                        Icons.hashtag
                        "Start thread"
                        (MessageMenu_PressedOpenThread messageId)
                        |> Just

                ( ViewThreadWithMessage _ _, _ ) ->
                    Nothing
            , button
                isMobile
                (Dom.id "messageMenu_copy")
                Icons.copyIcon
                (case model.lastCopied of
                    Just lastCopied ->
                        if lastCopied.copiedText == text then
                            "Copied!"

                        else
                            "Copy message"

                    Nothing ->
                        "Copy message"
                )
                (PressedCopyText text)
                |> Just
            , case newCustomEmojiIds of
                Just newCustomEmojiIds2 ->
                    button
                        isMobile
                        (Dom.id "messageMenu_addCustomEmojis")
                        Icons.plusIcon
                        "Get stickers & emojis"
                        (MessageMenu_PressedAddCustomEmojisToUser newCustomEmojiIds2)
                        |> Just

                Nothing ->
                    Nothing
            , if canEditAndDelete && not isMobile then
                Ui.el
                    [ Ui.height (Ui.px (buttonHeight False))
                    , Ui.contentCenterY
                    , Ui.paddingXY 8 0
                    ]
                    (Ui.el [ Ui.height (Ui.px 1), Ui.background MyUi.border1 ] Ui.none)
                    |> Just

              else
                Nothing
            , if canEditAndDelete then
                Ui.el
                    [ Ui.Font.color MyUi.errorColor ]
                    (button
                        isMobile
                        (Dom.id "messageMenu_deleteMessage")
                        Icons.delete
                        "Delete message"
                        (MessageMenu_PressedDeleteMessage guildOrDmId threadRoute)
                    )
                    |> Just

              else
                Nothing
            ]
                |> List.filterMap identity

        Nothing ->
            []


button : Bool -> HtmlId -> Html msg -> String -> msg -> Element msg
button isMobile htmlId icon text msg =
    MyUi.rowButton
        htmlId
        msg
        [ Ui.spacing 8
        , Ui.contentCenterY
        , Ui.paddingXY 8 0
        , buttonHeight isMobile |> Ui.px |> Ui.height
        , Ui.attrIf isMobile (Ui.Font.size 14)
        , MyUi.hover isMobile [ Ui.Anim.backgroundColor MyUi.hoverHighlight ]
        ]
        [ Ui.el [ Ui.width (Ui.px 24) ] (Ui.html icon), Ui.text text ]


messageCustomEmojiIds : Message messageId userId -> List (Id CustomEmojiId)
messageCustomEmojiIds message =
    let
        reactionIds : SeqDict EmojiOrCustomEmoji a -> List (Id CustomEmojiId)
        reactionIds reactions =
            SeqDict.keys reactions
                |> List.filterMap
                    (\emoji ->
                        case emoji of
                            EmojiOrCustomEmoji_CustomEmoji id ->
                                Just id

                            EmojiOrCustomEmoji_Emoji _ ->
                                Nothing
                    )
    in
    case message of
        UserTextMessage data ->
            RichText.customEmojiIds data.content ++ reactionIds data.reactions

        UserJoinedMessage _ _ reactions ->
            reactionIds reactions

        DeletedMessage _ ->
            []

        CallStarted _ _ reactions ->
            reactionIds reactions

        CallEnded _ reactions ->
            reactionIds reactions


buttonHeight : Bool -> number
buttonHeight isMobile =
    if isMobile then
        10 + 34

    else
        6 + 30
