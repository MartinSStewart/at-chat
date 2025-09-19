module Evergreen.V90.Log exposing (..)

import Effect.Http
import Evergreen.V90.EmailAddress
import Evergreen.V90.Id
import Evergreen.V90.Postmark


type Log
    = LoginEmail (Result Evergreen.V90.Postmark.SendEmailError ()) Evergreen.V90.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId)
    | ChangedUsers (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V90.Postmark.SendEmailError Evergreen.V90.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) Effect.Http.Error
