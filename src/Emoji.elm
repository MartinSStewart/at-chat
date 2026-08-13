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
    , emojisInText
    , firstShortName
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
import Ui.Events
import Ui.Font
import Ui.Input
import Ui.Shadow


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


{-| The name people type between colons to write this emoji. Emoji have several
of these and the first is the one the emoji picker leads with, so it's the one
worth showing when there's only room for a single name.
-}
firstShortName : CachedEmojiData -> UnicodeEmoji -> Maybe String
firstShortName emojiData emoji =
    SeqDict.get emoji emojiData.emojis
        |> Maybe.andThen (\data -> List.head data.shortNames)


view : UnicodeEmoji -> Element msg
view (UnicodeEmoji emoji) =
    Ui.el [ Ui.Font.size 20, Ui.width Ui.shrink ] (Ui.text emoji)


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
            Ui.el
                [ Ui.el
                    [ Ui.move { x = 10, y = 4, z = 0 }
                    , Ui.Font.color MyUi.white
                    , Ui.Font.bold
                    , Ui.Shadow.font { offset = ( 0, 0 ), blur = 2, color = MyUi.black }
                    ]
                    (Ui.text "+")
                    |> Ui.inFront
                , Ui.centerX
                ]
                (Ui.text "🙂")


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
    { -- Kept track of by index rather than by which emoji it is, because the recently used emojis
      -- at the top repeat emojis that also show up further down in their own category
      emojiHovered : Maybe { index : Int, emoji : EmojiOrSticker }
    , searchText : String
    , category : Category
    }


type alias EmojiConfig =
    { skinTone : Maybe SkinTone
    , lastUsedEmojis : Array EmojiOrCustomEmoji
    }


