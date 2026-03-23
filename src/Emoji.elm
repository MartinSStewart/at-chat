module Emoji exposing (Emoji(..), EmojiData, EmojiResponse, Msg(..), fromDiscord, isPressed, requestEmojiData, selector, toString, view)

import Codec exposing (Codec)
import Discord
import Effect.Browser.Dom as Dom
import Effect.Command exposing (Command)
import Effect.Http as Http
import Hex
import List.Extra
import MyUi
import SeqDict exposing (SeqDict)
import Ui exposing (Element)
import Ui.Font


{-| OpaqueVariants
-}
type Emoji
    = UnicodeEmoji String


toString : Emoji -> String
toString emoji =
    case emoji of
        UnicodeEmoji text ->
            text


view : Emoji -> Ui.Element msg
view emoji =
    case emoji of
        UnicodeEmoji text ->
            Ui.el [ Ui.Font.size 20 ] (Ui.text text)


fromDiscord : Discord.EmojiData -> Emoji
fromDiscord emoji =
    case emoji.type_ of
        Discord.UnicodeEmojiType string ->
            UnicodeEmoji string

        Discord.CustomEmojiType _ ->
            UnicodeEmoji "❓"


type Category
    = Activities
    | AnimalsAndNature
    | Components
    | Flags
    | FoodAndDrink
    | Objects
    | PeopleAndBody
    | SmileysAndEmotion
    | Symbols
    | TravelAndPlaces


categoryToString : Category -> String
categoryToString category =
    case category of
        Activities ->
            "Activities"

        AnimalsAndNature ->
            "Animals & Nature"

        Components ->
            "Component"

        Flags ->
            "Flags"

        FoodAndDrink ->
            "Food & Drink"

        Objects ->
            "Objects"

        PeopleAndBody ->
            "People & Body"

        SmileysAndEmotion ->
            "Smileys & Emotion"

        Symbols ->
            "Symbols"

        TravelAndPlaces ->
            "Travel & Places"


allCategories : List Category
allCategories =
    [ Activities
    , AnimalsAndNature
    , Components
    , Flags
    , FoodAndDrink
    , Objects
    , PeopleAndBody
    , SmileysAndEmotion
    , Symbols
    , TravelAndPlaces
    ]


type alias EmojiData =
    { categories : SeqDict Category (List String) }


type alias EmojiResponse =
    { char : String, shortNames : List String, category : Category }


type Msg
    = PressedContainer
    | PressedSelectorEmoji Emoji


isPressed : Msg -> Bool
isPressed msg =
    case msg of
        PressedContainer ->
            True

        PressedSelectorEmoji emoji ->
            True


selector : Maybe EmojiData -> Element Msg
selector emojiData =
    let
        columns =
            16
    in
    Ui.column
        [ Ui.width (Ui.px (columns * 32 + 21))
        , Ui.height (Ui.px 400)
        , Ui.scrollable
        , Ui.background MyUi.background1
        , Ui.border 1
        , Ui.borderColor MyUi.border1
        , Ui.Font.size 24
        , MyUi.blockClickPropagation PressedContainer
        ]
        (case emojiData of
            Just emojiData2 ->
                List.map
                    (\( category, emojis ) ->
                        Ui.text (categoryToString category)
                            :: List.map
                                (\emojiRow ->
                                    Ui.row
                                        [ Ui.height (Ui.px 34) ]
                                        (List.map
                                            (\emoji ->
                                                let
                                                    emojiText =
                                                        emoji
                                                in
                                                MyUi.elButton
                                                    (Dom.id ("guild_emojiSelector_" ++ emojiText))
                                                    (PressedSelectorEmoji (UnicodeEmoji emojiText))
                                                    [ Ui.width (Ui.px 32)
                                                    , Ui.contentCenterX
                                                    ]
                                                    (Ui.text emojiText)
                                            )
                                            emojiRow
                                        )
                                )
                                (List.Extra.greedyGroupsOf columns emojis)
                            |> Ui.column []
                    )
                    (SeqDict.toList emojiData2.categories)

            Nothing ->
                [ Ui.text "Emojis didn't load for some reason" ]
        )
        |> Ui.el [ Ui.alignBottom, Ui.paddingXY 8 0, Ui.width Ui.shrink ]


requestEmojiData : (Result Http.Error EmojiData -> msg) -> Command restriction toFrontend msg
requestEmojiData gotEmojiData =
    Http.get
        { url = "/emoji.json"
        , expect =
            Http.expectJson
                (\result ->
                    (case result of
                        Ok ok ->
                            { categories =
                                List.foldl
                                    (\emoji dict ->
                                        SeqDict.update
                                            emoji.category
                                            (\maybe -> Maybe.withDefault [] maybe |> (::) emoji.char |> Just)
                                            dict
                                    )
                                    SeqDict.empty
                                    ok
                            }
                                |> Ok

                        Err error ->
                            Err error
                    )
                        |> gotEmojiData
                )
                (Codec.decoder (Codec.list emojiResponseCodec))
        }


emojiResponseCodec : Codec EmojiResponse
emojiResponseCodec =
    Codec.object EmojiResponse
        |> Codec.field "unified" .char charCodeCodec
        |> Codec.field "short_names" .shortNames (Codec.list Codec.string)
        |> Codec.field "category" .category categoryCodec
        |> Codec.buildObject


categoryCodec : Codec Category
categoryCodec =
    Codec.enum Codec.string
        (List.map
            (\category ->
                ( case category of
                    Activities ->
                        "Activities"

                    AnimalsAndNature ->
                        "Animals & Nature"

                    Components ->
                        "Component"

                    Flags ->
                        "Flags"

                    FoodAndDrink ->
                        "Food & Drink"

                    Objects ->
                        "Objects"

                    PeopleAndBody ->
                        "People & Body"

                    SmileysAndEmotion ->
                        "Smileys & Emotion"

                    Symbols ->
                        "Symbols"

                    TravelAndPlaces ->
                        "Travel & Places"
                , category
                )
            )
            allCategories
        )


charCodeCodec : Codec String
charCodeCodec =
    Codec.map
        (\code ->
            String.split "-" code
                |> List.map
                    (\codePoint ->
                        case Hex.fromString (String.toLower codePoint) of
                            Ok code2 ->
                                Char.fromCode code2 |> String.fromChar

                            Err error ->
                                let
                                    _ =
                                        Debug.log "error" error
                                in
                                "?"
                    )
                |> String.concat
        )
        (\text -> String.toList text |> List.map (\char -> Char.toCode char |> Hex.toString) |> String.join "-")
        Codec.string
