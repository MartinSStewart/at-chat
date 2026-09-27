module Evergreen.V388.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V388.Discord
import Evergreen.V388.DiscordUserData
import Evergreen.V388.EmailAddress
import Evergreen.V388.FileStatus
import Evergreen.V388.PersonName
import Evergreen.V388.UserColor
import Evergreen.V388.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V388.PersonName.PersonName
    , color : Evergreen.V388.UserColor.UserColor
    , icon : Maybe Evergreen.V388.FileStatus.FileHash
    , email : Maybe Evergreen.V388.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V388.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) Evergreen.V388.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) DiscordFrontendCurrentUser)
