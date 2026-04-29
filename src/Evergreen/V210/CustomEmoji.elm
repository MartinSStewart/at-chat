module Evergreen.V210.CustomEmoji exposing (..)

import Evergreen.V210.Coord
import Evergreen.V210.CssPixels
import Evergreen.V210.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V210.FileStatus.FileHash (Maybe (Evergreen.V210.Coord.Coord Evergreen.V210.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
