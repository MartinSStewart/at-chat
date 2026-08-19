module MessageInput exposing
    ( MentionUserDropdown
    , Msg(..)
    , NameSoFar(..)
    , NameSoFarData
    , TextInputFocus
    , TimestampData(..)
    , disabledView
    , editView
    , insertTab
    , isPress
    , largePastedText
    , tabText
    , textarea
    , view
    )

import CustomEmoji exposing (CustomEmojiData)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.File as File exposing (File)
import Effect.Time as Time
import FileStatus exposing (FileId, FileStatus)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Icons
import Id exposing (AnyGuildOrDmId(..), CustomEmojiId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, StickerId, UserId)
import Json.Decode
import Json.Decode.Extra
import List.Nonempty exposing (Nonempty)
import MyUi
import PersonName exposing (PersonName)
import Range exposing (Range, SelectionDirection)
import RichText exposing (RichText)
import SeqDict exposing (SeqDict)
import Sticker exposing (StickerData)
import String.Nonempty exposing (NonemptyString)
import Ui exposing (Element)
import Ui.Events
import Ui.Font
import User exposing (FrontendUser, LocalUser)
import UserAgent exposing (Browser(..), UserAgent)
import UserSession exposing (DiscordFrontendUser)


type alias MentionUserDropdown =
    { dropdownIndex : Int
    , inputElement : { x : Float, y : Float, width : Float, height : Float }
    }


type alias TextInputFocus =
    { htmlId : HtmlId, selection : Range, direction : SelectionDirection, dropdown : Maybe MentionUserDropdown }


type NameSoFar
    = NameSoFar NameSoFarData
    | EmojiSoFar NameSoFarData
    | TimestampSoFar Range TimestampData


type TimestampData
    = WeekOffset Float
    | DayOffset Float
    | HourOffset Float
    | MinuteOffset Float
    | TimeOfDay { hours : Int, minutes : Int }


type alias NameSoFarData =
    { nameSoFar : String, index : Int }


type Msg
    = PressedTextInput
    | TypedMessage String
    | PressedSendMessage { charsLeft : Int }
    | TypedArrowInDropdown Int
    | TypedArrowUpInEmptyInput
    | PressedDropdownItem Int
    | PressedPingDropdownContainer
    | PressedUploadFile
    | PressedOpenEmojiSelector
    | OnPasteFiles (Nonempty File)
    | TypedPageUp
    | TypedPageDown
    | TypedTabInCodeBlock Range
      -- A key press that the textarea gets to handle in its normal way. It only exists because
      -- Html.Events.preventDefaultOn needs a msg to hand back.
    | IgnoredKeyPress


counterThreshold : number
counterThreshold =
    900


{-| Pasted text has to be longer than this before it's turned into a file attachment.
-}
largePasteThreshold : number
largePasteThreshold =
    1000


{-| If the text input changed by a large chunk of text appearing all at once (i.e. the user pasted something long) and the result doesn't fit within a single message, return the pasted text so it can be attached as a file instead, along with the text surrounding it.
-}
largePastedText : String -> String -> Maybe { textBeforePaste : String, pastedText : String, textAfterPaste : String }
largePastedText previousText text =
    if String.length text > RichText.maxLength then
        let
            previousChars : List Char
            previousChars =
                String.toList previousText

            chars : List Char
            chars =
                String.toList text

            prefixLength : Int
            prefixLength =
                commonPrefixLength 0 previousChars chars

            suffixLength : Int
            suffixLength =
                commonPrefixLength
                    0
                    (List.drop prefixLength previousChars |> List.reverse)
                    (List.drop prefixLength chars |> List.reverse)

            pastedText : String
            pastedText =
                List.drop prefixLength chars
                    |> List.take (List.length chars - prefixLength - suffixLength)
                    |> String.fromList
        in
        if String.length pastedText > largePasteThreshold then
            Just
                { textBeforePaste = List.take prefixLength chars |> String.fromList
                , pastedText = pastedText
                , textAfterPaste = List.drop (List.length chars - suffixLength) chars |> String.fromList
                }

        else
            Nothing

    else
        Nothing


commonPrefixLength : Int -> List Char -> List Char -> Int
commonPrefixLength count listA listB =
    case ( listA, listB ) of
        ( headA :: restA, headB :: restB ) ->
            if headA == headB then
                commonPrefixLength (count + 1) restA restB

            else
                count

        _ ->
            count


