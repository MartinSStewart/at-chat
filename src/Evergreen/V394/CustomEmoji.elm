module Evergreen.V394.CustomEmoji exposing (..)

import Evergreen.V394.Coord
import Evergreen.V394.CssPixels
import Evergreen.V394.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V394.FileStatus.FileHash (Maybe (Evergreen.V394.Coord.Coord Evergreen.V394.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
