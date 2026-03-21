module MessageInput exposing
    ( MentionUserDropdown
    , Msg(..)
    , NameSoFar
    , TextInputFocus
    , disabledView
    , discordUserDropdownList
    , editView
    , isPress
    , pingDropdownView
    , pressedArrowInDropdown
    , pressedPingUser
    , userDropdownList
    , view
    )

import Discord
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.File as File exposing (File)
import Effect.Task as Task
import FileStatus exposing (FileId)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Icons
import Id exposing (AnyGuildOrDmId(..), DiscordGuildOrDmId(..), GuildOrDmId(..), Id, UserId)
import Json.Decode
import Json.Decode.Extra
import List.Extra
import List.Nonempty exposing (Nonempty)
import LocalState exposing (LocalState)
import MyUi exposing (Range)
import NonemptyDict
import PersonName exposing (PersonName)
import Ports
import RichText
import SeqDict exposing (SeqDict)
import String.Nonempty exposing (NonemptyString)
import Ui exposing (Element)
import Ui.Anim
import Ui.Events
import Ui.Font
import User exposing (DiscordFrontendUser, FrontendUser)


type alias MentionUserDropdown =
    { dropdownIndex : Int
    , inputElement : { x : Float, y : Float, width : Float, height : Float }
    }


type alias TextInputFocus =
    { htmlId : HtmlId, selection : Range, dropdown : Maybe MentionUserDropdown }


type alias NameSoFar =
    { nameSoFar : String, index : Int }


type Msg
    = TextInputGotFocus HtmlId
    | TextInputLostFocus HtmlId
    | PressedTextInput
    | TypedMessage String
    | PressedSendMessage
    | PressedArrowInDropdown Int
    | PressedArrowUpInEmptyInput
    | PressedPingUser Int
    | PressedPingDropdownContainer
    | PressedUploadFile
    | OnPasteFiles (Nonempty File)
    | OnSelectionChanged HtmlId Range


isPress : Msg -> Bool
isPress msg =
    case msg of
        TextInputGotFocus _ ->
            False

        TextInputLostFocus _ ->
            False

        PressedTextInput ->
            True

        TypedMessage _ ->
            False

        PressedSendMessage ->
            True

        PressedArrowInDropdown _ ->
            True

        PressedArrowUpInEmptyInput ->
            True

        PressedPingUser _ ->
            True

        PressedPingDropdownContainer ->
            True

        PressedUploadFile ->
            True

        OnPasteFiles _ ->
            False

        OnSelectionChanged _ _ ->
            False


textarea :
    Bool
    -> HtmlId
    -> String
    -> String
    -> SeqDict (Id FileId) a
    -> Maybe TextInputFocus
    -> SeqDict userId { b | name : PersonName }
    -> Html Msg
