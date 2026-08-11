module SessionIdHash exposing (SessionIdHash(..), fromSessionId, fromString, toString)

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
