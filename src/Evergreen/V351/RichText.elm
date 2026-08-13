module Evergreen.V351.RichText exposing (..)

import Evergreen.V351.Coord
import Evergreen.V351.CssPixels
import Evergreen.V351.CustomEmoji
import Evergreen.V351.Discord
import Evergreen.V351.FileStatus
import Evergreen.V351.Id
import Evergreen.V351.Point2d
import Evergreen.V351.TimeInMinutes
import Evergreen.V351.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V351.Id.Id Evergreen.V351.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V351.Point2d.Point2d Evergreen.V351.CssPixels.CssPixels Evergreen.V351.Touch.ScreenCoordinate
    , imageSize : Evergreen.V351.Coord.Coord Evergreen.V351.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V351.Id.Id Evergreen.V351.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V351.Id.Id Evergreen.V351.Id.StickerId)
    | CustomEmoji (Evergreen.V351.Id.Id Evergreen.V351.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V351.TimeInMinutes.TimeInMinutes


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V351.Discord.Id Evergreen.V351.Discord.CustomEmojiId
    , name : Evergreen.V351.CustomEmoji.EmojiName
    }
