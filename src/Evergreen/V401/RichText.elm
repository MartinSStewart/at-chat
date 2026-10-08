module Evergreen.V401.RichText exposing (..)

import Evergreen.V401.Coord
import Evergreen.V401.CssPixels
import Evergreen.V401.CustomEmoji
import Evergreen.V401.Discord
import Evergreen.V401.FileStatus
import Evergreen.V401.Id
import Evergreen.V401.Point2d
import Evergreen.V401.TimeInMinutes
import Evergreen.V401.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V401.Point2d.Point2d Evergreen.V401.CssPixels.CssPixels Evergreen.V401.Touch.ScreenCoordinate
    , imageSize : Evergreen.V401.Coord.Coord Evergreen.V401.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V401.Id.Id Evergreen.V401.Id.StickerId)
    | CustomEmoji (Evergreen.V401.Id.Id Evergreen.V401.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V401.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V401.Discord.Id Evergreen.V401.Discord.CustomEmojiId
    , name : Evergreen.V401.CustomEmoji.EmojiName
    }
