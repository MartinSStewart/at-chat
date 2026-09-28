module Evergreen.V389.CustomEmoji exposing (..)

import Evergreen.V389.Coord
import Evergreen.V389.CssPixels
import Evergreen.V389.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V389.FileStatus.FileHash (Maybe (Evergreen.V389.Coord.Coord Evergreen.V389.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
