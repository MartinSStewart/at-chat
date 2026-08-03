module Emoji exposing
    ( CachedEmojiData
    , Category(..)
    , EmojiCategory(..)
    , EmojiConfig
    , EmojiData
    , EmojiOrCustomEmoji(..)
    , EmojiOrSticker(..)
    , EmojiResponse
    , Model
    , Msg(..)
    , SkinTone(..)
    , UnicodeEmoji(..)
    , emojiButtonId
    , emojiWithSkinTone
    , fromString
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
import Effect.Browser.Dom as Dom
import Effect.Command exposing (Command)
import Effect.Http as Http
import Hex
import Html
import Html.Attributes
import Html.Events
import Icons
import Id exposing (CustomEmojiId, Id, StickerId)
import Json.Decode
import MyUi
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
type UnicodeEmoji
    = UnicodeEmoji String


type EmojiOrCustomEmoji
    = EmojiOrCustomEmoji_Emoji UnicodeEmoji
    | EmojiOrCustomEmoji_CustomEmoji (Id CustomEmojiId)


toString : UnicodeEmoji -> String
toString emoji =
    case emoji of
        UnicodeEmoji text ->
            text


fromString : String -> UnicodeEmoji
fromString =
    UnicodeEmoji


view : UnicodeEmoji -> Element msg
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


emojiCategoryToString : EmojiCategory -> String
emojiCategoryToString emojiCategory =
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


categoryToString : Category -> String
categoryToString category =
    case category of
        EmojiCategory emojiCategory ->
            emojiCategoryToString emojiCategory

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
            "🏾"

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
    , lastUsedEmojis : Array EmojiOrCustomEmoji
    }


selectorInit : Model
selectorInit =
    { emojiHovered = Nothing
    , searchText = ""
    }


