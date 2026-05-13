module Evergreen.V215.CustomEmoji exposing (..)

import Evergreen.V215.Coord
import Evergreen.V215.CssPixels
import Evergreen.V215.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V215.FileStatus.FileHash (Maybe (Evergreen.V215.Coord.Coord Evergreen.V215.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
