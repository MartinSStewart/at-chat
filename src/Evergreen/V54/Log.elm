module Evergreen.V54.Log exposing (..)

import Effect.Http
import Evergreen.V54.EmailAddress
import Evergreen.V54.Id
import Evergreen.V54.Postmark


type Log
    = LoginEmail (Result Evergreen.V54.Postmark.SendEmailError ()) Evergreen.V54.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId)
    | ChangedUsers (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V54.Postmark.SendEmailError Evergreen.V54.EmailAddress.EmailAddress
    | PushNotificationError Effect.Http.Error
    | RegisteredPushNotificationRequest (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId)
