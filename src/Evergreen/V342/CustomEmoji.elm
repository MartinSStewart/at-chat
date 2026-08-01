module Evergreen.V342.CustomEmoji exposing (..)

import Evergreen.V342.Coord
import Evergreen.V342.CssPixels
import Evergreen.V342.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V342.FileStatus.FileHash (Maybe (Evergreen.V342.Coord.Coord Evergreen.V342.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