textarea isMobileKeyboard channelTextInputId placeholderText text attachedFiles textInputFocus users =
    let
        keyDownNoDropdown : Html.Attribute Msg
        keyDownNoDropdown =
            Html.Events.preventDefaultOn
                "keydown"
                (Json.Decode.map2 Tuple.pair
                    (Json.Decode.field "shiftKey" Json.Decode.bool)
                    (Json.Decode.field "key" Json.Decode.string)
                    |> Json.Decode.andThen
                        (\( shiftHeld, key ) ->
                            if key == "ArrowUp" && text == "" then
                                Json.Decode.succeed ( PressedArrowUpInEmptyInput, True )

                            else if key == "Enter" && not shiftHeld && not isMobileKeyboard then
                                Json.Decode.succeed ( PressedSendMessage, True )

                            else
                                Json.Decode.fail ""
                        )
                )
    in
    Html.div
        [ Html.Attributes.style "display" "flex"
        , Html.Attributes.style "position" "relative"
        , Html.Attributes.style "min-height" "min-content"
        , Html.Attributes.style "width" "100%"
        , Html.Attributes.style "height" "fit-content"
        ]
        [ Html.textarea
            [ Html.Attributes.style "color" "rgba(255,0,0,1)"
            , Html.Attributes.style "position" "absolute"
            , Html.Attributes.style "font-size" "inherit"
            , Html.Attributes.style "font-family" "inherit"
            , Html.Attributes.style "line-height" "inherit"
            , Html.Attributes.style "width" "calc(100% - 18px)"
            , Html.Attributes.style "height" "100%"
            , Dom.idToAttribute channelTextInputId
            , Html.Attributes.style "background-color" "transparent"
            , Html.Attributes.style "border" "0"
            , Html.Attributes.style "resize" "none"
            , Html.Attributes.style "overflow" "hidden"
            , Html.Attributes.style "caret-color" "white"
            , Html.Attributes.style "padding" "8px"
            , Html.Attributes.style "outline" "none"
            , Html.Events.onClick PressedTextInput
            , Html.Events.preventDefaultOn
                "paste"
                (Json.Decode.at
                    [ "clipboardData", "files" ]
                    (Json.Decode.Extra.collection File.decoder)
                    |> Json.Decode.andThen
                        (\list ->
                            case List.Nonempty.fromList list of
                                Just nonempty ->
                                    Json.Decode.succeed ( OnPasteFiles nonempty, True )

                                Nothing ->
                                    Json.Decode.fail ""
                        )
                )
            , Html.Events.onFocus (TextInputGotFocus channelTextInputId)
            , Html.Events.onBlur (TextInputLostFocus channelTextInputId)
            , case textInputFocus of
                Just textInputFocus2 ->
                    case textInputFocus2.dropdown of
                        Just { dropdownIndex } ->
                            Html.Events.preventDefaultOn
                                "keydown"
                                (Json.Decode.andThen
                                    (\key ->
                                        case key of
                                            "ArrowDown" ->
                                                Json.Decode.succeed ( PressedArrowInDropdown (dropdownIndex + 1), True )

                                            "ArrowUp" ->
                                                Json.Decode.succeed ( PressedArrowInDropdown (dropdownIndex - 1), True )

                                            "Enter" ->
                                                Json.Decode.succeed
                                                    ( PressedPingUser dropdownIndex, True )

                                            _ ->
                                                Json.Decode.fail ""
                                    )
                                    (Json.Decode.field "key" Json.Decode.string)
                                )

                        Nothing ->
                            keyDownNoDropdown

                Nothing ->
                    keyDownNoDropdown
            , Html.Events.onInput TypedMessage
            , MyUi.onSelectionChanged (OnSelectionChanged channelTextInputId)
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


disabledTextarea : String -> String -> SeqDict (Id FileId) a -> LocalState -> Html msg
disabledTextarea placeholderText text attachedFiles local =
    Html.div
        [ Html.Attributes.style "display" "flex"
        , Html.Attributes.style "position" "relative"
        , Html.Attributes.style "min-height" "min-content"
        , Html.Attributes.style "width" "100%"
        , Html.Attributes.style "height" "fit-content"
        ]
        [ Html.textarea
            [ Html.Attributes.style "color" "rgba(255,0,0,1)"
            , Html.Attributes.style "position" "absolute"
            , Html.Attributes.style "font-size" "inherit"
            , Html.Attributes.style "font-family" "inherit"
            , Html.Attributes.style "line-height" "inherit"
            , Html.Attributes.style "width" "calc(100% - 18px)"
            , Html.Attributes.style "height" "100%"
            , Html.Attributes.style "background-color" "transparent"
            , Html.Attributes.style "border" "0"
            , Html.Attributes.style "resize" "none"
            , Html.Attributes.style "overflow" "hidden"
            , Html.Attributes.style "caret-color" "white"
            , Html.Attributes.style "padding" "8px"
            , Html.Attributes.style "outline" "none"
            , Html.Attributes.value text
            , Html.Attributes.disabled True
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
                        users : SeqDict (Id UserId) FrontendUser
                        users =
                            LocalState.allUsers local.localUser
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
    -> HtmlId
    -> String
    -> String
    -> SeqDict (Id FileId) a
    -> Maybe TextInputFocus
    -> SeqDict userId { b | name : PersonName }
    -> Element Msg
editView htmlId height roundTopCorners isMobileKeyboard channelTextInputId placeholderText text attachedFiles pingUser users =
    let
        htmlIdPrefix : String
        htmlIdPrefix =
            Dom.idToString htmlId
    in
    textarea isMobileKeyboard channelTextInputId placeholderText text attachedFiles pingUser users
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
                    PressedUploadFile
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
                        (Json.Decode.succeed ( PressedUploadFile, True ))
                        |> Ui.htmlAttribute
                    ]
                    (Ui.html Icons.attachment)
                )
            , Ui.inFront
                (MyUi.elButton
                    (Dom.id (htmlIdPrefix ++ "_sendMessage"))
                    PressedSendMessage
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
                        (Json.Decode.succeed ( PressedSendMessage, True ))
                        |> Ui.htmlAttribute
                    ]
                    (Ui.html Icons.sendMessage)
                )
            ]


