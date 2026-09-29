module Evergreen.V394.RichText exposing (..)

import Evergreen.V394.Coord
import Evergreen.V394.CssPixels
import Evergreen.V394.CustomEmoji
import Evergreen.V394.Discord
import Evergreen.V394.FileStatus
import Evergreen.V394.Id
import Evergreen.V394.Point2d
import Evergreen.V394.TimeInMinutes
import Evergreen.V394.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V394.Point2d.Point2d Evergreen.V394.CssPixels.CssPixels Evergreen.V394.Touch.ScreenCoordinate
    , imageSize : Evergreen.V394.Coord.Coord Evergreen.V394.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V394.Id.Id Evergreen.V394.Id.StickerId)
    | CustomEmoji (Evergreen.V394.Id.Id Evergreen.V394.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V394.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V394.Discord.Id Evergreen.V394.Discord.CustomEmojiId
    , name : Evergreen.V394.CustomEmoji.EmojiName
    }