type alias CachedEmojiData =
    { emojis : SeqDict UnicodeEmoji EmojiData
    , categories : SeqDict EmojiCategory (List UnicodeEmoji)
    , shortNames : Array { shortName : String, emoji : UnicodeEmoji }
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


skinToneSelectorId : Dom.HtmlId
skinToneSelectorId =
    Dom.id "guild_skinToneSelector"


skinToneToId : Maybe SkinTone -> String
skinToneToId skinTone =
    case skinTone of
        Nothing ->
            "default"

        Just SkinTone1 ->
            "1"

        Just SkinTone2 ->
            "2"

        Just SkinTone3 ->
            "3"

        Just SkinTone4 ->
            "4"

        Just SkinTone5 ->
            "5"


skinToneFromId : String -> Maybe SkinTone
skinToneFromId text =
    case text of
        "1" ->
            Just SkinTone1

        "2" ->
            Just SkinTone2

        "3" ->
            Just SkinTone3

        "4" ->
            Just SkinTone4

        "5" ->
            Just SkinTone5

        _ ->
            Nothing


skinToneView : Maybe SkinTone -> Element Msg
skinToneView selectedSkinTone =
    Html.select
        [ Html.Attributes.id (Dom.idToString skinToneSelectorId)
        , Html.Attributes.value (skinToneToId selectedSkinTone)
        , Html.Events.onInput (\text -> skinToneFromId text |> PressedSkinTone)
        , Html.Attributes.attribute "aria-label" "Skin tone"
        , Html.Attributes.title "Skin tone"
        , Html.Attributes.style "height" "100%"
        , Html.Attributes.style "border" ("1px solid " ++ MyUi.colorToStyle MyUi.inputBorder)
        , Html.Attributes.style "border-radius" "4px"
        , Html.Attributes.style "padding" "0 4px"
        , Html.Attributes.style "font-size" "20px"
        , Html.Attributes.style "background-color" (MyUi.colorToStyle MyUi.background3)
        , Html.Attributes.style "color" (MyUi.colorToStyle MyUi.white)
        , Html.Attributes.style "cursor" "pointer"
        ]
        (List.map
            (\skinTone ->
                let
                    text : String
                    text =
                        case skinTone of
                            Nothing ->
                                "👍"

                            Just skinTone2 ->
                                "👍" ++ skinToneToString skinTone2
                in
                Html.option
                    [ Html.Attributes.value (skinToneToId skinTone)
                    , Html.Attributes.selected (skinTone == selectedSkinTone)
                    ]
                    [ Html.text text ]
            )
            (Nothing :: List.map Just allSkinTones)
        )
        |> Ui.html
        |> Ui.el [ Ui.width Ui.shrink, Ui.height Ui.fill, MyUi.noShrinking ]


emojiWidth : number
emojiWidth =
    40


emojiHeight : number
emojiHeight =
    50


selectorHeight : number
selectorHeight =
    400


heart : UnicodeEmoji
heart =
    UnicodeEmoji "❤️"


thumbsUp : UnicodeEmoji
thumbsUp =
    UnicodeEmoji "👍"


smiley : UnicodeEmoji
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


searchInput : Model -> Maybe SkinTone -> List (List EmojiOrSticker) -> Int -> Element Msg
searchInput model skinTone categories columns =
    let
        isSearching =
            model.searchText /= ""
    in
    Ui.row
        [ Ui.Font.size 16
        , Ui.paddingXY 8 4
        , Ui.spacing 8
        ]
        [ Ui.row
            [ Ui.border 1
            , Ui.borderColor MyUi.inputBorder
            , Ui.rounded 4
            , Ui.clip
            , Ui.height Ui.fill
            , (if isSearching then
                Ui.none

               else
                Ui.el
                    [ Ui.centerY, Ui.paddingXY 8 0, Ui.Font.color MyUi.font3, MyUi.noPointerEvents ]
                    (Ui.text "Search by name")
              )
                |> Ui.inFront
            ]
            [ Ui.Input.text
                [ if isSearching then
                    Ui.background MyUi.background3

                  else
                    Ui.background MyUi.background2
                , Ui.border 0
                , Ui.height Ui.fill
                , Ui.paddingXY 8 8
                , Ui.width Ui.fill
                , Ui.id (Dom.idToString searchInputId)
                , Ui.htmlAttribute
                    (Html.Events.preventDefaultOn "keydown" (decodeArrowKey model categories columns))
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
                    , MyUi.hoverText "Clear search"
                    ]
                    (Ui.html Icons.x)

              else
                Ui.none
            ]
        , skinToneView skinTone
        ]


setSearch : String -> Model -> Model
setSearch text model =
    { model | searchText = text, emojiHovered = Nothing }


{-| Where a category's emojis start within the flattened list of every category, and how many
there are. Empty categories are left out since there's nothing in them to move to.
-}
type alias CategoryRange =
    { start : Int, count : Int }


categoryRanges : List (List EmojiOrSticker) -> List CategoryRange
categoryRanges categories =
    List.foldl
        (\category ( start, list ) ->
            ( start + List.length category
            , if List.isEmpty category then
                list

              else
                { start = start, count = List.length category } :: list
            )
        )
        ( 0, [] )
        categories
        |> Tuple.second
        |> List.reverse


{-| The emoji one row above `index`, or Nothing if `index` is on the very first row of the
selector. Each category starts a fresh grid, so moving up off the top row of one category lands
on the last row of the previous one.
-}
moveUp : Int -> Int -> Maybe CategoryRange -> List CategoryRange -> Maybe Int
moveUp columns index previous categories =
    case categories of
        current :: rest ->
            if index < current.start + current.count then
                let
                    column : Int
                    column =
                        modBy columns (index - current.start)
                in
                if index - current.start >= columns then
                    Just (index - columns)

                else
                    case previous of
                        Just previous2 ->
                            let
                                lastRowStart : Int
                                lastRowStart =
                                    (previous2.count - 1) // columns * columns
                            in
                            Just (previous2.start + min (lastRowStart + column) (previous2.count - 1))

                        Nothing ->
                            Nothing

            else
                moveUp columns index (Just current) rest

        [] ->
            Nothing


{-| The emoji one row below `index`, or Nothing if `index` is on the very last row of the
selector. Moving down off the last row of a category lands on the first row of the next one.
-}
moveDown : Int -> Int -> List CategoryRange -> Maybe Int
moveDown columns index categories =
    case categories of
        current :: rest ->
            if index < current.start + current.count then
                let
                    local : Int
                    local =
                        index - current.start

                    lastLocal : Int
                    lastLocal =
                        current.count - 1
                in
                if local + columns <= lastLocal then
                    Just (index + columns)

                else if local // columns < lastLocal // columns then
                    -- There's another row below but it stops short of this column
                    Just (current.start + lastLocal)

                else
                    case rest of
                        next :: _ ->
                            Just (next.start + min (modBy columns local) (next.count - 1))

                        [] ->
                            Nothing

            else
                moveDown columns index rest

        [] ->
            Nothing


decodeArrowKey : Model -> List (List EmojiOrSticker) -> Int -> Json.Decode.Decoder ( Msg, Bool )
decodeArrowKey model categories columns =
    Json.Decode.field "key" Json.Decode.string
        |> Json.Decode.andThen
            (\key ->
                let
                    items : Array EmojiOrSticker
                    items =
                        List.concat categories |> Array.fromList

                    count : Int
                    count =
                        Array.length items

                    ranges : List CategoryRange
                    ranges =
                        categoryRanges categories

                    currentIndex : Maybe Int
                    currentIndex =
                        case model.emojiHovered of
                            Just hovered ->
                                findIndex hovered items

                            Nothing ->
                                Nothing

                    moveTo : Int -> Json.Decode.Decoder ( Msg, Bool )
                    moveTo newIndex =
                        case Array.get newIndex items of
                            Just item ->
                                Json.Decode.succeed ( KeyboardMovedHover item newIndex, True )

                            Nothing ->
                                Json.Decode.fail ""
                in
                case key of
                    "ArrowLeft" ->
                        case currentIndex of
                            Just index ->
                                moveTo (clamp 0 (count - 1) (index - 1))

                            Nothing ->
                                Json.Decode.succeed ( NoOp, False )

                    "ArrowRight" ->
                        case currentIndex of
                            Just index ->
                                moveTo (clamp 0 (count - 1) (index + 1))

                            Nothing ->
                                Json.Decode.succeed ( NoOp, False )

                    "ArrowUp" ->
                        case currentIndex of
                            Just index ->
                                case moveUp columns index Nothing ranges of
                                    Just newIndex ->
                                        moveTo newIndex

                                    Nothing ->
                                        Json.Decode.succeed ( ClearEmojiHover, True )

                            Nothing ->
                                Json.Decode.succeed ( NoOp, False )

                    "ArrowDown" ->
                        case currentIndex of
                            Just index ->
                                case moveDown columns index ranges of
                                    Just newIndex ->
                                        moveTo newIndex

                                    Nothing ->
                                        Json.Decode.succeed ( NoOp, True )

                            Nothing ->
                                moveTo 0

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
    = EmojiOrSticker_UnicodeEmoji UnicodeEmoji
    | EmojiOrSticker_Sticker (Id StickerId)
    | EmojiOrSticker_CustomEmoji (Id CustomEmojiId)


emojiButtonHelper : Int -> EmojiOrSticker -> { a | emojiHovered : Maybe EmojiOrSticker } -> Element Msg -> Element Msg
emojiButtonHelper index item model content =
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
        content


emojiCategoryContainer : String -> List (Element msg) -> Element msg
emojiCategoryContainer title content =
    Ui.column
        []
        [ Ui.el [ Ui.Font.size 16 ] (Ui.text title), Ui.row [ Ui.wrap ] content ]


selector :
    Int
    -> Model
    -> EmojiConfig
    -> Maybe CachedEmojiData
    -> SeqSet (Id CustomEmojiId)
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> SeqSet (Id StickerId)
    -> SeqDict (Id StickerId) StickerData
    -> Element Msg
selector width model userData emojiData availableCustomEmojis customEmojisData availableStickers stickersData =
    case emojiData of
        Just emojiData2 ->
            let
                selectorWidth : Int
                selectorWidth =
                    min 620 width

                columns : Int
                columns =
                    max 1 (selectorWidth // emojiWidth)

                categories : List ( String, List EmojiOrSticker )
                categories =
                    List.filterMap
                        (\category ->
                            case category of
                                EmojiCategory emojiCategory ->
                                    case SeqDict.get emojiCategory emojiData2.categories of
                                        Just [] ->
                                            Nothing

                                        Just list ->
                                            ( emojiCategoryToString emojiCategory
                                            , List.map EmojiOrSticker_UnicodeEmoji list
                                            )
                                                |> Just

                                        Nothing ->
                                            Nothing

                                StickerCategory ->
                                    case SeqSet.toList availableStickers of
                                        [] ->
                                            Nothing

                                        list ->
                                            ( "Stickers", List.map EmojiOrSticker_Sticker list ) |> Just

                                CustomEmojiCategory ->
                                    case SeqSet.toList availableCustomEmojis of
                                        [] ->
                                            Nothing

                                        list ->
                                            ( "Custom emojis", List.map EmojiOrSticker_CustomEmoji list ) |> Just
                        )
                        (StickerCategory :: CustomEmojiCategory :: List.map EmojiCategory allEmojiCategories)

                -- Emoji buttons are numbered across every category rather than restarting at 0 in
                -- each one, so that the id we scroll to on arrow key presses is unique.
                emojis : List ( List EmojiOrSticker, Element Msg )
                emojis =
                    List.foldl
                        (\( title, list ) ( offset, sections ) ->
                            ( offset + List.length list
                            , ( list
                              , List.indexedMap
                                    (\index item ->
                                        emojiButtonHelper
                                            (offset + index)
                                            item
                                            model
                                            (case item of
                                                EmojiOrSticker_UnicodeEmoji emoji ->
                                                    emojiWithSkinTone userData.skinTone emoji emojiData2 |> Ui.text

                                                EmojiOrSticker_Sticker stickerId ->
                                                    Sticker.view "2lh" stickerId stickersData Sticker.LoopForever
                                                        |> Ui.html

                                                EmojiOrSticker_CustomEmoji customEmojiId ->
                                                    CustomEmoji.view
                                                        (String.fromInt emojiWidth ++ "px")
                                                        "0"
                                                        customEmojiId
                                                        customEmojisData
                                                        Sticker.LoopForever
                                                        |> Ui.html
                                            )
                                    )
                                    list
                                    |> emojiCategoryContainer title
                              )
                                :: sections
                            )
                        )
                        ( 0, [] )
                        categories
                        |> Tuple.second
                        |> List.reverse

                --if isSearching then
                --    let
                --        query : String
                --        query =
                --            String.toLower model.searchText |> String.filter Char.isAlphaNum
                --    in
                --    Array.foldl
                --        (\{ shortName, emoji } set ->
                --            if String.contains query (String.filter Char.isAlphaNum shortName) then
                --                SeqSet.insert emoji set
                --
                --            else
                --                set
                --        )
                --        SeqSet.empty
                --        emojiData2.shortNames
                --        |> SeqSet.toList
                --        |> List.map EmojiOrSticker_UnicodeEmoji
                --        |> Array.fromList
                --
                --else
                --    case userData.category of
                --        EmojiCategory emojiCategory ->
                --            SeqDict.get emojiCategory emojiData2.categories
                --                |> Maybe.withDefault []
                --                |> List.map EmojiOrSticker_UnicodeEmoji
                --                |> Array.fromList
                --
                --        StickerCategory ->
                --            SeqSet.toList availableStickers
                --                |> List.map EmojiOrSticker_Sticker
                --                |> Array.fromList
                --
                --        CustomEmojiCategory ->
                --            SeqSet.toList availableCustomEmojis
                --                |> List.map EmojiOrSticker_CustomEmoji
                --                |> Array.fromList
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
                [ searchInput model userData.skinTone (List.map Tuple.first emojis) columns
                , Ui.column
                    []
                    (List.map Tuple.second emojis)
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
                    (case model.emojiHovered of
                        Just (EmojiOrSticker_UnicodeEmoji emoji) ->
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
                ]

        Nothing ->
            Ui.text "Emojis didn't load for some reason"


emojiWithSkinTone : Maybe SkinTone -> UnicodeEmoji -> CachedEmojiData -> String
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
                                emojiData : SeqDict UnicodeEmoji EmojiData
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

                                categories : SeqDict EmojiCategory (List UnicodeEmoji)
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

                            Err _ ->
                                "?"
                    )
                |> String.concat
        )
        (\text -> String.toList text |> List.map (\char -> Char.toCode char |> Hex.toString) |> String.join "-")
        Codec.string
