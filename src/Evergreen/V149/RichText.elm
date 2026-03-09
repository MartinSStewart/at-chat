module Evergreen.V149.RichText exposing (..)

import Evergreen.V149.FileStatus
import Evergreen.V149.Id
import List.Nonempty
import String.Nonempty
import Url


type Language
    = Language String.Nonempty.NonemptyString
    | NoLanguage


type RichText userId
    = UserMention userId
    | NormalText Char String
    | Bold (List.Nonempty.Nonempty (RichText userId))
    | Italic (List.Nonempty.Nonempty (RichText userId))
    | Underline (List.Nonempty.Nonempty (RichText userId))
    | Strikethrough (List.Nonempty.Nonempty (RichText userId))
    | Spoiler (List.Nonempty.Nonempty (RichText userId))
    | Hyperlink Url.Protocol String
    | InlineCode Char String
    | CodeBlock Language String
    | AttachedFile (Evergreen.V149.Id.Id Evergreen.V149.FileStatus.FileId)


type alias Range =
    { start : Int
    , end : Int
    }
