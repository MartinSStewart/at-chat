module Evergreen.V407.RichText exposing (..)

import Evergreen.V407.Coord
import Evergreen.V407.CssPixels
import Evergreen.V407.CustomEmoji
import Evergreen.V407.Discord
import Evergreen.V407.FileStatus
import Evergreen.V407.Id
import Evergreen.V407.Point2d
import Evergreen.V407.TimeInMinutes
import Evergreen.V407.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V407.Point2d.Point2d Evergreen.V407.CssPixels.CssPixels Evergreen.V407.Touch.ScreenCoordinate
    , imageSize : Evergreen.V407.Coord.Coord Evergreen.V407.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V407.Id.Id Evergreen.V407.Id.StickerId)
    | CustomEmoji (Evergreen.V407.Id.Id Evergreen.V407.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V407.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V407.Discord.Id Evergreen.V407.Discord.CustomEmojiId
    , name : Evergreen.V407.CustomEmoji.EmojiName
    }
