module Evergreen.V354.TextEditor exposing (..)

import Array
import Evergreen.V354.Id
import Evergreen.V354.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V354.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Int
    , history : Array.Array ( Evergreen.V354.Id.Id Evergreen.V354.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId)
    | Server_Redo (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId)


type alias Model =
    {}
