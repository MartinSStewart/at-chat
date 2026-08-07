module Evergreen.V347.RichText exposing (..)

import Evergreen.V347.Coord
import Evergreen.V347.CssPixels
import Evergreen.V347.CustomEmoji
import Evergreen.V347.Discord
import Evergreen.V347.FileStatus
import Evergreen.V347.Id
import Evergreen.V347.Point2d
import Evergreen.V347.TimeInMinutes
import Evergreen.V347.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V347.Id.Id Evergreen.V347.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V347.Point2d.Point2d Evergreen.V347.CssPixels.CssPixels Evergreen.V347.Touch.ScreenCoordinate
    , imageSize : Evergreen.V347.Coord.Coord Evergreen.V347.CssPixels.CssPixels
    , displayWidth : Float
    }


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
    | AttachedFile (Evergreen.V347.Id.Id Evergreen.V347.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V347.Id.Id Evergreen.V347.Id.StickerId)
    | CustomEmoji (Evergreen.V347.Id.Id Evergreen.V347.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V347.TimeInMinutes.TimeInMinutes


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V347.Discord.Id Evergreen.V347.Discord.CustomEmojiId
    , name : Evergreen.V347.CustomEmoji.EmojiName
    }
