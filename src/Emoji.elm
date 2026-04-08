module Emoji exposing
    ( CachedEmojiData
    , Category(..)
    , Emoji(..)
    , EmojiCategory(..)
    , EmojiConfig
    , EmojiData
    , EmojiOrSticker(..)
    , EmojiResponse
    , Model
    , Msg(..)
    , SkinTone(..)
    , emojiWithSkinTone
    , fromDiscord
    , heart
    , isPressed
    , requestEmojiData
    , searchInputId
    , selector
    , selectorHeight
    , selectorInit
    , setSearch
    , smiley
    , thumbsUp
    , toString
    , view
    )

import Array exposing (Array)
import Codec exposing (Codec)
import Dict exposing (Dict)
import Discord
import Effect.Browser.Dom as Dom
import Effect.Command exposing (Command)
import Effect.Http as Http
import Hex
import Icons
import Id exposing (Id, StickerId)
import MyUi
import SeqDict exposing (SeqDict)
import SeqSet
import Sticker exposing (StickerData, StickerUrl(..))
import Ui exposing (Element)
import Ui.Anim
import Ui.Events
import Ui.Font
import Ui.Input


{-| OpaqueVariants
-}
type Emoji
    = UnicodeEmoji String


toString : Emoji -> String
toString emoji =
    case emoji of
        UnicodeEmoji text ->
            text


view : Emoji -> Element msg
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
    = EmojiCategory EmojiCategory
    | StickerCategory


type EmojiCategory
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
        EmojiCategory emojiCategory ->
            case emojiCategory of
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

        StickerCategory ->
            "Stickers"


categoryToEmojiString : Maybe SkinTone -> Category -> Element msg
categoryToEmojiString skinTone category =
    case category of
        EmojiCategory emojiCategory ->
            case emojiCategory of
                Activities ->
                    Ui.text "🎉"

                AnimalsAndNature ->
                    Ui.text "🐟"

                Components ->
                    Ui.text "C"

                Flags ->
                    Ui.text "🚩"

                FoodAndDrink ->
                    Ui.text "🥦"

                Objects ->
                    Ui.text "🔬"

                PeopleAndBody ->
                    (case skinTone of
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
                    )
                        |> Ui.text

                SmileysAndEmotion ->
                    Ui.text "🙂"

                Symbols ->
                    Ui.text "⬇️"

                TravelAndPlaces ->
                    Ui.text "🚆"

        StickerCategory ->
            Ui.text "S"


allEmojiCategories : List EmojiCategory
allEmojiCategories =
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


allCategories : List Category
allCategories =
    StickerCategory :: List.map EmojiCategory allEmojiCategories


{-| OpaqueVariants
-}
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


allSkinTones : List SkinTone
allSkinTones =
    [ SkinTone1
    , SkinTone2
    , SkinTone3
    , SkinTone4
    , SkinTone5
    ]


type alias Model =
    { emojiHovered : Maybe EmojiOrSticker
    , searchText : String
    }


type alias EmojiConfig =
    { skinTone : Maybe SkinTone
    , category : Category
    , lastUsedEmojis : Array Emoji
    }


selectorInit : Model
selectorInit =
    { emojiHovered = Nothing
    , searchText = ""
    }


type alias CachedEmojiData =
    { emojis : SeqDict Emoji EmojiData
    , categories : SeqDict EmojiCategory (List Emoji)
    , shortNames : Array { shortName : String, emoji : Emoji }
    }


type alias EmojiData =
    { skinVariations : Maybe String
    , shortNames : List String
    }


type alias EmojiResponse =
    { emoji : String, shortNames : List String, category : EmojiCategory, skinVariations : Maybe (Dict String String) }


type Msg
    = PressedContainer
    | PressedCategory Category
    | PressedSelectEmoji EmojiOrSticker
    | PressedSkinTone (Maybe SkinTone)
    | MouseEnteredEmoji EmojiOrSticker
    | TypedSearchText String
    | PressedClearSearch


isPressed : Msg -> Bool
isPressed msg =
    case msg of
        PressedContainer ->
            True

        PressedSelectEmoji _ ->
            True

        PressedCategory _ ->
            True

        PressedSkinTone _ ->
            True

        MouseEnteredEmoji _ ->
            False

        TypedSearchText _ ->
            False

        PressedClearSearch ->
            True


categoryButtonId : Category -> Dom.HtmlId
categoryButtonId category =
    Dom.id ("emoji_category_" ++ categoryToString category)


