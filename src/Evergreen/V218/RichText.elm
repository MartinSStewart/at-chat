module Evergreen.V218.RichText exposing (..)

import Evergreen.V218.CustomEmoji
import Evergreen.V218.Discord
import Evergreen.V218.FileStatus
import Evergreen.V218.Id
import List.Nonempty
import String.Nonempty
import Url


type Domain
    = Domain String


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


type RichText userId
    = UserMention userId
    | NormalText Char String
    | Bold (List.Nonempty.Nonempty (RichText userId))
    | Italic (List.Nonempty.Nonempty (RichText userId))
    | Underline (List.Nonempty.Nonempty (RichText userId))
    | Strikethrough (List.Nonempty.Nonempty (RichText userId))
    | Spoiler (List.Nonempty.Nonempty (RichText userId))
    | BlockQuote HasLeadingLineBreak (List (RichText userId))
    | Heading HeadingLevel HasLeadingLineBreak (List.Nonempty.Nonempty (RichText userId))
    | Hyperlink Url.Url
    | MarkdownLink String.Nonempty.NonemptyString Url.Url
    | InlineCode Char String
    | CodeBlock Language String
    | AttachedFile (Evergreen.V218.Id.Id Evergreen.V218.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V218.Id.Id Evergreen.V218.Id.StickerId)
    | CustomEmoji (Evergreen.V218.Id.Id Evergreen.V218.Id.CustomEmojiId)


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V218.Discord.Id Evergreen.V218.Discord.CustomEmojiId
    , name : Evergreen.V218.CustomEmoji.EmojiName
    }
