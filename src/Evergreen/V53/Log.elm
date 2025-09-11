module Evergreen.V53.Log exposing (..)

import Effect.Http
import Evergreen.V53.EmailAddress
import Evergreen.V53.Id
import Evergreen.V53.Postmark


type Log
    = LoginEmail (Result Evergreen.V53.Postmark.SendEmailError ()) Evergreen.V53.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId)
    | ChangedUsers (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V53.Postmark.SendEmailError Evergreen.V53.EmailAddress.EmailAddress
    | PushNotificationError Effect.Http.Error
    | RegisteredPushNotificationRequest (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId)
