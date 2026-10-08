module Evergreen.V400.CustomEmoji exposing (..)

import Evergreen.V400.Coord
import Evergreen.V400.CssPixels
import Evergreen.V400.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V400.FileStatus.FileHash (Maybe (Evergreen.V400.Coord.Coord Evergreen.V400.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
