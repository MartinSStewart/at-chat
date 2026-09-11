module Evergreen.V377.RichText exposing (..)

import Evergreen.V377.Coord
import Evergreen.V377.CssPixels
import Evergreen.V377.CustomEmoji
import Evergreen.V377.Discord
import Evergreen.V377.FileStatus
import Evergreen.V377.Id
import Evergreen.V377.Point2d
import Evergreen.V377.TimeInMinutes
import Evergreen.V377.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V377.Point2d.Point2d Evergreen.V377.CssPixels.CssPixels Evergreen.V377.Touch.ScreenCoordinate
    , imageSize : Evergreen.V377.Coord.Coord Evergreen.V377.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V377.Id.Id Evergreen.V377.Id.StickerId)
    | CustomEmoji (Evergreen.V377.Id.Id Evergreen.V377.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V377.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V377.Discord.Id Evergreen.V377.Discord.CustomEmojiId
    , name : Evergreen.V377.CustomEmoji.EmojiName
    }
