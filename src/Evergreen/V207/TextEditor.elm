module Evergreen.V207.TextEditor exposing (..)

import Array
import Evergreen.V207.Id
import Evergreen.V207.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V207.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Int
    , history : Array.Array ( Evergreen.V207.Id.Id Evergreen.V207.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Evergreen.V207.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId)
    | Server_Redo (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
