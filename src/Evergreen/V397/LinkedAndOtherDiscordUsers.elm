module Evergreen.V397.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V397.Discord
import Evergreen.V397.DiscordUserData
import Evergreen.V397.EmailAddress
import Evergreen.V397.FileStatus
import Evergreen.V397.PersonName
import Evergreen.V397.UserColor
import Evergreen.V397.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V397.PersonName.PersonName
    , color : Evergreen.V397.UserColor.UserColor
    , icon : Maybe Evergreen.V397.FileStatus.FileHash
    , email : Maybe Evergreen.V397.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V397.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) Evergreen.V397.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) DiscordFrontendCurrentUser)
