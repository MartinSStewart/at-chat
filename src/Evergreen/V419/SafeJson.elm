module Evergreen.V419.SafeJson exposing (..)

import Dict
import Evergreen.V419.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V419.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
