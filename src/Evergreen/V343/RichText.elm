module Evergreen.V343.RichText exposing (..)

import Evergreen.V343.Coord
import Evergreen.V343.CssPixels
import Evergreen.V343.CustomEmoji
import Evergreen.V343.Discord
import Evergreen.V343.FileStatus
import Evergreen.V343.Id
import Evergreen.V343.Point2d
import Evergreen.V343.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V343.Id.Id Evergreen.V343.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V343.Point2d.Point2d Evergreen.V343.CssPixels.CssPixels Evergreen.V343.Touch.ScreenCoordinate
    , imageSize : Evergreen.V343.Coord.Coord Evergreen.V343.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V343.Id.Id Evergreen.V343.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V343.Id.Id Evergreen.V343.Id.StickerId)
    | CustomEmoji (Evergreen.V343.Id.Id Evergreen.V343.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V343.Discord.Id Evergreen.V343.Discord.CustomEmojiId
    , name : Evergreen.V343.CustomEmoji.EmojiName
    }
