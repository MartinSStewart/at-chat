module Evergreen.V419.RichText exposing (..)

import Evergreen.V419.Coord
import Evergreen.V419.CssPixels
import Evergreen.V419.CustomEmoji
import Evergreen.V419.Discord
import Evergreen.V419.FileStatus
import Evergreen.V419.Id
import Evergreen.V419.Point2d
import Evergreen.V419.TimeInMinutes
import Evergreen.V419.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V419.Point2d.Point2d Evergreen.V419.CssPixels.CssPixels Evergreen.V419.Touch.ScreenCoordinate
    , imageSize : Evergreen.V419.Coord.Coord Evergreen.V419.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V419.Id.Id Evergreen.V419.Id.StickerId)
    | CustomEmoji (Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V419.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V419.Discord.Id Evergreen.V419.Discord.CustomEmojiId
    , name : Evergreen.V419.CustomEmoji.EmojiName
    }
