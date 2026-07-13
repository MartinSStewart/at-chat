module Evergreen.V318.Emoji exposing (..)

import Array
import Evergreen.V318.Id
import SeqDict


type UnicodeEmoji
    = UnicodeEmoji String


type EmojiOrCustomEmoji
    = EmojiOrCustomEmoji_Emoji UnicodeEmoji
    | EmojiOrCustomEmoji_CustomEmoji (Evergreen.V318.Id.Id Evergreen.V318.Id.CustomEmojiId)


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


type Category
    = EmojiCategory EmojiCategory
    | StickerCategory
    | CustomEmojiCategory


type EmojiOrSticker
    = EmojiOrSticker_UnicodeEmoji UnicodeEmoji
    | EmojiOrSticker_Sticker (Evergreen.V318.Id.Id Evergreen.V318.Id.StickerId)
    | EmojiOrSticker_CustomEmoji (Evergreen.V318.Id.Id Evergreen.V318.Id.CustomEmojiId)


type SkinTone
    = SkinTone1
    | SkinTone2
    | SkinTone3
    | SkinTone4
    | SkinTone5


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


type alias EmojiData =
    { skinVariations : Maybe String
    , shortNames : List String
    }


type alias CachedEmojiData =
    { emojis : SeqDict.SeqDict UnicodeEmoji EmojiData
    , categories : SeqDict.SeqDict EmojiCategory (List UnicodeEmoji)
    , shortNames :
        Array.Array
            { shortName : String
            , emoji : UnicodeEmoji
            }
    }


type alias EmojiConfig =
    { skinTone : Maybe SkinTone
    , category : Category
    , lastUsedEmojis : Array.Array EmojiOrCustomEmoji
    }


type alias Model =
    { emojiHovered : Maybe EmojiOrSticker
    , searchText : String
    }
