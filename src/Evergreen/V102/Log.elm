module Evergreen.V102.Log exposing (..)

import Effect.Http
import Evergreen.V102.EmailAddress
import Evergreen.V102.Id
import Evergreen.V102.Postmark


type Log
    = LoginEmail (Result Evergreen.V102.Postmark.SendEmailError ()) Evergreen.V102.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId)
    | ChangedUsers (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V102.Postmark.SendEmailError Evergreen.V102.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) Effect.Http.Error
