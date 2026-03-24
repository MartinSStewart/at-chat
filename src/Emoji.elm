module Emoji exposing (CachedEmojiData, Category(..), Emoji(..), EmojiResponse, Model, Msg(..), SkinTone, emojiWithSkinTone, fromDiscord, isPressed, requestEmojiData, selector, selectorInit, toString, view)

import Array exposing (Array)
import Codec exposing (Codec)
import Dict exposing (Dict)
import Discord
import Effect.Browser.Dom as Dom
import Effect.Command exposing (Command)
import Effect.Http as Http
import Hex
import List.Extra
import MyUi
import SeqDict exposing (SeqDict)
import Ui exposing (Element)
import Ui.Anim
import Ui.Events
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


representativeEmoji : Maybe SkinTone -> Category -> String
representativeEmoji skinTone category =
    case category of
        Activities ->
            "🎉"

        AnimalsAndNature ->
            "🐟"

        Components ->
            "C"

        Flags ->
            "🚩"

        FoodAndDrink ->
            "🥦"

        Objects ->
            "🔬"

        PeopleAndBody ->
            case skinTone of
                Nothing ->
                    "👍"

                Just SkinTone1 ->
                    "👍🏻"

                Just SkinTone2 ->
                    "👍🏼"

                Just SkinTone3 ->
                    "👍🏽"

                Just SkinTone4 ->
                    "👍🏾"

                Just SkinTone5 ->
                    "👍🏿"

        SmileysAndEmotion ->
            "🙂"

        Symbols ->
            "⬇️"

        TravelAndPlaces ->
            "🚆"


allCategories : List Category
allCategories =
    [ SmileysAndEmotion
    , Activities
    , AnimalsAndNature
    , Flags
    , FoodAndDrink
    , Objects
    , PeopleAndBody
    , Symbols
    , TravelAndPlaces
    , Components
    ]


type SkinTone
    = SkinTone1
    | SkinTone2
    | SkinTone3
    | SkinTone4
    | SkinTone5


skinToneToString : SkinTone -> String
skinToneToString skinTone =
    case skinTone of
        SkinTone1 ->
            "🏻"

        SkinTone2 ->
            "🏼"

        SkinTone3 ->
            "🏽"

        SkinTone4 ->
            "🏽"

        SkinTone5 ->
            "🏿"


stringToSkinTone : String -> Maybe SkinTone
stringToSkinTone text =
    case text of
        "1F3FB" ->
            Just SkinTone1

        "1F3FC" ->
            Just SkinTone2

        "1F3FD" ->
            Just SkinTone3

        "1F3FE" ->
            Just SkinTone4

        "1F3FF" ->
            Just SkinTone5

        _ ->
            Nothing


allSkinTones : List SkinTone
allSkinTones =
    [ SkinTone1
    , SkinTone2
    , SkinTone3
    , SkinTone4
    , SkinTone5
    ]


type alias Model =
    { selectedCategory : Category
    , selectedSkinTone : Maybe SkinTone
    , emojiHovered : Maybe Emoji
    }


selectorInit : Model
selectorInit =
    { selectedCategory = SmileysAndEmotion
    , selectedSkinTone = Nothing
    , emojiHovered = Nothing
    }


type alias CachedEmojiData =
    { emojis : SeqDict Emoji EmojiData
    , categories : SeqDict Category (List Emoji)
    , shortNames : Array { shortName : String, emoji : Emoji }
    }


type alias EmojiData =
    { skinVariations : SeqDict SkinTone String
    , shortNames : List String
    }


type alias EmojiResponse =
    { emoji : String, shortNames : List String, category : Category, skinVariations : Maybe (Dict String String) }


type Msg
    = PressedContainer
    | PressedCategory Category
    | PressedSelectEmoji Emoji
    | PressedSkinTone (Maybe SkinTone)
    | MouseEnteredEmoji Emoji


