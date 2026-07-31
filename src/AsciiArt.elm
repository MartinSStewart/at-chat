module AsciiArt exposing (AsciiArt, art)

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import List.Nonempty exposing (Nonempty(..))


type alias AsciiArt =
    { url : String
    , coordinates : Coord CssPixels
    , size : Coord CssPixels
    }


art : Nonempty AsciiArt
art =
    Nonempty
        { url = "ascii-bari-gisher"
        , coordinates = Coord.xy 1173 -47
        , size = Coord.xy 276 103
        }
        [ { url = "ascii-sw-home"
          , coordinates = Coord.xy -434 -141
          , size = Coord.xy 365 371
          }
        ]



--https://ascii-collab.app/?x=-169&y=-176 Box house
--https://ascii-collab.app/?x=-723&y=-150 Sandwich
--https://ascii-collab.app/?x=-892&y=-187 PrincS
--https://ascii-collab.app/?x=-662&y=-344 Crab
--https://ascii-collab.app/?x=-630&y=-344 Squirrel
--https://ascii-collab.app/?x=-860&y=-353 Large cat
--https://ascii-collab.app/?x=-812&y=-226 Bat
--https://ascii-collab.app/?x=-189&y=169 Paintings
--https://ascii-collab.app/?x=24&y=146 Key
--https://ascii-collab.app/?x=23&y=-58 Fishermoon
--https://ascii-collab.app/?x=125&y=-91 Lamb
--https://ascii-collab.app/?x=189&y=-202 Cat and fish
--https://ascii-collab.app/?x=621&y=-20 Snail
--https://ascii-collab.app/?x=1173&y=-47 Bari gisher
--https://ascii-collab.app/?x=916&y=201 Sister
--https://ascii-collab.app/?x=707&y=192 Brother
--https://ascii-collab.app/?x=326&y=95 Cheese
--https://ascii-collab.app/?x=-730&y=-169 Ice cream
--https://ascii-collab.app/?x=-68&y=122 Party popper