selectorInit : Model
selectorInit =
    { emojiHovered = Nothing
    , searchText = ""
    , category = EmojiCategory SmileysAndEmotion
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
    | PressedCategory Category Int
    | ScrolledToCategory Category
    | PressedSelectEmoji EmojiOrSticker
    | PressedSkinTone (Maybe SkinTone)
    | MouseEnteredEmoji Int EmojiOrSticker
    | KeyboardMovedHover Int EmojiOrSticker
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

        PressedCategory _ _ ->
            True

        ScrolledToCategory _ ->
            False

        PressedSkinTone _ ->
            True

        MouseEnteredEmoji _ _ ->
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


{-| Everything in the scrollable part of the selector has a fixed size so that the scroll position
each category starts at can be worked out with arithmetic instead of `Dom.getElement`.
-}
emojiWidth : number
emojiWidth =
    40


stickerWidth : number
stickerWidth =
    emojiWidth * 2


emojiHeight : number
emojiHeight =
    40


categoryTitleHeight : number
categoryTitleHeight =
    24


categoryColumnWidth : number
categoryColumnWidth =
    40


selectorHeight : number
selectorHeight =
    500


{-| How much of the emoji list is on screen at once.
-}
scrollViewportHeight : number
scrollViewportHeight =
    selectorHeight - searchInputHeight


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


searchInputHeight : number
searchInputHeight =
    40


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
        , Ui.height (Ui.px searchInputHeight)
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


{-| How tall a category's section is: its title, plus however many rows its emojis wrap onto.
-}
categorySectionHeight : Int -> Int -> Int
categorySectionHeight columns itemCount =
    categoryTitleHeight + categorySectionBodyHeight columns itemCount


categorySectionBodyHeight : Int -> Int -> Int
categorySectionBodyHeight columns itemCount =
    (itemCount + columns - 1) // columns * emojiHeight


{-| Each category paired with the scroll position its section starts at, which is also the position
it's clicked to jump to.

The first category is the exception: it jumps to the very top instead, so that the recently used
emojis sitting above it are on screen alongside it.

-}
categoryOffsets : Int -> List EmojiOrSticker -> List ( Category, List EmojiOrSticker ) -> List ( Category, Int )
categoryOffsets columns recentEmojis categories =
    let
        offsets : List ( Category, Int )
        offsets =
            List.foldl
                (\( category, items ) ( offset, list ) ->
                    ( offset + categorySectionHeight columns (List.length items)
                    , ( category, offset ) :: list
                    )
                )
                ( if List.isEmpty recentEmojis then
                    0

                  else
                    categorySectionHeight columns (List.length recentEmojis)
                , []
                )
                categories
                |> Tuple.second
                |> List.reverse
    in
    case offsets of
        ( firstCategory, _ ) :: rest ->
            ( firstCategory, 0 ) :: rest

        [] ->
            []


{-| Whether an emoji should show up in the list, based on its names and what's been typed into the
search input. Everything is stripped down to letters and digits first so that searching for
"thumbs up" finds ":thumbsup:".
-}
filterBySearch : String -> (a -> List String) -> List a -> List a
filterBySearch query toNames list =
    if query == "" then
        list

    else
        List.filter
            (\item ->
                List.any
                    (\name -> String.toLower name |> String.filter Char.isAlphaNum |> String.contains query)
                    (toNames item)
            )
            list


{-| The stretch of the list that could be on screen, given which category is at the top of the
viewport. That's all we know about the scroll position, since listening for every scroll event just
to keep track of it would make scrolling lag, so the scroll position is somewhere between that
category's offset and the next one's and this covers either extreme.
-}
visibleRange : Int -> Maybe Category -> List ( Category, Int ) -> { from : Int, to : Int }
visibleRange contentHeight selectedCategory offsets =
    case offsets of
        ( category, offset ) :: rest ->
            if Just category == selectedCategory then
                { from = offset
                , to =
                    (case rest of
                        ( _, nextOffset ) :: _ ->
                            nextOffset

                        [] ->
                            contentHeight
                    )
                        + scrollViewportHeight
                }

            else
                visibleRange contentHeight selectedCategory rest

        [] ->
            { from = 0, to = scrollViewportHeight }


{-| The category whose section the top of the scroll container is showing.
-}
categoryAtScrollPosition : Int -> List ( Category, Int ) -> Maybe Category
categoryAtScrollPosition scrollTop offsets =
    List.foldl
        (\( category, offset ) current ->
            if offset <= scrollTop then
                Just category

            else
                current
        )
        Nothing
        offsets


{-| Fails when scrolling hasn't brought a different category into view. A decoder that fails sends
no message at all, which keeps us from running an update for every scroll event.
-}
decodeScroll : Category -> List ( Category, Int ) -> Json.Decode.Decoder Msg
decodeScroll currentCategory offsets =
    Json.Decode.at [ "target", "scrollTop" ] Json.Decode.float
        |> Json.Decode.andThen
            (\scrollTop ->
                case categoryAtScrollPosition (round scrollTop) offsets of
                    Just category ->
                        if category == currentCategory then
                            Json.Decode.fail ""

                        else
                            Json.Decode.succeed (ScrolledToCategory category)

                    Nothing ->
                        Json.Decode.fail ""
            )


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
                        Maybe.map .index model.emojiHovered

                    moveTo : Int -> Json.Decode.Decoder ( Msg, Bool )
                    moveTo newIndex =
                        case Array.get newIndex items of
                            Just item ->
                                Json.Decode.succeed ( KeyboardMovedHover newIndex item, True )

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
                                Json.Decode.succeed ( PressedSelectEmoji hovered.emoji, True )

                            Nothing ->
                                case Array.get 0 items of
                                    Just first ->
                                        Json.Decode.succeed ( PressedSelectEmoji first, True )

                                    Nothing ->
                                        Json.Decode.succeed ( NoOp, False )

                    _ ->
                        Json.Decode.succeed ( NoOp, False )
            )


type EmojiOrSticker
    = EmojiOrSticker_UnicodeEmoji UnicodeEmoji
    | EmojiOrSticker_Sticker (Id StickerId)
    | EmojiOrSticker_CustomEmoji (Id CustomEmojiId)


emojiButtonHelper : Int -> EmojiOrSticker -> { a | emojiHovered : Maybe { index : Int, emoji : EmojiOrSticker } } -> Element Msg -> Element Msg
emojiButtonHelper index item model content =
    MyUi.elButton
        (emojiButtonId index)
        (PressedSelectEmoji item)
        [ Ui.Events.onMouseEnter (MouseEnteredEmoji index item)
        , Ui.attrIf
            (Maybe.map .index model.emojiHovered == Just index)
            (Ui.background MyUi.hoverHighlight)
        , Ui.contentCenterX
        , Ui.contentCenterY
        , Ui.width (Ui.px emojiWidth)
        , Ui.height (Ui.px emojiHeight)
        ]
        content


