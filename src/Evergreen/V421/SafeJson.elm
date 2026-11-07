module Evergreen.V421.SafeJson exposing (..)

import Dict
import Evergreen.V421.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V421.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
