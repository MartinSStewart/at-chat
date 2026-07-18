module Evergreen.V327.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V327.Discord
import Evergreen.V327.DiscordUserData
import Evergreen.V327.EmailAddress
import Evergreen.V327.FileStatus
import Evergreen.V327.PersonName
import Evergreen.V327.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V327.PersonName.PersonName
    , icon : Maybe Evergreen.V327.FileStatus.FileHash
    , email : Maybe Evergreen.V327.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V327.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) Evergreen.V327.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) DiscordFrontendCurrentUser)