isPress : Msg -> Bool
isPress msg =
    case msg of
        PressedTextInput ->
            True

        TypedMessage _ ->
            False

        PressedSendMessage _ ->
            True

        TypedArrowInDropdown _ ->
            False

        TypedArrowUpInEmptyInput ->
            False

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

        TypedPageUp ->
            False

        TypedPageDown ->
            False

        TypedTabInCodeBlock _ ->
            False

        IgnoredKeyPress ->
            False


{-| The two spaces that get inserted when tab is pressed inside a code block.
-}
tabText : String
tabText =
    "  "


{-| Replaces the selected text (or inserts, if nothing is selected) with `tabText`.
-}
insertTab : Range -> String -> String
insertTab range text =
    String.left range.start text ++ tabText ++ String.dropLeft range.end text


{-| The selection, but only if the cursor is inside a code block. This is an ad hoc check rather
than a full parse: an odd number of triple backticks before the cursor means the most recent one
opened a code block that hasn't been closed yet.
-}
selectionInsideCodeBlock : String -> Maybe Range -> Maybe Range
selectionInsideCodeBlock text maybeSelection =
    case maybeSelection of
        Just selection ->
            if modBy 2 (String.left selection.start text |> String.indexes "```" |> List.length) == 1 then
                Just selection

            else
                Nothing

        Nothing ->
            Nothing


textarea :
    Bool
    -> HtmlId
    -> String
    -> Int
    -> String
    -> Maybe (Nonempty (RichText userId))
    -> SeqDict (Id FileId) a
    ->
        { localUser
            | userAgent : UserAgent
            , timezone : Time.Zone
            , stickers : SeqDict (Id StickerId) StickerData
            , customEmojis : SeqDict (Id CustomEmojiId) CustomEmojiData
        }
    -> { c | typedTextCounter : Int, textInputFocus : Maybe TextInputFocus }
    -> SeqDict userId { b | name : PersonName }
    -> Html Msg
