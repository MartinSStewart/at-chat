module Evergreen.V403.Game exposing (..)

import Array
import Evergreen.V403.Go
import Evergreen.V403.Id
import Evergreen.V403.Message
import Evergreen.V403.SecretId
import Evergreen.V403.SheepGame
import Evergreen.V403.UserSession
import Evergreen.V403.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V403.Go.GameMsg
    | GoSetupMsg Evergreen.V403.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V403.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V403.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V403.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V403.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V403.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V403.Go.ValidatedSetup (Array.Array Evergreen.V403.Go.ActionWithTime) Evergreen.V403.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V403.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V403.WordSpellingGame.ActionWithTime) Evergreen.V403.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V403.SheepGame.ValidatedSetup (Array.Array Evergreen.V403.SheepGame.ActionWithTime) Evergreen.V403.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V403.SecretId.SecretId Evergreen.V403.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V403.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V403.Go.ValidatedSetup (Array.Array Evergreen.V403.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V403.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V403.WordSpellingGame.ActionWithTime) Evergreen.V403.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V403.SheepGame.ValidatedSetup (Array.Array Evergreen.V403.SheepGame.ActionWithTime) Evergreen.V403.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V403.SecretId.SecretId Evergreen.V403.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.UserSession.ToBeFilledInByBackend (Evergreen.V403.SecretId.SecretId Evergreen.V403.Id.GamePublicId))
    | LoadMatch (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V403.Go.GameModel
    | WordSpellingGame_Game Evergreen.V403.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V403.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V403.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V403.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V403.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId, Evergreen.V403.SheepGame.Input ) Int
    }
