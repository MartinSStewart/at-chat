module Evergreen.V397.RichText exposing (..)

import Evergreen.V397.Coord
import Evergreen.V397.CssPixels
import Evergreen.V397.CustomEmoji
import Evergreen.V397.Discord
import Evergreen.V397.FileStatus
import Evergreen.V397.Id
import Evergreen.V397.Point2d
import Evergreen.V397.TimeInMinutes
import Evergreen.V397.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V397.Point2d.Point2d Evergreen.V397.CssPixels.CssPixels Evergreen.V397.Touch.ScreenCoordinate
    , imageSize : Evergreen.V397.Coord.Coord Evergreen.V397.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V397.Id.Id Evergreen.V397.Id.StickerId)
    | CustomEmoji (Evergreen.V397.Id.Id Evergreen.V397.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V397.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V397.Discord.Id Evergreen.V397.Discord.CustomEmojiId
    , name : Evergreen.V397.CustomEmoji.EmojiName
    }