textarea isMobileKeyboard channelTextInputId placeholderText charsLeft text richText attachedFiles localUser loggedIn users =
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
                                Json.Decode.succeed ( TypedArrowUpInEmptyInput, True )

                            else if key == "Enter" && not shiftHeld && not isMobileKeyboard then
                                case codeBlockSelection of
                                    Just _ ->
                                        -- The user is writing a code block so the textarea gets to
                                        -- insert a line break instead of the message being sent.
                                        Json.Decode.succeed ( IgnoredKeyPress, False )

                                    Nothing ->
                                        Json.Decode.succeed ( PressedSendMessage { charsLeft = charsLeft }, True )

                            else if key == "Tab" && not shiftHeld then
                                -- Shift+tab is left out so there's still a way to move the focus
                                -- out of the message input with the keyboard.
                                case codeBlockSelection of
                                    Just range ->
                                        Json.Decode.succeed ( TypedTabInCodeBlock range, True )

                                    Nothing ->
                                        -- Outside of a code block, tab moves the focus like usual.
                                        Json.Decode.succeed ( IgnoredKeyPress, False )

                            else if key == "PageUp" then
                                Json.Decode.succeed ( TypedPageUp, True )

                            else if key == "PageDown" then
                                Json.Decode.succeed ( TypedPageDown, True )

                            else
                                Json.Decode.fail ""
                        )
                )

        selection : Maybe Range
        selection =
            case loggedIn.textInputFocus of
                Just textInputFocus ->
                    -- Only this input's selection gets drawn. Otherwise text in every message input
                    -- on screen is highlighted when one of them is focused.
                    if textInputFocus.htmlId == channelTextInputId then
                        Just textInputFocus.selection

                    else
                        Nothing

                Nothing ->
                    Nothing

        codeBlockSelection : Maybe Range
        codeBlockSelection =
            selectionInsideCodeBlock text selection
    in
    Html.div
        [ Html.Attributes.style "display" "flex"
        , Html.Attributes.style "position" "relative"
        , Html.Attributes.style "min-height" "min-content"
        , Html.Attributes.style "width" "100%"
        , Html.Attributes.style "height" "fit-content"
        , Html.Attributes.style
            "letter-spacing"
            (if localUser.userAgent.browser == Safari && modBy 2 loggedIn.typedTextCounter == 0 then
                "-0.001px"

             else
                "0"
            )
        , RichText.bigEmojiFont

        -- Keeps the textarea's z-index from escaping this div and covering the buttons that are
        -- placed in front of the message input.
        , Html.Attributes.style "isolation" "isolate"
        ]
        [ -- The textarea is drawn on top of the rich text, otherwise the caret is hidden behind
          -- backgrounds the rich text draws (spoilers and inline code are opaque). The text it
          -- contains is transparent so that the rich text below is what you actually see, and the
          -- selection highlight is translucent so it doesn't hide the rich text either (see the
          -- rich-text-input rules in MyUi.css).
          Html.textarea
            [ Html.Attributes.class "rich-text-input"
            , Html.Attributes.style "z-index" "1"
            , Html.Attributes.style "color" "transparent"

            -- Safari uses this instead of color when filling in glyphs
            , Html.Attributes.style "-webkit-text-fill-color" "transparent"
            , Html.Attributes.style "position" "absolute"
            , Html.Attributes.style "font-size" "inherit"
            , Html.Attributes.style "font-family" "inherit"
            , Html.Attributes.style "line-height" "inherit"
            , Html.Attributes.style "letter-spacing" "inherit"
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
            , case loggedIn.textInputFocus of
                Just textInputFocus2 ->
                    case textInputFocus2.dropdown of
                        Just { dropdownIndex } ->
                            Html.Events.preventDefaultOn
                                "keydown"
                                (Json.Decode.andThen
                                    (\key ->
                                        case key of
                                            "ArrowDown" ->
                                                Json.Decode.succeed ( TypedArrowInDropdown (dropdownIndex + 1), True )

                                            "ArrowUp" ->
                                                Json.Decode.succeed ( TypedArrowInDropdown (dropdownIndex - 1), True )

                                            "Enter" ->
                                                Json.Decode.succeed
                                                    ( PressedDropdownItem dropdownIndex, True )

                                            "PageUp" ->
                                                Json.Decode.succeed ( TypedPageUp, True )

                                            "PageDown" ->
                                                Json.Decode.succeed ( TypedPageDown, True )

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
            (textareaOverlayAttributes text)
            (case richText of
                Just richText2 ->
                    RichText.textInputView
                        localUser.timezone
                        users
                        attachedFiles
                        localUser.customEmojis
                        localUser.stickers
                        selection
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


disabledTextarea : String -> String -> SeqDict (Id FileId) a -> LocalUser -> Html msg
disabledTextarea placeholderText text attachedFiles localUser =
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
            (textareaOverlayAttributes text)
            (case String.Nonempty.fromString text of
                Just nonempty ->
                    let
                        users : SeqDict (Id UserId) FrontendUser
                        users =
                            SeqDict.insert
                                localUser.session.userId
                                (User.backendToFrontendForUser localUser.user)
                                localUser.otherUsers
                    in
                    RichText.textInputView
                        localUser.timezone
                        users
                        attachedFiles
                        localUser.customEmojis
                        localUser.stickers
                        Nothing
                        (RichText.fromNonemptyString localUser.timezone users nonempty)
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


textareaOverlayAttributes : String -> List (Html.Attribute msg)
textareaOverlayAttributes text =
    [ Html.Attributes.style "pointer-events" "none"
    , Html.Attributes.style "padding" "0 9px 0 9px"
    , Html.Attributes.style "transform" "translateX(-1px) translateY(8px)"
    , Html.Attributes.style "overflow-wrap" "anywhere"
    , Html.Attributes.style "height" "fit-content"
    , Html.Attributes.style "min-height" "100%"

    -- Without this the overlay is a flex item sized by its own max-content width. Custom emoji and
    -- stickers are written with zero width spaces (see Sticker.toBase4) and Safari counts a zero
    -- width space as a line break when it measures max-content, so the overlay ends up only as wide
    -- as the widest piece of text between two of them. Text that fits on one line in the textarea
    -- then wraps in the overlay and the two stop lining up. Filling the flex line instead makes the
    -- overlay as wide as the textarea it's drawn behind, which is the width it should wrap at anyway.
    , Html.Attributes.style "flex-grow" "1"
    ]
        ++ (if text == "" then
                [ Html.Attributes.style "color" (MyUi.colorToStyle MyUi.dimFont)
                , Html.Attributes.style "white-space" "nowrap"
                , Html.Attributes.style "text-overflow" "ellipsis"
                , Html.Attributes.style "overflow" "hidden"
                ]

            else
                [ Html.Attributes.style "color" (MyUi.colorToStyle MyUi.white), Html.Attributes.style "white-space" "pre-wrap" ]
           )


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
    -> Bool
    -> SeqDict (Id FileId) a
    -> LocalUser
    -> { c | typedTextCounter : Int, textInputFocus : Maybe TextInputFocus }
    -> SeqDict userId { b | name : PersonName }
    -> Element Msg
editView htmlId height roundTopCorners isMobileKeyboard channelTextInputId placeholderText charsLeft text richText attachmentsUploading attachedFiles localUser loggedIn users =
    let
        htmlIdPrefix : String
        htmlIdPrefix =
            Dom.idToString htmlId
    in
    textarea
        isMobileKeyboard
        channelTextInputId
        placeholderText
        charsLeft
        text
        richText
        attachedFiles
        localUser
        loggedIn
        users
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
                    (PressedSendMessage { charsLeft = charsLeft })
                    [ Ui.alignRight
                    , Ui.width Ui.shrink
                    , Ui.rounded 4
                    , Ui.paddingXY 4 0
                    , Ui.height (Ui.px 38)
                    , Ui.background
                        (if charsLeft < 0 || attachmentsUploading then
                            MyUi.disabledButtonBackground

                         else
                            MyUi.buttonBackground
                        )
                    , Ui.move { x = -2, y = 0, z = 0 }
                    , Ui.contentCenterY
                    , Ui.centerY
                    , MyUi.hoverText "Send message"
                    , Html.Events.preventDefaultOn
                        "touchend"
                        (Json.Decode.succeed ( PressedSendMessage { charsLeft = charsLeft }, True ))
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
    -> SeqDict (Id FileId) FileStatus
    ->
        { localUser
            | userAgent : UserAgent
            , timezone : Time.Zone
            , stickers : SeqDict (Id StickerId) StickerData
            , customEmojis : SeqDict (Id CustomEmojiId) CustomEmojiData
        }
    -> { a | typedTextCounter : Int, textInputFocus : Maybe TextInputFocus }
    -> SeqDict userId { b | name : PersonName }
    -> Element Msg
view htmlId roundTopCorners isMobileKeyboard channelTextInputId placeholderText charsLeft text richText attachedFiles localUser loggedIn users =
    let
        htmlIdPrefix : String
        htmlIdPrefix =
            Dom.idToString htmlId
    in
    textarea
        isMobileKeyboard
        channelTextInputId
        placeholderText
        charsLeft
        text
        richText
        attachedFiles
        localUser
        loggedIn
        users
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
                    (PressedSendMessage { charsLeft = charsLeft })
                    [ Ui.alignRight
                    , Ui.width Ui.shrink
                    , Ui.rounded 4
                    , Ui.paddingXY 4 0
                    , Ui.height (Ui.px 38)
                    , Ui.background
                        (if charsLeft < 0 || FileStatus.hasUploadingFile attachedFiles then
                            MyUi.disabledButtonBackground

                         else
                            MyUi.buttonBackground
                        )
                    , Ui.move { x = -2, y = 0, z = 0 }
                    , Ui.contentCenterY
                    , Ui.centerY
                    , MyUi.hoverText "Send message"
                    , Html.Events.custom
                        "touchstart"
                        (Json.Decode.succeed
                            { message = PressedSendMessage { charsLeft = charsLeft }
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
        , MyUi.hoverText "Attach file"
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
        , MyUi.hoverText "Add emoji"
        , Ui.Events.stopPropagationOn "click" (Json.Decode.succeed ( PressedOpenEmojiSelector, True ))
        , Html.Events.preventDefaultOn
            "touchend"
            (Json.Decode.succeed ( PressedOpenEmojiSelector, True ))
            |> Ui.htmlAttribute
        ]
        (Ui.html Icons.smile)


disabledView : Bool -> String -> String -> SeqDict (Id FileId) a -> LocalUser -> Element msg
disabledView roundTopCorners placeholderText text attachedFiles localUser =
    disabledTextarea placeholderText text attachedFiles localUser
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
