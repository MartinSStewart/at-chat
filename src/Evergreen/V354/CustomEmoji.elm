module Evergreen.V354.CustomEmoji exposing (..)

import Evergreen.V354.Coord
import Evergreen.V354.CssPixels
import Evergreen.V354.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V354.FileStatus.FileHash (Maybe (Evergreen.V354.Coord.Coord Evergreen.V354.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
