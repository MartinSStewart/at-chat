module Evergreen.V59.Log exposing (..)

import Effect.Http
import Evergreen.V59.EmailAddress
import Evergreen.V59.Id
import Evergreen.V59.Postmark


type Log
    = LoginEmail (Result Evergreen.V59.Postmark.SendEmailError ()) Evergreen.V59.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId)
    | ChangedUsers (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V59.Postmark.SendEmailError Evergreen.V59.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Effect.Http.Error
    | RegisteredPushNotificationRequest (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId)
