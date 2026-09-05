module Evergreen.V368.RichText exposing (..)

import Evergreen.V368.Coord
import Evergreen.V368.CssPixels
import Evergreen.V368.CustomEmoji
import Evergreen.V368.Discord
import Evergreen.V368.FileStatus
import Evergreen.V368.Id
import Evergreen.V368.Point2d
import Evergreen.V368.TimeInMinutes
import Evergreen.V368.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V368.Point2d.Point2d Evergreen.V368.CssPixels.CssPixels Evergreen.V368.Touch.ScreenCoordinate
    , imageSize : Evergreen.V368.Coord.Coord Evergreen.V368.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V368.Id.Id Evergreen.V368.Id.StickerId)
    | CustomEmoji (Evergreen.V368.Id.Id Evergreen.V368.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V368.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V368.Discord.Id Evergreen.V368.Discord.CustomEmojiId
    , name : Evergreen.V368.CustomEmoji.EmojiName
    }
