module Evergreen.V388.SafeJson exposing (..)

import Dict
import Evergreen.V388.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V388.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
