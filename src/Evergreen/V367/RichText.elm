module Evergreen.V367.RichText exposing (..)

import Evergreen.V367.Coord
import Evergreen.V367.CssPixels
import Evergreen.V367.CustomEmoji
import Evergreen.V367.Discord
import Evergreen.V367.FileStatus
import Evergreen.V367.Id
import Evergreen.V367.Point2d
import Evergreen.V367.TimeInMinutes
import Evergreen.V367.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V367.Point2d.Point2d Evergreen.V367.CssPixels.CssPixels Evergreen.V367.Touch.ScreenCoordinate
    , imageSize : Evergreen.V367.Coord.Coord Evergreen.V367.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V367.Id.Id Evergreen.V367.Id.StickerId)
    | CustomEmoji (Evergreen.V367.Id.Id Evergreen.V367.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V367.TimeInMinutes.TimeInMinutes


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V367.Discord.Id Evergreen.V367.Discord.CustomEmojiId
    , name : Evergreen.V367.CustomEmoji.EmojiName
    }
