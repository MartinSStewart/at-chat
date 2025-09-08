module Evergreen.V52.RichText exposing (..)

import Evergreen.V52.FileStatus
import Evergreen.V52.Id
import List.Nonempty
import String.Nonempty
import Url


type Language
    = Language String.Nonempty.NonemptyString
    | NoLanguage


type RichText
    = UserMention (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId)
    | NormalText Char String
    | Bold (List.Nonempty.Nonempty RichText)
    | Italic (List.Nonempty.Nonempty RichText)
    | Underline (List.Nonempty.Nonempty RichText)
    | Strikethrough (List.Nonempty.Nonempty RichText)
    | Spoiler (List.Nonempty.Nonempty RichText)
    | Hyperlink Url.Protocol String
    | InlineCode Char String
    | CodeBlock Language String
    | AttachedFile (Evergreen.V52.Id.Id Evergreen.V52.FileStatus.FileId)
