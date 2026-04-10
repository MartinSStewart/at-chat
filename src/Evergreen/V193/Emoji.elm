module Evergreen.V193.Emoji exposing (..)

import Array
import Evergreen.V193.Id
import SeqDict


type SkinTone
    = SkinTone1
    | SkinTone2
    | SkinTone3
    | SkinTone4
    | SkinTone5


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


type Emoji
    = UnicodeEmoji String


type alias EmojiConfig =
    { skinTone : Maybe SkinTone
    , category : Category
    , lastUsedEmojis : Array.Array Emoji
    }


type EmojiOrSticker
    = EmojiOrSticker_Emoji Emoji
    | EmojiOrSticker_Sticker (Evergreen.V193.Id.Id Evergreen.V193.Id.StickerId)


type alias Model =
    { emojiHovered : Maybe EmojiOrSticker
    , searchText : String
    }


type alias EmojiData =
    { skinVariations : Maybe String
    , shortNames : List String
    }


type alias CachedEmojiData =
    { emojis : SeqDict.SeqDict Emoji EmojiData
    , categories : SeqDict.SeqDict EmojiCategory (List Emoji)
    , shortNames :
        Array.Array
            { shortName : String
            , emoji : Emoji
            }
    }


type Msg
    = PressedContainer
    | PressedCategory Category
    | PressedSelectEmoji EmojiOrSticker
    | PressedSkinTone (Maybe SkinTone)
    | MouseEnteredEmoji EmojiOrSticker
    | TypedSearchText String
    | PressedClearSearch
