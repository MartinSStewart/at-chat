module SessionIdHash exposing (SessionIdHash(..), codec, fromSessionId, fromString, toString)

import Codec exposing (Codec)
import Effect.Lamdera as Lamdera
import Sha256


type SessionIdHash
    = SessionIdHash String


toString : SessionIdHash -> String
toString (SessionIdHash a) =
    a


fromSessionId : Lamdera.SessionId -> SessionIdHash
fromSessionId sessionId =
    Lamdera.sessionIdToString sessionId |> Sha256.sha224 |> SessionIdHash


fromString : String -> SessionIdHash
fromString =
    SessionIdHash


codec : Codec SessionIdHash
codec =
    Codec.map fromString toString Codec.string
