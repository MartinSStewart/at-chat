module MessageInput exposing
    ( MentionUserDropdown
    , MentionUserTarget(..)
    , MsgConfig
    , editView
    , multilineUpdate
    , pingDropdownView
    , pressedArrowInDropdown
    , pressedPingUser
    , view
    )

import Diff
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.File as File exposing (File)
import Effect.Task as Task
import FileStatus exposing (FileId)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Icons
import Id exposing (GuildOrDmIdNoThread(..), Id, UserId)
import Json.Decode
import Json.Decode.Extra
import List.Extra
import List.Nonempty exposing (Nonempty)
import LocalState exposing (LocalState)
import MyUi
import PersonName
import RichText
import SeqDict exposing (SeqDict)
import String.Nonempty exposing (NonemptyString)
import Ui exposing (Element)
import Ui.Anim
import Ui.Font
import User exposing (FrontendUser)


type alias MentionUserDropdown =
    { charIndex : Int
    , dropdownIndex : Int
    , inputElement : { x : Float, y : Float, width : Float, height : Float }
    , target : MentionUserTarget
    }


type MentionUserTarget
    = NewMessage
    | EditMessage


type alias MsgConfig msg =
    { gotPingUserPosition : Result Dom.Error MentionUserDropdown -> msg
    , textInputGotFocus : HtmlId -> msg
    , textInputLostFocus : HtmlId -> msg
    , pressedTextInput : msg
    , typedMessage : String -> msg
    , pressedSendMessage : msg
    , pressedArrowInDropdown : Int -> msg
    , pressedArrowUpInEmptyInput : msg
    , pressedPingUser : Int -> msg
    , pressedPingDropdownContainer : msg
    , pressedUploadFile : msg
    , target : MentionUserTarget
    , onPasteFiles : Nonempty File -> msg
    }


