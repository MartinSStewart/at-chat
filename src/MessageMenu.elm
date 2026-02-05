module MessageMenu exposing
    ( close
    , desktopMenuHeight
    , editMessageTextInputConfig
    , editMessageTextInputId
    , messageMenuSpeed
    , mobileMenuMaxHeight
    , mobileMenuOpeningOffset
    , showEdit
    , view
    , width
    )

import Array exposing (Array)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Discord.Id
import DmChannel
import Duration exposing (Seconds)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Html exposing (Html)
import Icons
import Id exposing (AnyGuildOrDmId(..), DiscordGuildOrDmId(..), GuildOrDmId(..), Id, ThreadRoute, ThreadRouteWithMessage(..), UserId)
import LocalState exposing (LocalState)
import Message exposing (Message(..), MessageState(..))
import MessageInput exposing (MsgConfig)
import MyUi
import Quantity exposing (Quantity, Rate)
import RichText
import SeqDict
import SeqSet
import Types exposing (EditMessage, FrontendMsg(..), LoadedFrontend, LoggedIn2, MessageHover(..), MessageHoverMobileMode(..), MessageMenuExtraOptions)
import Ui exposing (Element)
import Ui.Font
import User


width : number
width =
    200


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


desktopMenuHeight :
    { a | guildOrDmId : AnyGuildOrDmId, threadRoute : ThreadRouteWithMessage, position : Coord CssPixels }
    -> LocalState
    -> LoadedFrontend
    -> Int
desktopMenuHeight extraOptions local model =
    let
        itemCount =
            menuItems False extraOptions.guildOrDmId extraOptions.threadRoute False extraOptions.position local model
                |> List.length
    in
    itemCount * buttonHeight False + 2


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
                        [ MessageInput.editView
                            (Dom.id "messageMenu_editMobile")
                            (mobileMenuMaxHeightHelper (List.length menuItems2) |> round |> (+) -32)
                            True
                            True
                            (editMessageTextInputConfig
                                extraOptions.guildOrDmId
                                (Id.threadRouteWithoutMessage extraOptions.threadRoute)
                            )
                            editMessageTextInputId
                            ""
                            edit.text
                            edit.attachedFiles
                            loggedIn.pingUser
                            local
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
        Ui.column
            [ Ui.move
                { x = Coord.xRaw extraOptions.position
                , y = Coord.yRaw extraOptions.position
                , z = 0
                }
            , Ui.background MyUi.background1
            , Ui.border 1
            , Ui.borderColor MyUi.border1
            , Ui.width (Ui.px width)
            , Ui.rounded 8
            , MyUi.blockClickPropagation MessageMenu_PressedContainer
            ]
            (menuItems
                False
                extraOptions.guildOrDmId
                extraOptions.threadRoute
                extraOptions.isThreadStarter
                extraOptions.position
                local
                model
            )


editMessageTextInputConfig : AnyGuildOrDmId -> ThreadRoute -> MsgConfig FrontendMsg
editMessageTextInputConfig guildOrDmId threadRoute =
    { gotPingUserPosition = GotPingUserPositionForEditMessage
    , textInputGotFocus = TextInputGotFocus
    , textInputLostFocus = TextInputLostFocus
    , pressedTextInput = PressedTextInput
    , typedMessage = TypedEditMessage ( guildOrDmId, threadRoute )
    , pressedSendMessage = PressedSendEditMessage ( guildOrDmId, threadRoute )
    , pressedArrowInDropdown = PressedArrowInDropdownForEditMessage guildOrDmId
    , pressedArrowUpInEmptyInput = FrontendNoOp
    , pressedPingUser = PressedPingUserForEditMessage ( guildOrDmId, threadRoute )
    , pressedPingDropdownContainer = PressedEditMessagePingDropdownContainer
    , pressedUploadFile = EditMessage_PressedAttachFiles ( guildOrDmId, threadRoute )
    , target = MessageInput.EditMessage
    , onPasteFiles = EditMessage_PastedFiles ( guildOrDmId, threadRoute )
    }


editMessageTextInputId : HtmlId
editMessageTextInputId =
    Dom.id "editMessageTextInput"


menuItems : Bool -> AnyGuildOrDmId -> ThreadRouteWithMessage -> Bool -> Coord CssPixels -> LocalState -> LoadedFrontend -> List (Element FrontendMsg)
menuItems isMobile guildOrDmId threadRoute isThreadStarter position local model =
    let
        helper : Id messageId -> { a | messages : Array (MessageState messageId (Id UserId)) } -> Maybe ( Bool, String )
        helper messageId thread =
            case DmChannel.getArray messageId thread.messages of
                Just (MessageLoaded message) ->
                    ( case message of
                        UserTextMessage data ->
                            data.createdBy == local.localUser.session.userId

                        _ ->
                            False
                    , case message of
                        UserTextMessage a ->
                            RichText.toString (LocalState.allUsers local) a.content

                        UserJoinedMessage _ userId _ ->
                            User.toString userId (LocalState.allUsers local)
                                ++ " joined!"

                        DeletedMessage _ ->
                            "Message deleted"
                    )
                        |> Just

                _ ->
                    Nothing

        discordHelper : Id messageId -> { a | messages : Array (MessageState messageId (Discord.Id.Id Discord.Id.UserId)) } -> Maybe ( Bool, String )
        discordHelper messageId thread =
            case DmChannel.getArray messageId thread.messages of
                Just (MessageLoaded message) ->
                    ( case message of
                        UserTextMessage data ->
                            SeqDict.member data.createdBy local.localUser.linkedDiscordUsers

                        _ ->
                            False
                    , case message of
                        UserTextMessage a ->
                            RichText.toString (LocalState.allDiscordUsers2 local.localUser) a.content

                        UserJoinedMessage _ userId _ ->
                            User.toString userId (LocalState.allDiscordUsers2 local.localUser)
                                ++ " joined!"

                        DeletedMessage _ ->
                            "Message deleted"
                    )
                        |> Just

                _ ->
                    Nothing

        maybeData : Maybe ( Bool, String )
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

                DiscordGuildOrDmId (DiscordGuildOrDmId_Dm _ channelId) ->
                    case SeqDict.get channelId local.discordDmChannels of
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
        Just ( canEditAndDelete, text ) ->
            [ button
                isMobile
                (Dom.id "messageMenu_addReaction")
                Icons.smile
                "Add reaction emoji"
                (MessageMenu_PressedShowReactionEmojiSelector guildOrDmId threadRoute position)
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
            , case threadRoute of
                NoThreadWithMessage messageId ->
                    button
                        isMobile
                        (Dom.id "messageMenu_openThread")
                        Icons.hashtag
                        "Start thread"
                        (MessageMenu_PressedOpenThread messageId)
                        |> Just

                ViewThreadWithMessage _ _ ->
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
        ]
        [ Ui.el [ Ui.width (Ui.px 24) ] (Ui.html icon), Ui.text text ]


buttonHeight : Bool -> number
buttonHeight isMobile =
    if isMobile then
        10 + 34

    else
        6 + 30
