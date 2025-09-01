module Evergreen.V46.Log exposing (..)

import Effect.Http
import Evergreen.V46.EmailAddress
import Evergreen.V46.Id
import Evergreen.V46.Postmark


type Log
    = LoginEmail (Result Evergreen.V46.Postmark.SendEmailError ()) Evergreen.V46.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId)
    | ChangedUsers (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V46.Postmark.SendEmailError Evergreen.V46.EmailAddress.EmailAddress
    | PushNotificationError Effect.Http.Error
    | RegisteredPushNotificationRequest (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId)
