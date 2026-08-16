module Evergreen.V353.CustomEmoji exposing (..)

import Evergreen.V353.Coord
import Evergreen.V353.CssPixels
import Evergreen.V353.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V353.FileStatus.FileHash (Maybe (Evergreen.V353.Coord.Coord Evergreen.V353.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
