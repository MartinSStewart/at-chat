module MessageMenu exposing
    ( close
    , editMessageTextInputConfig
    , editMessageTextInputId
    , messageMenuSpeed
    , miniView
    , mobileMenuMaxHeight
    , mobileMenuOpeningOffset
    , view
    , width
    )

import Array
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Duration exposing (Seconds)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Html exposing (Html)
import Html.Attributes
import Icons
import Id exposing (ChannelId, GuildId, Id)
import Json.Decode
import LocalState exposing (LocalState, Message(..))
import MessageInput exposing (MsgConfig)
import MyUi
import Quantity exposing (Quantity, Rate)
import RichText
import SeqDict
import Types exposing (FrontendMsg(..), LoadedFrontend, LoggedIn2, MessageHover(..), MessageHoverMobileMode(..), MessageId, MessageMenuExtraOptions)
import Ui exposing (Element)
import Ui.Events
import Ui.Font
import Ui.Input
import User


width : number
width =
    200


close : LoadedFrontend -> LoggedIn2 -> LoggedIn2
close model loggedIn =
    case loggedIn.messageHover of
        NoMessageHover ->
            loggedIn

        MessageHover _ ->
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
                                    MessageMenuClosing offset ->
                                        MessageMenuClosing offset

                                    MessageMenuOpening { offset } ->
                                        MessageMenuClosing offset

                                    MessageMenuDragging { offset } ->
                                        MessageMenuClosing offset

                                    MessageMenuFixed offset ->
                                        MessageMenuClosing offset
                        }
                            |> MessageMenu

                    else
                        NoMessageHover
                , editMessage =
                    if isMobile then
                        SeqDict.remove
                            ( extraOptions.messageId.guildId
                            , extraOptions.messageId.channelId
                            )
                            loggedIn.editMessage

                    else
                        loggedIn.editMessage
            }


mobileMenuMaxHeight : MessageMenuExtraOptions -> LocalState -> LoggedIn2 -> LoadedFrontend -> Quantity Float CssPixels
mobileMenuMaxHeight extraOptions local loggedIn model =
    (case showEdit extraOptions.messageId loggedIn of
        Just edit ->
            toFloat (List.length (String.lines edit)) * 22.4 + 16 + 2 + mobileCloseButton + topPadding + bottomPadding

        Nothing ->
            let
                itemCount : Float
                itemCount =
                    menuItems True extraOptions.messageId Coord.origin local model |> List.length |> toFloat
            in
            itemCount * buttonHeight True + itemCount - 1 + mobileCloseButton + topPadding + bottomPadding
    )
        |> CssPixels.cssPixels


mobileMenuOpeningOffset : MessageId -> LocalState -> LoadedFrontend -> Quantity Float CssPixels
mobileMenuOpeningOffset messageId local model =
    let
        itemCount : Float
        itemCount =
            menuItems True messageId Coord.origin local model |> List.length |> toFloat |> min 3.4
    in
    itemCount * buttonHeight True + itemCount - 1 + mobileCloseButton + topPadding + bottomPadding |> CssPixels.cssPixels


messageMenuSpeed : Quantity Float (Rate CssPixels Seconds)
messageMenuSpeed =
    Quantity.rate (CssPixels.cssPixels 800) Duration.second


topPadding : number
topPadding =
    4


bottomPadding : number
bottomPadding =
    8


mobileCloseButton : number
mobileCloseButton =
    12


showEdit : MessageId -> LoggedIn2 -> Maybe String
showEdit messageId loggedIn =
    case SeqDict.get ( messageId.guildId, messageId.channelId ) loggedIn.editMessage of
        Just edit ->
            if edit.messageIndex == messageId.messageIndex then
                Just edit.text

            else
                Nothing

        Nothing ->
            Nothing


