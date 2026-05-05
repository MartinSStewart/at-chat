module Evergreen.V214.TextEditor exposing (..)

import Array
import Evergreen.V214.Id
import Evergreen.V214.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V214.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId) Int
    , history : Array.Array ( Evergreen.V214.Id.Id Evergreen.V214.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId) Evergreen.V214.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId)
    | Server_Redo (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
