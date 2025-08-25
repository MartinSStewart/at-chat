module Image exposing (Error(..), Image(..), defaultSize, image)

import Pixels exposing (Pixels)
import Quantity exposing (Quantity)


type Image
    = Image String


type Error
    = InvalidDataUrlPrefix
    | StringIsTooLong


prefix : String
prefix =
    "data:image/png;base64,"


image : String -> Result Error Image
image data =
    if String.length data > 100000 then
        Err StringIsTooLong

    else if String.startsWith prefix data |> not then
        Err InvalidDataUrlPrefix

    else
        Image (String.dropLeft (String.length prefix) data) |> Ok


defaultSize : Quantity Int Pixels
defaultSize =
    Pixels.pixels 80
