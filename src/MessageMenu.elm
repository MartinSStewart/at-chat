module MessageMenu exposing
    ( close
    , editMessageTextInputId
    , messageMenuSpeed
    , mobileMenuMaxHeight
    , mobileMenuOpeningOffset
    , view
    )

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Discord
import Duration exposing (Seconds)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Emoji exposing (EmojiOrCustomEmoji(..))
import Env
import FileStatus
import Html exposing (Html)
import Icons
import Id exposing (AnyGuildOrDmId(..), CustomEmojiId, DiscordGuildOrDmId(..), GuildOrDmId(..), Id, ThreadRouteWithMessage(..), UserId)
import IdArray exposing (IdArray)
import LinkedAndOtherDiscordUsers
import List.Nonempty exposing (Nonempty)
import LocalState exposing (LocalState)
import Message exposing (Message(..), MessageState(..))
import MessageInput
import MessageView
import MyUi exposing (Copied(..))
import NonemptySet exposing (NonemptySet)
import OneToOne
import PersonName exposing (PersonName)
import Quantity exposing (Quantity, Rate)
import RichText exposing (RichText)
import SeqDict exposing (SeqDict)
import SeqSet
import String.Nonempty
import Types exposing (EditMessage, FrontendMsg_(..), LoadedFrontend, LoggedIn2, MessageHover(..), MessageHoverMobileMode(..), MessageMenuExtraOptions)
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
    menuItems
        True
        extraOptions.guildOrDmId
        extraOptions.threadRoute
        False
        extraOptions.imageUrl
        extraOptions.linkUrl
        Coord.origin
        local
        model
        |> .items
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
            menuItems True guildOrDmId threadRoute False Nothing Nothing Coord.origin local model
                |> .items
                |> List.length
                |> toFloat
                |> min 3.4
    in
    itemCount * buttonHeight True + itemCount - 1 + mobileCloseButton + topPadding + bottomPadding |> CssPixels.cssPixels


messageMenuSpeed : Quantity Float (Rate CssPixels Seconds)
messageMenuSpeed =
    Quantity.rate (CssPixels.cssPixels 800) Duration.second


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


viewMobile : Float -> MessageMenuExtraOptions -> LoggedIn2 -> LocalState -> LoadedFrontend -> Element FrontendMsg_
viewMobile offset extraOptions loggedIn local model =
    let
        height : Int
        height =
            1000

        { items } =
            menuItems
                True
                extraOptions.guildOrDmId
                extraOptions.threadRoute
                extraOptions.isThreadStarter
                extraOptions.imageUrl
                extraOptions.linkUrl
                extraOptions.position
                local
                model
    in
    Ui.column
        [ Ui.move { x = 0, y = negate offset |> round |> (+) height, z = 0 }
        , Ui.roundedWith { topLeft = 16, topRight = 16, bottomRight = 0, bottomLeft = 0 }
        , Ui.background MyUi.black
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
                                    (mobileMenuMaxHeightHelper (List.length items) |> round |> (+) -32)
                                    True
                                    True
                                    editMessageTextInputId
                                    ""
                                    charsLeft
                                    edit.text
                                    richText
                                    (FileStatus.hasUploadingFile edit.attachedFiles)
                                    edit.attachedFiles
                                    local.localUser
                                    loggedIn
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
                                        LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers

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
                            items
               )
        )


view : LoadedFrontend -> MessageMenuExtraOptions -> LocalState -> LoggedIn2 -> Element FrontendMsg_
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
            { items, height } =
                menuItems
                    False
                    extraOptions.guildOrDmId
                    extraOptions.threadRoute
                    extraOptions.isThreadStarter
                    extraOptions.imageUrl
                    extraOptions.linkUrl
                    extraOptions.position
                    local
                    model

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
            items


editMessageTextInputId : HtmlId
editMessageTextInputId =
    Dom.id "editMessageTextInput"


