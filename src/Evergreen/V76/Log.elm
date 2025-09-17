module Evergreen.V76.Log exposing (..)

import Effect.Http
import Evergreen.V76.EmailAddress
import Evergreen.V76.Id
import Evergreen.V76.Postmark


type Log
    = LoginEmail (Result Evergreen.V76.Postmark.SendEmailError ()) Evergreen.V76.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId)
    | ChangedUsers (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V76.Postmark.SendEmailError Evergreen.V76.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Effect.Http.Error
