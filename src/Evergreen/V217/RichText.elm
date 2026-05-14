module Evergreen.V217.RichText exposing (..)

import Evergreen.V217.CustomEmoji
import Evergreen.V217.Discord
import Evergreen.V217.FileStatus
import Evergreen.V217.Id
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
    | AttachedFile (Evergreen.V217.Id.Id Evergreen.V217.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V217.Id.Id Evergreen.V217.Id.StickerId)
    | CustomEmoji (Evergreen.V217.Id.Id Evergreen.V217.Id.CustomEmojiId)


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V217.Discord.Id Evergreen.V217.Discord.CustomEmojiId
    , name : Evergreen.V217.CustomEmoji.EmojiName
    }
