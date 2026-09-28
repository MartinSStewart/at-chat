module Evergreen.V389.TextEditor exposing (..)

import Array
import Evergreen.V389.Id
import Evergreen.V389.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V389.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Int
    , history : Array.Array ( Evergreen.V389.Id.Id Evergreen.V389.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
    | Server_Redo (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)


type alias Model =
    {}
