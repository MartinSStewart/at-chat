module Evergreen.V359.RichText exposing (..)

import Evergreen.V359.Coord
import Evergreen.V359.CssPixels
import Evergreen.V359.CustomEmoji
import Evergreen.V359.Discord
import Evergreen.V359.FileStatus
import Evergreen.V359.Id
import Evergreen.V359.Point2d
import Evergreen.V359.TimeInMinutes
import Evergreen.V359.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V359.Id.Id Evergreen.V359.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V359.Point2d.Point2d Evergreen.V359.CssPixels.CssPixels Evergreen.V359.Touch.ScreenCoordinate
    , imageSize : Evergreen.V359.Coord.Coord Evergreen.V359.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V359.Id.Id Evergreen.V359.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V359.Id.Id Evergreen.V359.Id.StickerId)
    | CustomEmoji (Evergreen.V359.Id.Id Evergreen.V359.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V359.TimeInMinutes.TimeInMinutes


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V359.Discord.Id Evergreen.V359.Discord.CustomEmojiId
    , name : Evergreen.V359.CustomEmoji.EmojiName
    }
