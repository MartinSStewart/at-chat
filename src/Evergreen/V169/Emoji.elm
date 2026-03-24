module Evergreen.V169.Emoji exposing (..)

import Array
import SeqDict


type SkinTone
    = SkinTone1
    | SkinTone2
    | SkinTone3
    | SkinTone4
    | SkinTone5


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


type Emoji
    = UnicodeEmoji String


type alias EmojiConfig =
    { skinTone : Maybe SkinTone
    , category : Category
    , lastUsedEmojis : Array.Array Emoji
    }


type alias Model =
    { emojiHovered : Maybe Emoji
    }


type alias EmojiData =
    { skinVariations : SeqDict.SeqDict SkinTone String
    , shortNames : List String
    }


type alias CachedEmojiData =
    { emojis : SeqDict.SeqDict Emoji EmojiData
    , categories : SeqDict.SeqDict Category (List Emoji)
    , shortNames :
        Array.Array
            { shortName : String
            , emoji : Emoji
            }
    }


type Msg
    = PressedContainer
    | PressedCategory Category
    | PressedSelectEmoji Emoji
    | PressedSkinTone (Maybe SkinTone)
    | MouseEnteredEmoji Emoji
