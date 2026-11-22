module Evergreen.V423.CustomEmoji exposing (..)

import Evergreen.V423.Coord
import Evergreen.V423.CssPixels
import Evergreen.V423.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V423.FileStatus.FileHash (Maybe (Evergreen.V423.Coord.Coord Evergreen.V423.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
