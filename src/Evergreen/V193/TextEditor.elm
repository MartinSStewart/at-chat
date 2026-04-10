module Evergreen.V193.TextEditor exposing (..)

import Array
import Evergreen.V193.Id
import Evergreen.V193.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V193.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Int
    , history : Array.Array ( Evergreen.V193.Id.Id Evergreen.V193.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Evergreen.V193.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId)
    | Server_Redo (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
