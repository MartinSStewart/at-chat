module Evergreen.V298.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V298.Discord
import Evergreen.V298.DiscordUserData
import Evergreen.V298.EmailAddress
import Evergreen.V298.FileStatus
import Evergreen.V298.PersonName
import Evergreen.V298.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V298.PersonName.PersonName
    , icon : Maybe Evergreen.V298.FileStatus.FileHash
    , email : Maybe Evergreen.V298.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V298.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) Evergreen.V298.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) DiscordFrontendCurrentUser)
