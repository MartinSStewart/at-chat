module Evergreen.V426.RichText exposing (..)

import Evergreen.V426.Coord
import Evergreen.V426.CssPixels
import Evergreen.V426.CustomEmoji
import Evergreen.V426.Discord
import Evergreen.V426.FileStatus
import Evergreen.V426.Id
import Evergreen.V426.Point2d
import Evergreen.V426.TimeInMinutes
import Evergreen.V426.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V426.Point2d.Point2d Evergreen.V426.CssPixels.CssPixels Evergreen.V426.Touch.ScreenCoordinate
    , imageSize : Evergreen.V426.Coord.Coord Evergreen.V426.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V426.Id.Id Evergreen.V426.Id.StickerId)
    | CustomEmoji (Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V426.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V426.Discord.Id Evergreen.V426.Discord.CustomEmojiId
    , name : Evergreen.V426.CustomEmoji.EmojiName
    }
