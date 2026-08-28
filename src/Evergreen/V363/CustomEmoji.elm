module Evergreen.V363.CustomEmoji exposing (..)

import Evergreen.V363.Coord
import Evergreen.V363.CssPixels
import Evergreen.V363.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V363.FileStatus.FileHash (Maybe (Evergreen.V363.Coord.Coord Evergreen.V363.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
