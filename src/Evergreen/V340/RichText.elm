module Evergreen.V340.RichText exposing (..)

import Evergreen.V340.Coord
import Evergreen.V340.CssPixels
import Evergreen.V340.CustomEmoji
import Evergreen.V340.Discord
import Evergreen.V340.FileStatus
import Evergreen.V340.Id
import Evergreen.V340.Point2d
import Evergreen.V340.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V340.Id.Id Evergreen.V340.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V340.Point2d.Point2d Evergreen.V340.CssPixels.CssPixels Evergreen.V340.Touch.ScreenCoordinate
    , imageSize : Evergreen.V340.Coord.Coord Evergreen.V340.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V340.Id.Id Evergreen.V340.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V340.Id.Id Evergreen.V340.Id.StickerId)
    | CustomEmoji (Evergreen.V340.Id.Id Evergreen.V340.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V340.Discord.Id Evergreen.V340.Discord.CustomEmojiId
    , name : Evergreen.V340.CustomEmoji.EmojiName
    }
