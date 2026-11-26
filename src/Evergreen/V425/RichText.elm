module Evergreen.V425.RichText exposing (..)

import Evergreen.V425.Coord
import Evergreen.V425.CssPixels
import Evergreen.V425.CustomEmoji
import Evergreen.V425.Discord
import Evergreen.V425.FileStatus
import Evergreen.V425.Id
import Evergreen.V425.Point2d
import Evergreen.V425.TimeInMinutes
import Evergreen.V425.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V425.Point2d.Point2d Evergreen.V425.CssPixels.CssPixels Evergreen.V425.Touch.ScreenCoordinate
    , imageSize : Evergreen.V425.Coord.Coord Evergreen.V425.CssPixels.CssPixels
    , displayWidth : Float
    }


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


type RichText userId channelId
    = UserMention userId
    | ChannelMention channelId (Maybe (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId))
    | NormalText Char String
    | Bold (List.Nonempty.Nonempty (RichText userId channelId))
    | Italic (List.Nonempty.Nonempty (RichText userId channelId))
    | Underline (List.Nonempty.Nonempty (RichText userId channelId))
    | Strikethrough (List.Nonempty.Nonempty (RichText userId channelId))
    | Spoiler (List.Nonempty.Nonempty (RichText userId channelId))
    | BlockQuote HasLeadingLineBreak (List (RichText userId channelId))
    | Heading HeadingLevel HasLeadingLineBreak (List.Nonempty.Nonempty (RichText userId channelId))
    | Hyperlink Url.Url
    | MarkdownLink String.Nonempty.NonemptyString Url.Url
    | InlineCode Char String
    | CodeBlock Language String
    | AttachedFile (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V425.Id.Id Evergreen.V425.Id.StickerId)
    | CustomEmoji (Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V425.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V425.Discord.Id Evergreen.V425.Discord.CustomEmojiId
    , name : Evergreen.V425.CustomEmoji.EmojiName
    }
