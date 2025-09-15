module Evergreen.V60.Log exposing (..)

import Effect.Http
import Evergreen.V60.EmailAddress
import Evergreen.V60.Id
import Evergreen.V60.Postmark


type Log
    = LoginEmail (Result Evergreen.V60.Postmark.SendEmailError ()) Evergreen.V60.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId)
    | ChangedUsers (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V60.Postmark.SendEmailError Evergreen.V60.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Effect.Http.Error
    | RegisteredPushNotificationRequest (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId)
