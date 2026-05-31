module Evergreen.V262.TextEditor exposing (..)

import Array
import Evergreen.V262.Id
import Evergreen.V262.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V262.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId) Int
    , history : Array.Array ( Evergreen.V262.Id.Id Evergreen.V262.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId) Evergreen.V262.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId)
    | Server_Redo (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
