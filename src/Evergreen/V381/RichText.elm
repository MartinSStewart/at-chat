module Evergreen.V381.RichText exposing (..)

import Evergreen.V381.Coord
import Evergreen.V381.CssPixels
import Evergreen.V381.CustomEmoji
import Evergreen.V381.Discord
import Evergreen.V381.FileStatus
import Evergreen.V381.Id
import Evergreen.V381.Point2d
import Evergreen.V381.TimeInMinutes
import Evergreen.V381.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V381.Point2d.Point2d Evergreen.V381.CssPixels.CssPixels Evergreen.V381.Touch.ScreenCoordinate
    , imageSize : Evergreen.V381.Coord.Coord Evergreen.V381.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V381.Id.Id Evergreen.V381.Id.StickerId)
    | CustomEmoji (Evergreen.V381.Id.Id Evergreen.V381.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V381.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V381.Discord.Id Evergreen.V381.Discord.CustomEmojiId
    , name : Evergreen.V381.CustomEmoji.EmojiName
    }
