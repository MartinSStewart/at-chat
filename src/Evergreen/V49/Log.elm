module Evergreen.V49.Log exposing (..)

import Effect.Http
import Evergreen.V49.EmailAddress
import Evergreen.V49.Id
import Evergreen.V49.Postmark


type Log
    = LoginEmail (Result Evergreen.V49.Postmark.SendEmailError ()) Evergreen.V49.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)
    | ChangedUsers (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V49.Postmark.SendEmailError Evergreen.V49.EmailAddress.EmailAddress
    | PushNotificationError Effect.Http.Error
    | RegisteredPushNotificationRequest (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)