view :
    HtmlId
    -> Bool
    -> Bool
    -> HtmlId
    -> String
    -> String
    -> SeqDict (Id FileId) a
    -> Maybe TextInputFocus
    -> SeqDict userId { b | name : PersonName }
    -> Element Msg
view htmlId roundTopCorners isMobileKeyboard channelTextInputId placeholderText text attachedFiles pingUser users =
    let
        htmlIdPrefix : String
        htmlIdPrefix =
            Dom.idToString htmlId
    in
    textarea isMobileKeyboard channelTextInputId placeholderText text attachedFiles pingUser users
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
                    PressedUploadFile
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
                        (Json.Decode.succeed ( PressedUploadFile, True ))
                        |> Ui.htmlAttribute
                    ]
                    (Ui.html Icons.attachment)
                )
            , Ui.inFront
                (MyUi.elButton
                    (Dom.id (htmlIdPrefix ++ "_sendMessage"))
                    PressedSendMessage
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
                            { message = PressedSendMessage
                            , stopPropagation = True
                            , preventDefault = True
                            }
                        )
                        |> Ui.htmlAttribute
                    ]
                    (Ui.html Icons.sendMessage)
                )
            ]


disabledView :
    Bool
    -> String
    -> String
    -> SeqDict (Id FileId) a
    -> LocalState
    -> Element msg
disabledView roundTopCorners placeholderText text attachedFiles local =
    disabledTextarea placeholderText text attachedFiles local
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
                (Ui.el
                    [ Ui.alignLeft
                    , Ui.width Ui.shrink
                    , Ui.rounded 4
                    , Ui.paddingXY 6 0
                    , Ui.height (Ui.px 38)
                    , Ui.background MyUi.disabledButtonBackground
                    , Ui.move { x = 2, y = 0, z = 0 }
                    , Ui.contentCenterY
                    , Ui.centerY
                    ]
                    (Ui.html Icons.attachment)
                )
            , Ui.inFront
                (Ui.el
                    [ Ui.alignRight
                    , Ui.width Ui.shrink
                    , Ui.rounded 4
                    , Ui.paddingXY 4 0
                    , Ui.height (Ui.px 38)
                    , Ui.background MyUi.disabledButtonBackground
                    , Ui.move { x = -2, y = 0, z = 0 }
                    , Ui.contentCenterY
                    , Ui.centerY
                    ]
                    (Ui.html Icons.sendMessage)
                )
            ]


userDropdownList : Bool -> NameSoFar -> GuildOrDmId -> LocalState -> List ( Id UserId, FrontendUser )
userDropdownList isMobile nameSoFar guildOrDmId local =
    let
        allUsers : SeqDict (Id UserId) FrontendUser
        allUsers =
            LocalState.allUsers local.localUser
    in
    (case guildOrDmId of
        GuildOrDmId_Guild guildId _ ->
            case SeqDict.get guildId local.guilds of
                Just guild ->
                    guild.owner :: SeqDict.keys guild.members

                Nothing ->
                    []

        GuildOrDmId_Dm otherUserId ->
            [ local.localUser.session.userId, otherUserId ]
    )
        |> List.filterMap
            (\userId ->
                case SeqDict.get userId allUsers of
                    Just user ->
                        if String.startsWith nameSoFar.nameSoFar (PersonName.toString user.name) then
                            Just ( userId, user )

                        else
                            Nothing

                    Nothing ->
                        Nothing
            )
        |> List.sortBy (\( _, user ) -> PersonName.toString user.name)
        |> List.take (maxDropdownUsers isMobile)


