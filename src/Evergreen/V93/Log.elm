module Evergreen.V93.Log exposing (..)

import Effect.Http
import Evergreen.V93.EmailAddress
import Evergreen.V93.Id
import Evergreen.V93.Postmark


type Log
    = LoginEmail (Result Evergreen.V93.Postmark.SendEmailError ()) Evergreen.V93.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId)
    | ChangedUsers (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V93.Postmark.SendEmailError Evergreen.V93.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Effect.Http.Error
