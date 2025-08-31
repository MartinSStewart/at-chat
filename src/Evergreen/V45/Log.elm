module Evergreen.V45.Log exposing (..)

import Effect.Http
import Evergreen.V45.EmailAddress
import Evergreen.V45.Id
import Evergreen.V45.Postmark


type Log
    = LoginEmail (Result Evergreen.V45.Postmark.SendEmailError ()) Evergreen.V45.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId)
    | ChangedUsers (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V45.Postmark.SendEmailError Evergreen.V45.EmailAddress.EmailAddress
    | PushNotificationError Effect.Http.Error
    | RegisteredPushNotificationRequest (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId)
