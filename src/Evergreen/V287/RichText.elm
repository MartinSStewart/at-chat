module Evergreen.V287.RichText exposing (..)

import Evergreen.V287.Coord
import Evergreen.V287.CssPixels
import Evergreen.V287.CustomEmoji
import Evergreen.V287.Discord
import Evergreen.V287.FileStatus
import Evergreen.V287.Id
import Evergreen.V287.Point2d
import Evergreen.V287.Touch
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
    | AttachedFile (Evergreen.V287.Id.Id Evergreen.V287.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V287.Id.Id Evergreen.V287.Id.StickerId)
    | CustomEmoji (Evergreen.V287.Id.Id Evergreen.V287.Id.CustomEmojiId)


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V287.Discord.Id Evergreen.V287.Discord.CustomEmojiId
    , name : Evergreen.V287.CustomEmoji.EmojiName
    }


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V287.Id.Id Evergreen.V287.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V287.Point2d.Point2d Evergreen.V287.CssPixels.CssPixels Evergreen.V287.Touch.ScreenCoordinate
    , imageSize : Evergreen.V287.Coord.Coord Evergreen.V287.CssPixels.CssPixels
    , displayWidth : Float
    }
