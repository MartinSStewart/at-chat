module Evergreen.V404.TextEditor exposing (..)

import Array
import Evergreen.V404.Id
import Evergreen.V404.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V404.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) Int
    , history : Array.Array ( Evergreen.V404.Id.Id Evergreen.V404.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) Evergreen.V404.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId)
    | Server_Redo (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId)


type alias Model =
    {}
