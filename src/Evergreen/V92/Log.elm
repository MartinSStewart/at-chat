module Evergreen.V92.Log exposing (..)

import Effect.Http
import Evergreen.V92.EmailAddress
import Evergreen.V92.Id
import Evergreen.V92.Postmark


type Log
    = LoginEmail (Result Evergreen.V92.Postmark.SendEmailError ()) Evergreen.V92.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId)
    | ChangedUsers (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V92.Postmark.SendEmailError Evergreen.V92.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) Effect.Http.Error
