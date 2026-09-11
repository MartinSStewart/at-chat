module Evergreen.V378.RichText exposing (..)

import Evergreen.V378.Coord
import Evergreen.V378.CssPixels
import Evergreen.V378.CustomEmoji
import Evergreen.V378.Discord
import Evergreen.V378.FileStatus
import Evergreen.V378.Id
import Evergreen.V378.Point2d
import Evergreen.V378.TimeInMinutes
import Evergreen.V378.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V378.Point2d.Point2d Evergreen.V378.CssPixels.CssPixels Evergreen.V378.Touch.ScreenCoordinate
    , imageSize : Evergreen.V378.Coord.Coord Evergreen.V378.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V378.Id.Id Evergreen.V378.Id.StickerId)
    | CustomEmoji (Evergreen.V378.Id.Id Evergreen.V378.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V378.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V378.Discord.Id Evergreen.V378.Discord.CustomEmojiId
    , name : Evergreen.V378.CustomEmoji.EmojiName
    }
