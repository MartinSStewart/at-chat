module Evergreen.V401.Game exposing (..)

import Array
import Evergreen.V401.Go
import Evergreen.V401.Id
import Evergreen.V401.Message
import Evergreen.V401.SecretId
import Evergreen.V401.SheepGame
import Evergreen.V401.UserSession
import Evergreen.V401.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V401.Go.GameMsg
    | GoSetupMsg Evergreen.V401.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V401.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V401.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V401.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V401.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V401.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V401.Go.ValidatedSetup (Array.Array Evergreen.V401.Go.ActionWithTime) Evergreen.V401.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V401.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V401.WordSpellingGame.ActionWithTime) Evergreen.V401.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V401.SheepGame.ValidatedSetup (Array.Array Evergreen.V401.SheepGame.ActionWithTime) Evergreen.V401.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V401.SecretId.SecretId Evergreen.V401.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V401.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V401.Go.ValidatedSetup (Array.Array Evergreen.V401.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V401.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V401.WordSpellingGame.ActionWithTime) Evergreen.V401.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V401.SheepGame.ValidatedSetup (Array.Array Evergreen.V401.SheepGame.ActionWithTime) Evergreen.V401.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V401.SecretId.SecretId Evergreen.V401.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.UserSession.ToBeFilledInByBackend (Evergreen.V401.SecretId.SecretId Evergreen.V401.Id.GamePublicId))
    | LoadMatch (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V401.Go.GameModel
    | WordSpellingGame_Game Evergreen.V401.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V401.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V401.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V401.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V401.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId, Evergreen.V401.SheepGame.Input ) Int
    }
