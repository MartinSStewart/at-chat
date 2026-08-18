module Evergreen.V357.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V357.Discord
import Evergreen.V357.DiscordUserData
import Evergreen.V357.EmailAddress
import Evergreen.V357.FileStatus
import Evergreen.V357.PersonName
import Evergreen.V357.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V357.PersonName.PersonName
    , icon : Maybe Evergreen.V357.FileStatus.FileHash
    , email : Maybe Evergreen.V357.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V357.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) Evergreen.V357.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) DiscordFrontendCurrentUser)
