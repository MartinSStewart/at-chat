module Evergreen.V296.RichText exposing (..)

import Evergreen.V296.Coord
import Evergreen.V296.CssPixels
import Evergreen.V296.CustomEmoji
import Evergreen.V296.Discord
import Evergreen.V296.FileStatus
import Evergreen.V296.Id
import Evergreen.V296.Point2d
import Evergreen.V296.Touch
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
    | AttachedFile (Evergreen.V296.Id.Id Evergreen.V296.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V296.Id.Id Evergreen.V296.Id.StickerId)
    | CustomEmoji (Evergreen.V296.Id.Id Evergreen.V296.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V296.Discord.Id Evergreen.V296.Discord.CustomEmojiId
    , name : Evergreen.V296.CustomEmoji.EmojiName
    }


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V296.Id.Id Evergreen.V296.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V296.Point2d.Point2d Evergreen.V296.CssPixels.CssPixels Evergreen.V296.Touch.ScreenCoordinate
    , imageSize : Evergreen.V296.Coord.Coord Evergreen.V296.CssPixels.CssPixels
    , displayWidth : Float
    }
