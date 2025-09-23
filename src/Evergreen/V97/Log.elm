module Evergreen.V97.Log exposing (..)

import Effect.Http
import Evergreen.V97.EmailAddress
import Evergreen.V97.Id
import Evergreen.V97.Postmark


type Log
    = LoginEmail (Result Evergreen.V97.Postmark.SendEmailError ()) Evergreen.V97.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId)
    | ChangedUsers (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V97.Postmark.SendEmailError Evergreen.V97.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Effect.Http.Error
