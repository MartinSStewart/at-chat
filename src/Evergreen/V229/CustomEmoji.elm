module Evergreen.V229.CustomEmoji exposing (..)

import Evergreen.V229.Coord
import Evergreen.V229.CssPixels
import Evergreen.V229.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V229.FileStatus.FileHash (Maybe (Evergreen.V229.Coord.Coord Evergreen.V229.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
