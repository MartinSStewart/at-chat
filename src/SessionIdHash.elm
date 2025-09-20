module SessionIdHash exposing (..)

import Effect.Lamdera
import Sha256


type SessionIdHash
    = SessionIdHash String


toString : SessionIdHash -> String
toString (SessionIdHash a) =
    a


fromSessionId : Effect.Lamdera.SessionId -> SessionIdHash
fromSessionId sessionId =
    Effect.Lamdera.sessionIdToString sessionId |> Sha256.sha224 |> SessionIdHash


fromString : String -> SessionIdHash
fromString =
    SessionIdHash
