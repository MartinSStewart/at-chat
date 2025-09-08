module Evergreen.V52.Log exposing (..)

import Effect.Http
import Evergreen.V52.EmailAddress
import Evergreen.V52.Id
import Evergreen.V52.Postmark


type Log
    = LoginEmail (Result Evergreen.V52.Postmark.SendEmailError ()) Evergreen.V52.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId)
    | ChangedUsers (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V52.Postmark.SendEmailError Evergreen.V52.EmailAddress.EmailAddress
    | PushNotificationError Effect.Http.Error
    | RegisteredPushNotificationRequest (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId)
