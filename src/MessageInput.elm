module MessageInput exposing
    ( MentionUserDropdown
    , Msg(..)
    , NameSoFar(..)
    , NameSoFarData
    , TextInputFocus
    , disabledView
    , discordUserDropdownList
    , dropdownView
    , editView
    , emojiDropdownList
    , isPress
    , pressedArrowInDropdown
    , pressedDropdownItem
    , userDropdownList
    , view
    )

import Array
import Discord
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.File as File exposing (File)
import Effect.Task as Task
import Emoji exposing (CachedEmojiData, Emoji, SkinTone)
import FileStatus exposing (FileId)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Icons
import Id exposing (AnyGuildOrDmId(..), DiscordGuildOrDmId(..), GuildOrDmId(..), Id, StickerId, UserId)
import Json.Decode
import Json.Decode.Extra
import List.Extra
import List.Nonempty exposing (Nonempty)
import LocalState exposing (LocalState)
import MembersAndOwner
import MyUi
import NonemptyDict
import PersonName exposing (PersonName)
import Ports
import Range exposing (Range, SelectionDirection)
import RichText exposing (RichText)
import SeqDict exposing (SeqDict)
import Sticker exposing (StickerData)
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
    { htmlId : HtmlId, selection : Range, direction : SelectionDirection, dropdown : Maybe MentionUserDropdown }


type NameSoFar
    = NameSoFar NameSoFarData
    | EmojiSoFar NameSoFarData


type alias NameSoFarData =
    { nameSoFar : String, index : Int }


type Msg
    = PressedTextInput
    | TypedMessage String
    | PressedSendMessage
    | PressedArrowInDropdown Int
    | PressedArrowUpInEmptyInput
    | PressedDropdownItem Int
    | PressedPingDropdownContainer
    | PressedUploadFile
    | PressedOpenEmojiSelector
    | OnPasteFiles (Nonempty File)


counterThreshold : number
counterThreshold =
    900


isPress : Msg -> Bool
isPress msg =
    case msg of
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

        PressedDropdownItem _ ->
            True

        PressedPingDropdownContainer ->
            True

        PressedUploadFile ->
            True

        PressedOpenEmojiSelector ->
            True

        OnPasteFiles _ ->
            False


textarea :
    Bool
    -> HtmlId
    -> String
    -> String
    -> Maybe (Nonempty (RichText userId))
    -> SeqDict (Id FileId) a
    -> SeqDict (Id StickerId) StickerData
    -> Maybe TextInputFocus
    -> SeqDict userId { b | name : PersonName }
    -> Html Msg
