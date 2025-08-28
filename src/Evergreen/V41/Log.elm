module Evergreen.V41.Log exposing (..)

import Effect.Http
import Evergreen.V41.EmailAddress
import Evergreen.V41.Id
import Evergreen.V41.Postmark


type Log
    = LoginEmail (Result Evergreen.V41.Postmark.SendEmailError ()) Evergreen.V41.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId)
    | ChangedUsers (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V41.Postmark.SendEmailError Evergreen.V41.EmailAddress.EmailAddress
    | PushNotificationError Effect.Http.Error
