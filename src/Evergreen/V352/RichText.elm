module Evergreen.V352.RichText exposing (..)

import Evergreen.V352.Coord
import Evergreen.V352.CssPixels
import Evergreen.V352.CustomEmoji
import Evergreen.V352.Discord
import Evergreen.V352.FileStatus
import Evergreen.V352.Id
import Evergreen.V352.Point2d
import Evergreen.V352.TimeInMinutes
import Evergreen.V352.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V352.Id.Id Evergreen.V352.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V352.Point2d.Point2d Evergreen.V352.CssPixels.CssPixels Evergreen.V352.Touch.ScreenCoordinate
    , imageSize : Evergreen.V352.Coord.Coord Evergreen.V352.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V352.Id.Id Evergreen.V352.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V352.Id.Id Evergreen.V352.Id.StickerId)
    | CustomEmoji (Evergreen.V352.Id.Id Evergreen.V352.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V352.TimeInMinutes.TimeInMinutes


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V352.Discord.Id Evergreen.V352.Discord.CustomEmojiId
    , name : Evergreen.V352.CustomEmoji.EmojiName
    }
