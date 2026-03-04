module SecretId exposing (SecretId(..), fromString, getShortUniqueId, getUniqueId, toString)

import Effect.Time as Time
import Env
import Sha256


{-| OpaqueVariants
-}
type SecretId a
    = SecretId String


getUniqueId : Time.Posix -> { a | secretCounter : Int } -> ( { a | secretCounter : Int }, SecretId b )
getUniqueId time model =
    ( { model | secretCounter = model.secretCounter + 1 }
    , Env.secretKey
        ++ ":"
        ++ String.fromInt model.secretCounter
        ++ ":"
        ++ (if Env.isProduction then
                String.fromInt (Time.posixToMillis time)

            else
                ""
           )
        |> Sha256.sha256
        |> SecretId
    )


getShortUniqueId : Time.Posix -> { a | secretCounter : Int } -> ( { a | secretCounter : Int }, SecretId b )
getShortUniqueId time model =
    ( { model | secretCounter = model.secretCounter + 1 }
    , Env.secretKey
        ++ ":"
        ++ String.fromInt model.secretCounter
        ++ ":"
        ++ (if Env.isProduction then
                String.fromInt (Time.posixToMillis time)

            else
                ""
           )
        |> Sha256.sha256
        |> String.left 16
        |> SecretId
    )


toString : SecretId a -> String
toString (SecretId text) =
    text


fromString : String -> SecretId a
fromString =
    SecretId
