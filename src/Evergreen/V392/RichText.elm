module Evergreen.V392.RichText exposing (..)

import Evergreen.V392.Coord
import Evergreen.V392.CssPixels
import Evergreen.V392.CustomEmoji
import Evergreen.V392.Discord
import Evergreen.V392.FileStatus
import Evergreen.V392.Id
import Evergreen.V392.Point2d
import Evergreen.V392.TimeInMinutes
import Evergreen.V392.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V392.Point2d.Point2d Evergreen.V392.CssPixels.CssPixels Evergreen.V392.Touch.ScreenCoordinate
    , imageSize : Evergreen.V392.Coord.Coord Evergreen.V392.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V392.Id.Id Evergreen.V392.Id.StickerId)
    | CustomEmoji (Evergreen.V392.Id.Id Evergreen.V392.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V392.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V392.Discord.Id Evergreen.V392.Discord.CustomEmojiId
    , name : Evergreen.V392.CustomEmoji.EmojiName
    }
