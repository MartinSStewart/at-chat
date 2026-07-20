module Evergreen.V330.CustomEmoji exposing (..)

import Evergreen.V330.Coord
import Evergreen.V330.CssPixels
import Evergreen.V330.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V330.FileStatus.FileHash (Maybe (Evergreen.V330.Coord.Coord Evergreen.V330.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
