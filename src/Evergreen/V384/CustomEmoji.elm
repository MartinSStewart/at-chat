module Evergreen.V384.CustomEmoji exposing (..)

import Evergreen.V384.Coord
import Evergreen.V384.CssPixels
import Evergreen.V384.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V384.FileStatus.FileHash (Maybe (Evergreen.V384.Coord.Coord Evergreen.V384.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