view : LoadedFrontend -> MessageMenuExtraOptions -> LocalState -> LoggedIn2 -> Element FrontendMsg
view model extraOptions local loggedIn =
    let
        messageId : MessageId
        messageId =
            extraOptions.messageId
    in
    if MyUi.isMobile model then
        Ui.el
            [ Ui.height Ui.fill
            , Ui.background (Ui.rgba 0 0 0 0.3)
            , Ui.column
                [ Ui.move
                    { x = 0
                    , y =
                        Types.messageMenuMobileOffset extraOptions.mobileMode
                            |> CssPixels.inCssPixels
                            |> negate
                            |> round
                    , z = 0
                    }
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
                ]
                (Ui.el
                    [ Ui.height (Ui.px mobileCloseButton)
                    , Ui.Input.button MessageMenu_PressedClose
                    ]
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
                    :: (case showEdit messageId loggedIn of
                            Just edit ->
                                [ MessageInput.view
                                    True
                                    True
                                    (editMessageTextInputConfig messageId.guildId messageId.channelId)
                                    editMessageTextInputId
                                    ""
                                    edit
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
                                    (menuItems True extraOptions.messageId extraOptions.position local model)
                       )
                )
                |> Ui.below
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
            (menuItems False extraOptions.messageId extraOptions.position local model)


editMessageTextInputConfig : Id GuildId -> Id ChannelId -> MsgConfig FrontendMsg
editMessageTextInputConfig guildId channelId =
    { gotPingUserPosition = GotPingUserPositionForEditMessage
    , textInputGotFocus = TextInputGotFocus
    , textInputLostFocus = TextInputLostFocus
    , typedMessage = TypedEditMessage guildId channelId
    , pressedSendMessage = PressedSendEditMessage guildId channelId
    , pressedArrowInDropdown = PressedArrowInDropdownForEditMessage guildId
    , pressedArrowUpInEmptyInput = FrontendNoOp
    , pressedPingUser = PressedPingUserForEditMessage guildId channelId
    , pressedPingDropdownContainer = PressedEditMessagePingDropdownContainer
    , target = MessageInput.EditMessage
    }


editMessageTextInputId : HtmlId
editMessageTextInputId =
    Dom.id "editMessageTextInput"


miniView : Bool -> Int -> Element FrontendMsg
miniView canEdit messageIndex =
    Ui.row
        [ Ui.alignRight
        , Ui.background MyUi.background1
        , Ui.rounded 4
        , Ui.borderColor MyUi.border1
        , Ui.border 1
        , Ui.move { x = -8, y = -16, z = 0 }
        , Ui.height (Ui.px 32)
        ]
        [ miniButton (MessageMenu_PressedShowReactionEmojiSelector messageIndex) Icons.smile
        , if canEdit then
            miniButton (\_ -> MessageMenu_PressedEditMessage messageIndex) Icons.pencil

          else
            Ui.none
        , miniButton (\_ -> MessageMenu_PressedReply messageIndex) Icons.reply
        , miniButton (MessageMenu_PressedShowFullMenu messageIndex) Icons.dotDotDot
        ]


miniButton : (Coord CssPixels -> msg) -> Html msg -> Element msg
miniButton onPress svg =
    Ui.el
        [ Ui.width (Ui.px 32)
        , Ui.paddingXY 4 3
        , Ui.height Ui.fill
        , Ui.htmlAttribute (Html.Attributes.attribute "role" "button")

        --, Ui.Input.button onPress
        , Ui.Events.stopPropagationOn "click"
            (Json.Decode.map2
                (\x y -> ( onPress (Coord.xy (round x) (round y)), True ))
                (Json.Decode.field "clientX" Json.Decode.float)
                (Json.Decode.field "clientY" Json.Decode.float)
            )
        , Ui.pointer
        ]
        (Ui.html svg)


menuItems : Bool -> MessageId -> Coord CssPixels -> LocalState -> LoadedFrontend -> List (Element FrontendMsg)
menuItems isMobile messageId position local model =
    case LocalState.getGuildAndChannel messageId.guildId messageId.channelId local of
        Just ( _, channel ) ->
            case Array.get messageId.messageIndex channel.messages of
                Just message ->
                    let
                        canEditAndDelete : Bool
                        canEditAndDelete =
                            case message of
                                UserTextMessage data ->
                                    data.createdBy == local.localUser.userId

                                _ ->
                                    False

                        text : String
                        text =
                            case message of
                                UserTextMessage a ->
                                    RichText.toString (LocalState.allUsers local) a.content

                                UserJoinedMessage _ userId _ ->
                                    User.toString userId (LocalState.allUsers local)
                                        ++ " joined!"

                                DeletedMessage ->
                                    "Message deleted"
                    in
                    [ button
                        isMobile
                        Icons.smile
                        "Add reaction emoji"
                        (MessageMenu_PressedShowReactionEmojiSelector messageId.messageIndex position)
                        |> Just
                    , if canEditAndDelete then
                        button
                            isMobile
                            Icons.pencil
                            "Edit message"
                            (MessageMenu_PressedEditMessage messageId.messageIndex)
                            |> Just

                      else
                        Nothing
                    , button isMobile Icons.reply "Reply to" (MessageMenu_PressedReply messageId.messageIndex) |> Just
                    , button
                        isMobile
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
                                Icons.delete
                                "Delete message"
                                (MessageMenu_PressedDeleteMessage messageId)
                            )
                            |> Just

                      else
                        Nothing
                    ]
                        |> List.filterMap identity

                Nothing ->
                    []

        Nothing ->
            []


button : Bool -> Html msg -> String -> msg -> Element msg
button isMobile icon text msg =
    Ui.row
        [ Ui.Input.button msg
        , Ui.spacing 8
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
