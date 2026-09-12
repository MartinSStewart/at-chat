module Evergreen.V381.CustomEmoji exposing (..)

import Evergreen.V381.Coord
import Evergreen.V381.CssPixels
import Evergreen.V381.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V381.FileStatus.FileHash (Maybe (Evergreen.V381.Coord.Coord Evergreen.V381.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
