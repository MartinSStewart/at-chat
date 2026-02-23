module Evergreen.V119.Local exposing (..)

import Dict
import Time


type ChangeId
    = ChangeId Int


type Local msg model
    = Local
        { localMsgs :
            Dict.Dict
                Int
                { createdAt : Time.Posix
                , msg : msg
                }
        , localModel : model
        , serverModel : model
        , counter : ChangeId
        }