skinToneView : Maybe SkinTone -> List (Element Msg)
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


emojiWidth : number
emojiWidth =
    40


emojiHeight : number
emojiHeight =
    50


selectorHeight : number
selectorHeight =
    400


heart : Emoji
heart =
    UnicodeEmoji "❤️"


thumbsUp : Emoji
thumbsUp =
    UnicodeEmoji "👍"


smiley : Emoji
smiley =
    UnicodeEmoji "😃"


searchInputId : Dom.HtmlId
searchInputId =
    Dom.id "emoji_search_input"


searchInput : Bool -> Model -> Element Msg
searchInput searchHasFocus model =
    let
        isSearching =
            model.searchText /= ""
    in
    Ui.row
        [ Ui.attrIf
            (not isSearching && not searchHasFocus)
            (Ui.inFront (Ui.el [ MyUi.noPointerEvents, Ui.centerX ] (Ui.text "🔎")))
        , Ui.height Ui.fill
        ]
        [ Ui.Input.text
            [ if isSearching then
                Ui.background MyUi.background3

              else
                Ui.background MyUi.background2
            , Ui.Font.size 16
            , Ui.border 0
            , Ui.attrIf (not isSearching && not searchHasFocus) Ui.pointer
            , Ui.height Ui.fill
            , Ui.paddingXY 8 0
            , Ui.width Ui.fill
            , Ui.id (Dom.idToString searchInputId)
            ]
            { onChange = TypedSearchText
            , text = model.searchText
            , placeholder = Nothing
            , label = Ui.Input.labelHidden (Dom.idToString searchInputId)
            }
        , if isSearching then
            MyUi.elButton
                (Dom.id "emoji_clearSearch")
                PressedClearSearch
                [ Ui.width (Ui.px 40)
                , Ui.background MyUi.background3
                , Ui.height Ui.fill
                , Ui.contentCenterX
                , Ui.contentCenterY
                ]
                (Ui.html Icons.x)

          else
            Ui.none
        ]


setSearch : String -> Model -> Model
setSearch text model =
    { model | searchText = text, emojiHovered = Nothing }


type EmojiOrSticker
    = EmojiOrSticker_Emoji Emoji
    | EmojiOrSticker_Sticker (Id StickerId)


selector :
    Bool
    -> Bool
    -> Int
    -> Model
    -> EmojiConfig
    -> Maybe CachedEmojiData
    -> SeqDict (Id StickerId) StickerData
    -> Element Msg