menuItems :
    Bool
    -> AnyGuildOrDmId
    -> ThreadRouteWithMessage
    -> Bool
    -> Maybe String
    -> Maybe String
    -> Coord CssPixels
    -> LocalState
    -> LoadedFrontend
    -> { items : List (Element FrontendMsg_), height : Int }
menuItems isMobile guildOrDmId threadRoute isThreadStarter maybeImageUrl maybeLinkUrl position local model =
    let
        helper : Id messageId -> { a | messages : IdArray messageId (MessageState messageId (Id UserId)) } -> Maybe ( Bool, String, List (Id CustomEmojiId) )
        helper messageId thread =
            case IdArray.get messageId thread.messages of
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

        discordHelper : Id messageId -> { a | messages : IdArray messageId (MessageState messageId (Discord.Id Discord.UserId)) } -> Maybe ( Bool, String, List (Id CustomEmojiId) )
        discordHelper messageId thread =
            case IdArray.get messageId thread.messages of
                Just (MessageLoaded message) ->
                    ( case message of
                        UserTextMessage data ->
                            LinkedAndOtherDiscordUsers.isLinkedUser data.createdBy local.localUser.discordUsers

                        _ ->
                            False
                    , LocalState.messageToString
                        (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                        message
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
                        commonEmojis : List (Element FrontendMsg_)
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
                        |> Ui.row [ Ui.height (Ui.px (buttonHeight True)), MyUi.noShrinking ]

                  else
                    Ui.none
                ]
                |> ButtonItem
            , if canEditAndDelete then
                button
                    isMobile
                    (Dom.id "messageMenu_editMessage")
                    Icons.pencil
                    "Edit message"
                    (MessageMenu_PressedEditMessage guildOrDmId threadRoute)
                    |> ButtonItem

              else
                NoItem
            , if isThreadStarter then
                NoItem

              else
                button
                    isMobile
                    (Dom.id "messageMenu_replyTo")
                    Icons.reply
                    "Reply to"
                    (MessageMenu_PressedReply threadRoute)
                    |> ButtonItem
            , case ( threadRoute, guildOrDmId ) of
                ( _, DiscordGuildOrDmId (DiscordGuildOrDmId_Dm _) ) ->
                    NoItem

                ( NoThreadWithMessage messageId, _ ) ->
                    button
                        isMobile
                        (Dom.id "messageMenu_openThread")
                        Icons.hashtag
                        "Start thread"
                        (MessageMenu_PressedOpenThread messageId)
                        |> ButtonItem

                ( ViewThreadWithMessage _ _, _ ) ->
                    NoItem
            , button
                isMobile
                (Dom.id "messageMenu_copy")
                Icons.copyIcon
                (case model.lastCopied of
                    Just lastCopied ->
                        if lastCopied.copied == CopiedText text then
                            "Copied!"

                        else
                            "Copy message"

                    Nothing ->
                        "Copy message"
                )
                (PressedCopyText text)
                |> ButtonItem
            , case maybeImageUrl of
                Just imageUrl ->
                    GroupItem
                        [ HorizontalLineItem
                        , copyImageButton isMobile imageUrl model.lastCopied
                        , copyImageLinkButton isMobile imageUrl model.lastCopied |> ButtonItem
                        ]

                Nothing ->
                    NoItem
            , case maybeLinkUrl of
                Just linkUrl ->
                    copyLinkButton isMobile linkUrl model.lastCopied |> ButtonItem

                Nothing ->
                    NoItem
            , case newCustomEmojiIds of
                Just newCustomEmojiIds2 ->
                    button
                        isMobile
                        (Dom.id "messageMenu_addCustomEmojis")
                        Icons.plusIcon
                        "Get stickers & emojis"
                        (MessageMenu_PressedAddCustomEmojisToUser newCustomEmojiIds2)
                        |> ButtonItem

                Nothing ->
                    NoItem
            , if canEditAndDelete then
                GroupItem
                    [ HorizontalLineItem
                    , Ui.el
                        [ Ui.Font.color MyUi.errorColor ]
                        (button
                            isMobile
                            (Dom.id "messageMenu_deleteMessage")
                            Icons.delete
                            "Delete message"
                            (MessageMenu_PressedDeleteMessage guildOrDmId threadRoute)
                        )
                        |> ButtonItem
                    ]

              else
                NoItem
            ]
                |> menuItemsHelper isMobile

        Nothing ->
            { items = [], height = 0 }


