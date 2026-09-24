module Evergreen.V385.SafeJson exposing (..)

import Dict
import Evergreen.V385.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V385.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
