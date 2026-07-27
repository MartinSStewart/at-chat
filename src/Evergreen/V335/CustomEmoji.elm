module Evergreen.V335.CustomEmoji exposing (..)

import Evergreen.V335.Coord
import Evergreen.V335.CssPixels
import Evergreen.V335.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V335.FileStatus.FileHash (Maybe (Evergreen.V335.Coord.Coord Evergreen.V335.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
