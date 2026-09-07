module Evergreen.V372.RichText exposing (..)

import Evergreen.V372.Coord
import Evergreen.V372.CssPixels
import Evergreen.V372.CustomEmoji
import Evergreen.V372.Discord
import Evergreen.V372.FileStatus
import Evergreen.V372.Id
import Evergreen.V372.Point2d
import Evergreen.V372.TimeInMinutes
import Evergreen.V372.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V372.Point2d.Point2d Evergreen.V372.CssPixels.CssPixels Evergreen.V372.Touch.ScreenCoordinate
    , imageSize : Evergreen.V372.Coord.Coord Evergreen.V372.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V372.Id.Id Evergreen.V372.Id.StickerId)
    | CustomEmoji (Evergreen.V372.Id.Id Evergreen.V372.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V372.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V372.Discord.Id Evergreen.V372.Discord.CustomEmojiId
    , name : Evergreen.V372.CustomEmoji.EmojiName
    }