textarea : Bool -> MsgConfig msg -> HtmlId -> String -> String -> SeqDict (Id FileId) a -> Maybe MentionUserDropdown -> LocalState -> Html msg
textarea isMobileKeyboard msgConfig channelTextInputId placeholderText text attachedFiles pingUser local =
    Html.div
        [ Html.Attributes.style "display" "flex"
        , Html.Attributes.style "position" "relative"
        , Html.Attributes.style "min-height" "min-content"
        , Html.Attributes.style "width" "100%"
        , Html.Attributes.style "height" "fit-content"
        , Html.Attributes.style "min-height" "100%"
        ]
        [ Html.textarea
            [ Html.Attributes.style "color" "rgba(255,0,0,1)"
            , Html.Attributes.style "position" "absolute"
            , Html.Attributes.style "font-size" "inherit"
            , Html.Attributes.style "font-family" "inherit"
            , Html.Attributes.style "line-height" "inherit"
            , Html.Attributes.style "width" "calc(100% - 18px)"
            , Html.Attributes.style "height" "calc(100% - 2px)"
            , Dom.idToAttribute channelTextInputId
            , Html.Attributes.style "background-color" "transparent"
            , Html.Attributes.style "border" "0"
            , Html.Attributes.style "resize" "none"
            , Html.Attributes.style "overflow" "hidden"
            , Html.Attributes.style "caret-color" "white"
            , Html.Attributes.style "padding" "8px"
            , Html.Attributes.style "outline" "none"
            , Html.Events.onClick msgConfig.pressedTextInput
            , Html.Events.preventDefaultOn
                "paste"
                (Json.Decode.at
                    [ "clipboardData", "files" ]
                    (Json.Decode.Extra.collection File.decoder)
                    |> Json.Decode.andThen
                        (\list ->
                            case List.Nonempty.fromList list of
                                Just nonempty ->
                                    Json.Decode.succeed ( msgConfig.onPasteFiles nonempty, True )

                                Nothing ->
                                    Json.Decode.fail ""
                        )
                )
            , Html.Events.onFocus (msgConfig.textInputGotFocus channelTextInputId)
            , Html.Events.onBlur (msgConfig.textInputLostFocus channelTextInputId)
            , case pingUser of
                Just { dropdownIndex } ->
                    Html.Events.preventDefaultOn
                        "keydown"
                        (Json.Decode.andThen
                            (\key ->
                                case key of
                                    "ArrowDown" ->
                                        Json.Decode.succeed ( msgConfig.pressedArrowInDropdown (dropdownIndex + 1), True )

                                    "ArrowUp" ->
                                        Json.Decode.succeed ( msgConfig.pressedArrowInDropdown (dropdownIndex - 1), True )

                                    "Enter" ->
                                        Json.Decode.succeed
                                            ( msgConfig.pressedPingUser dropdownIndex, True )

                                    _ ->
                                        Json.Decode.fail ""
                            )
                            (Json.Decode.field "key" Json.Decode.string)
                        )

                Nothing ->
                    Html.Events.preventDefaultOn
                        "keydown"
                        (Json.Decode.map2 Tuple.pair
                            (Json.Decode.field "shiftKey" Json.Decode.bool)
                            (Json.Decode.field "key" Json.Decode.string)
                            |> Json.Decode.andThen
                                (\( shiftHeld, key ) ->
                                    if key == "ArrowUp" && text == "" then
                                        Json.Decode.succeed ( msgConfig.pressedArrowUpInEmptyInput, True )

                                    else if key == "Enter" && not shiftHeld && not isMobileKeyboard then
                                        Json.Decode.succeed ( msgConfig.pressedSendMessage, True )

                                    else
                                        Json.Decode.fail ""
                                )
                        )
            , Html.Events.onInput msgConfig.typedMessage
            , Html.Attributes.value text
            ]
            []
        , Html.div
            [ Html.Attributes.style "pointer-events" "none"
            , Html.Attributes.style "padding" "0 9px 0 9px"
            , Html.Attributes.style "transform" "translateX(-1px) translateY(8px)"
            , Html.Attributes.style "white-space" "pre-wrap"
            , Html.Attributes.style "overflow-wrap" "anywhere"
            , Html.Attributes.style "height" "fit-content"
            , Html.Attributes.style "min-height" "100%"
            , Html.Attributes.style "color"
                (if text == "" then
                    "rgb(180,180,180)"

                 else
                    "rgb(255,255,255)"
                )
            ]
            (case String.Nonempty.fromString text of
                Just nonempty ->
                    let
                        users =
                            LocalState.allUsers local
                    in
                    RichText.textInputView users attachedFiles (RichText.fromNonemptyString users nonempty)
                        ++ [ Html.text "\n" ]

                Nothing ->
                    [ if placeholderText == "" then
                        Html.text " "

                      else
                        Html.text placeholderText
                    ]
            )
        ]


editView :
    HtmlId
    -> Int
    -> Bool
    -> Bool
    -> MsgConfig msg
    -> HtmlId
    -> String
    -> String
    -> SeqDict (Id FileId) a
    -> Maybe MentionUserDropdown
    -> LocalState
    -> Element msg
