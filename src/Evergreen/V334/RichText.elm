module Evergreen.V334.RichText exposing (..)

import Evergreen.V334.Coord
import Evergreen.V334.CssPixels
import Evergreen.V334.CustomEmoji
import Evergreen.V334.Discord
import Evergreen.V334.FileStatus
import Evergreen.V334.Id
import Evergreen.V334.Point2d
import Evergreen.V334.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V334.Id.Id Evergreen.V334.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V334.Point2d.Point2d Evergreen.V334.CssPixels.CssPixels Evergreen.V334.Touch.ScreenCoordinate
    , imageSize : Evergreen.V334.Coord.Coord Evergreen.V334.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V334.Id.Id Evergreen.V334.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V334.Id.Id Evergreen.V334.Id.StickerId)
    | CustomEmoji (Evergreen.V334.Id.Id Evergreen.V334.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V334.Discord.Id Evergreen.V334.Discord.CustomEmojiId
    , name : Evergreen.V334.CustomEmoji.EmojiName
    }
