module Evergreen.V317.RichText exposing (..)

import Evergreen.V317.Coord
import Evergreen.V317.CssPixels
import Evergreen.V317.CustomEmoji
import Evergreen.V317.Discord
import Evergreen.V317.FileStatus
import Evergreen.V317.Id
import Evergreen.V317.Point2d
import Evergreen.V317.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V317.Id.Id Evergreen.V317.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V317.Point2d.Point2d Evergreen.V317.CssPixels.CssPixels Evergreen.V317.Touch.ScreenCoordinate
    , imageSize : Evergreen.V317.Coord.Coord Evergreen.V317.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V317.Id.Id Evergreen.V317.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V317.Id.Id Evergreen.V317.Id.StickerId)
    | CustomEmoji (Evergreen.V317.Id.Id Evergreen.V317.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V317.Discord.Id Evergreen.V317.Discord.CustomEmojiId
    , name : Evergreen.V317.CustomEmoji.EmojiName
    }
