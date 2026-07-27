module Evergreen.V336.CustomEmoji exposing (..)

import Evergreen.V336.Coord
import Evergreen.V336.CssPixels
import Evergreen.V336.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V336.FileStatus.FileHash (Maybe (Evergreen.V336.Coord.Coord Evergreen.V336.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
