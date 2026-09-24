module Evergreen.V385.RichText exposing (..)

import Evergreen.V385.Coord
import Evergreen.V385.CssPixels
import Evergreen.V385.CustomEmoji
import Evergreen.V385.Discord
import Evergreen.V385.FileStatus
import Evergreen.V385.Id
import Evergreen.V385.Point2d
import Evergreen.V385.TimeInMinutes
import Evergreen.V385.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V385.Point2d.Point2d Evergreen.V385.CssPixels.CssPixels Evergreen.V385.Touch.ScreenCoordinate
    , imageSize : Evergreen.V385.Coord.Coord Evergreen.V385.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V385.Id.Id Evergreen.V385.Id.StickerId)
    | CustomEmoji (Evergreen.V385.Id.Id Evergreen.V385.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V385.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V385.Discord.Id Evergreen.V385.Discord.CustomEmojiId
    , name : Evergreen.V385.CustomEmoji.EmojiName
    }
