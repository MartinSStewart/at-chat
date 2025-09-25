module Evergreen.V104.Log exposing (..)

import Effect.Http
import Evergreen.V104.EmailAddress
import Evergreen.V104.Id
import Evergreen.V104.Postmark


type Log
    = LoginEmail (Result Evergreen.V104.Postmark.SendEmailError ()) Evergreen.V104.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId)
    | ChangedUsers (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V104.Postmark.SendEmailError Evergreen.V104.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) Effect.Http.Error
