module Evergreen.V161.RichText exposing (..)

import Effect.Time
import Evergreen.V161.FileStatus
import Evergreen.V161.Id
import List.Nonempty
import String.Nonempty
import Url


type Domain
    = Domain String


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
    | Hyperlink Url.Url
    | InlineCode Char String
    | CodeBlock Language String
    | AttachedFile (Evergreen.V161.Id.Id Evergreen.V161.FileStatus.FileId)


type alias EmbedData =
    { title : Maybe String
    , image : Maybe String
    , content : Maybe String
    , createdAt : Maybe Effect.Time.Posix
    }


type Embed
    = EmbedLoading
    | EmbedLoaded EmbedData