textarea isMobileKeyboard channelTextInputId placeholderText text richText attachedFiles stickers textInputFocus users =
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
                                                    ( PressedDropdownItem dropdownIndex, True )

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
            , Html.Attributes.value text
            ]
            []
        , Html.div
            ([ Html.Attributes.style "pointer-events" "none"
             , Html.Attributes.style "padding" "0 9px 0 9px"
             , Html.Attributes.style "transform" "translateX(-1px) translateY(8px)"
             , Html.Attributes.style "overflow-wrap" "anywhere"
             , Html.Attributes.style "height" "fit-content"
             , Html.Attributes.style "min-height" "100%"
             ]
                ++ (if text == "" then
                        [ Html.Attributes.style "color" "rgb(180,180,180)"
                        , Html.Attributes.style "white-space" "nowrap"
                        , Html.Attributes.style "text-overflow" "ellipsis"
                        , Html.Attributes.style "overflow" "hidden"
                        ]

                    else
                        [ Html.Attributes.style "color" "rgb(255,255,255)", Html.Attributes.style "white-space" "pre-wrap" ]
                   )
            )
            (case richText of
                Just richText2 ->
                    RichText.textInputView
                        users
                        attachedFiles
                        stickers
                        (Maybe.map .selection textInputFocus)
                        richText2
                        ++ [ Html.text "\n" ]

                Nothing ->
                    [ if placeholderText == "" then
                        -- A normal space doesn't prevent the textarea from being 0 lines tall for some reason
                        Html.text "\u{00A0}"

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
                    RichText.textInputView
                        users
                        attachedFiles
                        local.localUser.stickers
                        Nothing
                        (RichText.fromNonemptyString users nonempty)
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
    -> Int
    -> String
    -> Maybe (Nonempty (RichText userId))
    -> SeqDict (Id FileId) a
    -> SeqDict (Id StickerId) StickerData
    -> Maybe TextInputFocus
    -> SeqDict userId { b | name : PersonName }
    -> Element Msg
editView htmlId height roundTopCorners isMobileKeyboard channelTextInputId placeholderText charsLeft text richText attachedFiles stickers pingUser users =
    let
        htmlIdPrefix : String
        htmlIdPrefix =
            Dom.idToString htmlId
    in
    textarea isMobileKeyboard channelTextInputId placeholderText text richText attachedFiles stickers pingUser users
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
            [ Ui.paddingWith { left = 80, right = 36, top = 0, bottom = 0 }
            , Ui.inFront
                (Ui.row
                    [ Ui.width Ui.shrink, Ui.move { x = 2, y = 0, z = 0 }, Ui.spacing 4 ]
                    [ attachmentButton htmlIdPrefix, showEmojiSelectorButton htmlIdPrefix ]
                )
            , Ui.inFront (characterCounter charsLeft)
            , Ui.inFront
                (MyUi.elButton
                    (Dom.id (htmlIdPrefix ++ "_sendMessage"))
                    PressedSendMessage
                    [ Ui.alignRight
                    , Ui.width Ui.shrink
                    , Ui.rounded 4
                    , Ui.paddingXY 4 0
                    , Ui.height (Ui.px 38)
                    , Ui.background
                        (if charsLeft < 0 then
                            MyUi.disabledButtonBackground

                         else
                            MyUi.buttonBackground
                        )
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
    -> Int
    -> String
    -> Maybe (Nonempty (RichText userId))
    -> SeqDict (Id FileId) a
    -> SeqDict (Id StickerId) StickerData
    -> Maybe TextInputFocus
    -> SeqDict userId { b | name : PersonName }
    -> Element Msg
view htmlId roundTopCorners isMobileKeyboard channelTextInputId placeholderText charsLeft text richText attachedFiles stickers pingUser users =
    let
        htmlIdPrefix : String
        htmlIdPrefix =
            Dom.idToString htmlId
    in
    textarea isMobileKeyboard channelTextInputId placeholderText text richText attachedFiles stickers pingUser users
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
            [ Ui.paddingWith { left = 80, right = 36, top = 0, bottom = 0 }
            , Ui.inFront
                (Ui.row
                    [ Ui.width Ui.shrink, Ui.move { x = 2, y = 2, z = 0 }, Ui.spacing 4 ]
                    [ attachmentButton htmlIdPrefix, showEmojiSelectorButton htmlIdPrefix ]
                )
            , Ui.inFront (characterCounter charsLeft)
            , Ui.inFront
                (MyUi.elButton
                    (Dom.id (htmlIdPrefix ++ "_sendMessage"))
                    PressedSendMessage
                    [ Ui.alignRight
                    , Ui.width Ui.shrink
                    , Ui.rounded 4
                    , Ui.paddingXY 4 0
                    , Ui.height (Ui.px 38)
                    , Ui.background
                        (if charsLeft < 0 then
                            MyUi.disabledButtonBackground

                         else
                            MyUi.buttonBackground
                        )
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


characterCounter : Int -> Element msg
characterCounter charsLeft =
    if charsLeft <= counterThreshold then
        Ui.el
            [ Ui.alignBottom
            , Ui.alignLeft
            , Ui.width Ui.shrink
            , Ui.paddingXY 6 2
            , Ui.Font.size 12
            , Ui.Font.color
                (if charsLeft < 0 then
                    MyUi.errorColor

                 else
                    MyUi.font3
                )
            , Ui.move { x = 2, y = -2, z = 0 }
            ]
            (Ui.text (String.fromInt charsLeft ++ "/" ++ String.fromInt RichText.maxLength))

    else
        Ui.none


attachmentButton : String -> Element Msg
attachmentButton htmlIdPrefix =
    MyUi.elButton
        (Dom.id (htmlIdPrefix ++ "_uploadFile"))
        PressedUploadFile
        [ Ui.rounded 4
        , Ui.paddingXY 6 0
        , Ui.height (Ui.px 40)
        , Ui.background MyUi.buttonBackground
        , Ui.contentCenterY
        , Ui.centerY
        , Html.Events.preventDefaultOn
            "touchend"
            (Json.Decode.succeed ( PressedUploadFile, True ))
            |> Ui.htmlAttribute
        ]
        (Ui.html Icons.attachment)


showEmojiSelectorButton : String -> Element Msg
showEmojiSelectorButton htmlIdPrefix =
    Ui.el
        [ Ui.rounded 4
        , Ui.id (htmlIdPrefix ++ "_openEmojiSelector")
        , Ui.pointer
        , Ui.paddingXY 6 0
        , Ui.height (Ui.px 40)
        , Ui.background MyUi.buttonBackground
        , Ui.contentCenterY
        , Ui.centerY
        , Ui.Events.stopPropagationOn "click" (Json.Decode.succeed ( PressedOpenEmojiSelector, True ))
        , Html.Events.preventDefaultOn
            "touchend"
            (Json.Decode.succeed ( PressedOpenEmojiSelector, True ))
            |> Ui.htmlAttribute
        ]
        (Ui.html Icons.smile)


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


userDropdownList : Bool -> NameSoFarData -> GuildOrDmId -> LocalState -> List ( Id UserId, FrontendUser )
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
                    MembersAndOwner.membersAndOwner guild.membersAndOwner

                Nothing ->
                    []

        GuildOrDmId_Dm otherUserId ->
            if local.localUser.session.userId == otherUserId then
                [ otherUserId ]

            else
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


emojiDropdownList : Bool -> NameSoFarData -> CachedEmojiData -> List Emoji
emojiDropdownList isMobile nameSoFar emojiData =
    let
        substring =
            String.toLower nameSoFar.nameSoFar
    in
    if String.length substring > 2 then
        Array.filter (\item -> String.contains substring item.shortName) emojiData.shortNames
            |> Array.toList
            |> List.map .emoji
            |> List.take (maxDropdownUsers isMobile)

    else
        []


discordUserDropdownList : Bool -> NameSoFarData -> DiscordGuildOrDmId -> LocalState -> List ( Discord.Id Discord.UserId, DiscordFrontendUser )
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
                    MembersAndOwner.membersAndOwner guild.membersAndOwner

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


pressedArrowInDropdown :
    Bool
    -> NameSoFar
    -> AnyGuildOrDmId
    -> Int
    -> Maybe MentionUserDropdown
    -> Maybe CachedEmojiData
    -> LocalState
    -> Maybe MentionUserDropdown
pressedArrowInDropdown isMobile nameSoFar guildOrDmId index maybePingUser emojiData local =
    case maybePingUser of
        Just pingUser ->
            let
                helper : Int -> Maybe MentionUserDropdown
                helper dropdownListLength =
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
            in
            case nameSoFar of
                NameSoFar nameSoFarData ->
                    case guildOrDmId of
                        GuildOrDmId guildOrDmId2 ->
                            userDropdownList isMobile nameSoFarData guildOrDmId2 local |> List.length |> helper

                        DiscordGuildOrDmId guildOrDmId2 ->
                            discordUserDropdownList isMobile nameSoFarData guildOrDmId2 local |> List.length |> helper

                EmojiSoFar emojiSoFar ->
                    case emojiData of
                        Just emojiData2 ->
                            emojiDropdownList isMobile emojiSoFar emojiData2 |> List.length |> helper

                        Nothing ->
                            Nothing

        Nothing ->
            Nothing


pressedDropdownItem :
    msg
    -> Bool
    -> NameSoFar
    -> AnyGuildOrDmId
    -> HtmlId
    -> Int
    -> Maybe MentionUserDropdown
    -> Maybe CachedEmojiData
    -> LocalState
    -> NonemptyString
    -> ( Maybe MentionUserDropdown, NonemptyString, Command FrontendOnly toMsg msg )
pressedDropdownItem setFocusMsg isMobile nameSoFar guildOrDmId channelTextInputId dropdownIndex pingUser emojiData local inputText =
    let
        maybeTextToInsert : Maybe ( Range, String )
        maybeTextToInsert =
            case nameSoFar of
                NameSoFar nameSoFarData ->
                    case guildOrDmId of
                        GuildOrDmId guildOrDmId2 ->
                            case
                                userDropdownList isMobile nameSoFarData guildOrDmId2 local
                                    |> List.Extra.getAt dropdownIndex
                            of
                                Just ( _, user ) ->
                                    ( { start = nameSoFarData.index
                                      , end = nameSoFarData.index + String.length nameSoFarData.nameSoFar
                                      }
                                    , PersonName.toString user.name
                                    )
                                        |> Just

                                Nothing ->
                                    Nothing

                        DiscordGuildOrDmId guildOrDmId2 ->
                            case
                                discordUserDropdownList isMobile nameSoFarData guildOrDmId2 local
                                    |> List.Extra.getAt dropdownIndex
                            of
                                Just ( _, user ) ->
                                    ( { start = nameSoFarData.index
                                      , end = nameSoFarData.index + String.length nameSoFarData.nameSoFar
                                      }
                                    , PersonName.toString user.name
                                    )
                                        |> Just

                                Nothing ->
                                    Nothing

                EmojiSoFar emojiSoFar ->
                    case emojiData of
                        Just emojiData2 ->
                            case emojiDropdownList isMobile emojiSoFar emojiData2 |> List.Extra.getAt dropdownIndex of
                                Just emoji ->
                                    ( { start = emojiSoFar.index - 1
                                      , end = emojiSoFar.index + String.length emojiSoFar.nameSoFar
                                      }
                                    , Emoji.emojiWithSkinTone local.localUser.user.emojiConfig.skinTone emoji emojiData2
                                    )
                                        |> Just

                                Nothing ->
                                    Nothing

                        Nothing ->
                            Nothing
    in
    case ( pingUser, maybeTextToInsert ) of
        ( Just _, Just ( range, textToInsert ) ) ->
            ( Nothing
            , inputText
            , Command.batch
                [ Dom.focus channelTextInputId
                    |> Task.attempt (\_ -> setFocusMsg)
                , Ports.execCommand
                    { htmlId = channelTextInputId
                    , commands = [ Ports.InsertText (textToInsert ++ " ") range ]
                    }
                ]
            )

        _ ->
            ( Nothing, inputText, Command.none )


dropdownView :
    Bool
    -> NameSoFar
    -> AnyGuildOrDmId
    -> Maybe SkinTone
    -> Maybe CachedEmojiData
    -> LocalState
    -> (Int -> HtmlId)
    -> MentionUserDropdown
    -> Element Msg
dropdownView isMobile nameSoFar guildOrDmId skinTone emojiData localState dropdownButtonId dropdown =
    case nameSoFar of
        NameSoFar nameSoFarData ->
            let
                rows : List (Element Msg)
                rows =
                    case guildOrDmId of
                        GuildOrDmId guildOrDmId2 ->
                            List.indexedMap
                                (\index ( _, user ) ->
                                    dropdownButton
                                        isMobile
                                        dropdown
                                        dropdownButtonId
                                        index
                                        (Ui.text (PersonName.toString user.name))
                                )
                                (userDropdownList isMobile nameSoFarData guildOrDmId2 localState)

                        DiscordGuildOrDmId guildOrDmId2 ->
                            List.indexedMap
                                (\index ( _, user ) ->
                                    dropdownButton
                                        isMobile
                                        dropdown
                                        dropdownButtonId
                                        index
                                        (Ui.text (PersonName.toString user.name))
                                )
                                (discordUserDropdownList isMobile nameSoFarData guildOrDmId2 localState)

                pingDropdownViewHeight : Int
                pingDropdownViewHeight =
                    List.length rows * dropdownButtonHeight isMobile
            in
            dropdownContainer dropdown pingDropdownViewHeight rows

        EmojiSoFar emojiSoFar ->
            case emojiData of
                Just emojiData2 ->
                    let
                        rows =
                            List.indexedMap
                                (\index emoji ->
                                    dropdownButton
                                        isMobile
                                        dropdown
                                        dropdownButtonId
                                        index
                                        (Ui.row
                                            [ Ui.spacing 8 ]
                                            [ Ui.el
                                                [ Ui.Font.size 24, Ui.width Ui.shrink ]
                                                (Ui.text (Emoji.emojiWithSkinTone skinTone emoji emojiData2))
                                            , case SeqDict.get emoji emojiData2.emojis of
                                                Just emoji2 ->
                                                    Ui.row
                                                        [ Ui.spacing 8 ]
                                                        (List.map (\shortName -> Ui.text (":" ++ shortName ++ ":")) emoji2.shortNames)

                                                Nothing ->
                                                    Ui.none
                                            ]
                                        )
                                )
                                (emojiDropdownList isMobile emojiSoFar emojiData2)

                        pingDropdownViewHeight : Int
                        pingDropdownViewHeight =
                            List.length rows * dropdownButtonHeight isMobile
                    in
                    dropdownContainer dropdown pingDropdownViewHeight rows

                Nothing ->
                    dropdownContainer dropdown 40 [ Ui.el [ Ui.height (Ui.px 40) ] (Ui.text "Loading emojis...") ]


dropdownContainer : MentionUserDropdown -> Int -> List (Element Msg) -> Element Msg
dropdownContainer dropdown contentHeight content =
    let
        headerHeight : number
        headerHeight =
            20
    in
    Ui.column
        [ Ui.background MyUi.background2
        , MyUi.blockClickPropagation PressedPingDropdownContainer
        , Ui.borderColor MyUi.border1
        , Ui.border 1
        , Ui.Font.color MyUi.font2
        , Ui.move
            { x = round dropdown.inputElement.x
            , y = round (dropdown.inputElement.y - (toFloat contentHeight + headerHeight) + 1)
            , z = 0
            }
        , Ui.width (Ui.px (round dropdown.inputElement.width))
        , Ui.height (Ui.px (contentHeight + headerHeight))
        , Ui.clip
        , Ui.roundedWith { topLeft = 8, topRight = 8, bottomLeft = 0, bottomRight = 0 }

        --, Ui.Shadow.shadows [ { x = 0, y = 1, size = 0, blur = 4, color = Ui.rgba 0 0 0 0.2 } ]
        ]
        [ Ui.el
            [ Ui.Font.size 14, Ui.Font.bold, Ui.paddingXY 8 0, Ui.height (Ui.px headerHeight) ]
            (Ui.text "Mention a user:")
        , Ui.column [] content
        ]


dropdownButtonHeight : Bool -> number
dropdownButtonHeight isMobile =
    if isMobile then
        50

    else
        30


dropdownButton : Bool -> MentionUserDropdown -> (Int -> HtmlId) -> Int -> Element Msg -> Element Msg
dropdownButton isMobile dropdown dropdownButtonId index content =
    MyUi.elButton
        (dropdownButtonId index)
        (PressedDropdownItem index)
        [ Ui.Events.onMouseDown (PressedDropdownItem index)
        , MyUi.touchPress (PressedDropdownItem index)
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
        content
