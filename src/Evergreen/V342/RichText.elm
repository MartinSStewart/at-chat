module Evergreen.V342.RichText exposing (..)

import Evergreen.V342.Coord
import Evergreen.V342.CssPixels
import Evergreen.V342.CustomEmoji
import Evergreen.V342.Discord
import Evergreen.V342.FileStatus
import Evergreen.V342.Id
import Evergreen.V342.Point2d
import Evergreen.V342.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V342.Id.Id Evergreen.V342.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V342.Point2d.Point2d Evergreen.V342.CssPixels.CssPixels Evergreen.V342.Touch.ScreenCoordinate
    , imageSize : Evergreen.V342.Coord.Coord Evergreen.V342.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V342.Id.Id Evergreen.V342.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V342.Id.Id Evergreen.V342.Id.StickerId)
    | CustomEmoji (Evergreen.V342.Id.Id Evergreen.V342.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V342.Discord.Id Evergreen.V342.Discord.CustomEmojiId
    , name : Evergreen.V342.CustomEmoji.EmojiName
    }
