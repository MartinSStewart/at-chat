module MessageMenu exposing
    ( close
    , editMessageTextInputConfig
    , editMessageTextInputId
    , menuHeight
    , messageMenuSpeed
    , mobileMenuMaxHeight
    , mobileMenuOpeningOffset
    , view
    , width
    )

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Duration exposing (Seconds)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Html exposing (Html)
import Icons
import Id exposing (ChannelMessageId, GuildOrDmId, Id, ThreadRoute(..))
import LocalState exposing (LocalState)
import Message exposing (Message(..))
import MessageInput exposing (MsgConfig)
import MyUi
import Quantity exposing (Quantity, Rate)
import RichText
import SeqDict
import Types exposing (EditMessage, FrontendMsg(..), LoadedFrontend, LoggedIn2, MessageHover(..), MessageHoverMobileMode(..), MessageMenuExtraOptions)
import Ui exposing (Element)
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
                        SeqDict.remove extraOptions.guildOrDmId loggedIn.editMessage

                    else
                        loggedIn.editMessage
            }


mobileMenuMaxHeight : MessageMenuExtraOptions -> LocalState -> LoggedIn2 -> LoadedFrontend -> Quantity Float CssPixels
mobileMenuMaxHeight extraOptions local loggedIn model =
    (case showEdit extraOptions.guildOrDmId extraOptions.messageIndex loggedIn of
        Just edit ->
            toFloat (List.length (String.lines edit.text)) * 22.4 + 16 + 2 + mobileCloseButton + topPadding + bottomPadding

        Nothing ->
            let
                itemCount : Float
                itemCount =
                    menuItems True extraOptions.guildOrDmId extraOptions.messageIndex False Coord.origin local model |> List.length |> toFloat
            in
            itemCount * buttonHeight True + itemCount - 1 + mobileCloseButton + topPadding + bottomPadding
    )
        |> CssPixels.cssPixels


mobileMenuOpeningOffset : GuildOrDmId -> Id ChannelMessageId -> LocalState -> LoadedFrontend -> Quantity Float CssPixels
mobileMenuOpeningOffset guildOrDmId messageIndex local model =
    let
        itemCount : Float
        itemCount =
            menuItems True guildOrDmId messageIndex False Coord.origin local model |> List.length |> toFloat |> min 3.4
    in
    itemCount * buttonHeight True + itemCount - 1 + mobileCloseButton + topPadding + bottomPadding |> CssPixels.cssPixels


messageMenuSpeed : Quantity Float (Rate CssPixels Seconds)
messageMenuSpeed =
    Quantity.rate (CssPixels.cssPixels 800) Duration.second


menuHeight :
    { a | guildOrDmId : GuildOrDmId, messageIndex : Id ChannelMessageId, position : Coord CssPixels }
    -> LocalState
    -> LoadedFrontend
    -> Int
menuHeight extraOptions local model =
    let
        itemCount =
            menuItems False extraOptions.guildOrDmId extraOptions.messageIndex False extraOptions.position local model
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


showEdit : GuildOrDmId -> Id ChannelMessageId -> LoggedIn2 -> Maybe EditMessage
showEdit guildOrDmId messageIndex loggedIn =
    case SeqDict.get guildOrDmId loggedIn.editMessage of
        Just edit ->
            if edit.messageIndex == messageIndex then
                Just edit

            else
                Nothing

        Nothing ->
            Nothing


view : LoadedFrontend -> MessageMenuExtraOptions -> LocalState -> LoggedIn2 -> Element FrontendMsg
view model extraOptions local loggedIn =
    let
        guildOrDmId : GuildOrDmId
        guildOrDmId =
            extraOptions.guildOrDmId
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
                    :: (case showEdit guildOrDmId extraOptions.messageIndex loggedIn of
                            Just edit ->
                                [ MessageInput.view
                                    True
                                    True
                                    (editMessageTextInputConfig guildOrDmId)
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
                                    (menuItems
                                        True
                                        extraOptions.guildOrDmId
                                        extraOptions.messageIndex
                                        extraOptions.isThreadStarter
                                        extraOptions.position
                                        local
                                        model
                                    )
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
            (menuItems
                False
                extraOptions.guildOrDmId
                extraOptions.messageIndex
                extraOptions.isThreadStarter
                extraOptions.position
                local
                model
            )


editMessageTextInputConfig : GuildOrDmId -> MsgConfig FrontendMsg
editMessageTextInputConfig guildOrDmId =
    { gotPingUserPosition = GotPingUserPositionForEditMessage
    , textInputGotFocus = TextInputGotFocus
    , textInputLostFocus = TextInputLostFocus
    , pressedTextInput = PressedTextInput
    , typedMessage = TypedEditMessage guildOrDmId
    , pressedSendMessage = PressedSendEditMessage guildOrDmId
    , pressedArrowInDropdown = PressedArrowInDropdownForEditMessage guildOrDmId
    , pressedArrowUpInEmptyInput = FrontendNoOp
    , pressedPingUser = PressedPingUserForEditMessage guildOrDmId
    , pressedPingDropdownContainer = PressedEditMessagePingDropdownContainer
    , pressedUploadFile = EditMessage_PressedAttachFiles guildOrDmId
    , target = MessageInput.EditMessage
    , onPasteFiles = EditMessage_PastedFiles guildOrDmId
    }


editMessageTextInputId : HtmlId
editMessageTextInputId =
    Dom.id "editMessageTextInput"


menuItems : Bool -> GuildOrDmId -> Id ChannelMessageId -> Bool -> Coord CssPixels -> LocalState -> LoadedFrontend -> List (Element FrontendMsg)
menuItems isMobile guildOrDmId messageIndex isThreadStarter position local model =
    case LocalState.getMessages guildOrDmId local of
        Just ( threadRoute, messages ) ->
            case LocalState.getArray messageIndex messages of
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

                                DeletedMessage _ ->
                                    "Message deleted"
                    in
                    [ button
                        isMobile
                        Icons.smile
                        "Add reaction emoji"
                        (MessageMenu_PressedShowReactionEmojiSelector guildOrDmId messageIndex position)
                        |> Just
                    , if canEditAndDelete then
                        button
                            isMobile
                            Icons.pencil
                            "Edit message"
                            (MessageMenu_PressedEditMessage guildOrDmId messageIndex)
                            |> Just

                      else
                        Nothing
                    , if isThreadStarter then
                        Nothing

                      else
                        button isMobile Icons.reply "Reply to" (MessageMenu_PressedReply messageIndex) |> Just
                    , case ( threadRoute, isThreadStarter ) of
                        ( NoThread, False ) ->
                            button
                                isMobile
                                Icons.hashtag
                                "Start thread"
                                (MessageMenu_PressedOpenThread messageIndex)
                                |> Just

                        _ ->
                            Nothing
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
                                (MessageMenu_PressedDeleteMessage guildOrDmId messageIndex)
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
