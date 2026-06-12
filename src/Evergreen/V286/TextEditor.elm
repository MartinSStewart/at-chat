module Evergreen.V286.TextEditor exposing (..)

import Array
import Evergreen.V286.Id
import Evergreen.V286.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V286.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Int
    , history : Array.Array ( Evergreen.V286.Id.Id Evergreen.V286.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Evergreen.V286.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId)
    | Server_Redo (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
