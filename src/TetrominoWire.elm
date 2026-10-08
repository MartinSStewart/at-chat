module TetrominoWire exposing (decodeMatchState, encodeMatchState)

{-| A match's state goes from one player to another through the backend as bytes, so the backend
passes it on without reading it.

These functions are in a separate module because Intellij flags w3\_\* functions as missing and
that's annoying to look at while doing other stuff.

-}

import Bytes exposing (Bytes)
import Lamdera.Wire3
import TetrominoSim exposing (MatchState)


encodeMatchState : MatchState -> Bytes
encodeMatchState state =
    Lamdera.Wire3.bytesEncode (TetrominoSim.w3_encode_MatchState state)


decodeMatchState : Bytes -> Maybe MatchState
decodeMatchState bytes =
    Lamdera.Wire3.bytesDecode TetrominoSim.w3_decode_MatchState bytes
