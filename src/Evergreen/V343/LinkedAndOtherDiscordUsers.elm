module Evergreen.V343.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V343.Discord
import Evergreen.V343.DiscordUserData
import Evergreen.V343.EmailAddress
import Evergreen.V343.FileStatus
import Evergreen.V343.PersonName
import Evergreen.V343.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V343.PersonName.PersonName
    , icon : Maybe Evergreen.V343.FileStatus.FileHash
    , email : Maybe Evergreen.V343.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V343.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) Evergreen.V343.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) DiscordFrontendCurrentUser)
