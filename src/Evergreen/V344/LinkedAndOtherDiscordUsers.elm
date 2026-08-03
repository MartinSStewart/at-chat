module Evergreen.V344.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V344.Discord
import Evergreen.V344.DiscordUserData
import Evergreen.V344.EmailAddress
import Evergreen.V344.FileStatus
import Evergreen.V344.PersonName
import Evergreen.V344.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V344.PersonName.PersonName
    , icon : Maybe Evergreen.V344.FileStatus.FileHash
    , email : Maybe Evergreen.V344.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V344.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) Evergreen.V344.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) DiscordFrontendCurrentUser)
