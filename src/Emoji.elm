module Emoji exposing
    ( CachedEmojiData
    , Category(..)
    , Emoji(..)
    , EmojiCategory(..)
    , EmojiConfig
    , EmojiData
    , EmojiOrCustomEmoji(..)
    , EmojiOrSticker(..)
    , EmojiResponse
    , Model
    , Msg(..)
    , SkinTone(..)
    , emojiButtonId
    , emojiWithSkinTone
    , heart
    , isPressed
    , requestEmojiData
    , scrollContainerId
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
import CustomEmoji exposing (CustomEmojiData)
import Dict exposing (Dict)
import Discord
import Effect.Browser.Dom as Dom
import Effect.Command exposing (Command)
import Effect.Http as Http
import Hex
import Html.Events
import Icons
import Id exposing (CustomEmojiId, Id, StickerId)
import Json.Decode
import MyUi
import OneToOne exposing (OneToOne)
import RichText exposing (DiscordCustomEmojiIdAndName)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Sticker exposing (StickerData)
import Ui exposing (Element)
import Ui.Anim
import Ui.Events
import Ui.Font
import Ui.Input


{-| OpaqueVariants
-}
type Emoji
    = UnicodeEmoji String


type EmojiOrCustomEmoji
    = EmojiOrCustomEmoji_Emoji Emoji
    | EmojiOrCustomEmoji_CustomEmoji (Id CustomEmojiId)


toString : Emoji -> String
toString emoji =
    case emoji of
        UnicodeEmoji text ->
            text


view : Emoji -> Element msg
view (UnicodeEmoji emoji) =
    Ui.el [ Ui.Font.size 20 ] (Ui.text emoji)


type Category
    = EmojiCategory EmojiCategory
    | StickerCategory
    | CustomEmojiCategory


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

        CustomEmojiCategory ->
            "Custom emojis"


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

        CustomEmojiCategory ->
            Ui.text "C"


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
    , lastUsedEmojis : Array EmojiOrCustomEmoji
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
    | KeyboardMovedHover EmojiOrSticker Int
    | ClearEmojiHover
    | TypedSearchText String
    | PressedClearSearch
    | NoOp


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

        KeyboardMovedHover _ _ ->
            False

        ClearEmojiHover ->
            False

        TypedSearchText _ ->
            False

        PressedClearSearch ->
            True

        NoOp ->
            False


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


scrollContainerId : Dom.HtmlId
scrollContainerId =
    Dom.id "emoji_scroll_container"


emojiButtonId : Int -> Dom.HtmlId
emojiButtonId index =
    Dom.id ("guild_emojiSelector_" ++ String.fromInt index)


searchInput : Bool -> Model -> Array EmojiOrSticker -> Int -> Element Msg
searchInput searchHasFocus model items columns =
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
            , Ui.htmlAttribute
                (Html.Events.preventDefaultOn "keydown" (decodeArrowKey model items columns))
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


decodeArrowKey : Model -> Array EmojiOrSticker -> Int -> Json.Decode.Decoder ( Msg, Bool )
decodeArrowKey model items columns =
    Json.Decode.field "key" Json.Decode.string
        |> Json.Decode.andThen
            (\key ->
                let
                    count : Int
                    count =
                        Array.length items

                    currentIndex : Maybe Int
                    currentIndex =
                        case model.emojiHovered of
                            Just hovered ->
                                findIndex hovered items

                            Nothing ->
                                Nothing

                    moveTo : Int -> Json.Decode.Decoder ( Msg, Bool )
                    moveTo delta =
                        if count == 0 then
                            Json.Decode.fail ""

                        else
                            let
                                newIndex : Int
                                newIndex =
                                    case currentIndex of
                                        Just idx ->
                                            clamp 0 (count - 1) (idx + delta)

                                        Nothing ->
                                            if delta < 0 then
                                                count - 1

                                            else
                                                0
                            in
                            case Array.get newIndex items of
                                Just item ->
                                    Json.Decode.succeed ( KeyboardMovedHover item newIndex, True )

                                Nothing ->
                                    Json.Decode.fail ""
                in
                case key of
                    "ArrowLeft" ->
                        case currentIndex of
                            Just _ ->
                                moveTo -1

                            Nothing ->
                                Json.Decode.succeed ( NoOp, False )

                    "ArrowRight" ->
                        case currentIndex of
                            Just _ ->
                                moveTo 1

                            Nothing ->
                                Json.Decode.succeed ( NoOp, False )

                    "ArrowUp" ->
                        case currentIndex of
                            Just idx ->
                                if idx < columns then
                                    Json.Decode.succeed ( ClearEmojiHover, True )

                                else
                                    moveTo -columns

                            Nothing ->
                                Json.Decode.succeed ( NoOp, False )

                    "ArrowDown" ->
                        moveTo columns

                    "Enter" ->
                        case model.emojiHovered of
                            Just hovered ->
                                Json.Decode.succeed ( PressedSelectEmoji hovered, True )

                            Nothing ->
                                case Array.get 0 items of
                                    Just first ->
                                        Json.Decode.succeed ( PressedSelectEmoji first, True )

                                    Nothing ->
                                        Json.Decode.succeed ( NoOp, False )

                    _ ->
                        Json.Decode.succeed ( NoOp, False )
            )


findIndex : a -> Array a -> Maybe Int
findIndex target array =
    Array.foldl
        (\item ( index, result ) ->
            case result of
                Just _ ->
                    ( index + 1, result )

                Nothing ->
                    if item == target then
                        ( index + 1, Just index )

                    else
                        ( index + 1, Nothing )
        )
        ( 0, Nothing )
        array
        |> Tuple.second


type EmojiOrSticker
    = EmojiOrSticker_Emoji Emoji
    | EmojiOrSticker_Sticker (Id StickerId)
    | EmojiOrSticker_CustomEmoji (Id CustomEmojiId)


selector :
    Bool
    -> Bool
    -> Int
    -> Model
    -> EmojiConfig
    -> Maybe CachedEmojiData
    -> SeqSet (Id CustomEmojiId)
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> SeqSet (Id StickerId)
    -> SeqDict (Id StickerId) StickerData
    -> Element Msg
selector searchHasFocus isMobile width model userData emojiData availableCustomEmojis customEmojisData availableStickers stickersData =
    case emojiData of
        Just emojiData2 ->
            let
                isSearching : Bool
                isSearching =
                    model.searchText /= ""

                selectorWidth : Int
                selectorWidth =
                    min 620 width

                columns : Int
                columns =
                    max 1 (selectorWidth // emojiWidth)

                emojis : Array EmojiOrSticker
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
                            |> Array.fromList

                    else
                        case userData.category of
                            EmojiCategory emojiCategory ->
                                SeqDict.get emojiCategory emojiData2.categories
                                    |> Maybe.withDefault []
                                    |> List.map EmojiOrSticker_Emoji
                                    |> Array.fromList

                            StickerCategory ->
                                SeqSet.toList availableStickers
                                    |> List.map EmojiOrSticker_Sticker
                                    |> Array.fromList

                            CustomEmojiCategory ->
                                SeqSet.toList availableCustomEmojis
                                    |> List.map EmojiOrSticker_CustomEmoji
                                    |> Array.fromList
            in
            Ui.column
                [ Ui.width (Ui.px selectorWidth)
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
                    (searchInput searchHasFocus model emojis columns
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
                                    (StickerCategory :: CustomEmojiCategory :: List.map EmojiCategory allEmojiCategories)
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

                                        EmojiOrSticker_CustomEmoji id ->
                                            CustomEmoji.view
                                                (String.fromInt emojiWidth ++ "px")
                                                "0"
                                                id
                                                customEmojisData
                                                Sticker.LoopForever
                                                |> Ui.html
                            in
                            MyUi.elButton
                                (emojiButtonId index)
                                (PressedSelectEmoji item)
                                [ Ui.Events.onMouseEnter (MouseEnteredEmoji item)
                                , Ui.attrIf
                                    (model.emojiHovered == Just item)
                                    (Ui.background MyUi.hoverHighlight)
                                , Ui.contentCenterX
                                , Ui.width Ui.shrink
                                ]
                                text
                        )
                        (Array.toList emojis)
                    )
                    |> Ui.el
                        [ Ui.background MyUi.background3
                        , Ui.scrollable
                        , Ui.heightMin 0
                        , Ui.id (Dom.idToString scrollContainerId)
                        ]
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

                        Just (EmojiOrSticker_CustomEmoji customEmojiId) ->
                            case SeqDict.get customEmojiId customEmojisData of
                                Just sticker ->
                                    [ Ui.el
                                        [ Ui.Font.size 16, Ui.width Ui.shrink ]
                                        (Ui.text (":" ++ CustomEmoji.emojiNameToString sticker.name ++ ":"))
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
