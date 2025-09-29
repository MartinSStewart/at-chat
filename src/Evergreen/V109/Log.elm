module Evergreen.V109.Log exposing (..)

import Effect.Http
import Evergreen.V109.EmailAddress
import Evergreen.V109.Id
import Evergreen.V109.Postmark


type Log
    = LoginEmail (Result Evergreen.V109.Postmark.SendEmailError ()) Evergreen.V109.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId)
    | ChangedUsers (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V109.Postmark.SendEmailError Evergreen.V109.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Effect.Http.Error
