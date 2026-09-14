module Evergreen.V382.RichText exposing (..)

import Evergreen.V382.Coord
import Evergreen.V382.CssPixels
import Evergreen.V382.CustomEmoji
import Evergreen.V382.Discord
import Evergreen.V382.FileStatus
import Evergreen.V382.Id
import Evergreen.V382.Point2d
import Evergreen.V382.TimeInMinutes
import Evergreen.V382.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V382.Point2d.Point2d Evergreen.V382.CssPixels.CssPixels Evergreen.V382.Touch.ScreenCoordinate
    , imageSize : Evergreen.V382.Coord.Coord Evergreen.V382.CssPixels.CssPixels
    , displayWidth : Float
    }


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
    | AttachedFile (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V382.Id.Id Evergreen.V382.Id.StickerId)
    | CustomEmoji (Evergreen.V382.Id.Id Evergreen.V382.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V382.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V382.Discord.Id Evergreen.V382.Discord.CustomEmojiId
    , name : Evergreen.V382.CustomEmoji.EmojiName
    }
