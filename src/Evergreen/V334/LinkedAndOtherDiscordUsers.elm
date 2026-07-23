module Evergreen.V334.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V334.Discord
import Evergreen.V334.DiscordUserData
import Evergreen.V334.EmailAddress
import Evergreen.V334.FileStatus
import Evergreen.V334.PersonName
import Evergreen.V334.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V334.PersonName.PersonName
    , icon : Maybe Evergreen.V334.FileStatus.FileHash
    , email : Maybe Evergreen.V334.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V334.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) Evergreen.V334.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) DiscordFrontendCurrentUser)