isPressed : Msg -> Bool
isPressed msg =
    case msg of
        PressedContainer ->
            True

        PressedSelectEmoji emoji ->
            True

        PressedCategory category ->
            True

        PressedSkinTone maybeSkinTone ->
            True

        MouseEnteredEmoji string ->
            False


categoryButtonId : Category -> Dom.HtmlId
categoryButtonId category =
    Dom.id ("emoji_category_" ++ categoryToString category)


skinToneView : Maybe SkinTone -> Element Msg
skinToneView selectedSkinTone =
    List.map
        (\skinTone ->
            let
                text : String
                text =
                    case skinTone of
                        Just skinTone2 ->
                            skinToneToString skinTone2

                        Nothing ->
                            "🟨"
            in
            MyUi.elButton
                (Dom.id ("guild_skinToneSelector_" ++ text))
                (PressedSkinTone skinTone)
                [ Ui.width (Ui.px emojiWidth)
                , Ui.contentCenterX
                , if selectedSkinTone == skinTone then
                    Ui.opacity 1

                  else
                    Ui.opacity 0.3
                ]
                (Ui.text text)
        )
        (Nothing :: List.map Just allSkinTones)
        |> Ui.row [ Ui.alignRight ]


emojiWidth : number
emojiWidth =
    40


emojiHeight : number
emojiHeight =
    50


selector : Bool -> Model -> Maybe CachedEmojiData -> Element Msg
selector isMobile model emojiData =
    let
        columns =
            16
    in
    case emojiData of
        Just emojiData2 ->
            Ui.column
                [ Ui.width (Ui.px (columns * emojiWidth + 21))
                , Ui.height (Ui.px 400)
                , Ui.background MyUi.background2
                , Ui.border 1
                , Ui.borderColor MyUi.highlightedBorder
                , Ui.rounded 8
                , Ui.Font.size 32
                , MyUi.blockClickPropagation PressedContainer
                , Ui.heightMin 0
                , Ui.clip
                ]
                [ Ui.row
                    [ MyUi.noShrinking ]
                    (List.filterMap
                        (\category ->
                            case category of
                                Components ->
                                    Nothing

                                _ ->
                                    MyUi.elButton
                                        (categoryButtonId category)
                                        (PressedCategory category)
                                        [ Ui.Font.center
                                        , MyUi.hover isMobile [ Ui.Anim.backgroundColor MyUi.hoverHighlight ]
                                        , Ui.attrIf (category == model.selectedCategory) (Ui.background MyUi.background3)
                                        ]
                                        (Ui.text (representativeEmoji model.selectedSkinTone category))
                                        |> Just
                        )
                        allCategories
                    )
                , case SeqDict.get model.selectedCategory emojiData2.categories of
                    Just emojis ->
                        List.map
                            (\emojiRow ->
                                Ui.row
                                    [ Ui.height (Ui.px emojiHeight), Ui.width Ui.shrink ]
                                    (List.map
                                        (\emoji ->
                                            let
                                                emoji2 : String
                                                emoji2 =
                                                    case model.selectedCategory of
                                                        PeopleAndBody ->
                                                            emojiWithSkinTone model.selectedSkinTone emoji emojiData2

                                                        _ ->
                                                            toString emoji
                                            in
                                            MyUi.elButton
                                                (Dom.id ("guild_emojiSelector_" ++ emoji2))
                                                (PressedSelectEmoji emoji)
                                                [ Ui.Events.onMouseEnter (MouseEnteredEmoji emoji)
                                                , Ui.attrIf
                                                    (model.emojiHovered == Just emoji)
                                                    (Ui.background MyUi.hoverHighlight)
                                                ]
                                                (Ui.text emoji2)
                                        )
                                        emojiRow
                                    )
                            )
                            (List.Extra.greedyGroupsOf columns emojis)
                            |> Ui.column [ Ui.scrollable, Ui.heightMin 0, Ui.background MyUi.background3 ]

                    Nothing ->
                        Ui.none
                , Ui.row
                    [ Ui.height (Ui.px emojiHeight)
                    , Ui.contentCenterY
                    , Ui.spacing 8
                    , MyUi.noShrinking
                    , Ui.paddingXY 8 0
                    ]
                    ((case model.emojiHovered of
                        Just emoji ->
                            Ui.text (emojiWithSkinTone model.selectedSkinTone emoji emojiData2)
                                :: (case SeqDict.get emoji emojiData2.emojis of
                                        Just emoji2 ->
                                            List.map
                                                (\name ->
                                                    Ui.el
                                                        [ Ui.Font.size 16, Ui.width Ui.shrink ]
                                                        (Ui.text (":" ++ name ++ ":"))
                                                )
                                                emoji2.shortNames

                                        Nothing ->
                                            []
                                   )

                        Nothing ->
                            []
                     )
                        ++ (case model.selectedCategory of
                                PeopleAndBody ->
                                    [ skinToneView model.selectedSkinTone ]

                                _ ->
                                    []
                           )
                    )
                ]
                |> Ui.el [ Ui.alignBottom, Ui.paddingXY 8 0, Ui.width Ui.shrink ]

        Nothing ->
            Ui.text "Emojis didn't load for some reason"


