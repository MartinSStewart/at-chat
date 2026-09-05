module Evergreen.V368.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V368.Discord
import Evergreen.V368.DiscordUserData
import Evergreen.V368.EmailAddress
import Evergreen.V368.FileStatus
import Evergreen.V368.PersonName
import Evergreen.V368.UserColor
import Evergreen.V368.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V368.PersonName.PersonName
    , color : Evergreen.V368.UserColor.UserColor
    , icon : Maybe Evergreen.V368.FileStatus.FileHash
    , email : Maybe Evergreen.V368.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V368.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) Evergreen.V368.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) DiscordFrontendCurrentUser)
