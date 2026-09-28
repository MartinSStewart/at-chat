module Evergreen.V389.RichText exposing (..)

import Evergreen.V389.Coord
import Evergreen.V389.CssPixels
import Evergreen.V389.CustomEmoji
import Evergreen.V389.Discord
import Evergreen.V389.FileStatus
import Evergreen.V389.Id
import Evergreen.V389.Point2d
import Evergreen.V389.TimeInMinutes
import Evergreen.V389.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V389.Point2d.Point2d Evergreen.V389.CssPixels.CssPixels Evergreen.V389.Touch.ScreenCoordinate
    , imageSize : Evergreen.V389.Coord.Coord Evergreen.V389.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V389.Id.Id Evergreen.V389.Id.StickerId)
    | CustomEmoji (Evergreen.V389.Id.Id Evergreen.V389.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V389.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V389.Discord.Id Evergreen.V389.Discord.CustomEmojiId
    , name : Evergreen.V389.CustomEmoji.EmojiName
    }