editView htmlId height roundTopCorners isMobileKeyboard msgConfig channelTextInputId placeholderText text attachedFiles pingUser local =
    let
        htmlIdPrefix : String
        htmlIdPrefix =
            Dom.idToString htmlId
    in
    textarea isMobileKeyboard msgConfig channelTextInputId placeholderText text attachedFiles pingUser local
        |> Ui.html
        |> Ui.el
            [ Ui.paddingWith { left = 0, right = 0, top = 0, bottom = 19 }
            , Ui.scrollable
            , Ui.border 1
            , Ui.borderColor MyUi.border1
            , if roundTopCorners then
                Ui.rounded 8

              else
                Ui.roundedWith { topLeft = 0, topRight = 0, bottomLeft = 8, bottomRight = 8 }
            , Ui.height (Ui.px height)
            , Ui.heightMax height
            , Ui.heightMin 0
            , MyUi.htmlStyle "scrollbar-color" "black"
            , Ui.background MyUi.background2
            ]
        |> Ui.el
            [ Ui.paddingWith { left = 40, right = 36, top = 0, bottom = 0 }
            , Ui.inFront
                (MyUi.elButton
                    (Dom.id (htmlIdPrefix ++ "_uploadFile"))
                    msgConfig.pressedUploadFile
                    [ Ui.alignLeft
                    , Ui.width Ui.shrink
                    , Ui.rounded 4
                    , Ui.paddingXY 6 0
                    , Ui.height (Ui.px 38)
                    , Ui.background MyUi.buttonBackground
                    , Ui.move { x = 2, y = 0, z = 0 }
                    , Ui.contentCenterY
                    , Ui.centerY
                    , Html.Events.preventDefaultOn
                        "touchend"
                        (Json.Decode.succeed ( msgConfig.pressedUploadFile, True ))
                        |> Ui.htmlAttribute
                    ]
                    (Ui.html Icons.attachment)
                )
            , Ui.inFront
                (MyUi.elButton
                    (Dom.id (htmlIdPrefix ++ "_sendMessage"))
                    msgConfig.pressedSendMessage
                    [ Ui.alignRight
                    , Ui.width Ui.shrink
                    , Ui.rounded 4
                    , Ui.paddingXY 4 0
                    , Ui.height (Ui.px 38)
                    , Ui.background MyUi.buttonBackground
                    , Ui.move { x = -2, y = 0, z = 0 }
                    , Ui.contentCenterY
                    , Ui.centerY
                    , Html.Events.preventDefaultOn
                        "touchend"
                        (Json.Decode.succeed ( msgConfig.pressedSendMessage, True ))
                        |> Ui.htmlAttribute
                    ]
                    (Ui.html Icons.sendMessage)
                )
            ]


view :
    HtmlId
    -> Bool
    -> Bool
    -> MsgConfig msg
    -> HtmlId
    -> String
    -> String
    -> SeqDict (Id FileId) a
    -> Maybe MentionUserDropdown
    -> LocalState
    -> Element msg
view htmlId roundTopCorners isMobileKeyboard msgConfig channelTextInputId placeholderText text attachedFiles pingUser local =
    let
        htmlIdPrefix : String
        htmlIdPrefix =
            Dom.idToString htmlId
    in
    textarea isMobileKeyboard msgConfig channelTextInputId placeholderText text attachedFiles pingUser local
        |> Ui.html
        |> Ui.el
            [ Ui.paddingWith { left = 0, right = 0, top = 0, bottom = 19 }
            , Ui.scrollable
            , Ui.border 1
            , Ui.borderColor MyUi.border1
            , if roundTopCorners then
                Ui.rounded 8

              else
                Ui.roundedWith { topLeft = 0, topRight = 0, bottomLeft = 8, bottomRight = 8 }
            , Ui.heightMin 0
            , Ui.heightMax 400
            , MyUi.htmlStyle "scrollbar-color" "black"
            , Ui.background MyUi.background2
            ]
        |> Ui.el
            [ Ui.paddingWith { left = 40, right = 36, top = 0, bottom = 0 }
            , Ui.inFront
                (MyUi.elButton
                    (Dom.id (htmlIdPrefix ++ "_uploadFile"))
                    msgConfig.pressedUploadFile
                    [ Ui.alignLeft
                    , Ui.width Ui.shrink
                    , Ui.rounded 4
                    , Ui.paddingXY 6 0
                    , Ui.height (Ui.px 38)
                    , Ui.background MyUi.buttonBackground
                    , Ui.move { x = 2, y = 0, z = 0 }
                    , Ui.contentCenterY
                    , Ui.centerY
                    , Html.Events.preventDefaultOn
                        "touchend"
                        (Json.Decode.succeed ( msgConfig.pressedUploadFile, True ))
                        |> Ui.htmlAttribute
                    ]
                    (Ui.html Icons.attachment)
                )
            , Ui.inFront
                (MyUi.elButton
                    (Dom.id (htmlIdPrefix ++ "_sendMessage"))
                    msgConfig.pressedSendMessage
                    [ Ui.alignRight
                    , Ui.width Ui.shrink
                    , Ui.rounded 4
                    , Ui.paddingXY 4 0
                    , Ui.height (Ui.px 38)
                    , Ui.background MyUi.buttonBackground
                    , Ui.move { x = -2, y = 0, z = 0 }
                    , Ui.contentCenterY
                    , Ui.centerY
                    , Html.Events.custom
                        "touchstart"
                        (Json.Decode.succeed
                            { message = msgConfig.pressedSendMessage
                            , stopPropagation = True
                            , preventDefault = True
                            }
                        )
                        |> Ui.htmlAttribute
                    ]
                    (Ui.html Icons.sendMessage)
                )
            ]