maxDropdownUsers : Bool -> number
maxDropdownUsers isMobile =
    if isMobile then
        5

    else
        10


discordUserDropdownList : Bool -> NameSoFar -> DiscordGuildOrDmId -> LocalState -> List ( Discord.Id Discord.UserId, DiscordFrontendUser )
discordUserDropdownList isMobile nameSoFar guildOrDmId local =
    let
        allUsers : SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
        allUsers =
            LocalState.allDiscordUsers local.localUser
    in
    (case guildOrDmId of
        DiscordGuildOrDmId_Guild _ guildId _ ->
            case SeqDict.get guildId local.discordGuilds of
                Just guild ->
                    guild.owner :: SeqDict.keys guild.members

                Nothing ->
                    []

        DiscordGuildOrDmId_Dm data ->
            case SeqDict.get data.channelId local.discordDmChannels of
                Just channel ->
                    NonemptyDict.keys channel.members |> List.Nonempty.toList

                Nothing ->
                    []
    )
        |> List.filterMap
            (\userId ->
                case SeqDict.get userId allUsers of
                    Just user ->
                        if String.startsWith nameSoFar.nameSoFar (PersonName.toString user.name) then
                            Just ( userId, user )

                        else
                            Nothing

                    Nothing ->
                        Nothing
            )
        |> List.sortBy (\( _, user ) -> PersonName.toString user.name)
        |> List.take (maxDropdownUsers isMobile)


pressedArrowInDropdown : Bool -> NameSoFar -> AnyGuildOrDmId -> Int -> Maybe MentionUserDropdown -> LocalState -> Maybe MentionUserDropdown
pressedArrowInDropdown isMobile nameSoFar guildOrDmId index maybePingUser local =
    case maybePingUser of
        Just pingUser ->
            let
                dropdownListLength : Int
                dropdownListLength =
                    case guildOrDmId of
                        GuildOrDmId guildOrDmId2 ->
                            userDropdownList isMobile nameSoFar guildOrDmId2 local |> List.length

                        DiscordGuildOrDmId guildOrDmId2 ->
                            discordUserDropdownList isMobile nameSoFar guildOrDmId2 local |> List.length
            in
            { pingUser
                | dropdownIndex =
                    if index < 0 then
                        dropdownListLength - 1

                    else if index >= dropdownListLength then
                        0

                    else
                        index
            }
                |> Just

        Nothing ->
            Nothing


pressedPingUser :
    msg
    -> Bool
    -> NameSoFar
    -> AnyGuildOrDmId
    -> HtmlId
    -> Int
    -> Maybe MentionUserDropdown
    -> LocalState
    -> NonemptyString
    -> ( Maybe MentionUserDropdown, NonemptyString, Command FrontendOnly toMsg msg )
pressedPingUser setFocusMsg isMobile nameSoFar guildOrDmId channelTextInputId index pingUser local inputText =
    case ( pingUser, selectedUserName isMobile nameSoFar guildOrDmId index local ) of
        ( Just _, Just name ) ->
            ( Nothing
            , inputText
            , Command.batch
                [ Dom.focus channelTextInputId
                    |> Task.attempt (\_ -> setFocusMsg)
                , Ports.execCommand
                    channelTextInputId
                    nameSoFar.index
                    (nameSoFar.index + String.length nameSoFar.nameSoFar)
                    (name ++ " ")
                ]
            )

        _ ->
            ( Nothing, inputText, Command.none )


