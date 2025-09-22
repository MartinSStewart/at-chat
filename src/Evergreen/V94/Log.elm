module Evergreen.V94.Log exposing (..)

import Effect.Http
import Evergreen.V94.EmailAddress
import Evergreen.V94.Id
import Evergreen.V94.Postmark


type Log
    = LoginEmail (Result Evergreen.V94.Postmark.SendEmailError ()) Evergreen.V94.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId)
    | ChangedUsers (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V94.Postmark.SendEmailError Evergreen.V94.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) Effect.Http.Error
