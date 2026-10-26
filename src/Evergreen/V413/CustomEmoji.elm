module Evergreen.V413.CustomEmoji exposing (..)

import Evergreen.V413.Coord
import Evergreen.V413.CssPixels
import Evergreen.V413.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V413.FileStatus.FileHash (Maybe (Evergreen.V413.Coord.Coord Evergreen.V413.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
