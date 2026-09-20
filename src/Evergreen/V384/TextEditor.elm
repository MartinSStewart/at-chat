module Evergreen.V384.TextEditor exposing (..)

import Array
import Evergreen.V384.Id
import Evergreen.V384.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V384.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Int
    , history : Array.Array ( Evergreen.V384.Id.Id Evergreen.V384.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    | Server_Redo (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)


type alias Model =
    {}
