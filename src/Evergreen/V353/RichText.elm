module Evergreen.V353.RichText exposing (..)

import Evergreen.V353.Coord
import Evergreen.V353.CssPixels
import Evergreen.V353.CustomEmoji
import Evergreen.V353.Discord
import Evergreen.V353.FileStatus
import Evergreen.V353.Id
import Evergreen.V353.Point2d
import Evergreen.V353.TimeInMinutes
import Evergreen.V353.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V353.Id.Id Evergreen.V353.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V353.Point2d.Point2d Evergreen.V353.CssPixels.CssPixels Evergreen.V353.Touch.ScreenCoordinate
    , imageSize : Evergreen.V353.Coord.Coord Evergreen.V353.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V353.Id.Id Evergreen.V353.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V353.Id.Id Evergreen.V353.Id.StickerId)
    | CustomEmoji (Evergreen.V353.Id.Id Evergreen.V353.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V353.TimeInMinutes.TimeInMinutes


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V353.Discord.Id Evergreen.V353.Discord.CustomEmojiId
    , name : Evergreen.V353.CustomEmoji.EmojiName
    }
