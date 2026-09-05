module AsciiArt exposing (AsciiArt, art)

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import List.Nonempty exposing (Nonempty(..))


{-| One drawing from <https://ascii-collab.app>. `url` names the image in public/art (without
the .png), `coordinates` is where the drawing sits on the ascii-collab canvas
(<https://ascii-collab.app/?x=&y=>), and `size` is how many pixels the image is, which is what
the scale factor it's drawn at is worked out from.
-}
type alias AsciiArt =
    { url : String
    , coordinates : Coord CssPixels
    , size : Coord CssPixels
    }


art : Nonempty AsciiArt
art =
    Nonempty
        { url = "ascii-party-popper"
        , coordinates = Coord.xy -68 122
        , size = Coord.xy 145 157
        }
        [ { url = "ascii-bari-gisher"
          , coordinates = Coord.xy 1173 -47
          , size = Coord.xy 276 103
          }
        , { url = "ascii-fishermoon"
          , coordinates = Coord.xy 23 -58
          , size = Coord.xy 284 229
          }
        , { url = "ascii-lamb"
          , coordinates = Coord.xy 125 -91
          , size = Coord.xy 122 134
          }
        , { url = "ascii-sandwich"
          , coordinates = Coord.xy -723 -150
          , size = Coord.xy 385 309
          }
        , { url = "ascii-princess"
          , coordinates = Coord.xy -892 -187
          , size = Coord.xy 399 747
          }
        , { url = "ascii-crab"
          , coordinates = Coord.xy -662 -344
          , size = Coord.xy 163 76
          }
        , { url = "ascii-squirrel"
          , coordinates = Coord.xy -630 -344
          , size = Coord.xy 137 127
          }
        , { url = "ascii-cat-and-soup"
          , coordinates = Coord.xy -860 -353
          , size = Coord.xy 286 136
          }
        , { url = "ascii-bat"
          , coordinates = Coord.xy -812 -226
          , size = Coord.xy 297 101
          }
        , { url = "ascii-paintings"
          , coordinates = Coord.xy -189 169
          , size = Coord.xy 483 147
          }
        , { url = "ascii-key"
          , coordinates = Coord.xy 24 146
          , size = Coord.xy 205 203
          }
        , { url = "ascii-cat-and-fish"
          , coordinates = Coord.xy 189 -202
          , size = Coord.xy 266 298
          }
        , { url = "ascii-snail"
          , coordinates = Coord.xy 621 -20
          , size = Coord.xy 255 215
          }
        , { url = "ascii-sister"
          , coordinates = Coord.xy 916 201
          , size = Coord.xy 214 216
          }
        , { url = "ascii-brother"
          , coordinates = Coord.xy 707 192
          , size = Coord.xy 245 274
          }
        , { url = "ascii-cheese"
          , coordinates = Coord.xy 326 95
          , size = Coord.xy 255 222
          }
        , { url = "ascii-ice-cream"
          , coordinates = Coord.xy -730 -169
          , size = Coord.xy 103 282
          }
        , { url = "ascii-sw-home"
          , coordinates = Coord.xy -434 -141
          , size = Coord.xy 365 371
          }
        , { url = "ascii-box-house"
          , coordinates = Coord.xy -169 -176
          , size = Coord.xy 303 198
          }
        , { url = "ascii-man-on-moon"
          , coordinates = Coord.xy 89 -243
          , size = Coord.xy 765 401
          }
        , { url = "ascii-at-chat-logo"
          , coordinates = Coord.xy -557 350
          , size = Coord.xy 82 84
          }
        ]
