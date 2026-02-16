module Evergreen.V114.RichText exposing (..)

import Evergreen.V114.FileStatus
import Evergreen.V114.Id
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
    | AttachedFile (Evergreen.V114.Id.Id Evergreen.V114.FileStatus.FileId)


type alias Range =
    { start : Int
    , end : Int
    }
