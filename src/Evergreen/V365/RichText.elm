module Evergreen.V365.RichText exposing (..)

import Evergreen.V365.Coord
import Evergreen.V365.CssPixels
import Evergreen.V365.CustomEmoji
import Evergreen.V365.Discord
import Evergreen.V365.FileStatus
import Evergreen.V365.Id
import Evergreen.V365.Point2d
import Evergreen.V365.TimeInMinutes
import Evergreen.V365.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V365.Point2d.Point2d Evergreen.V365.CssPixels.CssPixels Evergreen.V365.Touch.ScreenCoordinate
    , imageSize : Evergreen.V365.Coord.Coord Evergreen.V365.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V365.Id.Id Evergreen.V365.Id.StickerId)
    | CustomEmoji (Evergreen.V365.Id.Id Evergreen.V365.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V365.TimeInMinutes.TimeInMinutes


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V365.Discord.Id Evergreen.V365.Discord.CustomEmojiId
    , name : Evergreen.V365.CustomEmoji.EmojiName
    }
