module Evergreen.V423.RichText exposing (..)

import Evergreen.V423.Coord
import Evergreen.V423.CssPixels
import Evergreen.V423.CustomEmoji
import Evergreen.V423.Discord
import Evergreen.V423.FileStatus
import Evergreen.V423.Id
import Evergreen.V423.Point2d
import Evergreen.V423.TimeInMinutes
import Evergreen.V423.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V423.Point2d.Point2d Evergreen.V423.CssPixels.CssPixels Evergreen.V423.Touch.ScreenCoordinate
    , imageSize : Evergreen.V423.Coord.Coord Evergreen.V423.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V423.Id.Id Evergreen.V423.Id.StickerId)
    | CustomEmoji (Evergreen.V423.Id.Id Evergreen.V423.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V423.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V423.Discord.Id Evergreen.V423.Discord.CustomEmojiId
    , name : Evergreen.V423.CustomEmoji.EmojiName
    }
