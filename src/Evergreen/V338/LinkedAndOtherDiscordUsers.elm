module Evergreen.V338.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V338.Discord
import Evergreen.V338.DiscordUserData
import Evergreen.V338.EmailAddress
import Evergreen.V338.FileStatus
import Evergreen.V338.PersonName
import Evergreen.V338.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V338.PersonName.PersonName
    , icon : Maybe Evergreen.V338.FileStatus.FileHash
    , email : Maybe Evergreen.V338.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V338.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) Evergreen.V338.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) DiscordFrontendCurrentUser)
