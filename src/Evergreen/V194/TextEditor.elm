module Evergreen.V194.TextEditor exposing (..)

import Array
import Evergreen.V194.Id
import Evergreen.V194.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V194.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Int
    , history : Array.Array ( Evergreen.V194.Id.Id Evergreen.V194.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Evergreen.V194.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId)
    | Server_Redo (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
