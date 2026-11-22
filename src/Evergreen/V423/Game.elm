module Evergreen.V423.Game exposing (..)

import Array
import Evergreen.V423.Go
import Evergreen.V423.Id
import Evergreen.V423.Message
import Evergreen.V423.SecretId
import Evergreen.V423.SheepGame
import Evergreen.V423.UserSession
import Evergreen.V423.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V423.Go.GameMsg
    | GoSetupMsg Evergreen.V423.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V423.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V423.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V423.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V423.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V423.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V423.Go.ValidatedSetup (Array.Array Evergreen.V423.Go.ActionWithTime) Evergreen.V423.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V423.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V423.WordSpellingGame.ActionWithTime) Evergreen.V423.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V423.SheepGame.ValidatedSetup (Array.Array Evergreen.V423.SheepGame.ActionWithTime) Evergreen.V423.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V423.SecretId.SecretId Evergreen.V423.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V423.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V423.Go.ValidatedSetup (Array.Array Evergreen.V423.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V423.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V423.WordSpellingGame.ActionWithTime) Evergreen.V423.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V423.SheepGame.ValidatedSetup (Array.Array Evergreen.V423.SheepGame.ActionWithTime) Evergreen.V423.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V423.SecretId.SecretId Evergreen.V423.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.UserSession.ToBeFilledInByBackend (Evergreen.V423.SecretId.SecretId Evergreen.V423.Id.GamePublicId))
    | LoadMatch (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V423.Go.GameModel
    | WordSpellingGame_Game Evergreen.V423.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V423.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V423.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V423.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V423.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId, Evergreen.V423.SheepGame.Input ) Int
    }
