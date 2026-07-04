module Evergreen.V302.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V302.Discord
import Evergreen.V302.DiscordUserData
import Evergreen.V302.EmailAddress
import Evergreen.V302.FileStatus
import Evergreen.V302.PersonName
import Evergreen.V302.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V302.PersonName.PersonName
    , icon : Maybe Evergreen.V302.FileStatus.FileHash
    , email : Maybe Evergreen.V302.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V302.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) Evergreen.V302.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) DiscordFrontendCurrentUser)
