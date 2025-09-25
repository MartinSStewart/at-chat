module Evergreen.V108.Log exposing (..)

import Effect.Http
import Evergreen.V108.EmailAddress
import Evergreen.V108.Id
import Evergreen.V108.Postmark


type Log
    = LoginEmail (Result Evergreen.V108.Postmark.SendEmailError ()) Evergreen.V108.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId)
    | ChangedUsers (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V108.Postmark.SendEmailError Evergreen.V108.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Effect.Http.Error
