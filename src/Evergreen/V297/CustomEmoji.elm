module Evergreen.V297.CustomEmoji exposing (..)

import Evergreen.V297.Coord
import Evergreen.V297.CssPixels
import Evergreen.V297.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V297.FileStatus.FileHash (Maybe (Evergreen.V297.Coord.Coord Evergreen.V297.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