emojiCategoryContainer : String -> List (Element msg) -> Element msg
emojiCategoryContainer title content =
    Ui.column
        []
        [ Ui.el
            [ Ui.Font.size 16
            , Ui.height (Ui.px categoryTitleHeight)
            , Ui.contentCenterY
            , Ui.Font.color MyUi.font3
            , Ui.paddingXY 8 0
            ]
            (Ui.text title)
        , Ui.row [ Ui.wrap ] content
        ]


categoryColumn : Maybe SkinTone -> Maybe Category -> List ( Category, Int ) -> Element Msg
categoryColumn skinTone selectedCategory offsets =
    List.map
        (\( category, offset ) ->
            MyUi.elButton
                (categoryButtonId category)
                (PressedCategory category offset)
                [ Ui.height (Ui.px categoryColumnWidth)
                , Ui.contentCenterX
                , Ui.contentCenterY
                , Ui.Font.size 24
                , MyUi.noShrinking
                , MyUi.hoverText (categoryToString category)
                , Ui.attrIf (Just category == selectedCategory) (Ui.background MyUi.background3)
                ]
                (categoryToEmojiString skinTone category)
        )
        offsets
        |> Ui.column [ Ui.width (Ui.px categoryColumnWidth), Ui.alignTop ]


selector :
    Int
    -> Int
    -> Model
    -> EmojiConfig
    -> Maybe CachedEmojiData
    -> SeqSet (Id CustomEmojiId)
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> SeqSet (Id StickerId)
    -> SeqDict (Id StickerId) StickerData
    -> Element Msg
