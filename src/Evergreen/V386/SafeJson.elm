module Evergreen.V386.SafeJson exposing (..)

import Dict
import Evergreen.V386.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V386.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
