module Evergreen.V294.RichText exposing (..)

import Evergreen.V294.Coord
import Evergreen.V294.CssPixels
import Evergreen.V294.CustomEmoji
import Evergreen.V294.Discord
import Evergreen.V294.FileStatus
import Evergreen.V294.Id
import Evergreen.V294.Point2d
import Evergreen.V294.Touch
import List.Nonempty
import String.Nonempty
import Url


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
    | AttachedFile (Evergreen.V294.Id.Id Evergreen.V294.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V294.Id.Id Evergreen.V294.Id.StickerId)
    | CustomEmoji (Evergreen.V294.Id.Id Evergreen.V294.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V294.Discord.Id Evergreen.V294.Discord.CustomEmojiId
    , name : Evergreen.V294.CustomEmoji.EmojiName
    }


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V294.Id.Id Evergreen.V294.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V294.Point2d.Point2d Evergreen.V294.CssPixels.CssPixels Evergreen.V294.Touch.ScreenCoordinate
    , imageSize : Evergreen.V294.Coord.Coord Evergreen.V294.CssPixels.CssPixels
    , displayWidth : Float
    }
