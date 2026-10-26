module Evergreen.V412.SafeJson exposing (..)

import Dict
import Evergreen.V412.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V412.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
