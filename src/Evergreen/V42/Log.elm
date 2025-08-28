module Evergreen.V42.Log exposing (..)

import Effect.Http
import Evergreen.V42.EmailAddress
import Evergreen.V42.Id
import Evergreen.V42.Postmark


type Log
    = LoginEmail (Result Evergreen.V42.Postmark.SendEmailError ()) Evergreen.V42.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId)
    | ChangedUsers (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V42.Postmark.SendEmailError Evergreen.V42.EmailAddress.EmailAddress
    | PushNotificationError Effect.Http.Error
    | RegisteredPushNotificationRequest (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId)
