module Evergreen.V357.RichText exposing (..)

import Evergreen.V357.Coord
import Evergreen.V357.CssPixels
import Evergreen.V357.CustomEmoji
import Evergreen.V357.Discord
import Evergreen.V357.FileStatus
import Evergreen.V357.Id
import Evergreen.V357.Point2d
import Evergreen.V357.TimeInMinutes
import Evergreen.V357.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V357.Id.Id Evergreen.V357.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V357.Point2d.Point2d Evergreen.V357.CssPixels.CssPixels Evergreen.V357.Touch.ScreenCoordinate
    , imageSize : Evergreen.V357.Coord.Coord Evergreen.V357.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V357.Id.Id Evergreen.V357.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V357.Id.Id Evergreen.V357.Id.StickerId)
    | CustomEmoji (Evergreen.V357.Id.Id Evergreen.V357.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V357.TimeInMinutes.TimeInMinutes


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V357.Discord.Id Evergreen.V357.Discord.CustomEmojiId
    , name : Evergreen.V357.CustomEmoji.EmojiName
    }
