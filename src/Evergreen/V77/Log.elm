module Evergreen.V77.Log exposing (..)

import Effect.Http
import Evergreen.V77.EmailAddress
import Evergreen.V77.Id
import Evergreen.V77.Postmark


type Log
    = LoginEmail (Result Evergreen.V77.Postmark.SendEmailError ()) Evergreen.V77.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId)
    | ChangedUsers (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V77.Postmark.SendEmailError Evergreen.V77.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Effect.Http.Error