multilineUpdate :
    MsgConfig msg
    -> HtmlId
    -> String
    -> String
    -> Maybe MentionUserDropdown
    -> ( Maybe MentionUserDropdown, Command FrontendOnly toMsg msg )
multilineUpdate msgConfig multilineId text oldText pingUser =
    let
        oldAtCount : Int
        oldAtCount =
            List.length (String.indexes "@" oldText)

        atCount : Int
        atCount =
            List.length (String.indexes "@" text)

        typedAtSymbol : Maybe Int
        typedAtSymbol =
            if
                (atCount > oldAtCount)
                    && -- Detect if the user is pasting in text and if they are, abort the @mention dropdown
                       (String.length text - String.length oldText < 3)
            then
                case newAtSymbol oldText text of
                    Just { index } ->
                        let
                            previous =
                                String.slice (index - 1) index text
                        in
                        if index == 0 || previous == " " || previous == "\n" then
                            Just index

                        else
                            Nothing

                    Nothing ->
                        Nothing

            else
                Nothing
    in
    ( if oldAtCount > atCount then
        Nothing

      else
        pingUser
    , case typedAtSymbol of
        Just index ->
            Dom.getElement multilineId
                |> Task.map
                    (\{ element } ->
                        { dropdownIndex = 0
                        , charIndex = index
                        , inputElement = element
                        , target = msgConfig.target
                        }
                    )
                |> Task.attempt msgConfig.gotPingUserPosition

        Nothing ->
            Command.none
    )


newAtSymbol : String -> String -> Maybe { index : Int }
newAtSymbol oldText text =
    List.foldl
        (\change state ->
            case change of
                Diff.Added char ->
                    if char == '@' then
                        { index = state.index + 1
                        , foundAtSymbol = Just { index = state.index }
                        }

                    else
                        case state.foundAtSymbol of
                            Just found ->
                                { index = state.index + 1
                                , foundAtSymbol = Just { index = found.index }
                                }

                            Nothing ->
                                { index = state.index + 1
                                , foundAtSymbol = state.foundAtSymbol
                                }

                _ ->
                    { index = state.index + 1
                    , foundAtSymbol = state.foundAtSymbol
                    }
        )
        { index = 0, foundAtSymbol = Nothing }
        (Diff.diff (String.toList oldText) (String.toList text))
        |> .foundAtSymbol


userDropdownList : GuildOrDmIdNoThread -> LocalState -> List ( Id UserId, FrontendUser )
userDropdownList guildOrDmId local =
    let
        allUsers : SeqDict (Id UserId) FrontendUser
        allUsers =
            LocalState.allUsers local
    in
    (case guildOrDmId of
        GuildOrDmId_Guild guildId _ ->
            case SeqDict.get guildId local.guilds of
                Just guild ->
                    guild.owner
                        :: SeqDict.keys guild.members

                Nothing ->
                    []

        GuildOrDmId_Dm otherUserId ->
            [ local.localUser.session.userId, otherUserId ]
    )
        |> List.filterMap
            (\userId ->
                case SeqDict.get userId allUsers of
                    Just user ->
                        Just ( userId, user )

                    Nothing ->
                        Nothing
            )
        |> List.sortBy (\( _, user ) -> PersonName.toString user.name)


pressedArrowInDropdown : GuildOrDmIdNoThread -> Int -> Maybe MentionUserDropdown -> LocalState -> Maybe MentionUserDropdown
pressedArrowInDropdown guildOrDmId index maybePingUser local =
    case maybePingUser of
        Just pingUser ->
            { pingUser
                | dropdownIndex =
                    if index < 0 then
                        List.length (userDropdownList guildOrDmId local) - 1

                    else if index >= List.length (userDropdownList guildOrDmId local) then
                        0

                    else
                        index
            }
                |> Just

        Nothing ->
            Nothing


