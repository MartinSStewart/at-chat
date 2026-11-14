module Evergreen.V422.RichText exposing (..)

import Evergreen.V422.Coord
import Evergreen.V422.CssPixels
import Evergreen.V422.CustomEmoji
import Evergreen.V422.Discord
import Evergreen.V422.FileStatus
import Evergreen.V422.Id
import Evergreen.V422.Point2d
import Evergreen.V422.TimeInMinutes
import Evergreen.V422.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V422.Point2d.Point2d Evergreen.V422.CssPixels.CssPixels Evergreen.V422.Touch.ScreenCoordinate
    , imageSize : Evergreen.V422.Coord.Coord Evergreen.V422.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V422.Id.Id Evergreen.V422.Id.StickerId)
    | CustomEmoji (Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V422.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V422.Discord.Id Evergreen.V422.Discord.CustomEmojiId
    , name : Evergreen.V422.CustomEmoji.EmojiName
    }