selectedUserName : Bool -> NameSoFar -> AnyGuildOrDmId -> Int -> LocalState -> Maybe String
selectedUserName isMobile nameSoFar guildOrDmId index local =
    case guildOrDmId of
        GuildOrDmId guildOrDmId2 ->
            case userDropdownList isMobile nameSoFar guildOrDmId2 local |> List.Extra.getAt index of
                Just ( _, user ) ->
                    PersonName.toString user.name |> Just

                Nothing ->
                    Nothing

        DiscordGuildOrDmId guildOrDmId2 ->
            case discordUserDropdownList isMobile nameSoFar guildOrDmId2 local |> List.Extra.getAt index of
                Just ( _, user ) ->
                    PersonName.toString user.name |> Just

                Nothing ->
                    Nothing


pingDropdownView :
    Bool
    -> NameSoFar
    -> AnyGuildOrDmId
    -> LocalState
    -> (Int -> HtmlId)
    -> MentionUserDropdown
    -> Element Msg
pingDropdownView isMobile nameSoFar guildOrDmId localState dropdownButtonId dropdown =
    let
        rows : List (Element Msg)
        rows =
            case guildOrDmId of
                GuildOrDmId guildOrDmId2 ->
                    List.indexedMap
                        (\index ( _, user ) -> dropdownButton isMobile dropdown dropdownButtonId index user.name)
                        (userDropdownList isMobile nameSoFar guildOrDmId2 localState)

                DiscordGuildOrDmId guildOrDmId2 ->
                    List.indexedMap
                        (\index ( _, user ) -> dropdownButton isMobile dropdown dropdownButtonId index user.name)
                        (discordUserDropdownList isMobile nameSoFar guildOrDmId2 localState)

        headerHeight =
            20

        pingDropdownViewHeight : Int
        pingDropdownViewHeight =
            List.length rows * dropdownButtonHeight isMobile + headerHeight
    in
    Ui.column
        [ Ui.background MyUi.background2
        , MyUi.blockClickPropagation PressedPingDropdownContainer
        , Ui.borderColor MyUi.border1
        , Ui.border 1
        , Ui.Font.color MyUi.font2
        , Ui.move
            { x = round dropdown.inputElement.x
            , y = round (dropdown.inputElement.y - toFloat pingDropdownViewHeight + 1)
            , z = 0
            }
        , Ui.width (Ui.px (round dropdown.inputElement.width))
        , Ui.height (Ui.px pingDropdownViewHeight)
        , Ui.clip
        , Ui.roundedWith { topLeft = 8, topRight = 8, bottomLeft = 0, bottomRight = 0 }

        --, Ui.Shadow.shadows [ { x = 0, y = 1, size = 0, blur = 4, color = Ui.rgba 0 0 0 0.2 } ]
        ]
        [ Ui.el
            [ Ui.Font.size 14, Ui.Font.bold, Ui.paddingXY 8 0, Ui.height (Ui.px headerHeight) ]
            (Ui.text "Mention a user:")
        , Ui.column [] rows
        ]


dropdownButtonHeight : Bool -> number
dropdownButtonHeight isMobile =
    if isMobile then
        50

    else
        30


dropdownButton : Bool -> MentionUserDropdown -> (Int -> HtmlId) -> Int -> PersonName -> Element Msg
dropdownButton isMobile dropdown dropdownButtonId index name =
    MyUi.elButton
        (dropdownButtonId index)
        (PressedPingUser index)
        [ Ui.Events.onMouseDown (PressedPingUser index)
        , MyUi.touchPress (PressedPingUser index)
        , Ui.paddingXY 8 0
        , Ui.contentCenterY
        , MyUi.hover isMobile [ Ui.Anim.backgroundColor MyUi.hoverHighlight ]
        , Ui.height (Ui.px (dropdownButtonHeight isMobile))
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
                            Json.Decode.succeed (PressedArrowInDropdown (index + 1))

                        else if key == "ArrowUp" then
                            Json.Decode.succeed (PressedArrowInDropdown (index - 1))

                        else
                            Json.Decode.fail ""
                    )
            )
            |> Ui.htmlAttribute
        ]
        (Ui.text (PersonName.toString name))