pressedPingUser :
    msg
    -> GuildOrDmIdNoThread
    -> HtmlId
    -> Int
    -> Maybe MentionUserDropdown
    -> LocalState
    -> NonemptyString
    -> ( Maybe MentionUserDropdown, NonemptyString, Command FrontendOnly toMsg msg )
pressedPingUser setFocusMsg guildOrDmId channelTextInputId index pingUser local inputText =
    case ( pingUser, userDropdownList guildOrDmId local |> List.Extra.getAt index ) of
        ( Just { charIndex }, Just ( _, user ) ) ->
            let
                applyText : NonemptyString -> NonemptyString
                applyText nonempty =
                    let
                        name : String
                        name =
                            PersonName.toString user.name

                        text2 =
                            String.Nonempty.toString nonempty

                        followingText : String
                        followingText =
                            String.foldl
                                (\char ( name2, chars ) ->
                                    case name2 of
                                        head :: rest ->
                                            if Char.toLower head == Char.toLower char then
                                                ( rest, chars )

                                            else
                                                ( [], char :: chars )

                                        [] ->
                                            ( [], char :: chars )
                                )
                                ( String.toList name, [] )
                                (String.dropLeft (charIndex + 1) text2)
                                |> Tuple.second
                                |> List.reverse
                                |> String.fromList
                    in
                    String.left (charIndex + 1) text2
                        ++ name
                        ++ followingText
                        |> String.Nonempty.fromString
                        |> Maybe.withDefault nonempty
            in
            ( Nothing
            , applyText inputText
            , Dom.focus channelTextInputId
                |> Task.attempt (\_ -> setFocusMsg)
            )

        _ ->
            ( Nothing, inputText, Command.none )


pingDropdownView :
    MsgConfig msg
    -> GuildOrDmIdNoThread
    -> LocalState
    -> (Int -> HtmlId)
    -> MentionUserDropdown
    -> Element msg
pingDropdownView msgConfig guildOrDmId localState dropdownButtonId dropdown =
    Ui.column
        [ Ui.background MyUi.background2
        , MyUi.blockClickPropagation msgConfig.pressedPingDropdownContainer
        , Ui.borderColor MyUi.border1
        , Ui.border 1
        , Ui.Font.color MyUi.font2
        , Ui.move
            { x = round dropdown.inputElement.x
            , y = round (dropdown.inputElement.y - 400 + 1)
            , z = 0
            }
        , Ui.width (Ui.px (round dropdown.inputElement.width))
        , Ui.height (Ui.px 400)
        , Ui.clip
        , Ui.roundedWith { topLeft = 8, topRight = 8, bottomLeft = 0, bottomRight = 0 }

        --, Ui.Shadow.shadows [ { x = 0, y = 1, size = 0, blur = 4, color = Ui.rgba 0 0 0 0.2 } ]
        ]
        [ Ui.el [ Ui.Font.size 14, Ui.Font.bold, Ui.paddingXY 8 2 ] (Ui.text "Mention a user:")
        , Ui.column
            []
            (List.indexedMap
                (\index ( _, user ) ->
                    MyUi.elButton
                        (dropdownButtonId index)
                        (msgConfig.pressedPingUser index)
                        [ Ui.paddingXY 8 4
                        , Ui.Anim.focused (Ui.Anim.ms 100) [ Ui.Anim.backgroundColor MyUi.background3 ]
                        , if dropdown.dropdownIndex == index then
                            Ui.background MyUi.background3

                          else
                            Ui.noAttr
                        , Html.Events.on
                            "keydown"
                            (Json.Decode.field "key" Json.Decode.string
                                |> Json.Decode.andThen
                                    (\key ->
                                        if key == "ArrowDown" then
                                            Json.Decode.succeed (msgConfig.pressedArrowInDropdown (index + 1))

                                        else if key == "ArrowUp" then
                                            Json.Decode.succeed (msgConfig.pressedArrowInDropdown (index - 1))

                                        else
                                            Json.Decode.fail ""
                                    )
                            )
                            |> Ui.htmlAttribute
                        ]
                        (Ui.text (PersonName.toString user.name))
                )
                (userDropdownList guildOrDmId localState)
            )
        ]
