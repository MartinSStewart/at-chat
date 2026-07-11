module Evergreen.V312.CustomEmoji exposing (..)

import Evergreen.V312.Coord
import Evergreen.V312.CssPixels
import Evergreen.V312.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V312.FileStatus.FileHash (Maybe (Evergreen.V312.Coord.Coord Evergreen.V312.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