selector scrollbarWidth width model userData emojiData availableCustomEmojis customEmojisData availableStickers stickersData =
    case emojiData of
        Just emojiData2 ->
            let
                selectorWidth : Int
                selectorWidth =
                    min 620 width

                columns : Int
                columns =
                    max 1 ((selectorWidth - categoryColumnWidth - scrollbarWidth) // emojiWidth)

                query : String
                query =
                    String.toLower model.searchText |> String.filter Char.isAlphaNum

                itemNames : EmojiOrSticker -> List String
                itemNames item =
                    case item of
                        EmojiOrSticker_UnicodeEmoji emoji ->
                            case SeqDict.get emoji emojiData2.emojis of
                                Just emojiData3 ->
                                    emojiData3.shortNames

                                Nothing ->
                                    []

                        EmojiOrSticker_Sticker stickerId ->
                            case SeqDict.get stickerId stickersData of
                                Just sticker ->
                                    [ sticker.name ]

                                Nothing ->
                                    []

                        EmojiOrSticker_CustomEmoji customEmojiId ->
                            case SeqDict.get customEmojiId customEmojisData of
                                Just customEmoji ->
                                    [ CustomEmoji.emojiNameToString customEmoji.name ]

                                Nothing ->
                                    []

                categories : List ( Category, List EmojiOrSticker )
                categories =
                    List.filterMap
                        (\category ->
                            let
                                items : List EmojiOrSticker
                                items =
                                    (case category of
                                        EmojiCategory emojiCategory ->
                                            SeqDict.get emojiCategory emojiData2.categories
                                                |> Maybe.withDefault []
                                                |> List.map EmojiOrSticker_UnicodeEmoji

                                        StickerCategory ->
                                            SeqSet.toList availableStickers
                                                |> List.map EmojiOrSticker_Sticker

                                        CustomEmojiCategory ->
                                            SeqSet.toList availableCustomEmojis
                                                |> List.map EmojiOrSticker_CustomEmoji
                                    )
                                        |> filterBySearch query itemNames
                            in
                            case items of
                                [] ->
                                    Nothing

                                _ ->
                                    ( category, items ) |> Just
                        )
                        (List.filterMap
                            (\emojiCategory ->
                                case emojiCategory of
                                    Components ->
                                        Nothing

                                    _ ->
                                        EmojiCategory emojiCategory |> Just
                            )
                            allEmojiCategories
                            ++ [ StickerCategory
                               , CustomEmojiCategory
                               ]
                        )

                -- Recently used emojis, most recent first. They aren't a category of their own:
                -- nothing shows up for them in the column on the left, and they're reached by
                -- clicking the first category, which scrolls all the way to the top.
                recentEmojis : List EmojiOrSticker
                recentEmojis =
                    Array.toList userData.lastUsedEmojis
                        |> List.reverse
                        |> List.filterMap
                            (\emoji ->
                                case emoji of
                                    EmojiOrCustomEmoji_Emoji emoji2 ->
                                        EmojiOrSticker_UnicodeEmoji emoji2 |> Just

                                    EmojiOrCustomEmoji_CustomEmoji customEmojiId ->
                                        if SeqSet.member customEmojiId availableCustomEmojis then
                                            EmojiOrSticker_CustomEmoji customEmojiId |> Just

                                        else
                                            Nothing
                            )
                        |> List.foldl
                            (\emoji list ->
                                if List.member emoji list then
                                    list

                                else
                                    emoji :: list
                            )
                            []
                        |> List.reverse
                        |> filterBySearch query itemNames

                offsets : List ( Category, Int )
                offsets =
                    categoryOffsets columns recentEmojis categories

                -- The scroll container is rebuilt at the top every time the selector is opened, so
                -- fall back to the first category when the one we remember isn't on screen.
                selectedCategory : Maybe Category
                selectedCategory =
                    if List.any (\( category, _ ) -> category == model.category) offsets then
                        Just model.category

                    else
                        List.head offsets |> Maybe.map Tuple.first

                sections : List { title : String, items : List EmojiOrSticker }
                sections =
                    (if List.isEmpty recentEmojis then
                        []

                     else
                        [ { title = "Recently used", items = recentEmojis } ]
                    )
                        ++ List.map
                            (\( category, items ) -> { title = categoryToString category, items = items })
                            categories

                contentHeight : Int
                contentHeight =
                    List.foldl
                        (\section total -> total + categorySectionHeight columns (List.length section.items))
                        0
                        sections

                -- Sections that can't be on screen are rendered as an empty element of the right
                -- height instead. Which ones those are can't be worked out from the highlighted
                -- category alone: once the categories have been filtered down they can be short
                -- enough that several fit in the viewport at once.
                onScreen : { from : Int, to : Int }
                onScreen =
                    visibleRange contentHeight selectedCategory offsets

                -- Emoji buttons are numbered across every category rather than restarting at 0 in
                -- each one, so that the id we scroll to on arrow key presses is unique.
                emojis : List ( List EmojiOrSticker, Element Msg )
                emojis =
                    List.foldl
                        (\section state ->
                            let
                                itemCount : Int
                                itemCount =
                                    List.length section.items

                                height : Int
                                height =
                                    categorySectionHeight columns itemCount
                            in
                            { itemOffset = state.itemOffset + itemCount
                            , top = state.top + height
                            , sections =
                                ( section.items
                                , (if state.top < onScreen.to && state.top + height > onScreen.from then
                                    List.indexedMap
                                        (\index item ->
                                            emojiButtonHelper
                                                (state.itemOffset + index)
                                                item
                                                model
                                                (case item of
                                                    EmojiOrSticker_UnicodeEmoji emoji ->
                                                        emojiWithSkinTone userData.skinTone emoji emojiData2
                                                            |> Ui.text
                                                            |> Ui.el [ Ui.width (Ui.px emojiWidth), Ui.Font.center ]

                                                    EmojiOrSticker_Sticker stickerId ->
                                                        Sticker.view
                                                            (String.fromInt emojiWidth ++ "px")
                                                            stickerId
                                                            stickersData
                                                            Sticker.LoopForever
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
                                        section.items

                                   else
                                    [ Ui.el [ Ui.height (Ui.px (categorySectionBodyHeight columns itemCount)) ] Ui.none ]
                                  )
                                    |> emojiCategoryContainer section.title
                                )
                                    :: state.sections
                            }
                        )
                        { itemOffset = 0, top = 0, sections = [] }
                        sections
                        |> .sections
                        |> List.reverse
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
                , Ui.row
                    [ Ui.height Ui.fill, Ui.heightMin 0 ]
                    [ categoryColumn userData.skinTone selectedCategory offsets
                    , Ui.column
                        [ Ui.height Ui.fill, emojiHoverPreview stickersData customEmojisData userData emojiData2 model |> Ui.inFront ]
                        [ Ui.el
                            [ Ui.background MyUi.background3
                            , Ui.scrollable
                            , Ui.clipX
                            , Ui.height (Ui.px scrollViewportHeight)
                            , Ui.heightMin 0
                            , Ui.id (Dom.idToString scrollContainerId)
                            , Ui.htmlAttribute (Html.Events.on "scroll" (decodeScroll model.category offsets))
                            ]
                            (Ui.column
                                [ Ui.width (Ui.px (columns * emojiWidth))
                                , Ui.paddingWith { left = 0, right = 0, top = 0, bottom = stickerWidth }
                                ]
                                (List.map Tuple.second emojis)
                            )
                        ]
                    ]
                ]

        Nothing ->
            Ui.text "Emojis didn't load for some reason"


emojiHoverPreview :
    SeqDict (Id StickerId) StickerData
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> EmojiConfig
    -> CachedEmojiData
    -> Model
    -> Element msg
emojiHoverPreview stickersData customEmojisData userData emojiData2 model =
    Ui.row
        [ Ui.contentCenterY
        , Ui.spacing 8
        , Ui.alignBottom
        , Ui.background MyUi.background2
        , Ui.paddingXY 4 0
        ]
        (case Maybe.map .emoji model.emojiHovered of
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
                        [ Sticker.view
                            (String.fromInt stickerWidth ++ "px")
                            stickerId
                            stickersData
                            Sticker.LoopForever
                            |> Ui.html
                        , Ui.el
                            [ Ui.Font.size 16, Ui.width Ui.shrink ]
                            (Ui.text (":" ++ sticker.name ++ ":"))
                        ]

                    Nothing ->
                        []

            Just (EmojiOrSticker_CustomEmoji customEmojiId) ->
                case SeqDict.get customEmojiId customEmojisData of
                    Just sticker ->
                        [ CustomEmoji.view
                            (String.fromInt emojiWidth ++ "px")
                            "0"
                            customEmojiId
                            customEmojisData
                            Sticker.LoopForever
                            |> Ui.html
                        , Ui.el
                            [ Ui.Font.size 16, Ui.width Ui.shrink ]
                            (Ui.text (":" ++ CustomEmoji.emojiNameToString sticker.name ++ ":"))
                        ]

                    Nothing ->
                        []

            Nothing ->
                []
        )


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


{-| The most code points a single emoji is made up of, taken from compact-emoji.json. Flags like
🏴󠁧󠁢󠁥󠁮󠁧󠁿 are the longest.
-}
maxEmojiLength : Int
maxEmojiLength =
    8


{-| The emojis in some text, in the order they first appear and without repeats. Skin tone
modifiers are dropped first, so 👍🏽 counts as a use of 👍, which is how emojis are stored.

The emoji data is only loaded in the frontend, so this is also the only place text can be picked
apart into emojis.

-}
emojisInText : CachedEmojiData -> String -> List UnicodeEmoji
emojisInText emojiData text =
    List.foldl
        (\skinTone text2 -> String.replace (skinToneToString skinTone) "" text2)
        text
        allSkinTones
        |> String.toList
        |> emojisInTextHelper emojiData.emojis []
        |> List.reverse


emojisInTextHelper : SeqDict UnicodeEmoji EmojiData -> List UnicodeEmoji -> List Char -> List UnicodeEmoji
emojisInTextHelper emojis found chars =
    case chars of
        [] ->
            found

        _ :: rest ->
            case emojiStartingWith emojis chars of
                Just ( emoji, length ) ->
                    emojisInTextHelper
                        emojis
                        (if List.member emoji found then
                            found

                         else
                            emoji :: found
                        )
                        (List.drop length chars)

                Nothing ->
                    emojisInTextHelper emojis found rest


{-| The emoji the text starts with and how many code points long it is. Longer emojis are tried
first so that 👨‍👩‍👧 isn't mistaken for a 👨 followed by some junk.
-}
emojiStartingWith : SeqDict UnicodeEmoji EmojiData -> List Char -> Maybe ( UnicodeEmoji, Int )
emojiStartingWith emojis chars =
    List.foldl
        (\length result ->
            case result of
                Just _ ->
                    result

                Nothing ->
                    let
                        emoji : UnicodeEmoji
                        emoji =
                            List.take length chars |> String.fromList |> UnicodeEmoji
                    in
                    if SeqDict.member emoji emojis then
                        Just ( emoji, length )

                    else
                        Nothing
        )
        Nothing
        (List.range 1 maxEmojiLength |> List.reverse)


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
