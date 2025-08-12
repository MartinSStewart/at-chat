module Evergreen.V27.RichText exposing (..)

import Evergreen.V27.FileStatus
import Evergreen.V27.Id
import List.Nonempty
import String.Nonempty
import Url


type Language
    = Language String.Nonempty.NonemptyString
    | None


type RichText
    = UserMention (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
    | NormalText Char String
    | Bold (List.Nonempty.Nonempty RichText)
    | Italic (List.Nonempty.Nonempty RichText)
    | Underline (List.Nonempty.Nonempty RichText)
    | Strikethrough (List.Nonempty.Nonempty RichText)
    | Spoiler (List.Nonempty.Nonempty RichText)
    | Hyperlink Url.Protocol String
    | InlineCode Char String
    | CodeBlock Language String
    | AttachedFile (Evergreen.V27.Id.Id Evergreen.V27.FileStatus.FileId)
