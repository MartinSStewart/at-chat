module Evergreen.V396.RichText exposing (..)

import Evergreen.V396.Coord
import Evergreen.V396.CssPixels
import Evergreen.V396.CustomEmoji
import Evergreen.V396.Discord
import Evergreen.V396.FileStatus
import Evergreen.V396.Id
import Evergreen.V396.Point2d
import Evergreen.V396.TimeInMinutes
import Evergreen.V396.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V396.Point2d.Point2d Evergreen.V396.CssPixels.CssPixels Evergreen.V396.Touch.ScreenCoordinate
    , imageSize : Evergreen.V396.Coord.Coord Evergreen.V396.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V396.Id.Id Evergreen.V396.Id.StickerId)
    | CustomEmoji (Evergreen.V396.Id.Id Evergreen.V396.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V396.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V396.Discord.Id Evergreen.V396.Discord.CustomEmojiId
    , name : Evergreen.V396.CustomEmoji.EmojiName
    }
