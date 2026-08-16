module Evergreen.V353.TextEditor exposing (..)

import Array
import Evergreen.V353.Id
import Evergreen.V353.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V353.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Int
    , history : Array.Array ( Evergreen.V353.Id.Id Evergreen.V353.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId)
    | Server_Redo (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId)


type alias Model =
    {}
