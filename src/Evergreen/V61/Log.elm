module Evergreen.V61.Log exposing (..)

import Effect.Http
import Evergreen.V61.EmailAddress
import Evergreen.V61.Id
import Evergreen.V61.Postmark


type Log
    = LoginEmail (Result Evergreen.V61.Postmark.SendEmailError ()) Evergreen.V61.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId)
    | ChangedUsers (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V61.Postmark.SendEmailError Evergreen.V61.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Effect.Http.Error
    | RegisteredPushNotificationRequest (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId)
