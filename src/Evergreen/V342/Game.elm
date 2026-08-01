module Evergreen.V342.Game exposing (..)

import Array
import Evergreen.V342.Go
import Evergreen.V342.Id
import Evergreen.V342.Message
import Evergreen.V342.SecretId
import Evergreen.V342.UserSession
import Evergreen.V342.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V342.Go.GameMsg
    | GoSetupMsg Evergreen.V342.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V342.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V342.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V342.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V342.Go.ValidatedSetup (Array.Array Evergreen.V342.Go.ActionWithTime) Evergreen.V342.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V342.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V342.WordSpellingGame.ActionWithTime) Evergreen.V342.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V342.SecretId.SecretId Evergreen.V342.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.UserSession.ToBeFilledInByBackend (Evergreen.V342.SecretId.SecretId Evergreen.V342.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) Evergreen.V342.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) Evergreen.V342.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V342.Go.GameModel
    | WordSpellingGame_Game Evergreen.V342.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V342.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V342.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V342.Go.ValidatedSetup (Array.Array Evergreen.V342.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V342.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V342.WordSpellingGame.ActionWithTime) Evergreen.V342.WordSpellingGame.Shared