emojiWithSkinTone : Maybe SkinTone -> Emoji -> CachedEmojiData -> String
emojiWithSkinTone maybeSkinTone emoji emojiData2 =
    case maybeSkinTone of
        Just skinTone ->
            case SeqDict.get emoji emojiData2.emojis of
                Just emojiData3 ->
                    SeqDict.get skinTone emojiData3.skinVariations
                        |> Maybe.withDefault (toString emoji)

                Nothing ->
                    toString emoji

        Nothing ->
            toString emoji


requestEmojiData : (Result Http.Error CachedEmojiData -> msg) -> Command restriction toFrontend msg
requestEmojiData gotEmojiData =
    Http.get
        { url = "/emoji.json"
        , expect =
            Http.expectJson
                (\result ->
                    (case result of
                        Ok ok ->
                            let
                                emojiData : SeqDict Emoji EmojiData
                                emojiData =
                                    List.foldl
                                        (\emoji dict ->
                                            SeqDict.insert
                                                (UnicodeEmoji emoji.emoji)
                                                { shortNames = emoji.shortNames
                                                , skinVariations =
                                                    case emoji.skinVariations of
                                                        Just skinVariations ->
                                                            List.filterMap
                                                                (\( key, value ) ->
                                                                    case stringToSkinTone key of
                                                                        Just skinTone ->
                                                                            Just ( skinTone, value )

                                                                        Nothing ->
                                                                            Nothing
                                                                )
                                                                (Dict.toList skinVariations)
                                                                |> SeqDict.fromList

                                                        Nothing ->
                                                            SeqDict.empty
                                                }
                                                dict
                                        )
                                        SeqDict.empty
                                        ok

                                categories : SeqDict Category (List Emoji)
                                categories =
                                    List.foldl
                                        (\emoji dict ->
                                            SeqDict.update
                                                emoji.category
                                                (\maybe -> UnicodeEmoji emoji.emoji :: Maybe.withDefault [] maybe |> Just)
                                                dict
                                        )
                                        (allCategories |> List.map (\category -> ( category, [] )) |> SeqDict.fromList)
                                        ok
                            in
                            { emojis = emojiData
                            , categories = categories
                            , shortNames =
                                List.concatMap
                                    (\emoji ->
                                        List.map
                                            (\shortName -> { shortName = shortName, emoji = UnicodeEmoji emoji.emoji })
                                            emoji.shortNames
                                    )
                                    ok
                                    |> Array.fromList
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
        |> Codec.field "unified" .emoji charCodeCodec
        |> Codec.field "short_names" .shortNames (Codec.list Codec.string)
        |> Codec.field "category" .category categoryCodec
        |> Codec.optionalField "skin_variations" .skinVariations (Codec.dict skinVariationCodec)
        |> Codec.buildObject


skinVariationCodec : Codec String
skinVariationCodec =
    Codec.object identity
        |> Codec.field "unified" identity charCodeCodec
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
