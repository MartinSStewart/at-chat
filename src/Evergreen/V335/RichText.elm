module Evergreen.V335.RichText exposing (..)

import Evergreen.V335.Coord
import Evergreen.V335.CssPixels
import Evergreen.V335.CustomEmoji
import Evergreen.V335.Discord
import Evergreen.V335.FileStatus
import Evergreen.V335.Id
import Evergreen.V335.Point2d
import Evergreen.V335.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V335.Id.Id Evergreen.V335.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V335.Point2d.Point2d Evergreen.V335.CssPixels.CssPixels Evergreen.V335.Touch.ScreenCoordinate
    , imageSize : Evergreen.V335.Coord.Coord Evergreen.V335.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V335.Id.Id Evergreen.V335.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V335.Id.Id Evergreen.V335.Id.StickerId)
    | CustomEmoji (Evergreen.V335.Id.Id Evergreen.V335.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V335.Discord.Id Evergreen.V335.Discord.CustomEmojiId
    , name : Evergreen.V335.CustomEmoji.EmojiName
    }
