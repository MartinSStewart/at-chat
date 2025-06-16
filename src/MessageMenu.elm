module MessageMenu exposing
    ( close
    , miniView
    , view
    , width
    )

import Array
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Html exposing (Html)
import Html.Attributes
import Icons
import Json.Decode
import LocalState exposing (LocalState, Message(..))
import MyUi
import RichText
import SeqDict
import Types exposing (FrontendMsg(..), LoadedFrontend, LoggedIn2, MessageHover(..), MessageHoverExtraOptions, MessageId)
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

        MessageHoverShowExtraOptions extraOptions ->
            { loggedIn
                | messageHover = NoMessageHover
                , editMessage =
                    if MyUi.isMobile model then
                        SeqDict.remove
                            ( extraOptions.messageId.guildId
                            , extraOptions.messageId.channelId
                            )
                            loggedIn.editMessage

                    else
                        loggedIn.editMessage
            }


view : LoadedFrontend -> MessageHoverExtraOptions -> LocalState -> Element FrontendMsg
view model extraOptions local =
    let
        messageId : MessageId
        messageId =
            extraOptions.messageId
    in
    if MyUi.isMobile model then
        Ui.column
            [ Ui.alignBottom
            , Ui.roundedWith { topLeft = 16, topRight = 16, bottomRight = 0, bottomLeft = 0 }
            , Ui.background MyUi.background1
            , Ui.paddingWith { left = 8, right = 8, top = 4, bottom = 8 }
            , MyUi.blockClickPropagation PressedMessageHoverExtraOptionsContainer
            ]
            (Ui.el
                [ Ui.paddingXY 0 4, Ui.Input.button PressedCloseMessageHoverExtraOptions ]
                (Ui.el
                    [ Ui.background (Ui.rgb 40 50 60)
                    , Ui.rounded 99
                    , Ui.width (Ui.px 40)
                    , Ui.height (Ui.px 4)
                    , Ui.centerX
                    ]
                    Ui.none
                )
                :: List.intersperse
                    (Ui.el
                        [ Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
                        , Ui.borderColor MyUi.border2
                        ]
                        Ui.none
                    )
                    (items extraOptions messageId local model)
            )

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
            , MyUi.blockClickPropagation PressedMessageHoverExtraOptionsContainer
            ]
            (items extraOptions messageId local model)


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
        [ messageHoverButton (PressedShowReactionEmojiSelector messageIndex) Icons.smile
        , if canEdit then
            messageHoverButton (\_ -> PressedEditMessage messageIndex) Icons.pencil

          else
            Ui.none
        , messageHoverButton (\_ -> PressedReply messageIndex) Icons.reply
        , messageHoverButton (PressedShowMessageHoverExtraOptions messageIndex) Icons.dotDotDot
        ]


messageHoverButton : (Coord CssPixels -> msg) -> Html msg -> Element msg
messageHoverButton onPress svg =
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


items :
    MessageHoverExtraOptions
    -> MessageId
    -> LocalState
    -> LoadedFrontend
    -> List (Element FrontendMsg)
items extraOptions messageId local model =
    case LocalState.getGuildAndChannel messageId.guildId messageId.channelId local of
        Just ( _, channel ) ->
            case Array.get messageId.messageIndex channel.messages of
                Just message ->
                    let
                        canEditAndDelete : Bool
                        canEditAndDelete =
                            case message of
                                UserTextMessage data ->
                                    if data.createdBy == local.localUser.userId then
                                        True

                                    else
                                        False

                                _ ->
                                    False

                        text : String
                        text =
                            case message of
                                UserTextMessage a ->
                                    RichText.toString (LocalState.allUsers local) a.content

                                UserJoinedMessage _ userId _ ->
                                    User.userToName userId (LocalState.allUsers local)
                                        ++ " joined!"

                                DeletedMessage ->
                                    "Message deleted"
                    in
                    [ button
                        Icons.smile
                        "Add reaction emoji"
                        (PressedShowReactionEmojiSelector
                            messageId.messageIndex
                            extraOptions.position
                        )
                    , if canEditAndDelete then
                        button Icons.pencil "Edit message" (PressedEditMessage messageId.messageIndex)

                      else
                        Ui.none
                    , button Icons.reply "Reply to" (PressedReply messageId.messageIndex)
                    , button
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
                    , if canEditAndDelete then
                        Ui.el
                            [ Ui.Font.color MyUi.errorColor ]
                            (button
                                Icons.delete
                                "Delete message"
                                (PressedDeleteMessage messageId)
                            )

                      else
                        Ui.none
                    ]

                Nothing ->
                    []

        Nothing ->
            []


button : Html msg -> String -> msg -> Element msg
button icon text msg =
    Ui.row
        [ Ui.Input.button msg
        , Ui.spacing 8
        , Ui.contentCenterY
        , Ui.paddingXY 8 6
        ]
        [ Ui.el [ Ui.width (Ui.px 24) ] (Ui.html icon), Ui.text text ]
