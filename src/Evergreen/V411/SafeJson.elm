module Evergreen.V411.SafeJson exposing (..)

import Dict
import Evergreen.V411.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V411.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
