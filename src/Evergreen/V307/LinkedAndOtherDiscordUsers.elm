module Evergreen.V307.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V307.Discord
import Evergreen.V307.DiscordUserData
import Evergreen.V307.EmailAddress
import Evergreen.V307.FileStatus
import Evergreen.V307.PersonName
import Evergreen.V307.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V307.PersonName.PersonName
    , icon : Maybe Evergreen.V307.FileStatus.FileHash
    , email : Maybe Evergreen.V307.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V307.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) Evergreen.V307.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) DiscordFrontendCurrentUser)
