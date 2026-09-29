module Evergreen.V394.SafeJson exposing (..)

import Dict
import Evergreen.V394.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V394.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
