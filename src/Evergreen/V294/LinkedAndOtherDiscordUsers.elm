module Evergreen.V294.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V294.Discord
import Evergreen.V294.DiscordUserData
import Evergreen.V294.EmailAddress
import Evergreen.V294.FileStatus
import Evergreen.V294.PersonName
import Evergreen.V294.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V294.PersonName.PersonName
    , icon : Maybe Evergreen.V294.FileStatus.FileHash
    , email : Maybe Evergreen.V294.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V294.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) Evergreen.V294.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) DiscordFrontendCurrentUser)
