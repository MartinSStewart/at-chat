module Evergreen.V101.Log exposing (..)

import Effect.Http
import Evergreen.V101.EmailAddress
import Evergreen.V101.Id
import Evergreen.V101.Postmark


type Log
    = LoginEmail (Result Evergreen.V101.Postmark.SendEmailError ()) Evergreen.V101.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId)
    | ChangedUsers (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V101.Postmark.SendEmailError Evergreen.V101.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) Effect.Http.Error
