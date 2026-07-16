module Evergreen.V326.RichText exposing (..)

import Evergreen.V326.Coord
import Evergreen.V326.CssPixels
import Evergreen.V326.CustomEmoji
import Evergreen.V326.Discord
import Evergreen.V326.FileStatus
import Evergreen.V326.Id
import Evergreen.V326.Point2d
import Evergreen.V326.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V326.Id.Id Evergreen.V326.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V326.Point2d.Point2d Evergreen.V326.CssPixels.CssPixels Evergreen.V326.Touch.ScreenCoordinate
    , imageSize : Evergreen.V326.Coord.Coord Evergreen.V326.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V326.Id.Id Evergreen.V326.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V326.Id.Id Evergreen.V326.Id.StickerId)
    | CustomEmoji (Evergreen.V326.Id.Id Evergreen.V326.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V326.Discord.Id Evergreen.V326.Discord.CustomEmojiId
    , name : Evergreen.V326.CustomEmoji.EmojiName
    }
