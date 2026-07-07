module Evergreen.V305.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V305.Discord
import Evergreen.V305.DiscordUserData
import Evergreen.V305.EmailAddress
import Evergreen.V305.FileStatus
import Evergreen.V305.PersonName
import Evergreen.V305.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V305.PersonName.PersonName
    , icon : Maybe Evergreen.V305.FileStatus.FileHash
    , email : Maybe Evergreen.V305.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V305.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) Evergreen.V305.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) DiscordFrontendCurrentUser)