selector searchHasFocus isMobile width model userData emojiData stickersData =
    case emojiData of
        Just emojiData2 ->
            let
                isSearching : Bool
                isSearching =
                    model.searchText /= ""

                emojis : List EmojiOrSticker
                emojis =
                    if isSearching then
                        let
                            query : String
                            query =
                                String.toLower model.searchText |> String.filter Char.isAlphaNum
                        in
                        Array.foldl
                            (\{ shortName, emoji } set ->
                                if String.contains query (String.filter Char.isAlphaNum shortName) then
                                    SeqSet.insert emoji set

                                else
                                    set
                            )
                            SeqSet.empty
                            emojiData2.shortNames
                            |> SeqSet.toList
                            |> List.map EmojiOrSticker_Emoji

                    else
                        case userData.category of
                            EmojiCategory emojiCategory ->
                                SeqDict.get emojiCategory emojiData2.categories
                                    |> Maybe.withDefault []
                                    |> List.map EmojiOrSticker_Emoji

                            StickerCategory ->
                                SeqDict.toList stickersData
                                    |> List.filterMap
                                        (\( stickerId, sticker ) ->
                                            case sticker.url of
                                                StickerInternal _ _ ->
                                                    EmojiOrSticker_Sticker stickerId |> Just

                                                DiscordStandardSticker id ->
                                                    Nothing

                                                StickerLoading ->
                                                    Nothing
                                        )
            in
            Ui.column
                [ Ui.width (Ui.px (min 620 width))
                , Ui.height (Ui.px selectorHeight)
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
                    (searchInput searchHasFocus model
                        :: (if isSearching then
                                -- This is here just so the header height doesn't change
                                [ Ui.el [ Ui.opacity 0 ] (Ui.text "🔎") ]

                            else
                                List.filterMap
                                    (\category ->
                                        case category of
                                            EmojiCategory Components ->
                                                Nothing

                                            _ ->
                                                MyUi.elButton
                                                    (categoryButtonId category)
                                                    (PressedCategory category)
                                                    [ Ui.Font.center
                                                    , MyUi.hover isMobile [ Ui.Anim.backgroundColor MyUi.hoverHighlight ]
                                                    , Ui.attrIf (category == userData.category) (Ui.background MyUi.background3)
                                                    ]
                                                    (categoryToEmojiString userData.skinTone category)
                                                    |> Just
                                    )
                                    allCategories
                           )
                    )
                , Ui.row
                    [ Ui.heightMin 0, Ui.width Ui.shrink, Ui.wrap ]
                    (List.indexedMap
                        (\index item ->
                            let
                                text =
                                    case item of
                                        EmojiOrSticker_Emoji emoji ->
                                            emojiWithSkinTone userData.skinTone emoji emojiData2 |> Ui.text

                                        EmojiOrSticker_Sticker stickerId ->
                                            Sticker.view "2lh" stickerId stickersData Sticker.LoopForever |> Ui.html
                            in
                            MyUi.elButton
                                (Dom.id ("guild_emojiSelector_" ++ String.fromInt index))
                                (PressedSelectEmoji item)
                                [ Ui.Events.onMouseEnter (MouseEnteredEmoji item)
                                , Ui.attrIf
                                    (model.emojiHovered == Just item)
                                    (Ui.background MyUi.hoverHighlight)
                                , Ui.width Ui.shrink
                                ]
                                text
                        )
                        emojis
                    )
                    |> Ui.el [ Ui.background MyUi.background3, Ui.scrollable, Ui.heightMin 0 ]
                , Ui.row
                    [ Ui.height (Ui.px emojiHeight)
                    , Ui.contentCenterY
                    , Ui.spacing 8
                    , MyUi.noShrinking
                    , Ui.paddingXY 8 0
                    ]
                    ((case model.emojiHovered of
                        Just (EmojiOrSticker_Emoji emoji) ->
                            Ui.text (emojiWithSkinTone userData.skinTone emoji emojiData2)
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

                        Just (EmojiOrSticker_Sticker stickerId) ->
                            case SeqDict.get stickerId stickersData of
                                Just sticker ->
                                    [ Ui.el
                                        [ Ui.Font.size 16, Ui.width Ui.shrink ]
                                        (Ui.text (":" ++ sticker.name ++ ":"))
                                    ]

                                Nothing ->
                                    []

                        Nothing ->
                            []
                     )
                        ++ [ skinToneView userData.skinTone
                                |> Ui.row
                                    [ if isMobile then
                                        Ui.alignLeft

                                      else
                                        Ui.alignRight
                                    ]
                           ]
                    )
                ]

        Nothing ->
            Ui.text "Emojis didn't load for some reason"


emojiWithSkinTone : Maybe SkinTone -> Emoji -> CachedEmojiData -> String
emojiWithSkinTone maybeSkinTone emoji emojiData2 =
    case maybeSkinTone of
        Just skinTone ->
            case SeqDict.get emoji emojiData2.emojis of
                Just emojiData3 ->
                    case emojiData3.skinVariations of
                        Just skinVariation ->
                            String.replace (skinToneToString SkinTone1) (skinToneToString skinTone) skinVariation

                        Nothing ->
                            toString emoji

                Nothing ->
                    toString emoji

        Nothing ->
            toString emoji


requestEmojiData : (Result Http.Error CachedEmojiData -> msg) -> Command restriction toFrontend msg
requestEmojiData gotEmojiData =
    Http.get
        { url = "/compact-emoji.json"
        , expect =
            Http.expectJson
                (\result ->
                    (case result of
                        Ok ok ->
                            let
                                --_ =
                                --    Debug.log "" (Codec.encodeToString 0 (Codec.list emojiResponseCodec) ok)
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
                                                            Dict.get "1F3FB" skinVariations

                                                        Nothing ->
                                                            Nothing
                                                }
                                                dict
                                        )
                                        SeqDict.empty
                                        ok

                                categories : SeqDict EmojiCategory (List Emoji)
                                categories =
                                    List.foldl
                                        (\emoji dict ->
                                            SeqDict.update
                                                emoji.category
                                                (\maybe -> UnicodeEmoji emoji.emoji :: Maybe.withDefault [] maybe |> Just)
                                                dict
                                        )
                                        (allEmojiCategories |> List.map (\category -> ( category, [] )) |> SeqDict.fromList)
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


categoryCodec : Codec EmojiCategory
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
            allEmojiCategories
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
