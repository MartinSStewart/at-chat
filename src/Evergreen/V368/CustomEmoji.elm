module Evergreen.V368.CustomEmoji exposing (..)

import Evergreen.V368.Coord
import Evergreen.V368.CssPixels
import Evergreen.V368.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V368.FileStatus.FileHash (Maybe (Evergreen.V368.Coord.Coord Evergreen.V368.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
