module Evergreen.V285.RichText exposing (..)

import Evergreen.V285.Coord
import Evergreen.V285.CssPixels
import Evergreen.V285.CustomEmoji
import Evergreen.V285.Discord
import Evergreen.V285.FileStatus
import Evergreen.V285.Id
import Evergreen.V285.Point2d
import Evergreen.V285.Touch
import List.Nonempty
import String.Nonempty
import Url


type Domain
    = Domain String


type HasLeadingLineBreak
    = HasLeadingLineBreak
    | NoLeadingLineBreak


type HeadingLevel
    = H1
    | H2
    | H3
    | Small


type Language
    = Language String.Nonempty.NonemptyString
    | NoLanguage


type EscapedChar
    = EscapedSquareBracket
    | EscapedBackslash
    | EscapedBacktick
    | EscapedAtSymbol
    | EscapedBold
    | EscapedItalic
    | EscapedStrikethrough
    | EscapedSpoilered


type RichText userId
    = UserMention userId
    | NormalText Char String
    | Bold (List.Nonempty.Nonempty (RichText userId))
    | Italic (List.Nonempty.Nonempty (RichText userId))
    | Underline (List.Nonempty.Nonempty (RichText userId))
    | Strikethrough (List.Nonempty.Nonempty (RichText userId))
    | Spoiler (List.Nonempty.Nonempty (RichText userId))
    | BlockQuote HasLeadingLineBreak (List (RichText userId))
    | Heading HeadingLevel HasLeadingLineBreak (List.Nonempty.Nonempty (RichText userId))
    | Hyperlink Url.Url
    | MarkdownLink String.Nonempty.NonemptyString Url.Url
    | InlineCode Char String
    | CodeBlock Language String
    | AttachedFile (Evergreen.V285.Id.Id Evergreen.V285.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V285.Id.Id Evergreen.V285.Id.StickerId)
    | CustomEmoji (Evergreen.V285.Id.Id Evergreen.V285.Id.CustomEmojiId)


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V285.Discord.Id Evergreen.V285.Discord.CustomEmojiId
    , name : Evergreen.V285.CustomEmoji.EmojiName
    }


type alias PressedImageData =
    { fileId : Evergreen.V285.Id.Id Evergreen.V285.FileStatus.FileId
    , fileUrl : String
    , position : Evergreen.V285.Point2d.Point2d Evergreen.V285.CssPixels.CssPixels Evergreen.V285.Touch.ScreenCoordinate
    , imageSize : Evergreen.V285.Coord.Coord Evergreen.V285.CssPixels.CssPixels
    }
