module Evergreen.V318.TextEditor exposing (..)

import Array
import Evergreen.V318.Id
import Evergreen.V318.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V318.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Int
    , history : Array.Array ( Evergreen.V318.Id.Id Evergreen.V318.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Evergreen.V318.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId)
    | Server_Redo (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId)


type alias Model =
    {}