menuItemsHelper : Bool -> List ContextMenuItem -> { items : List (Element FrontendMsg_), height : Int }
menuItemsHelper isMobile a =
    List.foldl
        (\item { items, height } ->
            case item of
                NoItem ->
                    { items = items, height = height }

                HorizontalLineItem ->
                    if isMobile then
                        { items = items, height = height }

                    else
                        { items = horizontalLine :: items, height = height + horizontalLineHeight }

                ButtonItem element ->
                    { items = element :: items, height = height + buttonHeight isMobile }

                GroupItem groupItems ->
                    let
                        b =
                            menuItemsHelper isMobile groupItems
                    in
                    { items = List.reverse b.items ++ items, height = height + b.height }
        )
        { items = [], height = 0 }
        a
        |> (\{ items, height } -> { items = List.reverse items, height = height })


type ContextMenuItem
    = NoItem
    | ButtonItem (Element FrontendMsg_)
    | HorizontalLineItem
    | GroupItem (List ContextMenuItem)


copyImageButton : Bool -> String -> Maybe MyUi.LastCopy -> ContextMenuItem
copyImageButton isMobile imageUrl lastCopied =
    if String.startsWith Env.domain imageUrl then
        button
            isMobile
            (Dom.id "messageMenu_copyImage")
            (Icons.image 22)
            (case lastCopied of
                Just lastCopied2 ->
                    if lastCopied2.copied == CopiedImage imageUrl then
                        "Copied!"

                    else
                        "Copy image"

                Nothing ->
                    "Copy image"
            )
            (PressedCopyImage imageUrl)
            |> ButtonItem

    else
        NoItem


copyImageLinkButton : Bool -> String -> Maybe MyUi.LastCopy -> Element FrontendMsg_
copyImageLinkButton isMobile imageUrl lastCopied =
    button
        isMobile
        (Dom.id "messageMenu_copyImageLink")
        Icons.link
        (case lastCopied of
            Just lastCopied2 ->
                if lastCopied2.copied == CopiedText imageUrl then
                    "Copied!"

                else
                    "Copy image link"

            Nothing ->
                "Copy image link"
        )
        (PressedCopyText imageUrl)


copyLinkButton : Bool -> String -> Maybe MyUi.LastCopy -> Element FrontendMsg_
copyLinkButton isMobile linkUrl lastCopied =
    button
        isMobile
        (Dom.id "messageMenu_copyLink")
        Icons.link
        (case lastCopied of
            Just lastCopied2 ->
                if lastCopied2.copied == CopiedText linkUrl then
                    "Copied!"

                else
                    "Copy link"

            Nothing ->
                "Copy link"
        )
        (PressedCopyText linkUrl)


horizontalLine : Element msg
horizontalLine =
    Ui.el
        [ Ui.height (Ui.px horizontalLineHeight)
        , Ui.contentCenterY
        , Ui.paddingXY 8 0
        ]
        (Ui.el [ Ui.height (Ui.px 1), Ui.background MyUi.border1 ] Ui.none)


horizontalLineHeight : number
horizontalLineHeight =
    16


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

        UserJoinedMessage _ _ reactions _ ->
            reactionIds reactions

        DeletedMessage _ ->
            []

        CallStarted { reactions } ->
            reactionIds reactions

        GameStarted { reactions } ->
            reactionIds reactions


buttonHeight : Bool -> number
buttonHeight isMobile =
    if isMobile then
        10 + 34

    else
        6 + 30
