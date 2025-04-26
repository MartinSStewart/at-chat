module TwoFactorAuthentication exposing
    ( TwoFactorAuthentication
    , TwoFactorAuthenticationSetup
    , TwoFactorSecret
    , getCode
    , getConfig
    , isValidCode
    )

import Duration
import Effect.Time as Time
import Env
import Id exposing (Id)
import TOTP.Algorithm
import TOTP.Key


type alias TwoFactorAuthentication =
    { secret : Id TwoFactorSecret
    , finishedAt : Time.Posix
    }


type alias TwoFactorAuthenticationSetup =
    { secret : Id TwoFactorSecret
    , startedAt : Time.Posix
    }


type TwoFactorSecret
    = TwoFactorSecret Never


getConfig : String -> Id TwoFactorSecret -> Result String TOTP.Key.Key
getConfig user secret =
    TOTP.Key.init
        { issuer = Env.companyName
        , user = user
        , rawSecret = Id.toString secret
        , outputLength =
            -- We can leave this as nothing since the default is 6 and not including it makes the QR code a bit smaller
            Nothing
        , periodSeconds =
            -- We can leave this as nothing since the default is 30 and not including it makes the QR code a bit smaller
            Nothing
        , algorithm =
            -- You can't change this value. Google Authenticator will ignore this setting and always use SHA1. If you change this, it will make it impossible for anyone setting up 2FA to use Google Authenticator.
            TOTP.Algorithm.SHA1
        }


{-| You can't change this value. Google Authenticator will ignore this setting and always use 30. If you change this, it will make it impossible for anyone setting up 2FA to use Google Authenticator.
-}
periodSeconds : number
periodSeconds =
    30


isValidCode : Time.Posix -> Int -> Id TwoFactorSecret -> Bool
isValidCode time code secret =
    case getConfig "" secret of
        Ok config ->
            List.any
                (\t ->
                    case getCode t config of
                        Just expectedCode ->
                            expectedCode == code

                        Nothing ->
                            False
                )
                [ time
                , Duration.addTo time (Duration.seconds periodSeconds)
                , Duration.addTo time (Duration.seconds -periodSeconds)
                ]

        Err _ ->
            False


getCode : Time.Posix -> TOTP.Key.Key -> Maybe Int
getCode time config =
    case TOTP.Key.code time config of
        Ok ok ->
            String.toInt ok

        Err _ ->
            Nothing
