module Evergreen.V56.Log exposing (..)

import Effect.Http
import Evergreen.V56.EmailAddress
import Evergreen.V56.Id
import Evergreen.V56.Postmark


type Log
    = LoginEmail (Result Evergreen.V56.Postmark.SendEmailError ()) Evergreen.V56.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)
    | ChangedUsers (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V56.Postmark.SendEmailError Evergreen.V56.EmailAddress.EmailAddress
    | PushNotificationError Effect.Http.Error
    | RegisteredPushNotificationRequest (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)
