module Evergreen.V376.RichText exposing (..)

import Evergreen.V376.Coord
import Evergreen.V376.CssPixels
import Evergreen.V376.CustomEmoji
import Evergreen.V376.Discord
import Evergreen.V376.FileStatus
import Evergreen.V376.Id
import Evergreen.V376.Point2d
import Evergreen.V376.TimeInMinutes
import Evergreen.V376.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V376.Point2d.Point2d Evergreen.V376.CssPixels.CssPixels Evergreen.V376.Touch.ScreenCoordinate
    , imageSize : Evergreen.V376.Coord.Coord Evergreen.V376.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V376.Id.Id Evergreen.V376.Id.StickerId)
    | CustomEmoji (Evergreen.V376.Id.Id Evergreen.V376.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V376.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V376.Discord.Id Evergreen.V376.Discord.CustomEmojiId
    , name : Evergreen.V376.CustomEmoji.EmojiName
    }
