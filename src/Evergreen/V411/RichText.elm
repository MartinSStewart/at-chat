module Evergreen.V411.RichText exposing (..)

import Evergreen.V411.Coord
import Evergreen.V411.CssPixels
import Evergreen.V411.CustomEmoji
import Evergreen.V411.Discord
import Evergreen.V411.FileStatus
import Evergreen.V411.Id
import Evergreen.V411.Point2d
import Evergreen.V411.TimeInMinutes
import Evergreen.V411.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V411.Id.Id Evergreen.V411.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V411.Point2d.Point2d Evergreen.V411.CssPixels.CssPixels Evergreen.V411.Touch.ScreenCoordinate
    , imageSize : Evergreen.V411.Coord.Coord Evergreen.V411.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V411.Id.Id Evergreen.V411.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V411.Id.Id Evergreen.V411.Id.StickerId)
    | CustomEmoji (Evergreen.V411.Id.Id Evergreen.V411.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V411.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V411.Discord.Id Evergreen.V411.Discord.CustomEmojiId
    , name : Evergreen.V411.CustomEmoji.EmojiName
    }
