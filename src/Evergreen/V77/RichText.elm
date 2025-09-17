module Evergreen.V77.RichText exposing (..)

import Evergreen.V77.FileStatus
import Evergreen.V77.Id
import List.Nonempty
import String.Nonempty
import Url


type Language
    = Language String.Nonempty.NonemptyString
    | NoLanguage


type RichText
    = UserMention (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId)
    | NormalText Char String
    | Bold (List.Nonempty.Nonempty RichText)
    | Italic (List.Nonempty.Nonempty RichText)
    | Underline (List.Nonempty.Nonempty RichText)
    | Strikethrough (List.Nonempty.Nonempty RichText)
    | Spoiler (List.Nonempty.Nonempty RichText)
    | Hyperlink Url.Protocol String
    | InlineCode Char String
    | CodeBlock Language String
    | AttachedFile (Evergreen.V77.Id.Id Evergreen.V77.FileStatus.FileId)
