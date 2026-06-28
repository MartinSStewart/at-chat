module Evergreen.V296.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V296.Discord
import Evergreen.V296.DiscordUserData
import Evergreen.V296.EmailAddress
import Evergreen.V296.FileStatus
import Evergreen.V296.PersonName
import Evergreen.V296.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V296.PersonName.PersonName
    , icon : Maybe Evergreen.V296.FileStatus.FileHash
    , email : Maybe Evergreen.V296.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V296.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) Evergreen.V296.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) DiscordFrontendCurrentUser)
