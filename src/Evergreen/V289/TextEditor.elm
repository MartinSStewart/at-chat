module Evergreen.V289.TextEditor exposing (..)

import Array
import Evergreen.V289.Id
import Evergreen.V289.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V289.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Int
    , history : Array.Array ( Evergreen.V289.Id.Id Evergreen.V289.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Evergreen.V289.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId)
    | Server_Redo (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
