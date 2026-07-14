module Evergreen.V323.RichText exposing (..)

import Evergreen.V323.Coord
import Evergreen.V323.CssPixels
import Evergreen.V323.CustomEmoji
import Evergreen.V323.Discord
import Evergreen.V323.FileStatus
import Evergreen.V323.Id
import Evergreen.V323.Point2d
import Evergreen.V323.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V323.Id.Id Evergreen.V323.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V323.Point2d.Point2d Evergreen.V323.CssPixels.CssPixels Evergreen.V323.Touch.ScreenCoordinate
    , imageSize : Evergreen.V323.Coord.Coord Evergreen.V323.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V323.Id.Id Evergreen.V323.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V323.Id.Id Evergreen.V323.Id.StickerId)
    | CustomEmoji (Evergreen.V323.Id.Id Evergreen.V323.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V323.Discord.Id Evergreen.V323.Discord.CustomEmojiId
    , name : Evergreen.V323.CustomEmoji.EmojiName
    }
