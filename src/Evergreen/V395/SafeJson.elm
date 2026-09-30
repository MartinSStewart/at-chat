module Evergreen.V395.SafeJson exposing (..)

import Dict
import Evergreen.V395.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V395.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
