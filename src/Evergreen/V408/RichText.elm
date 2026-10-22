module Evergreen.V408.RichText exposing (..)

import Evergreen.V408.Coord
import Evergreen.V408.CssPixels
import Evergreen.V408.CustomEmoji
import Evergreen.V408.Discord
import Evergreen.V408.FileStatus
import Evergreen.V408.Id
import Evergreen.V408.Point2d
import Evergreen.V408.TimeInMinutes
import Evergreen.V408.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V408.Point2d.Point2d Evergreen.V408.CssPixels.CssPixels Evergreen.V408.Touch.ScreenCoordinate
    , imageSize : Evergreen.V408.Coord.Coord Evergreen.V408.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V408.Id.Id Evergreen.V408.Id.StickerId)
    | CustomEmoji (Evergreen.V408.Id.Id Evergreen.V408.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V408.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V408.Discord.Id Evergreen.V408.Discord.CustomEmojiId
    , name : Evergreen.V408.CustomEmoji.EmojiName
    }
